import * as admin from "firebase-admin";
import { Recruiter } from "../types/models";
import { createLogger } from "./logger";

const logger = createLogger({ module: "recruiterClaims" });

export const RECRUITER_RBAC_CLAIMS_VERSION = 1;

const MANAGED_RECRUITER_CLAIM_KEYS = [
  "isRecruiter",
  "recruiterRole",
  "companyId",
  "recruiterStatus",
  "mfaRequired",
  "assuranceLevel",
  "rbacVersion",
] as const;

type ManagedClaimKey = (typeof MANAGED_RECRUITER_CLAIM_KEYS)[number];

export interface RecruiterManagedClaims {
  isRecruiter: boolean;
  recruiterRole: Recruiter["role"];
  companyId: string;
  recruiterStatus: Recruiter["status"];
  mfaRequired: boolean;
  assuranceLevel: string;
  rbacVersion: number;
}

export interface SyncRecruiterClaimsOptions {
  dryRun?: boolean;
  revokeRefreshTokens?: boolean;
  source?: string;
}

export interface SyncRecruiterClaimsResult {
  uid: string;
  authUserFound: boolean;
  recruiterFound: boolean;
  updated: boolean;
  revokedTokens: boolean;
  managedClaims: RecruiterManagedClaims | null;
}

function cloneClaims(
  claims: Record<string, unknown> | undefined,
): Record<string, unknown> {
  return claims ? { ...claims } : {};
}

function toManagedClaims(
  recruiter: Recruiter | null,
): RecruiterManagedClaims | null {
  if (!recruiter) {
    return null;
  }

  const isActive = recruiter.status === "active";

  return {
    isRecruiter: isActive,
    recruiterRole: recruiter.role,
    companyId: recruiter.companyId,
    recruiterStatus: recruiter.status,
    mfaRequired: isActive,
    assuranceLevel: isActive ? "ens_medium_mfa" : "ens_basic",
    rbacVersion: RECRUITER_RBAC_CLAIMS_VERSION,
  };
}

function claimValueEquals(left: unknown, right: unknown): boolean {
  if (left === right) {
    return true;
  }

  if (typeof left !== typeof right) {
    return false;
  }

  if (
    left !== null &&
    right !== null &&
    typeof left === "object" &&
    typeof right === "object"
  ) {
    return JSON.stringify(left) === JSON.stringify(right);
  }

  return false;
}

function areClaimsEqual(
  left: Record<string, unknown>,
  right: Record<string, unknown>,
): boolean {
  const leftKeys = Object.keys(left);
  const rightKeys = Object.keys(right);

  if (leftKeys.length !== rightKeys.length) {
    return false;
  }

  for (const key of leftKeys) {
    if (!Object.prototype.hasOwnProperty.call(right, key)) {
      return false;
    }

    if (!claimValueEquals(left[key], right[key])) {
      return false;
    }
  }

  return true;
}

function mergeClaims(
  existingClaims: Record<string, unknown>,
  managedClaims: RecruiterManagedClaims | null,
): Record<string, unknown> {
  const nextClaims = { ...existingClaims };

  if (!managedClaims) {
    for (const key of MANAGED_RECRUITER_CLAIM_KEYS) {
      delete nextClaims[key];
    }
    return nextClaims;
  }

  for (const key of MANAGED_RECRUITER_CLAIM_KEYS) {
    nextClaims[key] = managedClaims[key as ManagedClaimKey];
  }

  return nextClaims;
}

export async function syncRecruiterClaims(
  uid: string,
  recruiter: Recruiter | null,
  options: SyncRecruiterClaimsOptions = {},
): Promise<SyncRecruiterClaimsResult> {
  const auth = admin.auth();
  const source = options.source ?? "unknown";

  let userRecord: admin.auth.UserRecord;
  try {
    userRecord = await auth.getUser(uid);
  } catch (error) {
    const err = error as { code?: string };
    if (err.code === "auth/user-not-found") {
      logger.warn("Auth user not found while syncing recruiter claims", {
        uid,
        source,
      });
      return {
        uid,
        authUserFound: false,
        recruiterFound: recruiter !== null,
        updated: false,
        revokedTokens: false,
        managedClaims: toManagedClaims(recruiter),
      };
    }

    throw error;
  }

  const existingClaims = cloneClaims(
    userRecord.customClaims as Record<string, unknown> | undefined,
  );
  const managedClaims = toManagedClaims(recruiter);
  const nextClaims = mergeClaims(existingClaims, managedClaims);
  const updated = !areClaimsEqual(existingClaims, nextClaims);

  if (updated && !options.dryRun) {
    await auth.setCustomUserClaims(uid, nextClaims);
  }

  let revokedTokens = false;
  if (updated && options.revokeRefreshTokens && !options.dryRun) {
    await auth.revokeRefreshTokens(uid);
    revokedTokens = true;
  }

  logger.info("Recruiter claims synchronized", {
    uid,
    source,
    authUserFound: true,
    updated,
    recruiterFound: recruiter !== null,
    revokedTokens,
    dryRun: options.dryRun === true,
    recruiterStatus: managedClaims?.recruiterStatus ?? null,
    recruiterRole: managedClaims?.recruiterRole ?? null,
  });

  return {
    uid,
    authUserFound: true,
    recruiterFound: recruiter !== null,
    updated,
    revokedTokens,
    managedClaims,
  };
}

export async function syncRecruiterClaimsFromFirestore(
  uid: string,
  options: SyncRecruiterClaimsOptions = {},
): Promise<SyncRecruiterClaimsResult> {
  const db = admin.firestore();
  const recruiterSnapshot = await db.collection("recruiters").doc(uid).get();
  const recruiter = recruiterSnapshot.exists ?
    (recruiterSnapshot.data() as Recruiter) :
    null;

  return syncRecruiterClaims(uid, recruiter, {
    ...options,
    source: options.source ?? "firestore",
  });
}
