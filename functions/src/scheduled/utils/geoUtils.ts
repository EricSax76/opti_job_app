import * as crypto from "crypto";
import * as http from "http";
import * as https from "https";
import * as admin from "firebase-admin";

export const REQUEST_TIMEOUT_MS = 30 * 1000;
export const MAX_REDIRECTS = 5;

export const PROVINCE_ID_KEYS = [
  "cpro",
  "codprov",
  "idprovincia",
  "provinciaid",
  "provinceid",
  "provincecode",
];
export const PROVINCE_NAME_KEYS = [
  "npro",
  "provincia",
  "nombreprovincia",
  "provincianame",
  "province",
  "province_name",
];
export const MUNICIPALITY_PART_KEYS = [
  "cmun",
  "codmun",
  "municipioid",
  "municipalityid",
  "idmunicipio",
  "codigomunicipio",
];
export const FULL_MUNICIPALITY_ID_KEYS = [
  "codigoine",
  "ine",
  "municipalityine",
  "municipioine",
  "codigocompleto",
  "municipalitycode",
];
export const MUNICIPALITY_NAME_KEYS = [
  "nombre",
  "municipio",
  "nombremunicipio",
  "municipality",
  "municipalityname",
  "municipality_name",
];

export interface MunicipalityCatalogItem {
  id: string;
  name: string;
  norm: string;
}

export interface ProvinceCatalogItem {
  id: string;
  name: string;
  slug: string;
}

export interface ProvinceAccumulator {
  id: string;
  name: string;
  slug: string;
  municipalities: Map<string, MunicipalityCatalogItem>;
}

export function readString(value: unknown): string | null {
  if (value == null) return null;
  const normalized = String(value).trim();
  return normalized.length === 0 ? null : normalized;
}

export function isTruthy(value: unknown): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value > 0;
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    return normalized === "1" || normalized === "true" || normalized === "yes";
  }
  return false;
}

export function normalizeHeaderName(value: string): string {
  return normalizeName(value).replace(/[^a-z0-9]/g, "");
}

export function normalizeName(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ");
}

export function toSlug(value: string): string {
  return normalizeName(value)
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function pickField(record: Map<string, string>, candidateKeys: string[]): string | null {
  for (const key of candidateKeys) {
    const value = record.get(key);
    if (value != null && value.trim().length > 0) {
      return value.trim();
    }
  }
  return null;
}

export function normalizeProvinceId(value: string | null): string | null {
  if (value == null) return null;
  const digits = value.replace(/\D/g, "");
  if (digits.length === 0) return null;
  const twoDigits = digits.length >= 2 ? digits.substring(0, 2) : digits.padStart(2, "0");
  return twoDigits;
}

export function normalizeMunicipalityPart(value: string | null): string | null {
  if (value == null) return null;
  const digits = value.replace(/\D/g, "");
  if (digits.length === 0) return null;
  if (digits.length >= 3) return digits.substring(0, 3);
  return digits.padStart(3, "0");
}

export function normalizeFullMunicipalityId(value: string | null): string | null {
  if (value == null) return null;
  const digits = value.replace(/\D/g, "");
  if (digits.length >= 5) return digits.substring(0, 5);
  return null;
}

export function detectDelimiter(headerLine: string): string {
  const candidates = [";", "\t", ","];
  let selected = ";";
  let highestCount = -1;

  for (const candidate of candidates) {
    const count = headerLine.split(candidate).length - 1;
    if (count > highestCount) {
      highestCount = count;
      selected = candidate;
    }
  }

  return selected;
}

export function parseDelimitedLine(line: string, delimiter: string): string[] {
  const values: string[] = [];
  let current = "";
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];

    if (char === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char === delimiter && !inQuotes) {
      values.push(current);
      current = "";
      continue;
    }

    current += char;
  }

  values.push(current);
  return values;
}

