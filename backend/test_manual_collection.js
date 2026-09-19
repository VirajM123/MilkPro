const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, ".env") });

const BASE_URL = `http://localhost:${process.env.PORT || 5000}`;
const TEST_FARM = "FARM-TEST-MANUAL-COLLECTION";
const JWT_SECRET = process.env.JWT_SECRET || "MilkPro_2026_Secure_JWT_Key_Change_This";

const adminToken = jwt.sign(
  {
    userId: "test-admin-manual",
    farmId: TEST_FARM,
    role: "admin",
  },
  JWT_SECRET,
  { expiresIn: "1h" }
);

function getSalesmanToken(salesmanId, mongoId) {
  return jwt.sign(
    {
      userId: mongoId ? mongoId.toString() : new mongoose.Types.ObjectId().toString(),
      farmId: TEST_FARM,
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
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  return { status: res.status, data };
}

function assert(condition, message) {
  if (!condition) {
    console.error(`❌ FAILED: ${message}`);
    throw new Error(message);
  }
  console.log(`  ✓ ${message}`);
}

async function runManualCollectionTests() {
  console.log("\n=======================================================");
  console.log("STARTING BILL-WISE USER-SELECTABLE COLLECTION TESTS (A - R)");
  console.log(`Farm: ${TEST_FARM}`);
  console.log(`Base URL: ${BASE_URL}`);
  console.log("=======================================================\n");

  await mongoose.connect(process.env.MONGODB_URI);
  const db = mongoose.connection;

  try {
    // 0. Cleanup
    await db.collection("MAS_CUSTOMER").deleteMany({ farmId: TEST_FARM });
    await db.collection("MAS_PRODUCT").deleteMany({ farmId: TEST_FARM });
    await db.collection("MAS_SALESMAN").deleteMany({ farmId: TEST_FARM });
    await db.collection("MAS_ROUTE").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_ALLOCATION").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_SALE").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_COLLECTION").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_CUSTOMER_OUTSTANDING").deleteMany({ farmId: TEST_FARM });

    // Setup base product
    const prodRes = await api("/api/products", {
      method: "POST",
      body: {
        productName: "Manual Test Milk",
        variant: "1L",
        category: "Dairy",
        unit: "Litre",
        stock: 10000,
        price: 100,
      },
    });
    assert(prodRes.status === 201, "Test product created");
    const productId = prodRes.data.data.productId;

    // Setup base customer
    const custRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "Ramesh Dairy",
        mobile: "9988776655",
        route: "Route Alpha",
        openingOutstanding: 0,
      },
    });
    assert(custRes.status === 201, "Test customer created");
    const customerId = custRes.data.data.customerId;

    // Setup 3 sales: Bill 1 (₹500), Bill 2 (₹400), Bill 3 (₹300)
    console.log("\nCreating 3 bills: Bill 1 (₹500), Bill 2 (₹400), Bill 3 (₹300)...");
    const s1 = await api("/api/sales", {
      method: "POST",
      body: {
        customerId,
        saleDate: "2026-03-01T10:00:00.000Z",
        products: [{ productId, quantity: 5, unitPrice: 100, total: 500 }],
      },
    });
    assert(s1.status === 201, "Bill 1 created (₹500)");
    const saleId1 = s1.data.data.saleId;

    const s2 = await api("/api/sales", {
      method: "POST",
      body: {
        customerId,
        saleDate: "2026-03-02T10:00:00.000Z",
        products: [{ productId, quantity: 4, unitPrice: 100, total: 400 }],
      },
    });
    assert(s2.status === 201, "Bill 2 created (₹400)");
    const saleId2 = s2.data.data.saleId;

    const s3 = await api("/api/sales", {
      method: "POST",
      body: {
        customerId,
        saleDate: "2026-03-03T10:00:00.000Z",
        products: [{ productId, quantity: 3, unitPrice: 100, total: 300 }],
      },
    });
    assert(s3.status === 201, "Bill 3 created (₹300)");
    const saleId3 = s3.data.data.saleId;

    // Verify GET /api/collections/outstanding
    console.log("\n--- Test M: customerName & customerId in outstanding bills ---");
    const outRes1 = await api("/api/collections/outstanding");
    assert(outRes1.status === 200, "Outstanding endpoint returned 200");
    const custOut1 = outRes1.data.data.find((c) => c.customerId === customerId);
    assert(custOut1 && custOut1.bills.length === 3, "All 3 bills found in customer bills");
    assert(custOut1.bills[0].customerName === "Ramesh Dairy", "bill[0] has authoritative customerName");
    assert(custOut1.bills[0].customerId === customerId, "bill[0] has customerId");
    assert(custOut1.bills[0].remainingOutstanding === 500, "Bill 1 remaining is 500");
    assert(custOut1.bills[1].remainingOutstanding === 400, "Bill 2 remaining is 400");
    assert(custOut1.bills[2].remainingOutstanding === 300, "Bill 3 remaining is 300");

    // --- Test A: Single bill manual selection (Unselected bill untouched) ---
    console.log("\n--- Test A: Single Bill Manual Selection (Bill 2 only, ₹400) ---");
    const colARes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 400,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        clientRequestId: "req-test-a-1",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: saleId2, amountApplied: 400 },
        ],
      },
    });
    assert(colARes.status === 201, `Collection A created: ${colARes.data.message}`);
    assert(colARes.data.data.allocationMode === "MANUAL", "allocationMode is MANUAL");
    assert(colARes.data.data.allocations.length === 1, "Exactly 1 allocation created");
    assert(colARes.data.data.allocations[0].referenceId === saleId2, "Allocated to Bill 2");
    assert(colARes.data.data.allocations[0].amountApplied === 400, "Bill 2 received ₹400");
    assert(colARes.data.data.allocations[0].customerName === "Ramesh Dairy", "Allocations stamped with authoritative customerName");

    // Check outstanding: Bill 1 (older) should remain UNTOUCHED at 500, Bill 2 should be 0, Bill 3 untouched at 300
    const outRes2 = await api("/api/collections/outstanding");
    const custOut2 = outRes2.data.data.find((c) => c.customerId === customerId);
    const b1_afterA = custOut2.bills.find((b) => b.saleId === saleId1);
    const b2_afterA = custOut2.bills.find((b) => b.saleId === saleId2);
    const b3_afterA = custOut2.bills.find((b) => b.saleId === saleId3);
    assert(b1_afterA.remainingOutstanding === 500, "Bill 1 untouched at 500 (not allocated by FIFO!)");
    assert(b2_afterA.remainingOutstanding === 0, "Bill 2 fully settled to 0");
    assert(b3_afterA.remainingOutstanding === 300, "Bill 3 untouched at 300");
    assert(custOut2.currentOutstanding === 800, "Total outstanding is now 800 (1200 - 400)");

    // --- Test L: Cancel Collection A restores exact selected allocations ---
    console.log("\n--- Test L: Cancellation of Manual Collection ---");
    const cancelRes = await api(`/api/collections/${colARes.data.data.collectionId}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Testing manual cancel" },
    });
    assert(cancelRes.status === 200, "Collection A cancelled successfully");
    const outResAfterCancel = await api("/api/collections/outstanding");
    const custOutAfterCancel = outResAfterCancel.data.data.find((c) => c.customerId === customerId);
    const b2_restored = custOutAfterCancel.bills.find((b) => b.saleId === saleId2);
    assert(b2_restored.remainingOutstanding === 400, "Bill 2 remaining restored to 400");
    assert(custOutAfterCancel.currentOutstanding === 1200, "Customer outstanding restored to 1200");

    // --- Test B & Test P: Multiple bills manual selection & array ordering preserved ---
    console.log("\n--- Test B & P: User-selected Order (Bill 3 first ₹300, then Bill 1 partial ₹200) ---");
    const colBRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 500,
        paymentMode: "UPI",
        allocationMode: "MANUAL",
        clientRequestId: "req-test-b-1",
        selectedAllocations: [
          // Order: Bill 3 first, then Bill 1!
          { sourceType: "SALE", referenceId: saleId3, amountApplied: 300 },
          { sourceType: "SALE", referenceId: saleId1, amountApplied: 200 },
        ],
      },
    });
    assert(colBRes.status === 201, "Collection B created (₹500)");
    const allocsB = colBRes.data.data.allocations;
    assert(allocsB.length === 2, "2 allocations recorded");
    assert(allocsB[0].referenceId === saleId3 && allocsB[0].allocationSequence === 1, "Bill 3 is Seq 1 (user array order preserved)");
    assert(allocsB[0].amountApplied === 300, "Bill 3 applied ₹300");
    assert(allocsB[0].outstandingAfter === 0, "Bill 3 outstandingAfter is 0");
    assert(allocsB[1].referenceId === saleId1 && allocsB[1].allocationSequence === 2, "Bill 1 is Seq 2");
    assert(allocsB[1].amountApplied === 200, "Bill 1 applied ₹200");
    assert(allocsB[1].outstandingAfter === 300, "Bill 1 outstandingAfter is 300 (500 - 200)");

    // --- Test C: Partial settlement verification ---
    console.log("\n--- Test C: Outstanding state after partial settlement ---");
    const outRes3 = await api("/api/collections/outstanding");
    const custOut3 = outRes3.data.data.find((c) => c.customerId === customerId);
    const b1_afterB = custOut3.bills.find((b) => b.saleId === saleId1);
    const b2_afterB = custOut3.bills.find((b) => b.saleId === saleId2);
    const b3_afterB = custOut3.bills.find((b) => b.saleId === saleId3);
    assert(b1_afterB.remainingOutstanding === 300, "Bill 1 remaining is 300 (500 - 200)");
    assert(b2_afterB.remainingOutstanding === 400, "Bill 2 untouched at 400");
    assert(b3_afterB.remainingOutstanding === 0, "Bill 3 is settled at 0");
    assert(custOut3.currentOutstanding === 700, "Total outstanding is 700");

    // --- Test D: Manual total mismatch (Allocated != Amount) -> HTTP 400 ---
    console.log("\n--- Test D: Manual Total Mismatch Rejection ---");
    const colDRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 300,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        clientRequestId: "req-test-d-1",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: saleId1, amountApplied: 250 }, // 250 != 300
        ],
      },
    });
    assert(colDRes.status === 400, `Mismatch correctly rejected with 400 (got ${colDRes.status})`);
    assert(colDRes.data.message.includes("must equal receipt amount"), `Error message: ${colDRes.data.message}`);

    // --- Test E: Over-allocate source (Applied > Open Due) -> rejection ---
    console.log("\n--- Test E: Over-allocate Source Rejection ---");
    const colERes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 350,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        clientRequestId: "req-test-e-1",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: saleId1, amountApplied: 350 }, // Bill 1 only has 300 due!
        ],
      },
    });
    assert(colERes.status === 400 || colERes.status === 409, `Over-allocation rejected (got ${colERes.status})`);
    assert(colERes.data.message.includes("exceeds remaining due"), `Error message: ${colERes.data.message}`);

    // --- Test F: Wrong customer source injection -> rejection ---
    console.log("\n--- Test F: Cross-customer Source Injection Rejection ---");
    const otherCustRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "Other Farmer",
        mobile: "9112233445",
        route: "Route Beta",
        openingOutstanding: 0,
      },
    });
    const otherCustId = otherCustRes.data.data.customerId;
    const otherSaleRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: otherCustId,
        saleDate: "2026-03-04T10:00:00.000Z",
        products: [{ productId, quantity: 1, unitPrice: 100, total: 100 }],
      },
    });
    const otherSaleId = otherSaleRes.data.data.saleId;

    const colFRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId, // Paying for Ramesh Dairy
        amount: 100,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        clientRequestId: "req-test-f-1",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: otherSaleId, amountApplied: 100 }, // Inject Other Farmer's bill!
        ],
      },
    });
    assert(colFRes.status === 400 || colFRes.status === 409, `Cross-customer bill rejected (got ${colFRes.status})`);
    assert(colFRes.data.message.includes("does not belong to this customer"), `Error message: ${colFRes.data.message}`);

    // --- Test G: Duplicate source selection -> HTTP 400 ---
    console.log("\n--- Test G: Duplicate Source Selection Rejection ---");
    const colGRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 200,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        clientRequestId: "req-test-g-1",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: saleId1, amountApplied: 100 },
          { sourceType: "SALE", referenceId: saleId1, amountApplied: 100 }, // Duplicate!
        ],
      },
    });
    assert(colGRes.status === 400, `Duplicate source rejected with 400 (got ${colGRes.status})`);
    assert(colGRes.data.message.includes("Duplicate source selection"), `Error message: ${colGRes.data.message}`);

    // --- Test H: Settled / Stale source selection -> HTTP 409 ---
    console.log("\n--- Test H: Settled / Stale Source Selection Rejection ---");
    const colHRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 100,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        clientRequestId: "req-test-h-1",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: saleId3, amountApplied: 100 }, // Bill 3 is already 0 due!
        ],
      },
    });
    assert(colHRes.status === 409 || colHRes.status === 400, `Fully settled bill selection rejected (got ${colHRes.status})`);
    assert(colHRes.data.message.includes("exceeds remaining due") || colHRes.data.message.includes("changed"), `Error message: ${colHRes.data.message}`);

    // --- Test I: Manual Outstanding Selection ---
    console.log("\n--- Test I: Manual Outstanding Selection ---");
    const manOutRes = await api("/api/customer-outstanding", {
      method: "POST",
      body: {
        customerId,
        amount: 250,
        notes: "Opening balance prior to software",
        asOfDate: "2026-02-01T00:00:00.000Z",
      },
    });
    assert(manOutRes.status === 201, "Manual outstanding added (₹250)");
    const manualOutstandingId = manOutRes.data.data.adjustmentId || manOutRes.data.data.outstandingId;

    // Check outstanding reflects manual outstanding with customerName
    const outResWithMan = await api("/api/collections/outstanding");
    const custWithMan = outResWithMan.data.data.find((c) => c.customerId === customerId);
    assert(custWithMan.manualOutstanding.length === 1, "Manual outstanding visible in customer");
    assert(custWithMan.manualOutstanding[0].customerName === "Ramesh Dairy", "Manual outstanding stamped with customerName");
    assert(custWithMan.manualOutstanding[0].customerId === customerId, "Manual outstanding has customerId");
    assert(custWithMan.manualOutstanding[0].remainingOutstanding === 250, "Manual outstanding remaining is 250");

    // Settle manual outstanding specifically via MANUAL mode
    const colIRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 250,
        paymentMode: "Bank Transfer",
        allocationMode: "MANUAL",
        clientRequestId: "req-test-i-1",
        selectedAllocations: [
          { sourceType: "MANUAL_OUTSTANDING", referenceId: manualOutstandingId, amountApplied: 250 },
        ],
      },
    });
    assert(colIRes.status === 201, "Collection I created for manual outstanding");
    assert(colIRes.data.data.allocations[0].sourceType === "MANUAL_OUTSTANDING", "Allocation is MANUAL_OUTSTANDING");
    assert(colIRes.data.data.allocations[0].amountApplied === 250, "Manual outstanding settled with ₹250");

    const outResAfterI = await api("/api/collections/outstanding");
    const custAfterI = outResAfterI.data.data.find((c) => c.customerId === customerId);
    const manRecordAfterI = custAfterI.manualOutstanding.find((m) => m.outstandingId === manualOutstandingId);
    assert(manRecordAfterI.remainingOutstanding === 0, "Manual outstanding is now 0");

    // Current remaining on customer: Bill 1 has 300, Bill 2 has 400. Total = 700.

    // --- Test J: FIFO backward compatibility (omitted allocationMode) ---
    console.log("\n--- Test J: FIFO Backward Compatibility (no allocationMode in payload) ---");
    const colJRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 200, // Should allocate to oldest open bill (Bill 1 has 300 due)
        paymentMode: "Cash",
        clientRequestId: "req-test-j-1",
      },
    });
    assert(colJRes.status === 201, "Legacy FIFO collection created");
    assert(colJRes.data.data.allocationMode === "FIFO", "allocationMode defaulted to FIFO");
    assert(colJRes.data.data.allocations[0].referenceId === saleId1, "Allocated to oldest Bill 1");
    assert(colJRes.data.data.allocations[0].amountApplied === 200, "Applied ₹200 to Bill 1");

    // --- Test K: Auto FIFO explicit (allocationMode: "FIFO") ---
    console.log("\n--- Test K: Auto FIFO Explicit (allocationMode: 'FIFO') ---");
    const colKRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 200, // Bill 1 has 100 left, Bill 2 has 400. Auto FIFO should split: ₹100 to Bill 1, ₹100 to Bill 2
        paymentMode: "Cash",
        allocationMode: "FIFO",
        clientRequestId: "req-test-k-1",
      },
    });
    assert(colKRes.status === 201, "Auto FIFO collection created");
    assert(colKRes.data.data.allocationMode === "FIFO", "allocationMode is FIFO");
    assert(colKRes.data.data.allocations.length === 2, "FIFO created 2 allocations across bills");
    assert(colKRes.data.data.allocations[0].referenceId === saleId1 && colKRes.data.data.allocations[0].amountApplied === 100, "Alloc 1 finished Bill 1 with ₹100");
    assert(colKRes.data.data.allocations[1].referenceId === saleId2 && colKRes.data.data.allocations[1].amountApplied === 100, "Alloc 2 took ₹100 from Bill 2");

    // Customer remaining: Bill 1 is 0, Bill 2 has 300, Bill 3 is 0. Total = 300.

    // --- Test N: Strict Concurrency Protection (different clientRequestId, same customer) ---
    console.log("\n--- Test N: Strict Concurrency Protection (two simultaneous requests) ---");
    // Customer has Bill 2 due = ₹300.
    // Request A tries to pay ₹300 on Bill 2.
    // Request B simultaneously tries to pay ₹300 on Bill 2 with different clientRequestId.
    // One MUST succeed (201), the other MUST fail with 409!
    const [raceRes1, raceRes2] = await Promise.all([
      api("/api/collections", {
        method: "POST",
        body: {
          customerId,
          amount: 300,
          paymentMode: "Cash",
          allocationMode: "MANUAL",
          clientRequestId: "race-client-request-A",
          selectedAllocations: [
            { sourceType: "SALE", referenceId: saleId2, amountApplied: 300 },
          ],
        },
      }),
      api("/api/collections", {
        method: "POST",
        body: {
          customerId,
          amount: 300,
          paymentMode: "Cash",
          allocationMode: "MANUAL",
          clientRequestId: "race-client-request-B",
          selectedAllocations: [
            { sourceType: "SALE", referenceId: saleId2, amountApplied: 300 },
          ],
        },
      }),
    ]);

    const statuses = [raceRes1.status, raceRes2.status].sort();
    console.log(`  Race statuses: ${raceRes1.status} and ${raceRes2.status}`);
    assert(statuses[0] === 201 && statuses[1] === 409, "Exactly one request succeeded (201) and one rejected with 409!");
    const conflictRes = raceRes1.status === 409 ? raceRes1 : raceRes2;
    console.log("  Conflict response data:", conflictRes.data);
    assert(
      (conflictRes.data.message && (
        conflictRes.data.message.includes("Outstanding position has changed") ||
        conflictRes.data.message.includes("exceeds remaining due") ||
        conflictRes.data.message.includes("no pending net outstanding") ||
        conflictRes.data.message.includes("WriteConflict") ||
        conflictRes.data.message.includes("try again")
      )),
      `Conflict error returned clear explanation: ${conflictRes.data.message}`
    );

    // Bill 2 is now fully settled! Total customer outstanding is 0.
    const outResAfterRace = await api("/api/collections/outstanding");
    const custAfterRace = outResAfterRace.data.data.find((c) => c.customerId === customerId);
    assert(custAfterRace.currentOutstanding === 0, "Customer outstanding is exactly 0");

    // --- Test O: Admin collection visible in Salesman accounting ---
    console.log("\n--- Test O: Salesman Accounting includes Admin Collections ---");
    const salesmanMongoId = new mongoose.Types.ObjectId();
    await db.collection("MAS_SALESMAN").insertOne({
      _id: salesmanMongoId,
      farmId: TEST_FARM,
      salesmanId: "SM-ALPHA",
      username: `suresh_salesman_${Date.now()}`,
      password: "test_password_123",
      name: "Suresh Salesman",
      mobile: "9811223344",
      routes: ["Route Alpha"],
      permissionMode: "custom",
      permissions: ["collectionCreate", "collectionView", "salesView", "salesCreate"],
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await db.collection("MAS_ROUTE").insertOne({
      farmId: TEST_FARM,
      routeId: "RT-ALPHA",
      routeName: "Route Alpha",
      salesmanId: "SM-ALPHA",
      salesmanName: "Suresh Salesman",
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await db.collection("TRN_ALLOCATION").insertOne({
      farmId: TEST_FARM,
      allocationId: "ALLOC-TEST-1",
      salesmanId: "SM-ALPHA",
      status: "POSTED",
      products: [{ productId, quantity: 100, returnedQuantity: 0 }],
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    console.log("  ✓ Stock allocated to Salesman Suresh");

    // Create a new bill by Salesman on Ramesh Dairy
    const smToken = getSalesmanToken("SM-ALPHA", salesmanMongoId);
    const s4 = await api("/api/sales", {
      method: "POST",
      body: {
        customerId,
        saleDate: "2026-03-05T10:00:00.000Z",
        products: [{ productId, quantity: 5, unitPrice: 100, total: 500 }],
      },
    }, smToken);
    assert(s4.status === 201, `Bill 4 created: ${s4.status} - ${s4.data?.message || ""}`);
    const saleId4 = s4.data.data.saleId;

    // Salesman checks outstanding: should see ₹500
    const smOut1 = await api("/api/collections/outstanding", {}, smToken);
    assert(smOut1.status === 200, "Salesman outstanding returned 200");
    const smCust1 = smOut1.data.data.find((c) => c.customerId === customerId);
    assert(smCust1 && smCust1.currentOutstanding === 500, "Salesman sees ₹500 due");

    // Now ADMIN records a collection of ₹300 against Bill 4!
    const adminCol4 = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 300,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        clientRequestId: "admin-col-for-salesman-bill",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: saleId4, amountApplied: 300 },
        ],
      },
    }, adminToken);
    assert(adminCol4.status === 201, "Admin recorded ₹300 collection against Salesman's bill");

    // Salesman re-checks outstanding: Salesman accounting MUST reflect Admin collection!
    const smOut2 = await api("/api/collections/outstanding", {}, smToken);
    const smCust2 = smOut2.data.data.find((c) => c.customerId === customerId);
    assert(smCust2.currentOutstanding === 200, "Salesman immediately sees remaining ₹200 due (reduced by Admin collection!)");
    const smBill4 = smCust2.bills.find((b) => b.saleId === saleId4);
    assert(smBill4.remainingOutstanding === 200, "Bill 4 remaining is 200 in salesman view");
    assert(smBill4.collectionApplied === 300, "Bill 4 shows 300 collection applied in salesman view");

    // --- Test Q: Read API Propagation ---
    console.log("\n--- Test Q: Allocation Mode across Read Endpoints ---");
    // 1. GET /api/collections
    const allColsRes = await api("/api/collections");
    assert(allColsRes.status === 200, "GET /api/collections returned 200");
    const testCols = allColsRes.data.data.filter((c) => c.customerId === customerId);
    const hasManual = testCols.some((c) => c.allocationMode === "MANUAL");
    const hasFifo = testCols.some((c) => c.allocationMode === "FIFO");
    assert(hasManual && hasFifo, "GET /api/collections contains both MANUAL and FIFO modes");

    // 2. GET /api/collections/outstanding receiptHistory
    const latestOut = await api("/api/collections/outstanding");
    const custWithHist = latestOut.data.data.find((c) => c.customerId === customerId);
    assert(custWithHist.receiptHistory.length > 0, "Customer has receiptHistory");
    assert(custWithHist.receiptHistory[0].allocationMode !== undefined, "receiptHistory has allocationMode");

    // 3. GET /api/history/salesman-details
    const smDetailsRes = await api(`/api/history/salesman-details?salesmanId=SM-ALPHA&startDate=2026-03-01&endDate=2026-03-10`);
    assert(smDetailsRes.status === 200, "GET /api/history/salesman-details returned 200");
    if (smDetailsRes.data.collections && smDetailsRes.data.collections.length > 0) {
      assert(smDetailsRes.data.collections[0].allocationMode !== undefined, "salesman-details returns allocationMode");
    }

    // --- Test R: Authoritative party name used; client party name ignored ---
    console.log("\n--- Test R: Authoritative Party Name Stamped from DB ---");
    const colRRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId,
        amount: 200,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        clientRequestId: "req-test-r-1",
        selectedAllocations: [
          {
            sourceType: "SALE",
            referenceId: saleId4,
            amountApplied: 200,
            customerName: "SPOOFED CLIENT NAME FAKE", // Client attempts to send fake name
          },
        ],
      },
    });
    assert(colRRes.status === 201, "Collection R created");
    assert(colRRes.data.data.allocations[0].customerName === "Ramesh Dairy", "Allocation stored 'Ramesh Dairy', client spoofed name was ignored!");

    console.log("\n=======================================================");
    console.log("ALL TESTS (A - R) PASSED SUCCESSFULLY!");
    console.log("=======================================================\n");

  } finally {
    // Cleanup
    await db.collection("MAS_CUSTOMER").deleteMany({ farmId: TEST_FARM });
    await db.collection("MAS_PRODUCT").deleteMany({ farmId: TEST_FARM });
    await db.collection("MAS_SALESMAN").deleteMany({ farmId: TEST_FARM });
    await db.collection("MAS_ROUTE").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_ALLOCATION").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_SALE").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_COLLECTION").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_CUSTOMER_OUTSTANDING").deleteMany({ farmId: TEST_FARM });
    await mongoose.disconnect();
  }
}

runManualCollectionTests().catch((err) => {
  console.error("Test execution failed:", err);
  process.exit(1);
});
