const mongoose = require("mongoose");
const path = require("path");
const jwt = require("jsonwebtoken");
require("dotenv").config({ path: path.join(__dirname, ".env") });

const BASE_URL = "http://localhost:5000";
const JWT_SECRET = process.env.JWT_SECRET || "MilkPro_2026_Secure_JWT_Key_Change_This";
const FARM_ID = "FARM-E2E-ACCEPTANCE";

const adminToken = jwt.sign(
  {
    userId: "admin_e2e_user",
    role: "admin",
    farmId: FARM_ID,
    username: "admin_e2e",
  },
  JWT_SECRET,
  { expiresIn: "1h" }
);

function getSalesmanToken(salesmanId, mongoId) {
  return jwt.sign(
    {
      userId: mongoId ? mongoId.toString() : new mongoose.Types.ObjectId().toString(),
      farmId: FARM_ID,
      role: "salesman",
      salesmanId: salesmanId,
      permissions: ["collectionCreate", "collectionView", "salesView", "salesCreate"],
    },
    JWT_SECRET,
    { expiresIn: "1h" }
  );
}

async function api(endpoint, options = {}, token = adminToken) {
  const url = `${BASE_URL}${endpoint}`;
  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
    ...(options.headers || {}),
  };
  const res = await fetch(url, {
    ...options,
    headers,
    body: typeof options.body === "object" ? JSON.stringify(options.body) : options.body,
  });
  const data = await res.json().catch(() => ({}));
  return { status: res.status, ok: res.ok, data };
}

function assert(condition, message) {
  if (!condition) {
    console.error(`  FAIL: ${message}`);
    throw new Error(message);
  }
  console.log(`  PASS: ${message}`);
}

