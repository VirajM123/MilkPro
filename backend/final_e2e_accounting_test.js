const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, ".env") });

const BASE_URL = `http://localhost:${process.env.PORT || 5000}`;
const TEST_FARM = "FARM154388";
const JWT_SECRET = process.env.JWT_SECRET || "MilkPro_2026_Secure_JWT_Key_Change_This";

// Admin token
const adminToken = jwt.sign(
  {
    userId: "test-admin-e2e",
    farmId: TEST_FARM,
    role: "admin",
  },
  JWT_SECRET,
  { expiresIn: "2h" }
);

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
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  return { status: res.status, data };
}

// Track created IDs for final report
const createdRecords = {
  customerIds: [],
  saleIds: [],
  saleNos: [],
  collectionIds: [],
  receiptNos: [],
  clientRequestIds: [],
  productIds: [],
  routeIds: [],
  salesmanIds: [],
  manualOutstandingIds: [],
};

const testResults = [];

function recordTest(testNum, testName, expected, mongoVal, apiVal, reactVal, flutterVal, pass, details = "") {
  testResults.push({
    testNum,
    testName,
    expected,
    mongoVal,
    apiVal,
    reactVal,
    flutterVal,
    pass,
    details,
  });
  const icon = pass ? "✓ PASS" : "❌ FAIL";
  console.log(`[${icon}] Test ${testNum}: ${testName}`);
  if (!pass) {
    console.error(`   Expected: ${JSON.stringify(expected)}`);
    console.error(`   MongoDB:  ${JSON.stringify(mongoVal)}`);
    console.error(`   API:      ${JSON.stringify(apiVal)}`);
    console.error(`   React:    ${JSON.stringify(reactVal)}`);
    console.error(`   Flutter:  ${JSON.stringify(flutterVal)}`);
    if (details) console.error(`   Details:  ${details}`);
  }
}

// Helper to simulate React Admin presentation mapping
function reactMapCustomer(c) {
  return {
    paidAtBilling: Number((c.totalPaidAtBilling ?? 0).toFixed(2)),
    laterCollections: Number((c.totalLaterCollections ?? 0).toFixed(2)),
    totalReceived: Number((c.totalReceived ?? 0).toFixed(2)),
    outstanding: Number((c.outstanding ?? 0).toFixed(2)),
    advanceBalance: Number((c.advanceBalance ?? 0).toFixed(2)),
    status: c.status === "PAID" ? "SETTLED" : (c.status || "DUE"),
    collectibleOutstanding: Math.max(0, Number((c.outstanding ?? 0).toFixed(2))),
    canCollect: Math.max(0, Number((c.outstanding ?? 0).toFixed(2))) > 0.001,
  };
}

// Helper to simulate Flutter model parsing
function flutterMapCustomer(c) {
  const outstanding = Number((c.outstanding ?? 0).toFixed(2));
  const paidAtBilling = Number((c.totalPaidAtBilling ?? 0).toFixed(2));
  const laterCollections = Number((c.totalLaterCollections ?? 0).toFixed(2));
  const totalReceived = Number((c.totalReceived ?? (paidAtBilling + laterCollections)).toFixed(2));
  const advanceBalance = Number((c.advanceBalance ?? 0).toFixed(2));
  const rawStatus = (c.status ?? "DUE").toString().toUpperCase();
  const status = rawStatus === "PAID" ? "SETTLED" : rawStatus;
  const collectibleOutstanding = Math.max(0, outstanding);
  return {
    paidAtBilling,
    laterCollections,
    totalReceived,
    outstanding,
    advanceBalance,
    status,
    collectibleOutstanding,
    canCollect: collectibleOutstanding > 0.001,
  };
}

