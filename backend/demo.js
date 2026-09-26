// ============================================================
// MilkPro Phase 1 - Allocation Cutover DRY RUN
// Date: 2026-09-25
//
// SAFE: READ-ONLY. This script does NOT update/insert/delete anything.
// Purpose:
//   1) Audit legacy allocations before 25-Sep-2026
//   2) Audit historical salesman-allocation sales
//   3) Calculate daily unused allocation and same-day oversell
//   4) Calculate the net opening quantity for the 25-Sep cutover
//
// Expected restored-test-DB fingerprint:
//   Legacy allocations : 41
//   Historical sales   : 478
//   Legacy adjustment  : 9225.20
//   Daily oversell     : 3246.00
//   Opening total      : 5979.20
// ============================================================

const TARGET_FARM_IDS = [
  "FARM990782",
  "FARM442481"
];

const OPENING_DATE = ISODate("2026-09-25T00:00:00.000Z");

// Sales are grouped by IST business date.
// End of 24-Sep-2026 IST = 24-Sep 18:30 UTC.
const SALE_CUTOFF = ISODate("2026-09-24T18:30:00.000Z");

const EXPECTED = {
  legacyAllocations: 41,
  historicalSales: 478,
  legacyAdjustment: 8514.20,
  dailyOversell: 3246.00,
  openingTotal: 5978.20
};

const TOLERANCE = 0.01;

function round2(value) {
  const n = Number(value || 0);
  if (!Number.isFinite(n)) return 0;
  const r = Math.round((n + Number.EPSILON) * 100) / 100;
  return Object.is(r, -0) ? 0 : r;
}

function allocationDay(value) {
  return new Date(value).toISOString().slice(0, 10);
}

function saleDayIST(value) {
  return new Date(
    new Date(value).getTime() + 19800000
  ).toISOString().slice(0, 10);
}

function norm(v) {
  return (v || "").toString().trim().toUpperCase();
}

function dayProductKey(farmId, salesmanId, day, productId) {
  return [
    norm(farmId),
    norm(salesmanId),
    day,
    norm(productId)
  ].join("|");
}

function salesmanProductKey(farmId, salesmanId, productId) {
  return [
    norm(farmId),
    norm(salesmanId),
    norm(productId)
  ].join("|");
}

function salesmanKey(farmId, salesmanId) {
  return [
    norm(farmId),
    norm(salesmanId)
  ].join("|");
}

function assertEq(label, actual, expected) {
  if (actual !== expected) {
    throw new Error(
      `${label} mismatch. Expected ${expected}, found ${actual}. STOP.`
    );
  }
}

function assertClose(label, actual, expected) {
  if (Math.abs(round2(actual) - round2(expected)) > TOLERANCE) {
    throw new Error(
      `${label} mismatch. Expected ${round2(expected)}, ` +
      `found ${round2(actual)}. STOP.`
    );
  }
}

print("\n============================================================");
print("MILKPRO PHASE 1 - ALLOCATION CUTOVER DRY RUN");
print("============================================================");
print(`Database: ${db.getName()}`);
print("Mode: READ-ONLY / DRY RUN");
print("No database documents will be changed.");


// ============================================================
// LOAD LEGACY DATA
// ============================================================

const legacyAllocations = db.TRN_ALLOCATION.find({
  farmId: { $in: TARGET_FARM_IDS },
  allocationDate: { $lt: OPENING_DATE },
  status: { $in: ["POSTED", "RETURNED"] }
})
.sort({
  allocationDate: 1,
  createdAt: 1,
  _id: 1
})
.toArray();

const historicalSales = db.TRN_SALE.find({
  farmId: { $in: TARGET_FARM_IDS },
  status: "POSTED",
  createdRole: "salesman",
  stockSource: "SALESMAN_ALLOCATION",
  saleDate: { $lt: SALE_CUTOFF }
})
.sort({
  saleDate: 1,
  createdAt: 1,
  _id: 1
})
.toArray();

print("\n===== SOURCE COUNTS =====");
printjson({
  legacyAllocations: legacyAllocations.length,
  historicalSales: historicalSales.length
});

assertEq(
  "Legacy allocation count",
  legacyAllocations.length,
  EXPECTED.legacyAllocations
);

assertEq(
  "Historical sale count",
  historicalSales.length,
  EXPECTED.historicalSales
);


// ============================================================
// BUILD DAILY ALLOCATION MAP
// ============================================================

const daily = new Map();
const meta = new Map();
const salesmanNames = new Map();

