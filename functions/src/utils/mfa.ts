import * as functions from "firebase-functions/v1";

function readSecondFactorId(
  context: functions.https.CallableContext,
): string | null {
  const firebaseToken = context.auth?.token?.firebase as
    | Record<string, unknown>
    | undefined;

  if (!firebaseToken) {
    return null;
  }

  const secondFactor = firebaseToken.sign_in_second_factor;
  if (typeof secondFactor !== "string") {
    return null;
  }

  const normalized = secondFactor.trim();
  return normalized.length > 0 ? normalized : null;
}

export function hasSecondFactor(
  context: functions.https.CallableContext,
): boolean {
  return readSecondFactorId(context) !== null;
}

export function requireSecondFactor(
  context: functions.https.CallableContext,
  message = "Esta operación requiere MFA. Inicia sesión con segundo factor.",
): void {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Debes iniciar sesión.",
    );
  }

  if (!hasSecondFactor(context)) {
    throw new functions.https.HttpsError("permission-denied", message);
  }
}
