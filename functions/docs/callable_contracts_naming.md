# Callable Contracts and Naming Conventions

Last updated: 2026-03-07

## Scope
This guide applies to Cloud Functions callables in `functions/src/callable`.

## Single Convention
1. Callable request/response keys: `camelCase`.
2. Audit log schema keys: `camelCase`.
3. Firestore writes:
   - prefer canonical `camelCase` for new fields.
   - if a legacy collection still depends on `snake_case`, dual-write temporarily and document the migration owner.
4. Audit action value:
   - keep existing `action` for backward compatibility.
   - `actionCanonical` is generated automatically for unified querying (`snake_case`).

## Audit Schema
Use unified helpers in `functions/src/utils/auditLog.ts`:
- `writeAuditLog(...)`
- `buildAuditLogRecord(...)` (for transaction-based writes)

Standard fields:
- `action`
- `actionCanonical`
- `actorUid`
- `actorRole`
- `targetType`
- `targetId`
- `companyId`
- `metadata`
- `schemaVersion`
- `timestamp`

## Response Contract Guard
Use `ensureCallableResponseContract(...)` from:
- `functions/src/utils/contractConventions.ts`

Guideline:
- strict (`deep: true`) for typed response payloads.
- shallow (`deep: false`) when payload embeds legacy Firestore documents with historical keys.

## Required Validations
Run before merge:
1. `npm run validate:contracts`
2. `npm run test:e2e:critical`

`validate:contracts` enforces:
- no raw `.collection("auditLogs").add(...)` inside callables.
- transaction audit writes must use `buildAuditLogRecord(...)`.
- critical callables include response guards.

## Migration Rule for Legacy Fields
When a callable still needs legacy `snake_case` writes:
1. keep read compatibility for both styles.
2. write canonical `camelCase` first.
3. add temporary alias field only where required.
4. remove alias after data migration and consumer cleanup.