for (const allocation of legacyAllocations) {
  const day = allocationDay(allocation.allocationDate);
  const farmId = norm(allocation.farmId);
  const salesmanId = norm(allocation.salesmanId);

  salesmanNames.set(
    salesmanKey(farmId, salesmanId),
    allocation.salesmanName || salesmanId
  );

  for (const p of (Array.isArray(allocation.products) ? allocation.products : [])) {
    const productId = norm(p.productId);
    if (!productId) continue;

    const key = dayProductKey(
      farmId,
      salesmanId,
      day,
      productId
    );

    if (!daily.has(key)) {
      daily.set(key, {
        farmId,
        salesmanId,
        salesmanName: allocation.salesmanName || salesmanId,
        day,
        productId,
        productName: p.productName || productId,
        variant: p.variant || "",
        unit: p.unit || "Pcs",
        allocated: 0,
        returned: 0,
        sold: 0
      });
    }

    const row = daily.get(key);

    row.allocated = round2(
      row.allocated + round2(p.quantity)
    );

    row.returned = round2(
      row.returned + round2(p.returnedQuantity)
    );

    meta.set(
      `${farmId}|${productId}`,
      {
        productName: p.productName || productId,
        variant: p.variant || "",
        unit: p.unit || "Pcs"
      }
    );
  }
}


// ============================================================
// ADD SAME-BUSINESS-DATE SALES
// ============================================================

for (const sale of historicalSales) {
  const day = saleDayIST(sale.saleDate);
  const farmId = norm(sale.farmId);
  const salesmanId = norm(sale.salesmanId);

  salesmanNames.set(
    salesmanKey(farmId, salesmanId),
    sale.salesmanName || salesmanId
  );

  for (const p of (Array.isArray(sale.products) ? sale.products : [])) {
    const productId = norm(p.productId);
    if (!productId) continue;

    const key = dayProductKey(
      farmId,
      salesmanId,
      day,
      productId
    );

    if (!daily.has(key)) {
      const m =
        meta.get(`${farmId}|${productId}`) ||
        {
          productName: p.productName || productId,
          variant: p.variant || "",
          unit: p.unit || "Pcs"
        };

      daily.set(key, {
        farmId,
        salesmanId,
        salesmanName: sale.salesmanName || salesmanId,
        day,
        productId,
        productName: m.productName,
        variant: m.variant,
        unit: m.unit,
        allocated: 0,
        returned: 0,
        sold: 0
      });
    }

    const row = daily.get(key);

    row.sold = round2(
      row.sold + round2(p.quantity)
    );

    if (!meta.has(`${farmId}|${productId}`)) {
      meta.set(
        `${farmId}|${productId}`,
        {
          productName: p.productName || productId,
          variant: p.variant || "",
          unit: p.unit || "Pcs"
        }
      );
    }
  }
}


// ============================================================
// DAILY VARIANCE
// ============================================================

const dailyRows = [];
let totalLegacyAdjustment = 0;
let totalDailyOversell = 0;

for (const row of daily.values()) {
  const usable = round2(
    row.allocated - row.returned
  );

  const variance = round2(
    usable - row.sold
  );

  const openQty =
    variance > 0 ? variance : 0;

  const oversoldQty =
    variance < 0 ? round2(-variance) : 0;

  totalLegacyAdjustment = round2(
    totalLegacyAdjustment + openQty
  );

  totalDailyOversell = round2(
    totalDailyOversell + oversoldQty
  );

  dailyRows.push({
    ...row,
    usable,
    variance,
    openQty,
    oversoldQty
  });
}

dailyRows.sort((a, b) =>
  a.day.localeCompare(b.day) ||
  a.salesmanName.localeCompare(b.salesmanName) ||
  a.productId.localeCompare(b.productId)
);


// ============================================================
// CUMULATIVE PRODUCT POSITION BY SALESMAN
// ============================================================

const cumulative = new Map();

for (const row of dailyRows) {
  const key = salesmanProductKey(
    row.farmId,
    row.salesmanId,
    row.productId
  );

  if (!cumulative.has(key)) {
    cumulative.set(key, {
      farmId: row.farmId,
      salesmanId: row.salesmanId,
      salesmanName: row.salesmanName,
      productId: row.productId,
      productName: row.productName,
      variant: row.variant,
      unit: row.unit,
      qty: 0
    });
  }

  cumulative.get(key).qty = round2(
    cumulative.get(key).qty + row.variance
  );
}


// ============================================================
// BUILD NET OPENING BY SALESMAN
//
// Legacy data contains a few product-level negative positions.
// For cutover, negatives are netted against that SAME SALESMAN'S
// positive historical balance so the opening represents the
// salesman-level net physical stock carried into 25-Sep.
// ============================================================

