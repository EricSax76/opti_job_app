/**
 * Callable: createInvitation
 *
 * Genera un código de invitación de 6 caracteres para que un administrador
 * añada nuevos reclutadores a su empresa.
 *
 * Solo puede ser llamada por reclutadores con rol 'admin'.
 * Escribe en invitations/{code} con expiresAt = now + 72h.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { Recruiter, Invitation } from "../../types/models";
import { requireSecondFactor } from "../../utils/mfa";

const logger = createLogger({ function: "createInvitation" });

const CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // sin 0/O/I/1
const CODE_LENGTH = 6;
const EXPIRY_HOURS = 72;

function generateCode(): string {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const crypto = require("crypto");
  const bytes: Buffer = crypto.randomBytes(CODE_LENGTH);
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CHARS[bytes[i] % CHARS.length];
  }
  return code;
}

interface CreateInvitationRequest {
  role:
    | "admin"
    | "recruiter"
    | "hiring_manager"
    | "external_evaluator"
    | "viewer"
    | "legal"
    | "auditor";
  email?: string;
}

export const createInvitation = functions
  .region("europe-west1")
  .https.onCall(async (data: CreateInvitationRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para crear invitaciones."
      );
    }
    requireSecondFactor(context);

    const callerUid = context.auth.uid;
    const payload = (data ?? {}) as CreateInvitationRequest;
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // Verificar que el caller es un admin activo
    const recruiterDoc = await db.collection("recruiters").doc(callerUid).get();
    if (!recruiterDoc.exists) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "No eres un reclutador registrado."
      );
    }

    const recruiter = recruiterDoc.data() as Recruiter;
    if (recruiter.role !== "admin" || recruiter.status !== "active") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Solo los administradores activos pueden crear invitaciones."
      );
    }

    // Validar rol
    const validRoles = [
      "admin",
      "recruiter",
      "hiring_manager",
      "external_evaluator",
      "viewer",
      "legal",
      "auditor",
    ];
    if (!validRoles.includes(payload.role)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Rol inválido. Usa: admin, recruiter, hiring_manager, external_evaluator, viewer, legal o auditor."
      );
    }

    const code = generateCode();
    const expiresAt = new admin.firestore.Timestamp(
      now.seconds + EXPIRY_HOURS * 3600,
      now.nanoseconds
    );

    const invitation: Invitation = {
      code,
      companyId: recruiter.companyId,
      role: payload.role,
      email: payload.email,
      createdBy: callerUid,
      status: "pending",
      createdAt: now,
      expiresAt,
    };

    await db.collection("invitations").doc(code).set(invitation);

    logger.info("Invitation created", { code, companyId: recruiter.companyId, role: payload.role });

    return { code, expiresAt: expiresAt.toDate().toISOString() };
  });
