import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  MunicipalityCatalogItem,
  ProvinceCatalogItem,
  readString,
  isTruthy,
  parseCatalogSource,
  downloadText,
  computeVersionHash,
  serializeDocument,
  normalizeProvinceId,
} from "./utils/geoUtils";

const REGION = "europe-west1";
const TIME_ZONE = "Europe/Madrid";
const CACHE_CONTROL = "public, max-age=3600, s-maxage=86400, stale-while-revalidate=86400";
const INTERNAL_CACHE_TTL_MS = 10 * 60 * 1000;

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