const salesmanBuckets = new Map();

for (const row of cumulative.values()) {
  const sk = salesmanKey(
    row.farmId,
    row.salesmanId
  );

  if (!salesmanBuckets.has(sk)) {
    salesmanBuckets.set(sk, {
      farmId: row.farmId,
      salesmanId: row.salesmanId,
      salesmanName:
        salesmanNames.get(sk) ||
        row.salesmanName ||
        row.salesmanId,
      positive: [],
      negativeTotal: 0
    });
  }

  const bucket = salesmanBuckets.get(sk);

  if (row.qty > 0) {
    bucket.positive.push({
      ...row,
      qty: round2(row.qty)
    });
  } else if (row.qty < 0) {
    bucket.negativeTotal = round2(
      bucket.negativeTotal + (-row.qty)
    );
  }
}

const openingRows = [];

for (const bucket of salesmanBuckets.values()) {
  // Deterministic ordering.
  bucket.positive.sort((a, b) =>
    a.productId.localeCompare(b.productId)
  );

  let deficit = round2(bucket.negativeTotal);

  // Consume historical negative positions from this salesman's
  // positive carry-forward stock.
  for (const p of bucket.positive) {
    if (deficit <= 0) break;

    const used = round2(
      Math.min(p.qty, deficit)
    );

    p.qty = round2(p.qty - used);
    deficit = round2(deficit - used);
  }

  if (deficit > TOLERANCE) {
    throw new Error(
      `Salesman ${bucket.salesmanName} (${bucket.salesmanId}) ` +
      `still has uncovered historical oversell ${deficit}. STOP.`
    );
  }

  for (const p of bucket.positive) {
    if (p.qty >= 0.01) {
      openingRows.push({
        farmId: bucket.farmId,
        salesmanId: bucket.salesmanId,
        salesmanName: bucket.salesmanName,
        productId: p.productId,
        productName: p.productName,
        variant: p.variant,
        unit: p.unit,
        openingQty: round2(p.qty)
      });
    }
  }
}

const openingBySalesmanMap = new Map();

for (const row of openingRows) {
  const sk = salesmanKey(
    row.farmId,
    row.salesmanId
  );

  if (!openingBySalesmanMap.has(sk)) {
    openingBySalesmanMap.set(sk, {
      farmId: row.farmId,
      salesmanId: row.salesmanId,
      salesmanName: row.salesmanName,
      products: 0,
      openingQty: 0
    });
  }

  const s = openingBySalesmanMap.get(sk);

  s.products += 1;
  s.openingQty = round2(
    s.openingQty + row.openingQty
  );
}

const openingBySalesman =
  Array.from(openingBySalesmanMap.values())
  .sort((a, b) =>
    b.openingQty - a.openingQty
  );

const openingTotal = round2(
  openingRows.reduce(
    (sum, x) => sum + x.openingQty,
    0
  )
);


// ============================================================
// SUMMARY + ASSERTIONS
// ============================================================

print("\n===== PHASE 1 DRY-RUN SUMMARY =====");
printjson({
  totalLegacyAdjustment,
  totalDailyOversell,
  openingTotal,
  legacyAllocations: legacyAllocations.length,
  historicalSales: historicalSales.length,
  openingAllocations: openingBySalesman.length,
  openingProductLines: openingRows.length
});

print("\n===== OPENING BY SALESMAN =====");
printjson(openingBySalesman);

print("\n===== TOP DAILY OVERSELL =====");
printjson(
  dailyRows
    .filter(x => x.oversoldQty > 0)
    .sort((a, b) => b.oversoldQty - a.oversoldQty)
    .slice(0, 30)
    .map(x => ({
      farmId: x.farmId,
      salesmanId: x.salesmanId,
      salesmanName: x.salesmanName,
      day: x.day,
      productId: x.productId,
      productName: x.productName,
      allocated: x.allocated,
      returned: x.returned,
      sold: x.sold,
      oversoldQty: x.oversoldQty
    }))
);

assertClose(
  "Legacy adjustment total",
  totalLegacyAdjustment,
  EXPECTED.legacyAdjustment
);

assertClose(
  "Daily oversell total",
  totalDailyOversell,
  EXPECTED.dailyOversell
);

assertClose(
  "Opening total",
  openingTotal,
  EXPECTED.openingTotal
);

print("\n============================================================");
print("ALL PHASE 1 DRY-RUN ASSERTIONS PASSED");
print("NO DATA WAS CHANGED");
print("============================================================");
