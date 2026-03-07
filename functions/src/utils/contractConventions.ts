type JsonRecord = Record<string, unknown>;

const CAMEL_CASE_KEY_PATTERN = /^[a-z][A-Za-z0-9]*$/;

function isPlainObject(value: unknown): value is JsonRecord {
  if (value == null || typeof value !== "object") return false;
  return Object.getPrototypeOf(value) === Object.prototype;
}

function normalizeAllowKeys(
  allowKeys: ReadonlySet<string> | readonly string[] | undefined,
): ReadonlySet<string> {
  if (!allowKeys) return new Set<string>();
  if (allowKeys instanceof Set) return allowKeys;
  return new Set<string>(allowKeys);
}

function isAllowedKey(key: string, allowKeys: ReadonlySet<string>): boolean {
  if (allowKeys.has(key)) return true;
  return false;
}

function assertCamelCaseKey({
  key,
  path,
  allowKeys,
}: {
  key: string;
  path: string;
  allowKeys: ReadonlySet<string>;
}): void {
  if (isAllowedKey(key, allowKeys)) return;
  if (CAMEL_CASE_KEY_PATTERN.test(key)) return;
  throw new Error(
    `[contract] Invalid key "${key}" at ${path}. Use camelCase keys in callable contracts.`,
  );
}

export function assertCamelCaseKeys(
  value: unknown,
  options?: {
    path?: string;
    allowKeys?: ReadonlySet<string> | readonly string[];
    deep?: boolean;
  },
): void {
  const path = options?.path ?? "root";
  const allowKeys = normalizeAllowKeys(options?.allowKeys);
  const deep = options?.deep ?? true;

  if (Array.isArray(value)) {
    if (!deep) return;
    for (let i = 0; i < value.length; i += 1) {
      assertCamelCaseKeys(value[i], {
        path: `${path}[${i}]`,
        allowKeys,
        deep,
      });
    }
    return;
  }

  if (!isPlainObject(value)) return;

  for (const [key, nestedValue] of Object.entries(value)) {
    assertCamelCaseKey({
      key,
      path: `${path}.${key}`,
      allowKeys,
    });
    if (deep) {
      assertCamelCaseKeys(nestedValue, {
        path: `${path}.${key}`,
        allowKeys,
        deep,
      });
    }
  }
}

export function ensureCallableResponseContract<T extends JsonRecord>(
  payload: T,
  options: {
    callableName: string;
    allowKeys?: ReadonlySet<string> | readonly string[];
    deep?: boolean;
  },
): T {
  assertCamelCaseKeys(payload, {
    path: `${options.callableName}.response`,
    allowKeys: options.allowKeys,
    deep: options.deep,
  });
  return payload;
}

export function asPlainObjectOrEmpty(value: unknown): JsonRecord {
  if (isPlainObject(value)) return value;
  return {};
}
