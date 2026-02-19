import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as http from "http";
import * as https from "https";
import * as crypto from "crypto";

const REGION = "europe-west1";
const TIME_ZONE = "Europe/Madrid";
const CACHE_CONTROL = "public, max-age=3600, s-maxage=86400, stale-while-revalidate=86400";
const INTERNAL_CACHE_TTL_MS = 10 * 60 * 1000;
const REQUEST_TIMEOUT_MS = 30 * 1000;
const MAX_REDIRECTS = 5;

const PROVINCE_ID_KEYS = [
  "cpro",
  "codprov",
  "idprovincia",
  "provinciaid",
  "provinceid",
  "provincecode",
];
const PROVINCE_NAME_KEYS = [
  "npro",
  "provincia",
  "nombreprovincia",
  "provincianame",
  "province",
  "province_name",
];
const MUNICIPALITY_PART_KEYS = [
  "cmun",
  "codmun",
  "municipioid",
  "municipalityid",
  "idmunicipio",
  "codigomunicipio",
];
const FULL_MUNICIPALITY_ID_KEYS = [
  "codigoine",
  "ine",
  "municipalityine",
  "municipioine",
  "codigocompleto",
  "municipalitycode",
];
const MUNICIPALITY_NAME_KEYS = [
  "nombre",
  "municipio",
  "nombremunicipio",
  "municipality",
  "municipalityname",
  "municipality_name",
];

interface MunicipalityCatalogItem {
  id: string;
  name: string;
  norm: string;
}

interface ProvinceCatalogItem {
  id: string;
  name: string;
  slug: string;
}

interface ProvinceAccumulator {
  id: string;
  name: string;
  slug: string;
  municipalities: Map<string, MunicipalityCatalogItem>;
}

interface SyncSummary {
  sourceUrl: string;
  version: string;
  provinces: number;
  municipalities: number;
  deletedProvinceDocs: number;
  dryRun: boolean;
}

interface CatalogCacheEntry {
  payload: Record<string, unknown>;
  expiresAt: number;
}

let provincesCache: CatalogCacheEntry | null = null;
const municipalitiesCache = new Map<string, CatalogCacheEntry>();

export const syncLocationCatalogScheduled = functions
  .region(REGION)
  .pubsub.schedule("0 3 * * *")
  .timeZone(TIME_ZONE)
  .onRun(async () => {
    const summary = await syncLocationCatalog({ dryRun: false });
    functions.logger.info("Location catalog synchronized", summary);
  });

export const syncLocationCatalogManual = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    setCommonResponseHeaders(res);
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed. Use POST." });
      return;
    }

    const syncToken = getSyncToken();
    if (!syncToken) {
      res.status(500).json({ error: "Missing sync token configuration." });
      return;
    }

    const providedToken = req.get("x-sync-token")?.trim() ?? "";
    if (!providedToken || providedToken !== syncToken) {
      res.status(403).json({ error: "Forbidden." });
      return;
    }

    const dryRun = isTruthy(req.query.dryRun) ||
      (req.body != null && typeof req.body === "object" && isTruthy((req.body as Record<string, unknown>).dryRun));

    try {
      const requestedSource =
        req.body != null && typeof req.body === "object"
          ? readString((req.body as Record<string, unknown>).sourceUrl)
          : null;

      const summary = await syncLocationCatalog({
        dryRun,
        sourceUrlOverride: requestedSource,
      });

      res.status(200).json({ ok: true, ...summary });
    } catch (error) {
      functions.logger.error("Failed to synchronize location catalog", error);
      res.status(500).json({
        error: "Failed to synchronize location catalog.",
        details: error instanceof Error ? error.message : String(error),
      });
    }
  });

export const geoCatalogProvinces = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    setCommonResponseHeaders(res);
    res.set("Cache-Control", CACHE_CONTROL);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "GET") {
      res.status(405).json({ error: "Method not allowed. Use GET." });
      return;
    }

    try {
      const payload = await readProvincesPayload();
      res.status(200).json(payload);
    } catch (error) {
      functions.logger.error("Failed to serve provinces catalog", error);
      res.status(500).json({
        error: "Failed to load provinces catalog.",
      });
    }
  });

