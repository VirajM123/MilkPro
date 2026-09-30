"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  isBusinessDateKey,
  normalizeBusinessDateKey,
  parseBusinessDateKey,
  getIndiaBusinessDateKey,
  getIndiaBusinessDayRange,
  parseBusinessDateInputToKey,
  businessDateToCanonicalUtcDate,
  getAllocationBusinessDateKey,
} = require("./business-date");

test("maps UTC instants to the correct India business date at midnight", () => {
  assert.equal(getIndiaBusinessDateKey("2026-09-25T18:29:59.999Z"), "2026-09-25");
  assert.equal(getIndiaBusinessDateKey("2026-09-25T18:30:00.000Z"), "2026-09-26");
  assert.equal(getIndiaBusinessDateKey("2026-09-26T18:29:59.999Z"), "2026-09-26");
  assert.equal(getIndiaBusinessDateKey("2026-09-26T18:30:00.000Z"), "2026-09-27");
});

test("validates and normalizes date-only business keys without a timezone shift", () => {
  assert.equal(isBusinessDateKey("2026-09-26"), true);
  assert.equal(normalizeBusinessDateKey(" 2026-09-26 "), "2026-09-26");
  assert.equal(isBusinessDateKey("2026-02-29"), false);
  assert.throws(() => parseBusinessDateKey("2026-02-29"), /valid YYYY-MM-DD/);
});

test("builds the exact IST business-day timestamp range", () => {
  const range = getIndiaBusinessDayRange("2026-09-26");

  assert.equal(range.date, "2026-09-26");
  assert.equal(range.start.toISOString(), "2026-09-25T18:30:00.000Z");
  assert.equal(range.end.toISOString(), "2026-09-26T18:30:00.000Z");
});

test("parses date-only, explicit-zone, and India wall-clock allocation input safely", () => {
  assert.equal(parseBusinessDateInputToKey("2026-09-26"), "2026-09-26");
  assert.equal(parseBusinessDateInputToKey("2026-09-25T18:30:00.000Z"), "2026-09-26");
  assert.equal(parseBusinessDateInputToKey("2026-09-26T00:15:00+05:30"), "2026-09-26");
  assert.equal(parseBusinessDateInputToKey("2026-09-26T23:59:59"), "2026-09-26");
  assert.throws(() => parseBusinessDateInputToKey("2026-09-26T24:00:00"), /invalid time/);
  assert.throws(() => parseBusinessDateInputToKey("2026-02-31"), /valid YYYY-MM-DD/);
});

test("stores allocation business dates canonically after resolving timestamp input", () => {
  const stored = businessDateToCanonicalUtcDate("2026-09-25T18:30:00.000Z");

  assert.equal(stored.toISOString(), "2026-09-26T00:00:00.000Z");
  assert.equal(
    getAllocationBusinessDateKey("2026-09-25T18:30:00.000Z"),
    "2026-09-26"
  );
});