async function runE2EAcceptance() {
  console.log("========================================================");
  console.log("STARTING FINAL E2E ACCEPTANCE TESTING (TESTS 1 - 18)");
  console.log(`Farm: ${FARM_ID}`);
  console.log(`Base URL: ${BASE_URL}`);
  console.log("========================================================\n");

  const mongoUri = process.env.MONGODB_URI || "mongodb://localhost:27017/MilkPro";
  const conn = await mongoose.createConnection(mongoUri).asPromise();
  const db = conn.useDb("MilkPro");
  const trnCollectionCol = db.collection("TRN_COLLECTION");

  try {
    // ----------------------------------------------------
    // CLEANUP & SETUP: PRODUCT & TEST CUSTOMER
    // ----------------------------------------------------
    await db.collection("MAS_CUSTOMER").deleteMany({ farmId: FARM_ID });
    await db.collection("MAS_PRODUCT").deleteMany({ farmId: FARM_ID });
    await db.collection("MAS_SALESMAN").deleteMany({ farmId: FARM_ID });
    await db.collection("MAS_ROUTE").deleteMany({ farmId: FARM_ID });
    await db.collection("TRN_ALLOCATION").deleteMany({ farmId: FARM_ID });
    await db.collection("TRN_SALE").deleteMany({ farmId: FARM_ID });
    await db.collection("TRN_COLLECTION").deleteMany({ farmId: FARM_ID });
    await db.collection("TRN_CUSTOMER_OUTSTANDING").deleteMany({ farmId: FARM_ID });

    console.log("--- SETUP: Test Customer & Product ---");
    const pRes = await api("/api/products", {
      method: "POST",
      body: {
        productName: "E2E Buffalo Milk",
        variant: "1L",
        category: "Milk",
        unit: "Litre",
        stock: 10000,
        price: 100,
      },
    });
    assert(pRes.status === 201 || pRes.status === 200, "Created test product");
    const testProduct = pRes.data.data;

    const custName = "E2E MANUAL COLLECTION CUSTOMER";
    const cRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: custName,
        mobile: "9876543210",
        route: "Route E2E",
        openingOutstanding: 0,
      },
    });
    assert(cRes.status === 201 || cRes.status === 200, "Created customer: " + custName);
    const testCustomer = cRes.data.data;
    const customerId = testCustomer.customerId;

    // ========================================================
    // TEST 1 — MANUAL SELECT A LATER BILL
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 1 — MANUAL SELECT A LATER BILL");
    console.log("========================================================");

    // Bill A: Due ₹300 (qty 3)
    const saleARes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId,
        saleDate: "2026-09-01T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 3, unitPrice: 100, total: 300 }],
      },
    });
    assert(saleARes.status === 201, "Created Bill A: Due ₹300");
    const billA = saleARes.data.data;

    // Bill B: Due ₹500 (qty 5)
    const saleBRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId,
        saleDate: "2026-09-02T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 5, unitPrice: 100, total: 500 }],
      },
    });
    assert(saleBRes.status === 201, "Created Bill B: Due ₹500");
    const billB = saleBRes.data.data;

    // Bill C: Due ₹700 (qty 7)
    const saleCRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId,
        saleDate: "2026-09-03T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 7, unitPrice: 100, total: 700 }],
      },
    });
    assert(saleCRes.status === 201, "Created Bill C: Due ₹700");
    const billC = saleCRes.data.data;

    // Verify bills display oldest-first
    const outRes1 = await api("/api/collections/outstanding");
    assert(outRes1.status === 200, "GET /api/collections/outstanding returned 200");
    const custRow1 = outRes1.data.data.find((c) => c.customerId === customerId);
    assert(custRow1 !== undefined, "Customer found in outstanding list");
    assert(custRow1.bills.length >= 3, "Customer has at least 3 bills");

    const userBills1 = custRow1.bills.filter((b) =>
      [billA.saleId, billB.saleId, billC.saleId].includes(b.saleId)
    );
    assert(userBills1.length === 3, "All 3 bills present in outstanding");
    assert(userBills1[0].saleId === billA.saleId, "Bill 1 is Bill A (oldest-first)");
    assert(userBills1[1].saleId === billB.saleId, "Bill 2 is Bill B");
    assert(userBills1[2].saleId === billC.saleId, "Bill 3 is Bill C");
    const initialOut = custRow1.currentOutstanding ?? custRow1.outstanding;
    assert(Math.abs(initialOut - 1500) < 0.01, `Customer outstanding before: 1500 (got ${initialOut})`);

    // Collection: ₹400, SELECT BILLS, Select ONLY Bill C, Apply ₹400
    const col1Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 400,
        paymentMode: "Cash",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST1",
        allocationMode: "MANUAL",
        selectedAllocations: [
          {
            sourceType: "SALE",
            referenceId: billC.saleId,
            amountApplied: 400,
          },
        ],
      },
    });
    assert(col1Res.status === 201, "Collection 1 created (status 201)");
    const col1Data = col1Res.data.data;
    assert(col1Data.allocationMode === "MANUAL", "allocationMode = MANUAL");
    assert(col1Data.allocations.length === 1, "allocations.length = 1");
    assert(col1Data.allocations[0].allocationSequence === 1, "allocationSequence = 1");
    assert(col1Data.allocations[0].referenceId === billC.saleId, "allocation.referenceId = Bill C saleId");
    assert(col1Data.allocations[0].customerName === custName, `Party Name beside Bill C: "${custName}"`);

    // Verify outstanding balances after Test 1
    const outRes1Post = await api("/api/collections/outstanding");
    const custRow1Post = outRes1Post.data.data.find((c) => c.customerId === customerId);
    const postOut1 = custRow1Post.currentOutstanding ?? custRow1Post.outstanding;
    assert(Math.abs(postOut1 - 1100) < 0.01, `Customer Outstanding after: ₹1100 (got ${postOut1})`);
    const bAPost = custRow1Post.bills.find((b) => b.saleId === billA.saleId);
    const bBPost = custRow1Post.bills.find((b) => b.saleId === billB.saleId);
    const bCPost = custRow1Post.bills.find((b) => b.saleId === billC.saleId);
    assert(Math.abs(bAPost.remainingOutstanding - 300) < 0.01, `Bill A remains ₹300 (got ${bAPost.remainingOutstanding})`);
    assert(Math.abs(bBPost.remainingOutstanding - 500) < 0.01, `Bill B remains ₹500 (got ${bBPost.remainingOutstanding})`);
    assert(Math.abs(bCPost.remainingOutstanding - 300) < 0.01, `Bill C Due After ₹300 (got ${bCPost.remainingOutstanding})`);

    // ========================================================
    // TEST 2 — MANUAL NON-FIFO MULTI BILL
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 2 — MANUAL NON-FIFO MULTI BILL");
    console.log("========================================================");
    // Collect ₹400. Selection order: 1. Bill B -> ₹250, 2. Bill A -> ₹150
    const col2Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 400,
        paymentMode: "UPI",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST2",
        allocationMode: "MANUAL",
        selectedAllocations: [
          {
            sourceType: "SALE",
            referenceId: billB.saleId,
            amountApplied: 250,
          },
          {
            sourceType: "SALE",
            referenceId: billA.saleId,
            amountApplied: 150,
          },
        ],
      },
    });
    assert(col2Res.status === 201, "Collection 2 created (status 201)");
    const col2Data = col2Res.data.data;
    assert(col2Data.allocations.length === 2, "2 allocations saved");
    const alloc1 = col2Data.allocations[0];
    const alloc2 = col2Data.allocations[1];

    assert(alloc1.allocationSequence === 1, "Seq 1 is first selected");
    assert(alloc1.referenceId === billB.saleId, "Seq 1 = Bill B (not reordered by date)");
    assert(Math.abs(alloc1.outstandingBefore - 500) < 0.01, `Seq 1 Before ₹500 (got ${alloc1.outstandingBefore})`);
    assert(Math.abs(alloc1.amountApplied - 250) < 0.01, `Seq 1 Applied ₹250 (got ${alloc1.amountApplied})`);
    assert(Math.abs(alloc1.outstandingAfter - 250) < 0.01, `Seq 1 After ₹250 (got ${alloc1.outstandingAfter})`);

    assert(alloc2.allocationSequence === 2, "Seq 2 is second selected");
    assert(alloc2.referenceId === billA.saleId, "Seq 2 = Bill A");
    assert(Math.abs(alloc2.outstandingBefore - 300) < 0.01, `Seq 2 Before ₹300 (got ${alloc2.outstandingBefore})`);
    assert(Math.abs(alloc2.amountApplied - 150) < 0.01, `Seq 2 Applied ₹150 (got ${alloc2.amountApplied})`);
    assert(Math.abs(alloc2.outstandingAfter - 150) < 0.01, `Seq 2 After ₹150 (got ${alloc2.outstandingAfter})`);

    const outRes2Post = await api("/api/collections/outstanding");
    const custRow2Post = outRes2Post.data.data.find((c) => c.customerId === customerId);
    const bCPost2 = custRow2Post.bills.find((b) => b.saleId === billC.saleId);
    assert(Math.abs(bCPost2.remainingOutstanding - 300) < 0.01, `Bill C remains unchanged at ₹300 (got ${bCPost2.remainingOutstanding})`);

    // ========================================================
    // TEST 3 — PARTIAL BILL
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 3 — PARTIAL BILL");
    console.log("========================================================");
    // Create dedicated bill of ₹500
    const sale3Res = await api("/api/sales", {
      method: "POST",
      body: {
        customerId,
        saleDate: "2026-09-04T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 5, unitPrice: 100, total: 500 }],
      },
    });
    assert(sale3Res.status === 201, "Created test bill with Due ₹500");
    const billPart = sale3Res.data.data;

    // Apply ₹200 on Bill of ₹500
    const col3Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 200,
        paymentMode: "Cash",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST3",
        allocationMode: "MANUAL",
        selectedAllocations: [
          {
            sourceType: "SALE",
            referenceId: billPart.saleId,
            amountApplied: 200,
          },
        ],
      },
    });
    assert(col3Res.status === 201, "Collection 3 partial applied (status 201)");
    const col3Alloc = col3Res.data.data.allocations[0];
    assert(Math.abs(col3Alloc.outstandingBefore - 500) < 0.01, `Due Before ₹500 (got ${col3Alloc.outstandingBefore})`);
    assert(Math.abs(col3Alloc.amountApplied - 200) < 0.01, `Applied ₹200 (got ${col3Alloc.amountApplied})`);
    assert(Math.abs(col3Alloc.outstandingAfter - 300) < 0.01, `Due After ₹300 (got ${col3Alloc.outstandingAfter})`);

    // ========================================================
    // TEST 4 — UNALLOCATED BLOCK
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 4 — UNALLOCATED BLOCK");
    console.log("========================================================");
    // Receipt ₹500, allocate only ₹400 -> Forced API returns 400
    const col4Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 500,
        paymentMode: "Cash",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST4",
        allocationMode: "MANUAL",
        selectedAllocations: [
          {
            sourceType: "SALE",
            referenceId: billPart.saleId,
            amountApplied: 400,
          },
        ],
      },
    });
    assert(col4Res.status === 400, `Forced API request rejected with HTTP 400 (got ${col4Res.status})`);
    assert(
      col4Res.data.message.includes("must equal receipt amount") || col4Res.data.message.includes("Sum of allocated amounts"),
      `Clear error message: "${col4Res.data.message}"`
    );

    // ========================================================
    // TEST 5 — OVER ALLOCATION
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 5 — OVER ALLOCATION");
    console.log("========================================================");
    // Bill Part has due ₹300. Try Apply Now ₹400 -> Forced API returns 400
    const col5Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 400,
        paymentMode: "Cash",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST5",
        allocationMode: "MANUAL",
        selectedAllocations: [
          {
            sourceType: "SALE",
            referenceId: billPart.saleId,
            amountApplied: 400,
          },
        ],
      },
    });
    assert(col5Res.status === 400, `Over-allocation rejected with HTTP 400 (got ${col5Res.status})`);
    assert(
      col5Res.data.message.includes("exceeds remaining due") || col5Res.data.message.includes("changed"),
      `Clear error message: "${col5Res.data.message}"`
    );

    // ========================================================
    // TEST 6 — AUTO FIFO
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 6 — AUTO FIFO");
    console.log("========================================================");
    // Create dedicated customer for clean Auto FIFO test: Bill A ₹300, Bill B ₹500, collect ₹400
    const cFifoRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "E2E AUTO FIFO CUSTOMER",
        mobile: "9876543211",
        route: "Route E2E",
        openingOutstanding: 0,
      },
    });
    assert(cFifoRes.status === 201, "Created E2E AUTO FIFO CUSTOMER");
    const fifoCustId = cFifoRes.data.data.customerId;

    const sFifoARes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: fifoCustId,
        saleDate: "2026-09-01T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 3, unitPrice: 100, total: 300 }],
      },
    });
    const sFifoBRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: fifoCustId,
        saleDate: "2026-09-02T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 5, unitPrice: 100, total: 500 }],
      },
    });
    assert(sFifoARes.status === 201 && sFifoBRes.status === 201, "Created FIFO Bill A (₹300) and Bill B (₹500)");

    const colFifoRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: fifoCustId,
        amount: 400,
        paymentMode: "Cash",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST6-FIFO",
        allocationMode: "FIFO",
      },
    });
    assert(colFifoRes.status === 201, "AUTO FIFO collection created (status 201)");
    const fifoCol = colFifoRes.data.data;
    assert(fifoCol.allocationMode === "FIFO", "allocationMode = FIFO");
    assert(fifoCol.allocations.length === 2, "FIFO allocated across 2 bills");
    const fAlloc1 = fifoCol.allocations[0];
    const fAlloc2 = fifoCol.allocations[1];

    assert(fAlloc1.referenceId === sFifoARes.data.data.saleId, "Allocation 1 = Bill A");
    assert(Math.abs(fAlloc1.outstandingBefore - 300) < 0.01, `Alloc 1 Before ₹300 (got ${fAlloc1.outstandingBefore})`);
    assert(Math.abs(fAlloc1.amountApplied - 300) < 0.01, `Alloc 1 Applied ₹300 (got ${fAlloc1.amountApplied})`);
    assert(Math.abs(fAlloc1.outstandingAfter - 0) < 0.01, `Alloc 1 After ₹0 (got ${fAlloc1.outstandingAfter})`);

    assert(fAlloc2.referenceId === sFifoBRes.data.data.saleId, "Allocation 2 = Bill B");
    assert(Math.abs(fAlloc2.outstandingBefore - 500) < 0.01, `Alloc 2 Before ₹500 (got ${fAlloc2.outstandingBefore})`);
    assert(Math.abs(fAlloc2.amountApplied - 100) < 0.01, `Alloc 2 Applied ₹100 (got ${fAlloc2.amountApplied})`);
    assert(Math.abs(fAlloc2.outstandingAfter - 400) < 0.01, `Alloc 2 After ₹400 (got ${fAlloc2.outstandingAfter})`);

    // ========================================================
    // TEST 7 — SWITCH BETWEEN MODES
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 7 — SWITCH BETWEEN MODES");
    console.log("========================================================");
    const col7Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: fifoCustId,
        amount: 200,
        paymentMode: "Cash",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST7-SWITCH",
        allocationMode: "FIFO",
      },
    });
    assert(col7Res.status === 201, "Switched mode collection submitted as FIFO");
    assert(col7Res.data.data.allocationMode === "FIFO", "Backend executed FIFO");

    // ========================================================
    // TEST 8 — PARTY NAME DISPLAY
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 8 — PARTY NAME DISPLAY");
    console.log("========================================================");
    const outRes8 = await api("/api/collections/outstanding");
    const custRow8 = outRes8.data.data.find((c) => c.customerId === customerId);
    assert(custRow8 !== undefined, "Customer found");
    const bill8 = custRow8.bills[0];
    assert(bill8.customerName === custName, `Bill displays Party Name: "${bill8.customerName}" (Not Salesman Name)`);
    assert(bill8.customerName !== "admin_e2e" && bill8.customerName !== "admin", "Party Name is NOT Admin / Salesman username");

    // ========================================================
    // TEST 9 — MANUAL OUTSTANDING SELECTION
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 9 — MANUAL OUTSTANDING SELECTION");
    console.log("========================================================");
    // Create dedicated customer: Sale ₹500, Manual ₹300, collect ₹200 on Manual
    const cManualRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "E2E MANUAL OUTSTANDING CUSTOMER",
        mobile: "9876543212",
        route: "Route E2E",
        openingOutstanding: 0,
      },
    });
    assert(cManualRes.status === 201, "Created customer for manual outstanding test");
    const manCustId = cManualRes.data.data.customerId;

    // Sale outstanding ₹500
    const sManRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: manCustId,
        saleDate: "2026-09-01T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 5, unitPrice: 100, total: 500 }],
      },
    });
    assert(sManRes.status === 201, "Created Sale ₹500");

    // Manual outstanding ₹300
    const adjRes = await api("/api/customer-outstanding", {
      method: "POST",
      body: {
        customerId: manCustId,
        amount: 300,
        asOfDate: "2026-09-02T10:00:00.000Z",
        notes: "Opening balance adjustment ₹300",
      },
    });
    assert(adjRes.status === 201 || adjRes.status === 200, "Created Manual Outstanding ₹300");
    const adjItem = adjRes.data.data;
    const manualRefId = adjItem.outstandingId || adjItem.adjustmentId;

    // Collect ₹200 on Manual Outstanding only
    const col9Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: manCustId,
        amount: 200,
        paymentMode: "Cash",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST9",
        allocationMode: "MANUAL",
        selectedAllocations: [
          {
            sourceType: "MANUAL_OUTSTANDING",
            referenceId: manualRefId,
            amountApplied: 200,
          },
        ],
      },
    });
    assert(col9Res.status === 201, "Collection 9 created (status 201)");
    const col9Alloc = col9Res.data.data.allocations[0];
    assert(col9Alloc.sourceType === "MANUAL_OUTSTANDING", "sourceType is MANUAL_OUTSTANDING");
    assert(Math.abs(col9Alloc.outstandingBefore - 300) < 0.01, `Manual Before ₹300 (got ${col9Alloc.outstandingBefore})`);
    assert(Math.abs(col9Alloc.amountApplied - 200) < 0.01, `Manual Applied ₹200 (got ${col9Alloc.amountApplied})`);
    assert(Math.abs(col9Alloc.outstandingAfter - 100) < 0.01, `Manual After ₹100 (got ${col9Alloc.outstandingAfter})`);

    const outRes9 = await api("/api/collections/outstanding");
    const custRow9 = outRes9.data.data.find((c) => c.customerId === manCustId);
    assert(Math.abs(custRow9.bills[0].remainingOutstanding - 500) < 0.01, `Sale remains ₹500 (got ${custRow9.bills[0].remainingOutstanding})`);
    assert(Math.abs(custRow9.manualOutstanding[0].remainingOutstanding - 100) < 0.01, `Manual remains ₹100 (got ${custRow9.manualOutstanding[0].remainingOutstanding})`);

    // ========================================================
    // TEST 10 — RECEIPT DETAIL
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 10 — RECEIPT DETAIL (MANUAL)");
    console.log("========================================================");
    const col1Fetch = await api(`/api/collections`);
    assert(col1Fetch.status === 200, "GET /api/collections returned 200");
    const rec10 = col1Fetch.data.data.find((r) => r.collectionId === col1Data.collectionId);
    assert(rec10 !== undefined, "Manual receipt found in collections history");
    assert(rec10.allocationMode === "MANUAL", "Allocation Method: Manual Bill Selection (allocationMode = MANUAL)");
    const alloc10 = rec10.allocations[0];
    assert(alloc10.allocationSequence === 1, "Seq: 1");
    assert(alloc10.sourceType === "SALE", "Source: SALE");
    assert(alloc10.customerName === custName, `Party Name: "${alloc10.customerName}"`);
    assert(alloc10.referenceId === billC.saleId, `Reference: ${alloc10.referenceId}`);
    assert(Math.abs(alloc10.sourceAmount - 700) < 0.01, `Source Amount: ₹${alloc10.sourceAmount}`);
    assert(Math.abs(alloc10.outstandingBefore - 700) < 0.01, `Due Before: ₹${alloc10.outstandingBefore}`);
    assert(Math.abs(alloc10.amountApplied - 400) < 0.01, `Applied: ₹${alloc10.amountApplied}`);
    assert(Math.abs(alloc10.outstandingAfter - 300) < 0.01, `Due After: ₹${alloc10.outstandingAfter}`);

    // ========================================================
    // TEST 11 — AUTO FIFO RECEIPT DETAIL
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 11 — AUTO FIFO RECEIPT DETAIL");
    console.log("========================================================");
    const rec11 = col1Fetch.data.data.find((r) => r.collectionId === fifoCol.collectionId);
    assert(rec11 !== undefined, "FIFO receipt found in collections history");
    assert(rec11.allocationMode === "FIFO", "Allocation Method: Auto FIFO (allocationMode = FIFO)");
    assert(rec11.allocations.length === 2, "2 FIFO allocations verified");

    // ========================================================
    // TEST 12 — CANCELLATION
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 12 — CANCELLATION");
    console.log("========================================================");
    // Create dedicated customer with Bill A ₹500, Bill B ₹500, Bill C ₹500
    const cCancelRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "E2E CANCEL TEST CUSTOMER",
        mobile: "9876543213",
        route: "Route E2E",
        openingOutstanding: 0,
      },
    });
    const cancelCustId = cCancelRes.data.data.customerId;
    const sCA = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cancelCustId,
        saleDate: "2026-09-01T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 5, unitPrice: 100, total: 500 }],
      },
    });
    const sCB = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cancelCustId,
        saleDate: "2026-09-02T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 5, unitPrice: 100, total: 500 }],
      },
    });
    const sCC = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cancelCustId,
        saleDate: "2026-09-03T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 5, unitPrice: 100, total: 500 }],
      },
    });

    // Create manual receipt: Bill C ₹200, Bill A ₹100
    const col12Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: cancelCustId,
        amount: 300,
        paymentMode: "Cash",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST12",
        allocationMode: "MANUAL",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: sCC.data.data.saleId, amountApplied: 200 },
          { sourceType: "SALE", referenceId: sCA.data.data.saleId, amountApplied: 100 },
        ],
      },
    });
    assert(col12Res.status === 201, "Manual receipt for cancellation test created (Bill C ₹200, Bill A ₹100)");

    // Cancel this latest receipt
    const cancel12Res = await api(`/api/collections/${col12Res.data.data.collectionId}/cancel`, {
      method: "PUT",
      body: { cancelReason: "E2E Acceptance Test Cancellation" },
    });
    assert(cancel12Res.status === 200, "Receipt cancelled successfully");

    const outRes12 = await api("/api/collections/outstanding");
    const custRow12 = outRes12.data.data.find((c) => c.customerId === cancelCustId);
    const bA12 = custRow12.bills.find((b) => b.saleId === sCA.data.data.saleId);
    const bB12 = custRow12.bills.find((b) => b.saleId === sCB.data.data.saleId);
    const bC12 = custRow12.bills.find((b) => b.saleId === sCC.data.data.saleId);

    assert(Math.abs(bC12.remainingOutstanding - 500) < 0.01, `Bill C received its ₹200 back (Due: ₹${bC12.remainingOutstanding})`);
    assert(Math.abs(bA12.remainingOutstanding - 500) < 0.01, `Bill A received its ₹100 back (Due: ₹${bA12.remainingOutstanding})`);
    assert(Math.abs(bB12.remainingOutstanding - 500) < 0.01, `Bill B remained completely untouched at ₹${bB12.remainingOutstanding}`);

    // ========================================================
    // TEST 13 — OUT-OF-ORDER CANCELLATION
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 13 — OUT-OF-ORDER CANCELLATION");
    console.log("========================================================");
    // Create Receipt 1 (₹100) and Receipt 2 (₹100)
    const rec1Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: cancelCustId,
        amount: 100,
        paymentMode: "Cash",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST13-REC1",
        allocationMode: "FIFO",
      },
    });
    const rec2Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: cancelCustId,
        amount: 100,
        paymentMode: "Cash",
        collectionDate: new Date().toISOString(),
        clientRequestId: "E2E-REQ-TEST13-REC2",
        allocationMode: "FIFO",
      },
    });
    assert(rec1Res.status === 201 && rec2Res.status === 201, "Created Receipt 1 and Receipt 2");

    // Try cancelling Receipt 1 first -> Should return 409 Conflict
    const cancelOldRes = await api(`/api/collections/${rec1Res.data.data.collectionId}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Try cancelling older receipt" },
    });
    assert(cancelOldRes.status === 409, `Out-of-order cancellation rejected with HTTP 409 (got ${cancelOldRes.status})`);
    assert(
      cancelOldRes.data.message.includes("newer collection transaction") || cancelOldRes.data.message.includes("Only the latest"),
      `Clear error message: "${cancelOldRes.data.message}"`
    );

    // ========================================================
    // TEST 14 — CONCURRENT COLLECTION
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 14 — CONCURRENT COLLECTION");
    console.log("========================================================");
    // Create customer with ₹500 bill
    const cRaceRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "E2E CONCURRENCY TEST CUSTOMER",
        mobile: "9876543214",
        route: "Route E2E",
        openingOutstanding: 0,
      },
    });
    const raceCustId = cRaceRes.data.data.customerId;
    await api("/api/sales", {
      method: "POST",
      body: {
        customerId: raceCustId,
        saleDate: "2026-09-01T10:00:00.000Z",
        products: [{ productId: testProduct.productId, quantity: 5, unitPrice: 100, total: 500 }],
      },
    });

    // Fire 2 simultaneous requests with DIFFERENT clientRequestIds
    const [reqA, reqB] = await Promise.all([
      api("/api/collections", {
        method: "POST",
        body: {
          customerId: raceCustId,
          amount: 500,
          paymentMode: "Cash",
          clientRequestId: "E2E-CON-A",
          allocationMode: "FIFO",
        },
      }),
      api("/api/collections", {
        method: "POST",
        body: {
          customerId: raceCustId,
          amount: 500,
          paymentMode: "Cash",
          clientRequestId: "E2E-CON-B",
          allocationMode: "FIFO",
        },
      }),
    ]);

    const statuses = [reqA.status, reqB.status].sort();
    assert(
      statuses[0] === 201 && (statuses[1] === 409 || statuses[1] === 400),
      `Race result: exactly one 201 and one conflict (got ${reqA.status} and ${reqB.status})`
    );

    const outResRace = await api("/api/collections/outstanding");
    const custRacePost = outResRace.data.data.find((c) => c.customerId === raceCustId);
    const postRaceOut = custRacePost.currentOutstanding ?? custRacePost.outstanding;
    assert(Math.abs(postRaceOut) < 0.01, `Outstanding is exactly ₹0, never negative (got ${postRaceOut})`);

    // ========================================================
    // TEST 15 — ADMIN COLLECTION -> SALESMAN FLUTTER
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 15 — ADMIN COLLECTION -> SALESMAN FLUTTER");
    console.log("========================================================");
    // Create salesman in database
    const salesmanId = "SM-E2E-SALESMAN";
    const salesmanMongoId = new mongoose.Types.ObjectId();
    await db.collection("MAS_SALESMAN").insertOne({
      _id: salesmanMongoId,
      farmId: FARM_ID,
      salesmanId,
      name: "E2E Salesman",
      mobile: "9988776655",
      routes: ["Route E2E"],
      permissionMode: "custom",
      permissions: ["collectionCreate", "collectionView", "salesView", "salesCreate"],
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await db.collection("MAS_ROUTE").insertOne({
      farmId: FARM_ID,
      routeId: "RT-E2E",
      routeName: "Route E2E",
      salesmanId,
      salesmanName: "E2E Salesman",
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const salesmanToken = getSalesmanToken(salesmanId, salesmanMongoId);

    // Allocate stock to salesman so salesman can record sale
    await db.collection("TRN_ALLOCATION").insertOne({
      farmId: FARM_ID,
      allocationId: "ALLOC-E2E-1",
      salesmanId,
      status: "POSTED",
      products: [{ productId: testProduct.productId, quantity: 100, returnedQuantity: 0 }],
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    // Create customer on salesman route
    const cSalesmanRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "E2E SYNC CUSTOMER",
        mobile: "9876543215",
        route: "Route E2E",
        salesmanId,
        openingOutstanding: 0,
      },
    });
    const syncCustId = cSalesmanRes.data.data.customerId;

    // Create bill through Salesman: Due ₹500
    const sSyncRes = await api(
      "/api/sales",
      {
        method: "POST",
        body: {
          customerId: syncCustId,
          saleDate: new Date().toISOString(),
          products: [{ productId: testProduct.productId, quantity: 5, unitPrice: 100, total: 500 }],
        },
      },
      salesmanToken
    );
    assert(sSyncRes.status === 201, "Salesman recorded sale: Due ₹500");
    const syncSaleId = sSyncRes.data.data.saleId;

    // Admin collects ₹300 against this bill
    const adminColSync = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: syncCustId,
        amount: 300,
        paymentMode: "Cash",
        clientRequestId: "E2E-REQ-ADMIN-SYNC",
        allocationMode: "MANUAL",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: syncSaleId, amountApplied: 300 },
        ],
      },
    });
    assert(adminColSync.status === 201, "Admin recorded ₹300 collection against Salesman's bill");

    // Refresh as same Salesman
    const smOutRes = await api("/api/collections/outstanding", {}, salesmanToken);
    assert(smOutRes.status === 200, "Salesman fetched /api/collections/outstanding");
    const smCustRow = smOutRes.data.data.find((c) => c.customerId === syncCustId);
    assert(smCustRow !== undefined, "Salesman sees customer");
    const smBill = smCustRow.bills.find((b) => b.saleId === syncSaleId);
    assert(Math.abs(smBill.remainingOutstanding - 200) < 0.01, `Salesman immediately sees remaining ₹200 due (got ${smBill.remainingOutstanding})`);

    // Salesman collects remaining ₹200
    const smColRes = await api(
      "/api/collections",
      {
        method: "POST",
        body: {
          customerId: syncCustId,
          amount: 200,
          paymentMode: "Cash",
          clientRequestId: "E2E-REQ-SM-COL",
          allocationMode: "MANUAL",
          selectedAllocations: [
            { sourceType: "SALE", referenceId: syncSaleId, amountApplied: 200 },
          ],
        },
      },
      salesmanToken
    );
    assert(smColRes.status === 201, "Salesman collected remaining ₹200");

    const smOutResFinal = await api("/api/collections/outstanding", {}, salesmanToken);
    const smCustFinal = smOutResFinal.data.data.find((c) => c.customerId === syncCustId);
    const smFinalOut = smCustFinal.currentOutstanding ?? smCustFinal.outstanding;
    assert(Math.abs(smFinalOut) < 0.01, `Final Due is ₹0 (got ${smFinalOut})`);

    // ========================================================
    // TEST 16 — IDEMPOTENCY
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 16 — IDEMPOTENCY");
    console.log("========================================================");
    const idemReq = {
      customerId,
      amount: 50,
      paymentMode: "Cash",
      clientRequestId: "E2E-IDEMPOTENT-KEY-123",
      allocationMode: "FIFO",
    };
    const idemRes1 = await api("/api/collections", { method: "POST", body: idemReq });
    const idemRes2 = await api("/api/collections", { method: "POST", body: idemReq });
    assert(idemRes1.status === 201, "Initial submit returned 201");
    assert(idemRes2.status === 200, "Duplicate submit returned 200 (idempotent replay)");
    assert(idemRes1.data.data.collectionId === idemRes2.data.data.collectionId, "Both resolve to exact same collectionId");

    const countIdem = await trnCollectionCol.countDocuments({ clientRequestId: "E2E-IDEMPOTENT-KEY-123" });
    assert(countIdem === 1, `Exactly ONE collection exists in DB for this clientRequestId (got ${countIdem})`);

    // ========================================================
    // TEST 17 — LEGACY FIFO
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 17 — LEGACY FIFO");
    console.log("========================================================");
    const legacyReq = {
      customerId,
      amount: 50,
      paymentMode: "Cash",
      clientRequestId: "E2E-LEGACY-PAYLOAD-1",
      // omits allocationMode & selectedAllocations
    };
    const legacyRes = await api("/api/collections", { method: "POST", body: legacyReq });
    assert(legacyRes.status === 201, "Legacy collection succeeded without error");
    assert(legacyRes.data.data.allocationMode === "FIFO", "Saved allocationMode defaulted to FIFO");

    // ========================================================
    // TEST 18 — HISTORICAL RECEIPT
    // ========================================================
    console.log("\n========================================================");
    console.log("TEST 18 — HISTORICAL RECEIPT");
    console.log("========================================================");
    // Insert an old legacy receipt missing snapshot fields directly into DB
    const histColId = "COL-HIST-OLD-999";
    await trnCollectionCol.insertOne({
      farmId: FARM_ID,
      collectionId: histColId,
      receiptNo: "REC-HIST-001",
      customerId,
      amount: 150,
      appliedAmount: 150,
      advanceAmount: 0,
      collectionDate: new Date("2024-01-01"),
      paymentMode: "Cash",
      status: "POSTED",
      allocations: [], // empty legacy allocations
      createdAt: new Date("2024-01-01"),
    });

    const getHist = await api(`/api/collections`);
    const histItem = getHist.data.data.find((r) => r.collectionId === histColId);
    assert(histItem !== undefined, "Historical receipt returned by API");
    assert(histItem.allocations.length === 0, "Allocations empty for historical receipt");

    // ========================================================
    // DATABASE CHECK
    // ========================================================
    console.log("\n========================================================");
    console.log("DATABASE CHECK — TRN_COLLECTION DIRECT INSPECTION");
    console.log("========================================================");
    const dbCol1 = await trnCollectionCol.findOne({ collectionId: col1Data.collectionId });
    assert(dbCol1 !== null, "Found Test 1 manual collection document in MongoDB");
    assert(dbCol1.allocationMode === "MANUAL", "DB: allocationMode = MANUAL");
    assert(dbCol1.amount === 400, "DB: amount = 400");
    assert(dbCol1.appliedAmount === 400, "DB: appliedAmount = 400");
    assert(dbCol1.clientRequestId === "E2E-REQ-TEST1", "DB: clientRequestId preserved");
    assert(Array.isArray(dbCol1.allocations) && dbCol1.allocations.length === 1, "DB: allocations array length 1");

    const dbAlloc = dbCol1.allocations[0];
    assert(dbAlloc.allocationSequence === 1, "DB Alloc: allocationSequence = 1");
    assert(dbAlloc.sourceType === "SALE", "DB Alloc: sourceType = SALE");
    assert(dbAlloc.referenceId === billC.saleId, "DB Alloc: referenceId = billC.saleId");
    assert(dbAlloc.customerName === custName, `DB Alloc: customerName = "${dbAlloc.customerName}"`);
    assert(dbAlloc.sourceAmount === 700, "DB Alloc: sourceAmount = 700");
    assert(dbAlloc.outstandingBefore === 700, "DB Alloc: outstandingBefore = 700");
    assert(dbAlloc.amountApplied === 400, "DB Alloc: amountApplied = 400");
    assert(dbAlloc.outstandingAfter === 300, "DB Alloc: outstandingAfter = 300");

    console.log("\n========================================================");
    console.log("ALL E2E ACCEPTANCE TESTS (1 - 18) PASSED SUCCESSFULLY!");
    console.log("========================================================");
  } finally {
    await conn.close();
  }
}

runE2EAcceptance().catch((err) => {
  console.error("FATAL ERROR IN E2E ACCEPTANCE:", err);
  process.exit(1);
});

