/**
 * Validation utilities for Cloud Functions
 */

export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ValidationError";
  }
}

/**
 * Validate email format
 * @param {string} email - Email to validate
 * @return {boolean} True if valid
 */
export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validate phone number (international format)
 * @param {string} phone - Phone number to validate
 * @return {boolean} True if valid
 */
export function validatePhoneNumber(phone: string): boolean {
  const phoneRegex = /^\+?[1-9]\d{1,14}$/;
  return phoneRegex.test(phone.replace(/[\s\-()]/g, ""));
}

/**
 * Validate URL format
 * @param {string} url - URL to validate
 * @return {boolean} True if valid
 */
export function validateURL(url: string): boolean {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

/**
 * Sanitize HTML to prevent XSS
 * @param {string} html - HTML to sanitize
 * @return {string} Sanitized HTML
 */
export function sanitizeHTML(html: string): string {
  return html
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#x27;")
    .replace(/\//g, "&#x2F;");
}

/**
 * Validate required fields in an object
 * @param {T} obj - Object to validate
 * @param {Array} requiredFields - Required field names
 * @return {void}
 */
export function validateRequiredFields<T extends Record<string, unknown>>(
  obj: T,
  requiredFields: (keyof T)[]
): void {
  const missingFields = requiredFields.filter((field) => !obj[field]);

  if (missingFields.length > 0) {
    throw new ValidationError(
      `Missing required fields: ${missingFields.join(", ")}`
    );
  }
}

/**
 * Validate curriculum data
 * @param {unknown} curriculum - Curriculum object to validate
 * @return {void}
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function validateCurriculum(curriculum: any): void {
  validateRequiredFields(curriculum, ["personal_info", "uid"]);
  validateRequiredFields(curriculum.personal_info, ["full_name", "email"]);

  if (!validateEmail(curriculum.personal_info.email)) {
    throw new ValidationError("Invalid email format");
  }

  if (curriculum.personal_info.phone &&
      !validatePhoneNumber(curriculum.personal_info.phone)) {
    throw new ValidationError("Invalid phone number format");
  }

  if (curriculum.personal_info.linkedin &&
      !validateURL(curriculum.personal_info.linkedin)) {
    throw new ValidationError("Invalid LinkedIn URL");
  }

  if (curriculum.personal_info.portfolio &&
      !validateURL(curriculum.personal_info.portfolio)) {
    throw new ValidationError("Invalid portfolio URL");
  }
}

/**
 * Validate job offer data
 * @param {unknown} offer - Job offer object to validate
 * @return {void}
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function validateJobOffer(offer: any): void {
  validateRequiredFields(offer, [
    "company_uid",
    "title",
    "description",
    "location",
    "salary_min",
    "salary_max",
    "salary_currency",
    "salary_period",
  ]);

  // AI Act / Resumen RGPD: Prohibido recoger historial salarial
  if ("previous_salary" in offer || "salary_history" in offer) {
    throw new ValidationError(
      "Illegal field detected: Asking for salary history is prohibited by law"
    );
  }

  if (typeof offer.job_type === "string" && offer.job_type) {
    const validJobTypes = [
      "Presencial",
      "Híbrido",
      "Solo teletrabajo",
      // Legacy values kept for backward compatibility
      "full_time",
      "part_time",
      "contract",
      "internship",
    ];
    if (!validJobTypes.includes(offer.job_type)) {
      throw new ValidationError(
        `Invalid job_type. Must be one of: ${validJobTypes.join(", ")}`
      );
    }
  }

  // Parse as numbers to compare properly
  const min = Number(offer.salary_min);
  const max = Number(offer.salary_max);
  if (!isNaN(min) && !isNaN(max) && min > max) {
    throw new ValidationError("salary_min cannot be greater than salary_max");
  }
}

/**
 * Validate application data
 * @param {unknown} application - Application object to validate
 * @return {void}
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function validateApplication(application: any): void {
  validateRequiredFields(application, [
    "job_offer_id",
    "candidate_uid",
    "curriculum_id",
  ]);
}