export const geoCatalogMunicipalities = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    setCommonResponseHeaders(res);
    res.set("Cache-Control", CACHE_CONTROL);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "GET") {
      res.status(405).json({ error: "Method not allowed. Use GET." });
      return;
    }

    const provinceId = resolveProvinceId(req);
    if (provinceId == null) {
      res.status(400).json({
        error: "Missing or invalid provinceId. Use ?provinceId=XX or /municipios_XX.json",
      });
      return;
    }

    try {
      const payload = await readMunicipalitiesPayload(provinceId);
      if (payload == null) {
        res.status(404).json({ error: `Province ${provinceId} not found.` });
        return;
      }
      res.status(200).json(payload);
    } catch (error) {
      functions.logger.error("Failed to serve municipalities catalog", error);
      res.status(500).json({
        error: "Failed to load municipalities catalog.",
      });
    }
  });

async function syncLocationCatalog({
  dryRun,
  sourceUrlOverride,
}: {
  dryRun: boolean;
  sourceUrlOverride?: string | null;
}): Promise<SyncSummary> {
  const sourceUrl =
    sourceUrlOverride?.trim() ||
    getSourceUrl();

  const sourceText = await downloadText(sourceUrl);
  const parsed = parseCatalogSource(sourceText);
  const version = computeVersionHash(sourceText);
  let deletedProvinceDocs = 0;

  if (!dryRun) {
    deletedProvinceDocs = await persistCatalog({
      sourceUrl,
      version,
      provinces: parsed.provinces,
      municipalitiesByProvince: parsed.municipalitiesByProvince,
    });
    invalidateCaches();
  }

  return {
    sourceUrl,
    version,
    provinces: parsed.provinces.length,
    municipalities: parsed.totalMunicipalities,
    deletedProvinceDocs: dryRun ? 0 : deletedProvinceDocs,
    dryRun,
  };
}

function parseCatalogSource(sourceText: string): {
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

    const explicitProvinceId = normalizeProvinceId(
      pickField(record, PROVINCE_ID_KEYS),
    );
    const municipalityPart = normalizeMunicipalityPart(
      pickField(record, MUNICIPALITY_PART_KEYS),
    );
    const explicitMunicipalityId = normalizeFullMunicipalityId(
      pickField(record, FULL_MUNICIPALITY_ID_KEYS),
    );

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

  return {
    provinces,
    municipalitiesByProvince,
    totalMunicipalities,
  };
}

async function persistCatalog({
  sourceUrl,
  version,
  provinces,
  municipalitiesByProvince,
}: {
  sourceUrl: string;
  version: string;
  provinces: ProvinceCatalogItem[];
  municipalitiesByProvince: Map<string, MunicipalityCatalogItem[]>;
}): Promise<number> {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  const existingMunicipalityDocs = await db.collection("catalog_municipios").get();
  const expectedProvinceIds = new Set(provinces.map((province) => province.id));

  const batch = db.batch();
  batch.set(
    db.collection("catalog").doc("provincias_es"),
    {
      updated_at: now,
      source_url: sourceUrl,
      version,
      items: provinces,
    },
    { merge: false },
  );

  for (const province of provinces) {
    const municipalities = municipalitiesByProvince.get(province.id) ?? [];
    batch.set(
      db.collection("catalog_municipios").doc(province.id),
      {
        updated_at: now,
        source_url: sourceUrl,
        version,
        provincia_id: province.id,
        provincia_name: province.name,
        items: municipalities,
      },
      { merge: false },
    );
  }

  let deletedProvinceDocs = 0;
  for (const doc of existingMunicipalityDocs.docs) {
    if (!expectedProvinceIds.has(doc.id)) {
      batch.delete(doc.ref);
      deletedProvinceDocs += 1;
    }
  }

  await batch.commit();
  return deletedProvinceDocs;
}

async function readProvincesPayload(): Promise<Record<string, unknown>> {
  if (isCacheValid(provincesCache)) {
    return provincesCache.payload;
  }

  const snapshot = await admin
    .firestore()
    .collection("catalog")
    .doc("provincias_es")
    .get();

  if (!snapshot.exists) {
    throw new Error("catalog/provincias_es not found");
  }

  const payload = serializeDocument(snapshot.data() ?? {});
  provincesCache = {
    payload,
    expiresAt: Date.now() + INTERNAL_CACHE_TTL_MS,
  };
  return payload;
}

async function readMunicipalitiesPayload(
  provinceId: string,
): Promise<Record<string, unknown> | null> {
  const cacheEntry = municipalitiesCache.get(provinceId);
  if (isCacheValid(cacheEntry)) {
    return cacheEntry.payload;
  }

  const snapshot = await admin
    .firestore()
    .collection("catalog_municipios")
    .doc(provinceId)
    .get();

  if (!snapshot.exists) {
    return null;
  }

  const payload = serializeDocument(snapshot.data() ?? {});
  municipalitiesCache.set(provinceId, {
    payload,
    expiresAt: Date.now() + INTERNAL_CACHE_TTL_MS,
  });

  return payload;
}

