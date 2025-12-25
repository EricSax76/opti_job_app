const express = require('express');
const admin = require('firebase-admin');
const { VertexAI } = require('@google-cloud/vertexai');
const crypto = require('crypto');

const app = express();
app.use(express.json({ limit: '256kb' }));

function env(name, fallback = '') {
  return process.env[name] ?? fallback;
}

function nowPlusDays(days) {
  const ms = Date.now() + days * 24 * 60 * 60 * 1000;
  return new Date(ms);
}

function parseUpdatedAtMs(value) {
  if (!value) return null;
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim()) {
    const parsed = Date.parse(value);
    if (!Number.isNaN(parsed)) return parsed;
    const asNumber = Number(value);
    if (Number.isFinite(asNumber)) return asNumber;
  }
  return null;
}

function truncate(text, max) {
  if (typeof text !== 'string') return '';
  const t = text.trim();
  return t.length <= max ? t : t.slice(0, max);
}

function compactCv(cv) {
  const skills = Array.isArray(cv?.skills) ? cv.skills : [];
  const normalized = [];
  for (const raw of skills) {
    if (typeof raw !== 'string') continue;
    const value = raw.trim();
    if (!value) continue;
    const dup = normalized.some((s) => s.toLowerCase() === value.toLowerCase());
    if (!dup) normalized.push(value);
    if (normalized.length >= 25) break;
  }

  function lastItems(items, max) {
    if (!Array.isArray(items)) return [];
    const slice = items.slice(Math.max(0, items.length - max));
    return slice
      .filter((item) => item && typeof item === 'object')
      .map((item) => ({
        title: truncate(item.title, 80),
        subtitle: truncate(item.subtitle, 80),
        period: truncate(item.period, 40),
        description: truncate(item.description, 600),
      }));
  }

  return {
    headline: truncate(cv?.headline, 120),
    summary: truncate(cv?.summary, 900),
    skills: normalized,
    experiences: lastItems(cv?.experiences, 3),
    education: lastItems(cv?.education, 3),
    updated_at: cv?.updated_at,
  };
}

function compactOffer(offer) {
  return {
    id: offer?.id,
    title: truncate(offer?.title, 140),
    location: truncate(offer?.location, 120),
    description: truncate(offer?.description, 1600),
    job_type: truncate(offer?.job_type ?? offer?.jobType, 60),
    education: truncate(offer?.education, 120),
    key_indicators: truncate(offer?.key_indicators ?? offer?.keyIndicators, 600),
    salary_min: offer?.salary_min ?? offer?.salaryMin,
    salary_max: offer?.salary_max ?? offer?.salaryMax,
  };
}

function compactOfferCriteria(criteria) {
  const mustHaveSkills = Array.isArray(criteria?.mustHaveSkills)
    ? criteria.mustHaveSkills
        .filter((v) => typeof v === 'string' && v.trim())
        .map((v) => truncate(v, 40))
        .slice(0, 12)
    : [];
  const niceToHaveSkills = Array.isArray(criteria?.niceToHaveSkills)
    ? criteria.niceToHaveSkills
        .filter((v) => typeof v === 'string' && v.trim())
        .map((v) => truncate(v, 40))
        .slice(0, 12)
    : [];

  return {
    companyName: truncate(criteria?.companyName, 80),
    role: truncate(criteria?.role, 80),
    seniority: truncate(criteria?.seniority, 40),
    location: truncate(criteria?.location, 80),
    jobType: truncate(criteria?.jobType, 40),
    salaryMin: truncate(criteria?.salaryMin, 20),
    salaryMax: truncate(criteria?.salaryMax, 20),
    education: truncate(criteria?.education, 80),
    tone: truncate(criteria?.tone, 40),
    language: truncate(criteria?.language, 20),
    about: truncate(criteria?.about, 600),
    responsibilities: truncate(criteria?.responsibilities, 900),
    requirements: truncate(criteria?.requirements, 900),
    benefits: truncate(criteria?.benefits, 600),
    notes: truncate(criteria?.notes, 400),
    mustHaveSkills,
    niceToHaveSkills,
  };
}

function sha256Base64Url(input) {
  const hash = crypto.createHash('sha256').update(input).digest('base64');
  return hash.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}

function extractJson(text) {
  if (typeof text !== 'string') throw new Error('invalid model output');
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) throw new Error('no json');
  const slice = text.slice(start, end + 1);
  return JSON.parse(slice);
}

function getVertexModel(quality) {
  const project = env('GCP_PROJECT', env('GOOGLE_CLOUD_PROJECT'));
  const location = env('GCP_LOCATION', 'us-central1');
  if (!project) {
    throw new Error('Missing GCP_PROJECT/GOOGLE_CLOUD_PROJECT');
  }
  const vertex = new VertexAI({ project, location });
  const modelName =
    quality === 'pro'
      ? env('AI_MODEL_PRO', 'gemini-1.5-pro')
      : env('AI_MODEL_FLASH', 'gemini-1.5-flash');
  return vertex.getGenerativeModel({ model: modelName });
}

