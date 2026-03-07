const assert = require("node:assert/strict");

const CAMEL_CASE_KEY_PATTERN = /^[a-z][A-Za-z0-9]*$/;

function isPlainObject(value) {
  if (value == null || typeof value !== "object") return false;
  return Object.getPrototypeOf(value) === Object.prototype;
}

function assertCamelCaseResponse(value, options = {}) {
  const path = options.path ?? "response";
  const deep = options.deep ?? true;
  const allowKeys = new Set(options.allowKeys ?? []);

  if (Array.isArray(value)) {
    if (!deep) return;
    for (let i = 0; i < value.length; i += 1) {
      assertCamelCaseResponse(value[i], {
        path: `${path}[${i}]`,
        deep,
        allowKeys: [...allowKeys],
      });
    }
    return;
  }

  if (!isPlainObject(value)) return;

  for (const [key, nested] of Object.entries(value)) {
    const isAllowed = allowKeys.has(key);
    assert.equal(
      isAllowed || CAMEL_CASE_KEY_PATTERN.test(key),
      true,
      `Invalid contract key "${key}" at ${path}.${key}. Expected camelCase.`,
    );
    if (deep) {
      assertCamelCaseResponse(nested, {
        path: `${path}.${key}`,
        deep,
        allowKeys: [...allowKeys],
      });
    }
  }
}

function assertAuditLogContract(auditLog) {
  assert.ok(auditLog, "auditLog is required");
  assertCamelCaseResponse(auditLog, {
    path: "auditLog",
    deep: false,
  });

  const requiredKeys = [
    "action",
    "actionCanonical",
    "actorUid",
    "actorRole",
    "targetType",
    "targetId",
    "metadata",
    "schemaVersion",
    "timestamp",
  ];
  for (const key of requiredKeys) {
    assert.notEqual(
      auditLog[key],
      undefined,
      `auditLog.${key} is required`,
    );
  }
}

module.exports = {
  assertCamelCaseResponse,
  assertAuditLogContract,
};