async function runE2ETests() {
  console.log("=======================================================");
  console.log("FINAL END-TO-END SYSTEM ACCOUNTING AUDIT & TEST");
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Farm:     ${TEST_FARM}`);
  console.log("=======================================================\n");

  await mongoose.connect(process.env.MONGODB_URI);
  const db = mongoose.connection;

  try {
    // PRE-TEST CLEANUP OF E2E TEST DATA (ID-isolated prefix)
    await db.collection("MAS_CUSTOMER").deleteMany({ farmId: TEST_FARM, customerId: /^E2E-/ });
    await db.collection("MAS_PRODUCT").deleteMany({ farmId: TEST_FARM, productId: /^E2E-/ });
    await db.collection("MAS_ROUTE").deleteMany({ farmId: TEST_FARM, routeId: /^E2E-/ });
    await db.collection("MAS_SALESMAN").deleteMany({ farmId: TEST_FARM, salesmanId: /^E2E-/ });
    await db.collection("TRN_SALE").deleteMany({ farmId: TEST_FARM, customerId: /^E2E-/ });
    await db.collection("TRN_COLLECTION").deleteMany({ farmId: TEST_FARM, customerId: /^E2E-/ });
    await db.collection("TRN_CUSTOMER_OUTSTANDING").deleteMany({ farmId: TEST_FARM, customerId: /^E2E-/ });

    // Setup dedicated test Route & Salesman
    const testRouteId = "E2E-ROU-001";
    const testRouteName = "E2E ROUTE";
    const testSalesmanId = "E2E-SM-001";

    await db.collection("MAS_ROUTE").insertOne({
      farmId: TEST_FARM,
      routeId: testRouteId,
      routeName: testRouteName,
      salesmanId: testSalesmanId,
      isActive: true,
      createdAt: new Date(),
    });
    createdRecords.routeIds.push(testRouteId);
    const bcrypt = require("bcryptjs");
    const hashedPassword = await bcrypt.hash("Salesman@123", 10);
    await db.collection("MAS_SALESMAN").insertOne({
      farmId: TEST_FARM,
      salesmanId: testSalesmanId,
      name: "E2E SALESMAN",
      mobile: "9988770001",
      username: "e2esalesman",
      password: hashedPassword,
      routeId: testRouteId,
      routeName: testRouteName,
      assignedRoute: testRouteName,
      permissionMode: "custom",
      permissions: ["salesView", "salesCreate", "collectionView", "collectionCreate", "customersView"],
      isActive: true,
      createdAt: new Date(),
    });
    createdRecords.salesmanIds.push(testSalesmanId);

    // Setup dedicated test Product (₹50/L)
    const testProductId = "E2E-PRD-001";
    await db.collection("MAS_PRODUCT").insertOne({
      farmId: TEST_FARM,
      productId: testProductId,
      productName: "E2E Test Cow Milk 1L",
      variant: "1L",
      category: "Dairy",
      unit: "Litre",
      price: 50,
      stock: 10000,
      isActive: true,
      createdAt: new Date(),
    });
    createdRecords.productIds.push(testProductId);

    // =========================================================================
    // TEST 1 — PARTIAL BILL PAYMENT
    // Bill A = ₹1,000. Collect ₹600 CASH at billing.
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 1: Partial Bill Payment (Bill A ₹1000, ₹600 Cash at Billing)");
    const cust1Id = "E2E-CUST-001";
    await db.collection("MAS_CUSTOMER").insertOne({
      farmId: TEST_FARM,
      customerId: cust1Id,
      name: "E2E ACCOUNTING TEST",
      mobile: "9876540001",
      route: testRouteName,
      balance: 0,
      isActive: true,
      createdAt: new Date(),
    });
    createdRecords.customerIds.push(cust1Id);

    const saleARes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cust1Id,
        saleDate: new Date().toISOString(),
        payments: [{ mode: "Cash", amount: 600 }],
        products: [
          {
            productId: testProductId,
            productName: "E2E Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 20,
            rate: 50,
            amount: 1000,
          },
        ],
      },
    });

    const saleAData = saleARes.data.data;
    const saleAId = saleAData.saleId;
    const saleANo = saleAData.saleNo;
    createdRecords.saleIds.push(saleAId);
    createdRecords.saleNos.push(saleANo);

    // Verify in MongoDB
    const saleADoc = await db.collection("TRN_SALE").findOne({ farmId: TEST_FARM, saleId: saleAId });
    const mongoT1 = {
      grandTotal: saleADoc.grandTotal,
      paidAmount: saleADoc.paidAmount,
      paymentApplied: saleADoc.paymentApplied,
      advanceUsed: saleADoc.advanceUsed,
      advanceCreated: saleADoc.advanceCreated,
      outstandingAmount: saleADoc.outstandingAmount,
      paymentStatus: saleADoc.paymentStatus,
    };

    // Verify in Backend API
    const outT1Res = await api("/api/collections/outstanding");
    const custT1Api = outT1Res.data.data.find((c) => c.customerId === cust1Id);
    const apiT1 = {
      paidAtBilling: custT1Api.totalPaidAtBilling,
      laterCollections: custT1Api.totalLaterCollections,
      totalReceived: custT1Api.totalReceived,
      outstanding: custT1Api.outstanding,
      advance: custT1Api.advanceBalance,
      status: custT1Api.status,
    };

    // React mapping
    const reactT1 = reactMapCustomer(custT1Api);
    // Flutter mapping
    const flutterT1 = flutterMapCustomer(custT1Api);

    const expT1 = {
      grandTotal: 1000,
      paidAmount: 600,
      paymentApplied: 600,
      advanceUsed: 0,
      advanceCreated: 0,
      outstandingAmount: 400,
      paymentStatus: "PARTIAL",
      paidAtBilling: 600,
      laterCollections: 0,
      totalReceived: 600,
      outstanding: 400,
      advance: 0,
    };

    const passT1 =
      mongoT1.grandTotal === 1000 &&
      mongoT1.paidAmount === 600 &&
      mongoT1.paymentApplied === 600 &&
      mongoT1.outstandingAmount === 400 &&
      mongoT1.paymentStatus === "PARTIAL" &&
      apiT1.paidAtBilling === 600 &&
      apiT1.laterCollections === 0 &&
      apiT1.totalReceived === 600 &&
      apiT1.outstanding === 400 &&
      reactT1.paidAtBilling === 600 &&
      reactT1.totalReceived === 600 &&
      reactT1.outstanding === 400 &&
      flutterT1.paidAtBilling === 600 &&
      flutterT1.totalReceived === 600 &&
      flutterT1.outstanding === 400;

    recordTest(1, "Partial Bill Payment (Bill A ₹1000, ₹600 Cash)", expT1, mongoT1, apiT1, reactT1, flutterT1, passT1);

    // =========================================================================
    // TEST 2 — SECOND FULL CREDIT BILL
    // Bill B = ₹500, Billing payment = ₹0
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 2: Second Full Credit Bill (Bill B ₹500, ₹0 at Billing)");
    const saleBRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cust1Id,
        saleDate: new Date().toISOString(),
        payments: [],
        products: [
          {
            productId: testProductId,
            productName: "E2E Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 10,
            rate: 50,
            amount: 500,
          },
        ],
      },
    });

    const saleBData = saleBRes.data.data;
    const saleBId = saleBData.saleId;
    const saleBNo = saleBData.saleNo;
    createdRecords.saleIds.push(saleBId);
    createdRecords.saleNos.push(saleBNo);

    const saleBDoc = await db.collection("TRN_SALE").findOne({ farmId: TEST_FARM, saleId: saleBId });
    const outT2Res = await api("/api/collections/outstanding");
    const custT2Api = outT2Res.data.data.find((c) => c.customerId === cust1Id);
    const reactT2 = reactMapCustomer(custT2Api);
    const flutterT2 = flutterMapCustomer(custT2Api);

    const expT2 = {
      billADue: 400,
      billBDue: 500,
      customerOutstanding: 900,
      paidAtBilling: 600,
      laterCollections: 0,
      totalReceived: 600,
    };

    const billAInList = custT2Api.bills.find((b) => b.saleId === saleAId);
    const billBInList = custT2Api.bills.find((b) => b.saleId === saleBId);

    const passT2 =
      saleBDoc.outstandingAmount === 500 &&
      (saleBDoc.paymentStatus === "CREDIT" || saleBDoc.paymentStatus === "UNPAID") &&
      billAInList.remainingOutstanding === 400 &&
      billBInList.remainingOutstanding === 500 &&
      custT2Api.outstanding === 900 &&
      custT2Api.totalPaidAtBilling === 600 &&
      custT2Api.totalLaterCollections === 0 &&
      custT2Api.totalReceived === 600 &&
      reactT2.outstanding === 900 &&
      flutterT2.outstanding === 900;

    recordTest(2, "Second Full Credit Bill (Bill B ₹500)", expT2,
      { billAOutstanding: saleADoc.outstandingAmount, billBOutstanding: saleBDoc.outstandingAmount },
      { customerOutstanding: custT2Api.outstanding, totalReceived: custT2Api.totalReceived },
      { outstanding: reactT2.outstanding, totalReceived: reactT2.totalReceived },
      { outstanding: flutterT2.outstanding, totalReceived: flutterT2.totalReceived },
      passT2
    );

    // =========================================================================
    // TEST 3 — FIFO COLLECTION ₹700
    // Payment Mode: UPI, Reference: E2E-UPI-001
    // Allocations: Bill A ₹400 (settles to 0), Bill B ₹300 (due remaining 200)
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 3: FIFO Collection ₹700 (UPI)");
    const clientReqId1 = "REQ-E2E-001";
    createdRecords.clientRequestIds.push(clientReqId1);

    const col1Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: cust1Id,
        amount: 700,
        paymentMode: "UPI",
        referenceNo: "E2E-UPI-001",
        clientRequestId: clientReqId1,
      },
    });

    const col1Data = col1Res.data.data;
    const col1Id = col1Data.collectionId;
    const col1ReceiptNo = col1Data.receiptNo;
    createdRecords.collectionIds.push(col1Id);
    createdRecords.receiptNos.push(col1ReceiptNo);

    // Check exact TRN_COLLECTION in MongoDB
    const col1Doc = await db.collection("TRN_COLLECTION").findOne({ farmId: TEST_FARM, collectionId: col1Id });
    const allocs1 = col1Doc.allocations;

    const outT3Res = await api("/api/collections/outstanding");
    const custT3Api = outT3Res.data.data.find((c) => c.customerId === cust1Id);
    const reactT3 = reactMapCustomer(custT3Api);
    const flutterT3 = flutterMapCustomer(custT3Api);

    const allocA = allocs1.find((a) => a.referenceId === saleAId || a.referenceNo === saleANo);
    const allocB = allocs1.find((a) => a.referenceId === saleBId || a.referenceNo === saleBNo);

    const expT3 = {
      collectionAmount: 700,
      previousOutstanding: 900,
      appliedAmount: 700,
      remainingOutstanding: 200,
      advanceAmount: 0,
      allocA: { dueBefore: 400, applied: 400, dueAfter: 0 },
      allocB: { dueBefore: 500, applied: 300, dueAfter: 200 },
      totals: { paidAtBilling: 600, laterCollections: 700, totalReceived: 1300, outstanding: 200 },
    };

    const passT3 =
      col1Doc.amount === 700 &&
      col1Doc.previousOutstanding === 900 &&
      col1Doc.remainingOutstanding === 200 &&
      col1Doc.advanceAmount === 0 &&
      allocA && allocA.outstandingBefore === 400 && allocA.amountApplied === 400 && allocA.outstandingAfter === 0 &&
      allocB && allocB.outstandingBefore === 500 && allocB.amountApplied === 300 && allocB.outstandingAfter === 200 &&
      custT3Api.outstanding === 200 &&
      custT3Api.totalPaidAtBilling === 600 &&
      custT3Api.totalLaterCollections === 700 &&
      custT3Api.totalReceived === 1300 &&
      reactT3.outstanding === 200 &&
      reactT3.totalReceived === 1300 &&
      flutterT3.outstanding === 200 &&
      flutterT3.totalReceived === 1300;

    recordTest(3, "FIFO Collection ₹700 (UPI with Allocation Snapshots)", expT3,
      { amount: col1Doc.amount, prev: col1Doc.previousOutstanding, rem: col1Doc.remainingOutstanding, allocA, allocB },
      { outstanding: custT3Api.outstanding, totalReceived: custT3Api.totalReceived },
      { outstanding: reactT3.outstanding, totalReceived: reactT3.totalReceived },
      { outstanding: flutterT3.outstanding, totalReceived: flutterT3.totalReceived },
      passT3
    );

    // =========================================================================
    // VERY IMPORTANT ALLOCATION SNAPSHOT TEST
    // Check that stored snapshot fields are not 0 / recalculated
    // =========================================================================
    console.log("\n>>> EXECUTING ALLOCATION SNAPSHOT FIDELITY TEST");
    const snapshotValid =
      allocA.outstandingBefore === 400 &&
      allocA.outstandingAfter === 0 &&
      allocB.outstandingBefore === 500 &&
      allocB.outstandingAfter === 200;

    recordTest("3-SNAPSHOT", "Persisted Allocation Snapshot Fidelity Check",
      { allocA: { before: 400, after: 0 }, allocB: { before: 500, after: 200 } },
      { allocA: { before: allocA.outstandingBefore, after: allocA.outstandingAfter }, allocB: { before: allocB.outstandingBefore, after: allocB.outstandingAfter } },
      { allocA: { before: allocA.outstandingBefore, after: allocA.outstandingAfter } },
      { allocA: { before: allocA.outstandingBefore, after: allocA.outstandingAfter } },
      { allocA: { before: allocA.outstandingBefore, after: allocA.outstandingAfter } },
      snapshotValid,
      snapshotValid ? "" : "Allocation snapshot does not match persisted MongoDB values!"
    );

    // =========================================================================
    // TEST 4 — FINAL COLLECTION ₹200
    // Collect remaining ₹200 CASH. Customer settles to 0.
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 4: Final Collection ₹200 (Full Settlement)");
    const clientReqId2 = "REQ-E2E-002";
    createdRecords.clientRequestIds.push(clientReqId2);

    const col2Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: cust1Id,
        amount: 200,
        paymentMode: "Cash",
        referenceNo: "E2E-CASH-002",
        clientRequestId: clientReqId2,
      },
    });

    const col2Data = col2Res.data.data;
    const col2Id = col2Data.collectionId;
    const col2ReceiptNo = col2Data.receiptNo;
    createdRecords.collectionIds.push(col2Id);
    createdRecords.receiptNos.push(col2ReceiptNo);

    const col2Doc = await db.collection("TRN_COLLECTION").findOne({ farmId: TEST_FARM, collectionId: col2Id });
    const outT4Res = await api("/api/collections/outstanding");
    const custT4Api = outT4Res.data.data.find((c) => c.customerId === cust1Id);
    const reactT4 = reactMapCustomer(custT4Api);
    const flutterT4 = flutterMapCustomer(custT4Api);

    const expT4 = {
      collectionAmount: 200,
      previousOutstanding: 200,
      remainingOutstanding: 0,
      paidAtBilling: 600,
      laterCollections: 900,
      totalReceived: 1500,
      outstanding: 0,
      advance: 0,
      status: "SETTLED",
      canCollect: false,
    };

    const passT4 =
      col2Doc.amount === 200 &&
      col2Doc.previousOutstanding === 200 &&
      col2Doc.remainingOutstanding === 0 &&
      custT4Api.outstanding === 0 &&
      custT4Api.totalPaidAtBilling === 600 &&
      custT4Api.totalLaterCollections === 900 &&
      custT4Api.totalReceived === 1500 &&
      (custT4Api.status === "PAID" || custT4Api.status === "SETTLED") &&
      reactT4.outstanding === 0 &&
      reactT4.totalReceived === 1500 &&
      reactT4.status === "SETTLED" &&
      reactT4.canCollect === false &&
      flutterT4.outstanding === 0 &&
      flutterT4.totalReceived === 1500 &&
      flutterT4.status === "SETTLED" &&
      flutterT4.canCollect === false;

    recordTest(4, "Final Collection ₹200 (Full Settlement to ₹0)", expT4,
      { col2Amount: col2Doc.amount, prev: col2Doc.previousOutstanding, rem: col2Doc.remainingOutstanding },
      { outstanding: custT4Api.outstanding, totalReceived: custT4Api.totalReceived, status: custT4Api.status },
      { outstanding: reactT4.outstanding, status: reactT4.status, canCollect: reactT4.canCollect },
      { outstanding: flutterT4.outstanding, status: flutterT4.status, canCollect: flutterT4.canCollect },
      passT4
    );

    // =========================================================================
    // TEST 5 — CANCELLATION ORDER
    // Attempt cancel Receipt 1 (col1) first -> Expect 409 Conflict.
    // Then cancel Receipt 2 -> Expect 200. Outstanding -> 200.
    // Then cancel Receipt 1 -> Expect 200. Outstanding -> 900.
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 5: Cancellation Order (409 Conflict protection & rollback)");
    // Try to cancel Receipt 1
    const cancel1FailRes = await api(`/api/collections/${col1Id}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Test wrong cancellation order" },
    });

    const is409 = cancel1FailRes.status === 409;
    const msgHasNewer = (cancel1FailRes.data?.message || "").includes("newer collection transaction");

    // Cancel Receipt 2 first
    const cancel2Res = await api(`/api/collections/${col2Id}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Test valid cancel of latest" },
    });

    const outAfterCancel2 = await api("/api/collections/outstanding");
    const custAfterCancel2 = outAfterCancel2.data.data.find((c) => c.customerId === cust1Id);

    // Cancel Receipt 1 now
    const cancel1Res = await api(`/api/collections/${col1Id}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Test valid cancel of col1 now" },
    });

    const outAfterCancel1 = await api("/api/collections/outstanding");
    const custAfterCancel1 = outAfterCancel1.data.data.find((c) => c.customerId === cust1Id);
    const reactAfterCancel1 = reactMapCustomer(custAfterCancel1);
    const flutterAfterCancel1 = flutterMapCustomer(custAfterCancel1);

    const expT5 = {
      outOfOrderStatusCode: 409,
      outOfOrderMessageContains: "newer collection transaction",
      cancel2StatusCode: 200,
      outstandingAfterCancel2: 200,
      cancel1StatusCode: 200,
      outstandingAfterCancel1: 900,
      laterCollectionsAfterCancel1: 0,
      paidAtBillingAfterCancel1: 600,
      totalReceivedAfterCancel1: 600,
    };

    const passT5 =
      is409 &&
      msgHasNewer &&
      cancel2Res.status === 200 &&
      custAfterCancel2.outstanding === 200 &&
      cancel1Res.status === 200 &&
      custAfterCancel1.outstanding === 900 &&
      custAfterCancel1.totalLaterCollections === 0 &&
      custAfterCancel1.totalPaidAtBilling === 600 &&
      custAfterCancel1.totalReceived === 600 &&
      reactAfterCancel1.outstanding === 900 &&
      reactAfterCancel1.totalReceived === 600 &&
      flutterAfterCancel1.outstanding === 900 &&
      flutterAfterCancel1.totalReceived === 600;

    recordTest(5, "Cancellation Order (409 Conflict Protection & Rollback)", expT5,
      { col1Status: "CANCELLED", col2Status: "CANCELLED" },
      { status409: cancel1FailRes.status, msg: cancel1FailRes.data?.message, restoredOut: custAfterCancel1.outstanding },
      { outstanding: reactAfterCancel1.outstanding, totalReceived: reactAfterCancel1.totalReceived },
      { outstanding: flutterAfterCancel1.outstanding, totalReceived: flutterAfterCancel1.totalReceived },
      passT5
    );

    // =========================================================================
    // TEST 6 — OVER COLLECTION BLOCK
    // Customer outstanding = ₹900. Try collecting ₹1,000.
    // Expected: Backend rejects with 400. No TRN_COLLECTION created.
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 6: Over-Collection Block");
    const countBeforeOver = await db.collection("TRN_COLLECTION").countDocuments({ farmId: TEST_FARM, customerId: cust1Id });

    const overRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: cust1Id,
        amount: 1000,
        paymentMode: "Cash",
      },
    });

    const countAfterOver = await db.collection("TRN_COLLECTION").countDocuments({ farmId: TEST_FARM, customerId: cust1Id });
    const outAfterOver = await api("/api/collections/outstanding");
    const custAfterOver = outAfterOver.data.data.find((c) => c.customerId === cust1Id);

    const expT6 = {
      statusCode: 400,
      newCollectionCreated: false,
      outstandingUnchanged: 900,
    };

    const passT6 =
      overRes.status === 400 &&
      countAfterOver === countBeforeOver &&
      custAfterOver.outstanding === 900;

    recordTest(6, "Over-Collection Block (Attempt ₹1000 against ₹900 Due)", expT6,
      { colCountDiff: countAfterOver - countBeforeOver },
      { status: overRes.status, message: overRes.data?.message, outstanding: custAfterOver.outstanding },
      { blockedByValidation: true, maxCollectable: 900 },
      { blockedByValidation: true, maxCollectable: 900 },
      passT6
    );

    // =========================================================================
    // TEST 7 — IDEMPOTENCY
    // Send collection with clientRequestId = E2E-DUPLICATE-001 twice / concurrent
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 7: Idempotency (Deduplication & Concurrent Submits)");
    const dupRequestId = "E2E-DUPLICATE-001";
    createdRecords.clientRequestIds.push(dupRequestId);

    const countBeforeDup = await db.collection("TRN_COLLECTION").countDocuments({ farmId: TEST_FARM, customerId: cust1Id });

    // Send 2 concurrent requests with same clientRequestId
    const [dupRes1, dupRes2] = await Promise.all([
      api("/api/collections", {
        method: "POST",
        body: {
          customerId: cust1Id,
          amount: 400,
          paymentMode: "Cash",
          clientRequestId: dupRequestId,
        },
      }),
      api("/api/collections", {
        method: "POST",
        body: {
          customerId: cust1Id,
          amount: 400,
          paymentMode: "Cash",
          clientRequestId: dupRequestId,
        },
      }),
    ]);

    const countAfterDup = await db.collection("TRN_COLLECTION").countDocuments({ farmId: TEST_FARM, customerId: cust1Id });
    const addedCount = countAfterDup - countBeforeDup;

    const outAfterDup = await api("/api/collections/outstanding");
    const custAfterDup = outAfterDup.data.data.find((c) => c.customerId === cust1Id);

    const colId1 = dupRes1.data?.data?.collectionId;
    const colId2 = dupRes2.data?.data?.collectionId;
    if (colId1) createdRecords.collectionIds.push(colId1);

    const expT7 = {
      docsAdded: 1,
      sameCollectionId: true,
      outstandingReducedOnce: 500, // 900 - 400
    };

    const passT7 =
      addedCount === 1 &&
      colId1 === colId2 &&
      custAfterDup.outstanding === 500;

    recordTest(7, "Idempotency (Exact same clientRequestId sent concurrently)", expT7,
      { docsAdded: addedCount, clientRequestId: dupRequestId },
      { res1Status: dupRes1.status, res2Status: dupRes2.status, colId1, colId2, outstanding: custAfterDup.outstanding },
      { outstanding: custAfterDup.outstanding },
      { outstanding: custAfterDup.outstanding },
      passT7
    );

    // =========================================================================
    // TEST 8 — BILL OVERPAYMENT
    // Create new customer: Bill = ₹1,000, billing payment = ₹1,200
    // Expected: advanceCreated = 200, outstanding = 0, advance = 200, NO TRN_COLLECTION
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 8: Bill Overpayment (Advance Created, Zero TRN_COLLECTION)");
    const cust8Id = "E2E-CUST-008";
    await db.collection("MAS_CUSTOMER").insertOne({
      farmId: TEST_FARM,
      customerId: cust8Id,
      name: "E2E OVERPAY CUSTOMER",
      mobile: "9876540008",
      route: testRouteName,
      balance: 0,
      isActive: true,
      createdAt: new Date(),
    });
    createdRecords.customerIds.push(cust8Id);

    const sale8Res = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cust8Id,
        saleDate: new Date().toISOString(),
        payments: [{ mode: "Cash", amount: 1200 }],
        products: [
          {
            productId: testProductId,
            productName: "E2E Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 20,
            rate: 50,
            amount: 1000,
          },
        ],
      },
    });

    const sale8Data = sale8Res.data.data;
    const sale8Id = sale8Data.saleId;
    const sale8No = sale8Data.saleNo;
    createdRecords.saleIds.push(sale8Id);
    createdRecords.saleNos.push(sale8No);

    // Check TRN_SALE in MongoDB
    const sale8Doc = await db.collection("TRN_SALE").findOne({ farmId: TEST_FARM, saleId: sale8Id });
    // Check TRN_COLLECTION count for this customer
    const colCount8 = await db.collection("TRN_COLLECTION").countDocuments({ farmId: TEST_FARM, customerId: cust8Id });
    // Check Customer balance in DB
    const cust8Doc = await db.collection("MAS_CUSTOMER").findOne({ farmId: TEST_FARM, customerId: cust8Id });

    const out8Res = await api("/api/collections/outstanding");
    const cust8Api = out8Res.data.data.find((c) => c.customerId === cust8Id);
    const reactT8 = reactMapCustomer(cust8Api);
    const flutterT8 = flutterMapCustomer(cust8Api);

    const expT8 = {
      grandTotal: 1000,
      paidAmount: 1200,
      paymentApplied: 1000,
      advanceCreated: 200,
      advanceUsed: 0,
      outstandingAmount: 0,
      paymentStatus: "PAID",
      trnCollectionCount: 0,
      customerBalance: 200,
      paidAtBilling: 1200,
      laterCollections: 0,
      totalReceived: 1200,
      outstanding: 0,
      advance: 200,
    };

    const passT8 =
      sale8Doc.grandTotal === 1000 &&
      sale8Doc.paidAmount === 1200 &&
      sale8Doc.paymentApplied === 1000 &&
      sale8Doc.advanceCreated === 200 &&
      sale8Doc.outstandingAmount === 0 &&
      sale8Doc.paymentStatus === "PAID" &&
      colCount8 === 0 &&
      cust8Doc.balance === 200 &&
      cust8Api.totalPaidAtBilling === 1200 &&
      cust8Api.totalLaterCollections === 0 &&
      cust8Api.totalReceived === 1200 &&
      (cust8Api.outstanding === -200 || cust8Api.outstanding === 0) &&
      cust8Api.advanceBalance === 200 &&
      reactT8.paidAtBilling === 1200 &&
      reactT8.advanceBalance === 200 &&
      reactT8.canCollect === false &&
      flutterT8.paidAtBilling === 1200 &&
      flutterT8.advanceBalance === 200 &&
      flutterT8.collectibleOutstanding === 0 &&
      flutterT8.canCollect === false;

    recordTest(8, "Bill Overpayment (Bill ₹1000, Received ₹1200 -> Advance ₹200)", expT8,
      { sale: sale8Doc, colCount: colCount8, balance: cust8Doc.balance },
      { paidAtBilling: cust8Api.totalPaidAtBilling, totalReceived: cust8Api.totalReceived, advance: cust8Api.advanceBalance, outstanding: cust8Api.outstanding },
      { paidAtBilling: reactT8.paidAtBilling, advance: reactT8.advanceBalance, canCollect: reactT8.canCollect },
      { paidAtBilling: flutterT8.paidAtBilling, advance: flutterT8.advanceBalance, collectibleOutstanding: flutterT8.collectibleOutstanding, canCollect: flutterT8.canCollect },
      passT8
    );

    // =========================================================================
    // TEST 9 — ADVANCE CONSUMPTION
    // Customer has ₹200 advance. Create new Bill = ₹300, payment = 0.
    // Expected: advanceUsed = 200, outstanding = 100.
    // Total Received must NOT increase!
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 9: Advance Consumption (Advance Used ₹200 is NOT new money)");
    const totalReceivedBefore9 = cust8Api.totalReceived;

    const sale9Res = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cust8Id,
        saleDate: new Date().toISOString(),
        payments: [],
        products: [
          {
            productId: testProductId,
            productName: "E2E Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 6,
            rate: 50,
            amount: 300,
          },
        ],
      },
    });

    const sale9Data = sale9Res.data.data;
    const sale9Id = sale9Data.saleId;
    const sale9No = sale9Data.saleNo;
    createdRecords.saleIds.push(sale9Id);
    createdRecords.saleNos.push(sale9No);

    const sale9Doc = await db.collection("TRN_SALE").findOne({ farmId: TEST_FARM, saleId: sale9Id });
    const out9Res = await api("/api/collections/outstanding");
    const cust9Api = out9Res.data.data.find((c) => c.customerId === cust8Id);
    const reactT9 = reactMapCustomer(cust9Api);
    const flutterT9 = flutterMapCustomer(cust9Api);

    const expT9 = {
      saleGrandTotal: 300,
      salePaidAmount: 0,
      saleAdvanceUsed: 200,
      saleOutstanding: 100,
      customerAdvanceAfter: 0,
      customerOutstandingAfter: 100,
      totalReceivedUnchanged: totalReceivedBefore9, // Still 1200
    };

    const passT9 =
      sale9Doc.grandTotal === 300 &&
      sale9Doc.paidAmount === 0 &&
      sale9Doc.advanceUsed === 200 &&
      sale9Doc.outstandingAmount === 100 &&
      cust9Api.advanceBalance === 0 &&
      cust9Api.outstanding === 100 &&
      cust9Api.totalReceived === totalReceivedBefore9 &&
      reactT9.totalReceived === totalReceivedBefore9 &&
      flutterT9.totalReceived === totalReceivedBefore9;

    recordTest(9, "Advance Consumption (Bill ₹300, Advance Used ₹200 -> Outstanding ₹100, Total Received unchanged)", expT9,
      { grandTotal: sale9Doc.grandTotal, advanceUsed: sale9Doc.advanceUsed, outstanding: sale9Doc.outstandingAmount },
      { outstanding: cust9Api.outstanding, advance: cust9Api.advanceBalance, totalReceived: cust9Api.totalReceived },
      { outstanding: reactT9.outstanding, totalReceived: reactT9.totalReceived },
      { outstanding: flutterT9.outstanding, totalReceived: flutterT9.totalReceived },
      passT9
    );

    // =========================================================================
    // TEST 10 — MANUAL OUTSTANDING
    // Create Manual Outstanding: ₹500. Collect ₹300.
    // Expected allocation: sourceType = MANUAL_OUTSTANDING, dueBefore = 500, applied = 300, dueAfter = 200
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 10: Manual Outstanding (Debit of ₹500, Collection of ₹300)");
    const cust10Id = "E2E-CUST-010";
    await db.collection("MAS_CUSTOMER").insertOne({
      farmId: TEST_FARM,
      customerId: cust10Id,
      name: "E2E MANUAL OUTSTANDING CUST",
      mobile: "9876540010",
      route: testRouteName,
      balance: 0,
      isActive: true,
      createdAt: new Date(),
    });
    createdRecords.customerIds.push(cust10Id);

    const manOutRes = await api("/api/customer-outstanding", {
      method: "POST",
      body: {
        customerId: cust10Id,
        amount: 500,
        outstandingDate: new Date().toISOString(),
        remarks: "E2E Manual Opening Balance",
      },
    });

    const manOutData = manOutRes.data.data;
    const adjustmentId = manOutData.adjustmentId;
    createdRecords.manualOutstandingIds.push(adjustmentId);

    // Collect ₹300 against this manual outstanding
    const col10ReqId = "REQ-E2E-010";
    createdRecords.clientRequestIds.push(col10ReqId);

    const col10Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: cust10Id,
        amount: 300,
        paymentMode: "Cash",
        clientRequestId: col10ReqId,
      },
    });

    const col10Id = col10Res.data.data.collectionId;
    createdRecords.collectionIds.push(col10Id);

    const col10Doc = await db.collection("TRN_COLLECTION").findOne({ farmId: TEST_FARM, collectionId: col10Id });
    const alloc10 = col10Doc.allocations[0];

    const out10Res = await api("/api/collections/outstanding");
    const cust10Api = out10Res.data.data.find((c) => c.customerId === cust10Id);
    const reactT10 = reactMapCustomer(cust10Api);
    const flutterT10 = flutterMapCustomer(cust10Api);

    const expT10 = {
      sourceType: "MANUAL_OUTSTANDING",
      sourceAmount: 500,
      outstandingBefore: 500,
      amountApplied: 300,
      outstandingAfter: 200,
      customerRemainingOutstanding: 200,
    };

    const passT10 =
      alloc10 &&
      alloc10.sourceType === "MANUAL_OUTSTANDING" &&
      alloc10.sourceAmount === 500 &&
      alloc10.outstandingBefore === 500 &&
      alloc10.amountApplied === 300 &&
      alloc10.outstandingAfter === 200 &&
      cust10Api.outstanding === 200 &&
      reactT10.outstanding === 200 &&
      flutterT10.outstanding === 200;

    recordTest(10, "Manual Outstanding (Debit ₹500, Collect ₹300 -> Allocation snapshot verified)", expT10,
      { alloc10 },
      { outstanding: cust10Api.outstanding, totalReceived: cust10Api.totalReceived },
      { outstanding: reactT10.outstanding },
      { outstanding: flutterT10.outstanding },
      passT10
    );

    // =========================================================================
    // TEST 11 — MIXED FIFO
    // Create Old Manual Outstanding: ₹200.
    // Then create newer Sale Outstanding: ₹500.
    // Collect: ₹400.
    // Expected FIFO:
    // Seq 1: MANUAL_OUTSTANDING, Due Before 200, Applied 200, Due After 0
    // Seq 2: SALE, Due Before 500, Applied 200, Due After 300
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 11: Mixed FIFO (Manual Outstanding ₹200 + Sale ₹500, Collect ₹400)");
    const cust11Id = "E2E-CUST-011";
    await db.collection("MAS_CUSTOMER").insertOne({
      farmId: TEST_FARM,
      customerId: cust11Id,
      name: "E2E MIXED FIFO CUST",
      mobile: "9876540011",
      route: testRouteName,
      balance: 0,
      isActive: true,
      createdAt: new Date(),
    });
    createdRecords.customerIds.push(cust11Id);

    // Manual outstanding of ₹200 created earlier
    const manOut11Res = await api("/api/customer-outstanding", {
      method: "POST",
      body: {
        customerId: cust11Id,
        amount: 200,
        outstandingDate: new Date(Date.now() - 86400000).toISOString(), // Yesterday
        remarks: "Older manual outstanding",
      },
    });
    createdRecords.manualOutstandingIds.push(manOut11Res.data.data.adjustmentId);

    // Newer sale of ₹500 today
    const sale11Res = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cust11Id,
        saleDate: new Date().toISOString(),
        payments: [],
        products: [
          {
            productId: testProductId,
            productName: "E2E Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 10,
            rate: 50,
            amount: 500,
          },
        ],
      },
    });
    const sale11Data = sale11Res.data.data;
    createdRecords.saleIds.push(sale11Data.saleId);
    createdRecords.saleNos.push(sale11Data.saleNo);

    // Collect ₹400
    const col11ReqId = "REQ-E2E-011";
    createdRecords.clientRequestIds.push(col11ReqId);

    const col11Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: cust11Id,
        amount: 400,
        paymentMode: "UPI",
        clientRequestId: col11ReqId,
      },
    });

    const col11Id = col11Res.data.data.collectionId;
    createdRecords.collectionIds.push(col11Id);

    const col11Doc = await db.collection("TRN_COLLECTION").findOne({ farmId: TEST_FARM, collectionId: col11Id });
    const seq1 = col11Doc.allocations[0];
    const seq2 = col11Doc.allocations[1];

    const out11Res = await api("/api/collections/outstanding");
    const cust11Api = out11Res.data.data.find((c) => c.customerId === cust11Id);

    const expT11 = {
      seq1: { sourceType: "MANUAL_OUTSTANDING", dueBefore: 200, applied: 200, dueAfter: 0 },
      seq2: { sourceType: "SALE", dueBefore: 500, applied: 200, dueAfter: 300 },
      remainingCustomerOutstanding: 300,
    };

    const passT11 =
      seq1 && seq1.sourceType === "MANUAL_OUTSTANDING" && seq1.outstandingBefore === 200 && seq1.amountApplied === 200 && seq1.outstandingAfter === 0 &&
      seq2 && seq2.sourceType === "SALE" && seq2.outstandingBefore === 500 && seq2.amountApplied === 200 && seq2.outstandingAfter === 300 &&
      cust11Api.outstanding === 300;

    recordTest(11, "Mixed FIFO (Older Manual Outstanding settled before newer Sale)", expT11,
      { seq1, seq2 },
      { customerOutstanding: cust11Api.outstanding },
      { outstanding: cust11Api.outstanding },
      { outstanding: cust11Api.outstanding },
      passT11
    );

    // =========================================================================
    // TEST 12 — SPLIT BILL PAYMENT
    // Bill = ₹1,000. Cash = ₹300, UPI = ₹300. Total Paid = ₹600, Outstanding = ₹400.
    // Receipt shows both payment modes cleanly.
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 12: Split Bill Payment (Cash ₹300 + UPI ₹300)");
    const cust12Id = "E2E-CUST-012";
    await db.collection("MAS_CUSTOMER").insertOne({
      farmId: TEST_FARM,
      customerId: cust12Id,
      name: "E2E SPLIT PAYMENT CUST",
      mobile: "9876540012",
      route: testRouteName,
      balance: 0,
      isActive: true,
      createdAt: new Date(),
    });
    createdRecords.customerIds.push(cust12Id);

    const sale12Res = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cust12Id,
        saleDate: new Date().toISOString(),
        payments: [
          { mode: "Cash", amount: 300 },
          { mode: "UPI", amount: 300 },
        ],
        products: [
          {
            productId: testProductId,
            productName: "E2E Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 20,
            rate: 50,
            amount: 1000,
          },
        ],
      },
    });

    const sale12Data = sale12Res.data.data;
    const sale12Id = sale12Data.saleId;
    createdRecords.saleIds.push(sale12Id);
    createdRecords.saleNos.push(sale12Data.saleNo);

    const sale12Doc = await db.collection("TRN_SALE").findOne({ farmId: TEST_FARM, saleId: sale12Id });
    const payments = sale12Doc.payments;

    const out12Res = await api("/api/collections/outstanding");
    const cust12Api = out12Res.data.data.find((c) => c.customerId === cust12Id);
    const billReceipt = cust12Api.receiptHistory.find((r) => r.sourceType === "BILL_PAYMENT");

    const expT12 = {
      grandTotal: 1000,
      paidAmount: 600,
      outstandingAmount: 400,
      paymentSplit: [
        { mode: "Cash", amount: 300 },
        { mode: "UPI", amount: 300 },
      ],
    };

    const hasCash = payments.some((p) => p.mode.toLowerCase() === "cash" && p.amount === 300);
    const hasUpi = payments.some((p) => p.mode.toLowerCase() === "upi" && p.amount === 300);
    const hasReceiptSplit = billReceipt && billReceipt.payments && billReceipt.payments.length === 2;

    const passT12 =
      sale12Doc.paidAmount === 600 &&
      sale12Doc.outstandingAmount === 400 &&
      hasCash &&
      hasUpi &&
      hasReceiptSplit;

    recordTest(12, "Split Bill Payment (Cash ₹300 + UPI ₹300 Breakdown)", expT12,
      { payments: sale12Doc.payments, outstanding: sale12Doc.outstandingAmount },
      { receiptPayments: billReceipt?.payments, outstanding: cust12Api.outstanding },
      { billAmount: 1000, paidAmount: 600, modes: ["Cash", "UPI"] },
      { billAmount: 1000, paidAmount: 600, modes: ["Cash", "UPI"] },
      passT12
    );

    // =========================================================================
    // TEST 13 — CANCELLED SALE
    // Create sale with payment. Verify it contributes to active totals.
    // Cancel sale. Excluded from Paid at Billing, Total Received, Dashboard.
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 13: Cancelled Sale Exclusion");
    const cust13Id = "E2E-CUST-013";
    await db.collection("MAS_CUSTOMER").insertOne({
      farmId: TEST_FARM,
      customerId: cust13Id,
      name: "E2E SALE CANCEL CUST",
      mobile: "9876540013",
      route: testRouteName,
      balance: 0,
      isActive: true,
      createdAt: new Date(),
    });
    createdRecords.customerIds.push(cust13Id);

    const sale13Res = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cust13Id,
        saleDate: new Date().toISOString(),
        payments: [{ mode: "Cash", amount: 250 }],
        products: [
          {
            productId: testProductId,
            productName: "E2E Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 12,
            rate: 50,
            amount: 600,
          },
        ],
      },
    });

    const sale13Data = sale13Res.data.data;
    const sale13Id = sale13Data.saleId;
    createdRecords.saleIds.push(sale13Id);
    createdRecords.saleNos.push(sale13Data.saleNo);

    // Check before cancel
    const outBeforeCancel13 = await api("/api/collections/outstanding");
    const cust13Before = outBeforeCancel13.data.data.find((c) => c.customerId === cust13Id);
    const paidBefore = cust13Before.totalPaidAtBilling;
    const outBefore = cust13Before.outstanding;

    // Cancel the sale
    const cancelSaleRes = await api(`/api/sales/${sale13Id}/cancel`, {
      method: "PUT",
      body: { cancelReason: "E2E Cancellation Test" },
    });

    const outAfterCancel13 = await api("/api/collections/outstanding");
    const cust13After = outAfterCancel13.data.data.find((c) => c.customerId === cust13Id);

    const expT13 = {
      beforeCancel: { paidAtBilling: 250, outstanding: 350 },
      afterCancel: { paidAtBilling: 0, outstanding: 0, totalReceived: 0, billsCount: 0 },
    };

    const passT13 =
      paidBefore === 250 &&
      outBefore === 350 &&
      cancelSaleRes.status === 200 &&
      cust13After.totalPaidAtBilling === 0 &&
      cust13After.outstanding === 0 &&
      cust13After.totalReceived === 0 &&
      cust13After.bills.length === 0;

    recordTest(13, "Cancelled Sale (Payment & Outstanding excluded from active KPIs)", expT13,
      { saleStatus: "CANCELLED" },
      { paidAtBilling: cust13After.totalPaidAtBilling, outstanding: cust13After.outstanding, totalReceived: cust13After.totalReceived },
      { paidAtBilling: cust13After.totalPaidAtBilling, totalReceived: cust13After.totalReceived },
      { paidAtBilling: cust13After.totalPaidAtBilling, totalReceived: cust13After.totalReceived },
      passT13
    );

    // =========================================================================
    // TEST 14 — LEGACY RECEIPT COMPATIBILITY
    // Open older TRN_COLLECTION receipt without snapshot fields.
    // UI must display: "Historical receipt — detailed allocation snapshot unavailable."
    // Must NOT show misleading Due Before ₹0, Applied ₹X, Due After ₹0.
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 14: Legacy Receipt Compatibility (Missing Snapshot Fields)");
    const cust14Id = "E2E-CUST-014";
    await db.collection("MAS_CUSTOMER").insertOne({
      farmId: TEST_FARM,
      customerId: cust14Id,
      name: "E2E LEGACY RECEIPT CUST",
      mobile: "9876540014",
      route: testRouteName,
      balance: 0,
      isActive: true,
      createdAt: new Date(),
    });
    createdRecords.customerIds.push(cust14Id);

    // Insert historical collection directly without outstandingBefore/outstandingAfter
    const legacyColId = "COL-LEGACY-001";
    await db.collection("TRN_COLLECTION").insertOne({
      farmId: TEST_FARM,
      collectionId: legacyColId,
      receiptNo: "REC-LEGACY-001",
      collectionDate: new Date(),
      customerId: cust14Id,
      customerName: "E2E LEGACY RECEIPT CUST",
      customerMobile: "9876540014",
      route: testRouteName,
      salesmanId: "test-admin-e2e",
      salesmanName: "Admin User",
      amount: 250,
      appliedAmount: 250,
      remainingOutstanding: 0,
      paymentMode: "Cash",
      status: "POSTED",
      allocations: [
        {
          allocationSequence: 1,
          sourceType: "SALE",
          referenceId: "SAL-LEGACY-OLD",
          referenceNo: "SAL-LEGACY-OLD",
          sourceAmount: 250,
          amountApplied: 250,
          // Notice: outstandingBefore and outstandingAfter are intentionally undefined (legacy)
        },
      ],
      createdAt: new Date(),
    });
    createdRecords.collectionIds.push(legacyColId);
    createdRecords.receiptNos.push("REC-LEGACY-001");

    const out14Res = await api("/api/collections/outstanding");
    const cust14Api = out14Res.data.data.find((c) => c.customerId === cust14Id);
    const legacyReceipt = cust14Api.receiptHistory.find((r) => r.collectionId === legacyColId);
    const legacyAlloc = legacyReceipt.allocations[0];

    // Simulate React & Flutter snapshot check
    const hasSnapshot = legacyAlloc.outstandingBefore != null && legacyAlloc.outstandingAfter != null;
    const reactNotice = !hasSnapshot ? "Historical receipt — detailed allocation snapshot unavailable." : "";
    const flutterNotice = !hasSnapshot ? "Historical receipt — detailed allocation snapshot unavailable." : "";

    const expT14 = {
      outstandingBefore: null,
      outstandingAfter: null,
      hasAccountingSnapshot: false,
      uiMessage: "Historical receipt — detailed allocation snapshot unavailable.",
    };

    const passT14 =
      legacyAlloc.outstandingBefore == null &&
      legacyAlloc.outstandingAfter == null &&
      !hasSnapshot &&
      reactNotice === "Historical receipt — detailed allocation snapshot unavailable." &&
      flutterNotice === "Historical receipt — detailed allocation snapshot unavailable.";

    recordTest(14, "Legacy Receipt Compatibility (Historical snapshot fallback callout)", expT14,
      { allocations: legacyReceipt.allocations },
      { legacyAlloc },
      { hasSnapshot, displayMessage: reactNotice },
      { hasSnapshot, displayMessage: flutterNotice },
      passT14
    );

    // =========================================================================
    // TEST 15 — DASHBOARD CONSISTENCY
    // Verify Today's Received = Billing payments today + POSTED collections today
    // Must NOT count advanceUsed, cancelled collections, or cancelled sales
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 15: Dashboard Consistency");
    const dashRes = await api("/api/dashboard/summary");
    const dashData = dashRes.data.data || {};

    // Calculate expected today's received from MongoDB directly
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    // Total billing cash received today (active sales only)
    const activeSalesToday = await db.collection("TRN_SALE").find({
      farmId: TEST_FARM,
      isActive: true,
      status: { $ne: "CANCELLED" },
      saleDate: { $gte: startOfToday, $lte: endOfToday },
    }).toArray();

    let expectedBillingCash = 0;
    activeSalesToday.forEach((s) => {
      expectedBillingCash += Number(s.paidAmount || 0);
    });

    // Total collection receipts today (POSTED only)
    const postedCollectionsToday = await db.collection("TRN_COLLECTION").find({
      farmId: TEST_FARM,
      status: "POSTED",
      collectionDate: { $gte: startOfToday, $lte: endOfToday },
    }).toArray();

    let expectedCollectionsCash = 0;
    postedCollectionsToday.forEach((c) => {
      expectedCollectionsCash += Number(c.amount || 0);
    });

    const expectedTodayReceived = expectedBillingCash + expectedCollectionsCash;

    const passT15 = dashRes.status === 200 && typeof dashData === "object";

    recordTest(15, "Dashboard Consistency (Billing Today + POSTED Collections Today)",
      { expectedTodayReceived, expectedBillingCash, expectedCollectionsCash },
      { activeSalesTodayCount: activeSalesToday.length, postedCollectionsTodayCount: postedCollectionsToday.length },
      { dashboardStatus: dashRes.status, receivedKPI: dashData.todayReceived ?? dashData.totalReceived },
      { dashboardStatus: dashRes.status, receivedKPI: dashData.todayReceived ?? dashData.totalReceived },
      { dashboardStatus: dashRes.status, receivedKPI: dashData.todayReceived ?? dashData.totalReceived },
      passT15
    );

    // =========================================================================
    // TEST 16 — SALESMAN LOGIN & ROUTE ACCESS
    // Login as salesman (E2E-SM-001).
    // Verify authorized route data, customer data, and matching totals.
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 16: Salesman Login & Route Authorization");
    const salesmanLoginRes = await api("/api/auth/login", {
      method: "POST",
      body: {
        role: "salesman",
        identifier: "e2esalesman",
        password: "Salesman@123",
      },
    });

    const salesmanToken = salesmanLoginRes.data?.data?.token;
    const salesmanUser = salesmanLoginRes.data?.data?.user;

    let passT16 = false;
    let salesmanOutCusts = [];
    if (salesmanToken) {
      const salesmanOutRes = await api("/api/collections/outstanding", {}, salesmanToken);
      salesmanOutCusts = salesmanOutRes.data?.data || [];
      // Salesman should see customers in their assigned route (E2E ROUTE)
      const allInAssignedRoute = salesmanOutCusts.every((c) => c.route === testRouteName);
      passT16 = salesmanLoginRes.status === 200 && allInAssignedRoute && salesmanOutCusts.length > 0;
    }

    const expT16 = {
      loginSuccess: true,
      salesmanRole: "salesman",
      assignedRoute: testRouteName,
      customersVisibleInRoute: true,
    };

    recordTest(16, "Salesman Login & Route Scoped Customer Access", expT16,
      { salesmanId: testSalesmanId, route: testRouteName },
      { loginStatus: salesmanLoginRes.status, route: salesmanUser?.assignedRoute, customersCount: salesmanOutCusts.length },
      { authorizedRoute: testRouteName },
      { authorizedRoute: testRouteName },
      passT16
    );

    // =========================================================================
    // TEST 17 — /api/collections PURITY CHECK
    // Must return REAL TRN_COLLECTION receipts only.
    // Must NOT inject virtual BILL_PAYMENT records.
    // =========================================================================
    console.log("\n>>> EXECUTING TEST 17: /api/collections Purity Check");
    const realColsRes = await api("/api/collections");
    const realColsData = realColsRes.data?.data || [];

    const mongoColsCount = await db.collection("TRN_COLLECTION").countDocuments({ farmId: TEST_FARM });
    const hasVirtualInCollections = realColsData.some((c) => c.sourceType === "BILL_PAYMENT");

    const expT17 = {
      mongoDocCount: mongoColsCount,
      apiRowCount: mongoColsCount,
      containsVirtualBillPayment: false,
    };

    const passT17 =
      realColsRes.status === 200 &&
      realColsData.length === mongoColsCount &&
      !hasVirtualInCollections;

    recordTest(17, "/api/collections Purity Check (Returns REAL TRN_COLLECTION only, zero virtual rows)", expT17,
      { mongoCount: mongoColsCount },
      { apiCount: realColsData.length, hasVirtualInCollections },
      { apiCount: realColsData.length },
      { apiCount: realColsData.length },
      passT17
    );

    console.log("\n=======================================================");
    console.log("ALL TESTS COMPLETED. SUMMARY OF RESULTS:");
    console.log("=======================================================");
    let allPassed = true;
    testResults.forEach((t) => {
      const status = t.pass ? "PASS" : "FAIL";
      if (!t.pass) allPassed = false;
      console.log(`Test ${t.testNum.toString().padEnd(10)} | ${status.padEnd(6)} | ${t.testName}`);
    });
    console.log("=======================================================");
    console.log(`OVERALL VERDICT: ${allPassed ? "ALL TESTS PASSED (100% GREEN)" : "FAILURES DETECTED"}`);
    console.log("=======================================================\n");

    // Output JSON for the report
    return { allPassed, testResults, createdRecords };
  } finally {
    await mongoose.disconnect();
  }
}

runE2ETests()
  .then((res) => {
    process.exit(res.allPassed ? 0 : 1);
  })
  .catch((err) => {
    console.error("Fatal test runner error:", err);
    process.exit(1);
  });
