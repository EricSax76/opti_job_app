#!/usr/bin/env node
/* eslint-disable no-console */
const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(__dirname, "..");
const CALLABLE_ROOT = path.join(ROOT, "src", "callable");

function walkFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const abs = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...walkFiles(abs));
      continue;
    }
    if (entry.isFile() && abs.endsWith(".ts")) {
      files.push(abs);
    }
  }
  return files;
}

function toRel(absPath) {
  return path.relative(ROOT, absPath).replaceAll("\\", "/");
}

const allCallableFiles = walkFiles(CALLABLE_ROOT);
const violations = [];

const rawAuditAddPattern =
  /collection\((["'])auditLogs\1\)\.add\(/;
const rawAuditDocPattern =
  /collection\((["'])auditLogs\1\)\.doc\(/;

for (const file of allCallableFiles) {
  const source = fs.readFileSync(file, "utf8");
  if (rawAuditAddPattern.test(source)) {
    violations.push(
      `${toRel(file)} -> raw audit write via .collection("auditLogs").add(...) is forbidden. Use writeAuditLog(...)`,
    );
  }

  if (rawAuditDocPattern.test(source) && !source.includes("buildAuditLogRecord(")) {
    violations.push(
      `${toRel(file)} -> audit doc creation must use buildAuditLogRecord(...) for schema alignment.`,
    );
  }
}

const requiredContractGuardFiles = [
  "src/callable/auth/eudiSelectiveDisclosureCallables.ts",
  "src/callable/applications/qualifiedSignatureCallables.ts",
  "src/callable/ats/evaluateKnockoutQuestions.ts",
  "src/callable/compliance/complianceCallables.ts",
];

for (const relPath of requiredContractGuardFiles) {
  const absPath = path.join(ROOT, relPath);
  const source = fs.readFileSync(absPath, "utf8");
  if (!source.includes("ensureCallableResponseContract")) {
    violations.push(
      `${relPath} -> missing ensureCallableResponseContract(...) guard on callable responses.`,
    );
  }
}

if (violations.length > 0) {
  console.error("Contract validation failed:");
  for (const violation of violations) {
    console.error(`- ${violation}`);
  }
  process.exit(1);
}

console.log("Contract validation passed.");
