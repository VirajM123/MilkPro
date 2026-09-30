"use strict";

// India has a fixed UTC offset and does not observe daylight-saving time.
// Keep calendar business dates (`YYYY-MM-DD`) separate from event timestamps.
const INDIA_OFFSET_MS = 5.5 * 60 * 60 * 1000;
const INDIA_TIME_ZONE = "Asia/Kolkata";
const DATE_KEY_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const ISO_DATE_TIME_PATTERN = /^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,9}))?)?([zZ]|[+-]\d{2}:?\d{2})?$/;

function createDateError(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

function datePartsFromKey(value) {
  const text = (value ?? "").toString().trim();
  const match = text.match(DATE_KEY_PATTERN);

  if (!match) {
    return null;
  }

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const check = new Date(Date.UTC(year, month - 1, day));

  if (
    check.getUTCFullYear() !== year ||
    check.getUTCMonth() !== month - 1 ||
    check.getUTCDate() !== day
  ) {
    return null;
  }

  return {
    year,
    month,
    day,
    key: `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`,
  };
}

function isBusinessDateKey(value) {
  return Boolean(datePartsFromKey(value));
}

function normalizeBusinessDateKey(value) {
  return datePartsFromKey(value)?.key || "";
}

function parseBusinessDateKey(value, label = "Business date") {
  const key = normalizeBusinessDateKey(value);

  if (!key) {
    throw createDateError(`${label} must be a valid YYYY-MM-DD date.`);
  }

  return key;
}

function getIndiaBusinessDateKey(value) {
  if (value === undefined || value === null || value === "") {
    return "";
  }

  const directKey = normalizeBusinessDateKey(value);
  if (directKey) {
    return directKey;
  }

  const instant = value instanceof Date ? new Date(value.getTime()) : new Date(value);
  if (Number.isNaN(instant.getTime())) {
    return "";
  }

  const indiaTime = new Date(instant.getTime() + INDIA_OFFSET_MS);
  const year = indiaTime.getUTCFullYear();
  const month = String(indiaTime.getUTCMonth() + 1).padStart(2, "0");
  const day = String(indiaTime.getUTCDate()).padStart(2, "0");

  return `${year}-${month}-${day}`;
}

// Date-only values are business-date tokens. Explicit-zone timestamps are real
// instants, so they are converted to Asia/Kolkata. A zone-less ISO timestamp is
// treated as India wall-clock input; this avoids making the server host's local
// timezone part of the business-date decision.
function parseBusinessDateInputToKey(value, label = "Business date") {
  const directKey = normalizeBusinessDateKey(value);
  if (directKey) {
    return directKey;
  }

  if (typeof value === "string") {
    const text = value.trim();

    // Do not let JavaScript normalize an impossible date such as 2026-02-31
    // into a different month.  A date-only value is always intended as a
    // business-date key, so reject it if validation above failed.
    if (/^\d{4}-\d{2}-\d{2}$/.test(text)) {
      return parseBusinessDateKey(text, label);
    }

    const match = text.match(ISO_DATE_TIME_PATTERN);

    if (match) {
      const dateKey = parseBusinessDateKey(match[1], label);
      const hour = Number(match[2]);
      const minute = Number(match[3]);
      const second = match[4] === undefined ? 0 : Number(match[4]);

      if (hour > 23 || minute > 59 || second > 59) {
        throw createDateError(`${label} contains an invalid time.`);
      }

      // No offset means this was entered as an India local datetime. Its date
      // component is the India business date and does not depend on host TZ.
      if (!match[6]) {
        return dateKey;
      }

      const key = getIndiaBusinessDateKey(text);
      if (key) {
        return key;
      }
    }
  }

  const key = getIndiaBusinessDateKey(value);
  if (!key) {
    throw createDateError(`${label} must be a valid date or ISO timestamp.`);
  }

  return key;
}

// A timestamp range for records whose business day must be inferred from their
// real event time. Start is 00:00:00 in India; end is exclusive.
function getIndiaBusinessDayRange(value) {
  const key = parseBusinessDateKey(value);
  const { year, month, day } = datePartsFromKey(key);
  const start = new Date(Date.UTC(year, month - 1, day) - INDIA_OFFSET_MS);
  const end = new Date(Date.UTC(year, month - 1, day + 1) - INDIA_OFFSET_MS);

  return { date: key, start, end };
}

// Allocations store a calendar date at UTC midnight. This is a storage
// convention for a business-date token, not an event timestamp.
function businessDateToCanonicalUtcDate(value, label = "Allocation date") {
  const key = parseBusinessDateInputToKey(value, label);
  const { year, month, day } = datePartsFromKey(key);

  return new Date(Date.UTC(year, month - 1, day, 0, 0, 0, 0));
}

function getAllocationBusinessDateKey(value) {
  try {
    return parseBusinessDateInputToKey(value, "Allocation date");
  } catch (_error) {
    return "";
  }
}

module.exports = {
  INDIA_OFFSET_MS,
  INDIA_TIME_ZONE,
  datePartsFromKey,
  isBusinessDateKey,
  normalizeBusinessDateKey,
  parseBusinessDateKey,
  getIndiaBusinessDateKey,
  parseBusinessDateInputToKey,
  getIndiaBusinessDayRange,
  businessDateToCanonicalUtcDate,
  getAllocationBusinessDateKey,

  // Compatibility aliases for the existing backend helper names.
  requireBusinessDateKey: parseBusinessDateKey,
  parseAllocationBusinessDate: businessDateToCanonicalUtcDate,
};