async function generateJson({ prompt, quality, maxOutputTokens }) {
  const model = getVertexModel(quality);
  const result = await model.generateContent({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    generationConfig: {
      maxOutputTokens,
      temperature: 0.3,
    },
  });

  const text =
    result?.response?.candidates?.[0]?.content?.parts
      ?.map((p) => p.text)
      .filter(Boolean)
      .join('') ?? '';
  return extractJson(text);
}

function requireAuth(req, res, next) {
  if (env('DISABLE_AUTH', 'false') === 'true') {
    req.user = { uid: 'dev' };
    return next();
  }

  const header = req.get('Authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'missing_token' });

  admin
    .auth()
    .verifyIdToken(token)
    .then((decoded) => {
      req.user = { uid: decoded.uid, claims: decoded };
      next();
    })
    .catch(() => res.status(401).json({ error: 'invalid_token' }));
}

function initFirebaseAdmin() {
  if (admin.apps.length) return;
  admin.initializeApp();
}

app.get('/healthz', (_req, res) => res.status(200).send('ok'));

app.post('/ai/improve-cv-summary', requireAuth, async (req, res) => {
  initFirebaseAdmin();

  const uid = req.user.uid;
  const ttlDays = Number(env('CACHE_TTL_DAYS', '7')) || 7;
  const locale = typeof req.body?.locale === 'string' ? req.body.locale : 'es-ES';
  const quality = typeof req.body?.quality === 'string' ? req.body.quality : 'flash';
  const cv = compactCv(req.body?.cv ?? {});
  const cvUpdatedAtMs = parseUpdatedAtMs(cv.updated_at);

  const firestore = admin.firestore();
  if (cvUpdatedAtMs) {
    const docId = `${uid}_${cvUpdatedAtMs}`;
    const docRef = firestore.collection('ai_cache_cv_summary').doc(docId);
    const cached = await docRef.get();
    const data = cached.exists ? cached.data() : null;
    const expiresAt = data?.expiresAt?.toDate?.();
    if (data?.summary && (!expiresAt || expiresAt.getTime() > Date.now())) {
      return res.json({ summary: data.summary, cached: true });
    }
  }

  const prompt = [
    'Devuelve SOLO JSON válido, sin markdown ni texto extra.',
    `Idioma: ${locale}.`,
    'Tarea: mejora el resumen profesional (2-4 frases) para un CV.',
    'Reglas: conciso, concreto, sin inventar experiencia no provista.',
    'Formato JSON: {"summary":"..."}',
    '',
    `CV: ${JSON.stringify(cv)}`,
  ].join('\n');

  try {
    const out = await withTimeout(
      generateJson({ prompt, quality, maxOutputTokens: 250 }),
      20000,
    );
    const summary = truncate(out?.summary, 1200);
    if (!summary) return res.status(502).json({ error: 'invalid_model_output' });

    if (cvUpdatedAtMs) {
      const docId = `${uid}_${cvUpdatedAtMs}`;
      await firestore
        .collection('ai_cache_cv_summary')
        .doc(docId)
        .set(
          {
            uid,
            cvUpdatedAtMs,
            summary,
            quality,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(nowPlusDays(ttlDays)),
          },
          { merge: true },
        );
    }

    return res.json({ summary, cached: false });
  } catch (e) {
    return res.status(502).json({ error: 'ai_failed' });
  }
});

app.post('/ai/match-offer-candidate', requireAuth, async (req, res) => {
  initFirebaseAdmin();

  const uid = req.user.uid;
  const ttlDays = Number(env('CACHE_TTL_DAYS', '7')) || 7;
  const locale = typeof req.body?.locale === 'string' ? req.body.locale : 'es-ES';
  const quality = typeof req.body?.quality === 'string' ? req.body.quality : 'flash';
  const cv = compactCv(req.body?.cv ?? {});
  const offer = compactOffer(req.body?.offer ?? {});
  const offerId = offer?.id;
  const cvUpdatedAtMs = parseUpdatedAtMs(cv.updated_at);

  if (!offerId) return res.status(400).json({ error: 'missing_offer_id' });

  const firestore = admin.firestore();
  if (cvUpdatedAtMs) {
    const docId = `${uid}_${offerId}`;
    const docRef = firestore.collection('ai_cache_matches').doc(docId);
    const cached = await docRef.get();
    const data = cached.exists ? cached.data() : null;
    const expiresAt = data?.expiresAt?.toDate?.();
    if (
      data?.result &&
      data?.cvUpdatedAtMs === cvUpdatedAtMs &&
      (!expiresAt || expiresAt.getTime() > Date.now())
    ) {
      return res.json({ ...data.result, cached: true });
    }
  }

  const prompt = [
    'Devuelve SOLO JSON válido, sin markdown ni texto extra.',
    `Idioma: ${locale}.`,
    'Tarea: calcula el match entre CV y oferta.',
    'Devuelve un score 0..100 (int), 3-6 reasons, y summary breve (1-2 frases).',
    'No inventes skills/experiencia no provista.',
    'Formato JSON: {"score":85,"summary":"...","reasons":["...","..."]}',
    '',
    `OFERTA: ${JSON.stringify(offer)}`,
    `CV: ${JSON.stringify(cv)}`,
  ].join('\n');

  try {
    const out = await withTimeout(
      generateJson({ prompt, quality, maxOutputTokens: 300 }),
      20000,
    );
    const score = Number.isFinite(out?.score) ? Math.max(0, Math.min(100, out.score)) : null;
    const reasons = Array.isArray(out?.reasons)
      ? out.reasons.filter((r) => typeof r === 'string' && r.trim()).slice(0, 6)
      : [];
    const summary = out?.summary ? truncate(out.summary, 1200) : null;
    if (score === null || reasons.length === 0) {
      return res.status(502).json({ error: 'invalid_model_output' });
    }

    const result = { score, summary, reasons };

    if (cvUpdatedAtMs) {
      const docId = `${uid}_${offerId}`;
      await firestore
        .collection('ai_cache_matches')
        .doc(docId)
        .set(
          {
            uid,
            offerId,
            cvUpdatedAtMs,
            result,
            quality,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(nowPlusDays(ttlDays)),
          },
          { merge: true },
        );
    }

    return res.json({ ...result, cached: false });
  } catch (e) {
    return res.status(502).json({ error: 'ai_failed' });
  }
});

app.post('/ai/generate-job-offer', requireAuth, async (req, res) => {
  initFirebaseAdmin();

  const uid = req.user.uid;
  const ttlDays = Number(env('CACHE_TTL_DAYS', '7')) || 7;
  const locale = typeof req.body?.locale === 'string' ? req.body.locale : 'es-ES';
  const quality = typeof req.body?.quality === 'string' ? req.body.quality : 'flash';
  const criteria = compactOfferCriteria(req.body?.criteria ?? {});

  if (!criteria.role) return res.status(400).json({ error: 'missing_role' });

  const criteriaKey = sha256Base64Url(JSON.stringify({ criteria, locale, quality }));
  const firestore = admin.firestore();
  const docId = `${uid}_${criteriaKey}`;
  const docRef = firestore.collection('ai_cache_job_offers').doc(docId);
  const cached = await docRef.get();
  const data = cached.exists ? cached.data() : null;
  const expiresAt = data?.expiresAt?.toDate?.();
  if (data?.draft && (!expiresAt || expiresAt.getTime() > Date.now())) {
    return res.json({ ...data.draft, cached: true });
  }

  const prompt = [
    'Devuelve SOLO JSON válido, sin markdown ni texto extra.',
    `Idioma: ${locale}.`,
    'Tarea: generar un borrador de oferta de trabajo a partir de criterios.',
    'Reglas: texto claro, profesional, sin claims legales, sin inventar datos no provistos.',
    'Incluye secciones: Descripción, Responsabilidades, Requisitos, Deseable, Beneficios.',
    'Si falta algo, deja un texto genérico breve (no "N/A").',
    'Formato JSON:',
    '{"title":"...","description":"...","location":"...","job_type":"...","salary_min":"...","salary_max":"...","education":"...","key_indicators":"..."}',
    '',
    `CRITERIOS: ${JSON.stringify(criteria)}`,
  ].join('\n');

  try {
    const out = await withTimeout(
      generateJson({ prompt, quality, maxOutputTokens: 450 }),
      20000,
    );

    const title = truncate(out?.title, 140);
    const description = truncate(out?.description, 4000);
    const location = truncate(out?.location, 120) || criteria.location || 'Remoto';
    const draft = {
      title,
      description,
      location,
      job_type: truncate(out?.job_type ?? out?.jobType ?? criteria.jobType, 60),
      salary_min: truncate(out?.salary_min ?? out?.salaryMin ?? criteria.salaryMin, 20),
      salary_max: truncate(out?.salary_max ?? out?.salaryMax ?? criteria.salaryMax, 20),
      education: truncate(out?.education ?? criteria.education, 120),
      key_indicators: truncate(out?.key_indicators ?? out?.keyIndicators, 600),
    };

    if (!draft.title || !draft.description || !draft.location) {
      return res.status(502).json({ error: 'invalid_model_output' });
    }

    await docRef.set(
      {
        uid,
        criteriaKey,
        criteria,
        locale,
        quality,
        draft,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(nowPlusDays(ttlDays)),
      },
      { merge: true },
    );

    return res.json({ ...draft, cached: false });
  } catch (e) {
    return res.status(502).json({ error: 'ai_failed' });
  }
});

function withTimeout(promise, ms) {
  let timer;
  const timeout = new Promise((_resolve, reject) => {
    timer = setTimeout(() => reject(new Error('timeout')), ms);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

const port = Number(env('PORT', '8080')) || 8080;
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`AI service listening on :${port}`);
});
