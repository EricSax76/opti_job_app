import { asRecord, asTrimmedString } from '../typeGuards';
import { compactWhitespace } from '../math/vectorUtils';

function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => asTrimmedString(item))
    .filter((item) => item.length > 0);
}

function readSkillNames(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const names: string[] = [];
  for (const item of value) {
    if (typeof item === "string") {
      const normalized = item.trim();
      if (normalized) names.push(normalized);
      continue;
    }
    if (item && typeof item === "object") {
      const row = item as Record<string, unknown>;
      const normalized = asTrimmedString(row.name ?? row.skillName ?? row.value);
      if (normalized) names.push(normalized);
    }
  }
  return names;
}

export function buildCandidateEmbeddingText({
  candidate,
  curriculum,
}: {
  candidate: unknown;
  curriculum: unknown;
}): string {
  const candidateData = asRecord(candidate);
  const curriculumData = asRecord(curriculum);

  const candidateSkills = [
    ...readSkillNames(candidateData.skills),
    ...readSkillNames(curriculumData.skills),
    ...readSkillNames(curriculumData.structuredSkills),
  ];

  const experienceRows = Array.isArray(curriculumData.experience)
    ? curriculumData.experience
    : [];
  const educationRows = Array.isArray(curriculumData.education)
    ? curriculumData.education
    : [];
  const languageRows = Array.isArray(curriculumData.languages)
    ? curriculumData.languages
    : [];

  const experienceText = experienceRows
    .map((row) => {
      const item = asRecord(row);
      return [
        asTrimmedString(item.position),
        asTrimmedString(item.company),
        asTrimmedString(item.description),
      ].filter(Boolean).join(" - ");
    })
    .filter(Boolean)
    .join(" | ");

  const educationText = educationRows
    .map((row) => {
      const item = asRecord(row);
      return [
        asTrimmedString(item.degree),
        asTrimmedString(item.institution),
        asTrimmedString(item.field),
      ].filter(Boolean).join(" - ");
    })
    .filter(Boolean)
    .join(" | ");

  const languageText = languageRows
    .map((row) => {
      const item = asRecord(row);
      return [asTrimmedString(item.name), asTrimmedString(item.proficiency)]
        .filter(Boolean)
        .join(": ");
    })
    .filter(Boolean)
    .join(" | ");

  return compactWhitespace([
    asTrimmedString(candidateData.name),
    asTrimmedString(candidateData.title),
    asTrimmedString(candidateData.bio),
    asTrimmedString(candidateData.location),
    asTrimmedString(curriculumData.summary),
    candidateSkills.join(", "),
    experienceText,
    educationText,
    languageText,
  ].filter(Boolean).join("\n"));
}

export function buildJobOfferEmbeddingText(offer: unknown): string {
  const offerData = asRecord(offer);
  const requiredSkills = [
    ...asStringList(offerData.requiredSkills),
    ...asStringList(offerData.skills),
  ];
  const preferredSkills = asStringList(offerData.preferredSkills);
  const qualifications = asStringList(offerData.qualifications);

  return compactWhitespace([
    asTrimmedString(offerData.title),
    asTrimmedString(offerData.description),
    asTrimmedString(offerData.location),
    asTrimmedString(offerData.job_category ?? offerData.jobCategory),
    asTrimmedString(offerData.contract_type ?? offerData.contractType),
    asTrimmedString(offerData.work_schedule ?? offerData.workSchedule),
    `Required skills: ${requiredSkills.join(", ")}`,
    `Preferred skills: ${preferredSkills.join(", ")}`,
    `Qualifications: ${qualifications.join(", ")}`,
    `Experience years: ${asTrimmedString(offerData.experience_years ?? offerData.experienceYears)}`,
  ].filter(Boolean).join("\n"));
}