export function parseCatalogSource(sourceText: string): {
  provinces: ProvinceCatalogItem[];
  municipalitiesByProvince: Map<string, MunicipalityCatalogItem[]>;
  totalMunicipalities: number;
} {
  const lines = sourceText
    .replace(/^\uFEFF/, "")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0);

  if (lines.length < 2) {
    throw new Error("Location source has no data rows.");
  }

  const delimiter = detectDelimiter(lines[0]);
  const headers = parseDelimitedLine(lines[0], delimiter).map(normalizeHeaderName);

  if (headers.length === 0) {
    throw new Error("Could not parse source headers.");
  }

  const provinceMap = new Map<string, ProvinceAccumulator>();

  for (const line of lines.slice(1)) {
    const values = parseDelimitedLine(line, delimiter);
    if (values.every((value) => value.trim().length === 0)) {
      continue;
    }

    const record = new Map<string, string>();
    for (let i = 0; i < headers.length; i++) {
      const key = headers[i];
      if (!key) continue;
      record.set(key, values[i]?.trim() ?? "");
    }

    const municipalityName = pickField(record, MUNICIPALITY_NAME_KEYS);
    if (municipalityName == null) continue;

    const explicitProvinceId = normalizeProvinceId(pickField(record, PROVINCE_ID_KEYS));
    const municipalityPart = normalizeMunicipalityPart(pickField(record, MUNICIPALITY_PART_KEYS));
    const explicitMunicipalityId = normalizeFullMunicipalityId(pickField(record, FULL_MUNICIPALITY_ID_KEYS));

    const municipalityId = explicitMunicipalityId ??
      (explicitProvinceId != null && municipalityPart != null
        ? `${explicitProvinceId}${municipalityPart}`
        : null);
    if (municipalityId == null) continue;

    const provinceId = explicitProvinceId ?? municipalityId.substring(0, 2);
    if (provinceId.length !== 2) continue;

    const provinceName = pickField(record, PROVINCE_NAME_KEYS);
    const normalizedProvinceName = provinceName ?? provinceId;

    let province = provinceMap.get(provinceId);
    if (province == null) {
      province = {
        id: provinceId,
        name: normalizedProvinceName,
        slug: toSlug(normalizedProvinceName),
        municipalities: new Map<string, MunicipalityCatalogItem>(),
      };
      provinceMap.set(provinceId, province);
    } else if (provinceName != null && province.name === province.id) {
      province.name = provinceName;
      province.slug = toSlug(provinceName);
    }

    if (!province.municipalities.has(municipalityId)) {
      province.municipalities.set(municipalityId, {
        id: municipalityId,
        name: municipalityName,
        norm: normalizeName(municipalityName),
      });
    }
  }

  const provinces = Array.from(provinceMap.values())
    .map((province) => ({
      id: province.id,
      name: province.name,
      slug: province.slug,
    }))
    .sort((a, b) => a.name.localeCompare(b.name, "es", { sensitivity: "base" }));

  if (provinces.length === 0) {
    throw new Error("No valid provinces were parsed from source data.");
  }

  const municipalitiesByProvince = new Map<string, MunicipalityCatalogItem[]>();
  let totalMunicipalities = 0;

  for (const province of provinces) {
    const accumulator = provinceMap.get(province.id);
    if (accumulator == null) continue;

    const municipalities = Array.from(accumulator.municipalities.values())
      .sort((a, b) => a.name.localeCompare(b.name, "es", { sensitivity: "base" }));

    municipalitiesByProvince.set(province.id, municipalities);
    totalMunicipalities += municipalities.length;
  }

  return { provinces, municipalitiesByProvince, totalMunicipalities };
}

export async function downloadText(url: string): Promise<string> {
  return downloadTextWithRedirect(url, 0);
}

export async function downloadTextWithRedirect(url: string, redirectCount: number): Promise<string> {
  if (redirectCount > MAX_REDIRECTS) {
    throw new Error("Too many redirects while downloading location source.");
  }

  const target = new URL(url);
  const client = target.protocol === "http:" ? http : https;

  return new Promise<string>((resolve, reject) => {
    const request = client.get(target, (response) => {
      const statusCode = response.statusCode ?? 0;
      const location = response.headers.location;

      if (statusCode >= 300 && statusCode < 400 && location) {
        const redirectedUrl = new URL(location, target).toString();
        response.resume();
        downloadTextWithRedirect(redirectedUrl, redirectCount + 1)
          .then(resolve)
          .catch(reject);
        return;
      }

      if (statusCode < 200 || statusCode >= 300) {
        response.resume();
        reject(new Error(`Source request failed with status ${statusCode}.`));
        return;
      }

      const chunks: Buffer[] = [];
      response.on("data", (chunk) => {
        chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
      });
      response.on("end", () => {
        resolve(Buffer.concat(chunks).toString("utf8"));
      });
      response.on("error", reject);
    });

    request.setTimeout(REQUEST_TIMEOUT_MS, () => {
      request.destroy(new Error("Source request timed out."));
    });
    request.on("error", reject);
  });
}

export function computeVersionHash(content: string): string {
  return crypto.createHash("sha1").update(content).digest("hex").substring(0, 16);
}

export function serializeDocument(data: FirebaseFirestore.DocumentData): Record<string, unknown> {
  const serialized: Record<string, unknown> = { ...data };
  const updatedAt = serialized.updated_at;
  if (updatedAt instanceof admin.firestore.Timestamp) {
    serialized.updated_at = updatedAt.toDate().toISOString();
  }
  return serialized;
}