function serializeDocument(data: FirebaseFirestore.DocumentData): Record<string, unknown> {
  const serialized: Record<string, unknown> = { ...data };
  const updatedAt = serialized.updated_at;
  if (updatedAt instanceof admin.firestore.Timestamp) {
    serialized.updated_at = updatedAt.toDate().toISOString();
  }
  return serialized;
}

function invalidateCaches(): void {
  provincesCache = null;
  municipalitiesCache.clear();
}

function isCacheValid(
  cacheEntry: CatalogCacheEntry | null | undefined,
): cacheEntry is CatalogCacheEntry {
  return cacheEntry != null && cacheEntry.expiresAt > Date.now();
}

function resolveProvinceId(req: functions.https.Request): string | null {
  const queryProvinceId = readString(req.query.provinceId);
  const normalizedQuery = normalizeProvinceId(queryProvinceId);
  if (normalizedQuery != null) {
    return normalizedQuery;
  }

  const pathCandidate = `${req.path ?? ""} ${req.originalUrl ?? ""}`;
  const matched = pathCandidate.match(/municipios[_-]?(\d{2})\.json/i);
  if (matched?.[1] != null) {
    return normalizeProvinceId(matched[1]);
  }

  return null;
}

function getSourceUrl(): string {
  const locationsConfig = (functions.config()?.locations ?? {}) as Record<string, unknown>;
  const sourceUrl =
    readString(process.env.LOCATION_CATALOG_SOURCE_URL) ??
    readString(locationsConfig.source_url);

  if (sourceUrl == null) {
    throw new Error(
      "Missing location source URL. Set LOCATION_CATALOG_SOURCE_URL or functions config locations.source_url.",
    );
  }

  return sourceUrl;
}

function getSyncToken(): string | null {
  const locationsConfig = (functions.config()?.locations ?? {}) as Record<string, unknown>;
  return (
    readString(process.env.LOCATION_SYNC_TOKEN) ??
    readString(locationsConfig.sync_token)
  );
}

function setCommonResponseHeaders(res: functions.Response<unknown>): void {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, X-Sync-Token");
  res.set("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  res.set("Vary", "Origin");
}

function normalizeHeaderName(value: string): string {
  return normalizeName(value).replace(/[^a-z0-9]/g, "");
}

function normalizeName(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ");
}

function toSlug(value: string): string {
  return normalizeName(value)
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function pickField(record: Map<string, string>, candidateKeys: string[]): string | null {
  for (const key of candidateKeys) {
    const value = record.get(key);
    if (value != null && value.trim().length > 0) {
      return value.trim();
    }
  }
  return null;
}

function normalizeProvinceId(value: string | null): string | null {
  if (value == null) return null;
  const digits = value.replace(/\D/g, "");
  if (digits.length === 0) return null;
  const twoDigits = digits.length >= 2 ? digits.substring(0, 2) : digits.padStart(2, "0");
  return twoDigits;
}

function normalizeMunicipalityPart(value: string | null): string | null {
  if (value == null) return null;
  const digits = value.replace(/\D/g, "");
  if (digits.length === 0) return null;
  if (digits.length >= 3) return digits.substring(0, 3);
  return digits.padStart(3, "0");
}

function normalizeFullMunicipalityId(value: string | null): string | null {
  if (value == null) return null;
  const digits = value.replace(/\D/g, "");
  if (digits.length >= 5) return digits.substring(0, 5);
  return null;
}

function detectDelimiter(headerLine: string): string {
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

function parseDelimitedLine(line: string, delimiter: string): string[] {
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

async function downloadText(url: string): Promise<string> {
  return downloadTextWithRedirect(url, 0);
}

async function downloadTextWithRedirect(url: string, redirectCount: number): Promise<string> {
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

function computeVersionHash(content: string): string {
  return crypto.createHash("sha1").update(content).digest("hex").substring(0, 16);
}

function readString(value: unknown): string | null {
  if (value == null) return null;
  const normalized = String(value).trim();
  return normalized.length === 0 ? null : normalized;
}

function isTruthy(value: unknown): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value > 0;
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    return normalized === "1" || normalized === "true" || normalized === "yes";
  }
  return false;
}
