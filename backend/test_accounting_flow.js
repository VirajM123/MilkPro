const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, ".env") });

const BASE_URL = `http://localhost:${process.env.PORT || 5000}`;
const TEST_FARM = "FARM-TEST-ACCOUNTING";
const JWT_SECRET = process.env.JWT_SECRET || "MilkPro_2026_Secure_JWT_Key_Change_This";

const token = jwt.sign(
  {
    userId: "test-admin-user",
    farmId: TEST_FARM,
    role: "admin",
  },
  JWT_SECRET,
  { expiresIn: "1h" }
);

async function api(endpoint, options = {}) {
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

async function runTests() {
  console.log("\n=======================================================");
  console.log("STARTING ACCOUNTING FLOW INTEGRATION TESTS");
  console.log(`Farm: ${TEST_FARM}`);
  console.log(`Base URL: ${BASE_URL}`);
  console.log("=======================================================\n");

  await mongoose.connect(process.env.MONGODB_URI);
  const db = mongoose.connection;

  try {
    // 0. Clean up previous test run
    await db.collection("MAS_CUSTOMER").deleteMany({ farmId: TEST_FARM });
    await db.collection("MAS_PRODUCT").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_SALE").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_COLLECTION").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_CUSTOMER_OUTSTANDING").deleteMany({ farmId: TEST_FARM });

    // 1. Setup Customer and Product via API
    console.log("Setting up test customer & product...");
    const custCreateRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "Accounting Test Customer",
        mobile: "9876543210",
        route: "Route 1",
        openingOutstanding: 0,
      },
    });
    assert(custCreateRes.status === 201, `Customer created: ${custCreateRes.data.message || custCreateRes.status}`);
    const testCustomerId = custCreateRes.data.data.customerId;

    const prodCreateRes = await api("/api/products", {
      method: "POST",
      body: {
        productName: "Test Cow Milk 1L",
        variant: "1L",
        category: "Dairy",
        unit: "Litre",
        stock: 5000,
        price: 50,
      },
    });
    assert(prodCreateRes.status === 201, `Product created: ${prodCreateRes.data.message || prodCreateRes.status}`);
    const testProductId = prodCreateRes.data.data.productId;

    // 2. Scenario 1: Sale of ₹1000 with ₹400 paid at billing (Partial payment)
    console.log("\n--- Test 1: Sale of ₹1000 with ₹400 paid at billing ---");
    const sale1Res = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: testCustomerId,
        saleDate: new Date().toISOString(),
        payments: [{ mode: "Cash", amount: 400 }],
        products: [
          {
            productId: testProductId,
            productName: "Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 20,
            rate: 50,
            amount: 1000,
          },
        ],
      },
    });

    assert(sale1Res.status === 201, `Sale creation returned status ${sale1Res.status}`);
    const sale1Data = sale1Res.data.data;
    assert(sale1Data.grandTotal === 1000, "grandTotal is 1000");
    assert(sale1Data.paidAmount === 400, "paidAmount is 400");
    assert(sale1Data.paymentApplied === 400, "paymentApplied is 400");
    assert(sale1Data.advanceCreated === 0, "advanceCreated is 0");
    assert(sale1Data.advanceUsed === 0, "advanceUsed is 0");
    assert(sale1Data.outstandingAmount === 600, "outstandingAmount is 600");
    assert(sale1Data.paymentStatus === "PARTIAL", "paymentStatus is PARTIAL");

    // 3. Scenario 2: Verify GET /api/collections/outstanding
    console.log("\n--- Test 2: GET /api/collections/outstanding verification ---");
    const outRes1 = await api("/api/collections/outstanding");
    assert(outRes1.status === 200, `GET outstanding returned ${outRes1.status}`);
    const custRow1 = outRes1.data.data.find((c) => c.customerId === testCustomerId);
    assert(custRow1 !== undefined, "Customer found in outstanding list");
    assert(custRow1.outstanding === 600, `Customer outstanding is 600 (got ${custRow1.outstanding})`);
    assert(custRow1.totalPaidAtBilling === 400, `totalPaidAtBilling is 400 (got ${custRow1.totalPaidAtBilling})`);
    assert(custRow1.totalLaterCollections === 0, `totalLaterCollections is 0 (got ${custRow1.totalLaterCollections})`);
    assert(custRow1.totalCollected === 400, `totalCollected is 400 (got ${custRow1.totalCollected})`);
    assert(custRow1.totalReceived === 400, `totalReceived is 400 (got ${custRow1.totalReceived})`);

    const bill1 = custRow1.bills.find((b) => b.saleId === sale1Data.saleId);
    assert(bill1 !== undefined, "Bill found in customer bills");
    assert(bill1.paidAtBilling === 400, `bill.paidAtBilling is 400 (got ${bill1.paidAtBilling})`);
    assert(bill1.paymentAppliedAtBilling === 400, `bill.paymentAppliedAtBilling is 400 (got ${bill1.paymentAppliedAtBilling})`);
    assert(bill1.advanceUsed === 0, `bill.advanceUsed is 0 (got ${bill1.advanceUsed})`);
    assert(bill1.collectionApplied === 0, `bill.collectionApplied is 0 (got ${bill1.collectionApplied})`);
    assert(bill1.totalAppliedToBill === 400, `bill.totalAppliedToBill is 400 (got ${bill1.totalAppliedToBill})`);
    assert(bill1.remainingOutstanding === 600, `bill.remainingOutstanding is 600 (got ${bill1.remainingOutstanding})`);
    assert(bill1.paymentStatus === "PARTIAL", `bill.paymentStatus is PARTIAL (got ${bill1.paymentStatus})`);

    // 4. Scenario 3: Record Collection 1 (₹350) with Idempotency Key
    console.log("\n--- Test 3: POST /api/collections with clientRequestId ---");
    const col1Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: testCustomerId,
        amount: 350,
        paymentMode: "Cash",
        clientRequestId: "REQ-TEST-001",
        remarks: "First collection payment",
      },
    });

    assert(col1Res.status === 201, `Collection 1 returned status ${col1Res.status}`);
    const col1Data = col1Res.data.data;
    assert(col1Data.amount === 350, "Collection amount is 350");
    assert(col1Data.appliedAmount === 350, "appliedAmount is 350");
    assert(col1Data.advanceAmount === 0, "advanceAmount is 0");
    assert(col1Data.previousOutstanding === 600, `previousOutstanding snapshot is 600 (got ${col1Data.previousOutstanding})`);
    assert(col1Data.remainingOutstanding === 250, `remainingOutstanding snapshot is 250 (got ${col1Data.remainingOutstanding})`);
    assert(col1Data.allocations.length === 1, "One allocation recorded");
    assert(col1Data.allocations[0].allocationSequence === 1, "allocationSequence is 1");
    assert(col1Data.allocations[0].outstandingBefore === 600, "outstandingBefore is 600");
    assert(col1Data.allocations[0].amountApplied === 350, "amountApplied is 350");
    assert(col1Data.allocations[0].outstandingAfter === 250, "outstandingAfter is 250");

    // Verify source Sale document in database is NOT mutated (Transaction-Derived)
    const saleInDb = await db.collection("TRN_SALE").findOne({ farmId: TEST_FARM, saleId: sale1Data.saleId });
    assert(saleInDb.outstandingAmount === 600, `Sale.outstandingAmount in DB is unchanged at 600 (got ${saleInDb.outstandingAmount})`);

    // 5. Scenario 4: Re-check GET /api/collections/outstanding after Collection 1
    console.log("\n--- Test 4: Outstanding & Bill status after Collection 1 ---");
    const outRes2 = await api("/api/collections/outstanding");
    const custRow2 = outRes2.data.data.find((c) => c.customerId === testCustomerId);
    assert(custRow2.outstanding === 250, `Customer outstanding is 250 (got ${custRow2.outstanding})`);
    assert(custRow2.totalPaidAtBilling === 400, "totalPaidAtBilling is 400");
    assert(custRow2.totalLaterCollections === 350, `totalLaterCollections is 350 (got ${custRow2.totalLaterCollections})`);
    assert(custRow2.totalCollected === 750, `totalCollected is 750 (got ${custRow2.totalCollected})`);
    assert(custRow2.totalReceived === 750, `totalReceived is 750 (got ${custRow2.totalReceived})`);

    const bill2 = custRow2.bills.find((b) => b.saleId === sale1Data.saleId);
    assert(bill2.paidAtBilling === 400, "bill.paidAtBilling is 400");
    assert(bill2.paymentAppliedAtBilling === 400, "bill.paymentAppliedAtBilling is 400");
    assert(bill2.advanceUsed === 0, "bill.advanceUsed is 0");
    assert(bill2.collectionApplied === 350, `bill.collectionApplied is 350 (got ${bill2.collectionApplied})`);
    assert(bill2.totalAppliedToBill === 750, `bill.totalAppliedToBill is 750 (got ${bill2.totalAppliedToBill})`);
    assert(bill2.remainingOutstanding === 250, `bill.remainingOutstanding is 250 (got ${bill2.remainingOutstanding})`);

    // 6. Scenario 5: Duplicate Submit Idempotency Check
    console.log("\n--- Test 5: Idempotency with exact same clientRequestId ---");
    const col1DupRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: testCustomerId,
        amount: 350,
        paymentMode: "Cash",
        clientRequestId: "REQ-TEST-001",
      },
    });
    assert(col1DupRes.status === 200, `Duplicate submit returned status 200 (got ${col1DupRes.status})`);
    assert(col1DupRes.data.data.collectionId === col1Data.collectionId, "Returned same collectionId");
    assert(col1DupRes.data.message.includes("idempotent"), "Message indicates idempotent request");

    // 7. Scenario 6: Record Collection 2 (₹150)
    console.log("\n--- Test 6: POST Collection 2 (₹150) ---");
    const col2Res = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: testCustomerId,
        amount: 150,
        paymentMode: "UPI",
        clientRequestId: "REQ-TEST-002",
      },
    });
    assert(col2Res.status === 201, `Collection 2 returned status ${col2Res.status}`);
    const col2Data = col2Res.data.data;
    assert(col2Data.previousOutstanding === 250, `Col 2 previousOutstanding is 250 (got ${col2Data.previousOutstanding})`);
    assert(col2Data.remainingOutstanding === 100, `Col 2 remainingOutstanding is 100 (got ${col2Data.remainingOutstanding})`);

    // 8. Scenario 7: Out-of-order Cancellation Rejection
    console.log("\n--- Test 7: Out-of-order cancellation protection ---");
    const cancel1FailRes = await api(`/api/collections/${col1Data.collectionId}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Attempt cancel older first" },
    });
    assert(cancel1FailRes.status === 409, `Attempt to cancel older collection returned status 409 (got ${cancel1FailRes.status})`);
    assert(
      cancel1FailRes.data.message.includes("newer collection transaction"),
      `Clear error returned: "${cancel1FailRes.data.message}"`
    );

    // 9. Scenario 8: Cancel Collection 2 first, then cancel Collection 1
    console.log("\n--- Test 8: Cancel Collection 2, then cancel Collection 1 ---");
    const cancel2Res = await api(`/api/collections/${col2Data.collectionId}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Mistake in amount" },
    });
    assert(cancel2Res.status === 200, `Cancel Col 2 returned status 200`);

    const cancel1Res = await api(`/api/collections/${col1Data.collectionId}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Customer requested receipt cancellation" },
    });
    assert(cancel1Res.status === 200, `Cancel Col 1 returned status 200`);

    // Verify outstanding after both cancellations returns to 600
    const outRes3 = await api("/api/collections/outstanding");
    const custRow3 = outRes3.data.data.find((c) => c.customerId === testCustomerId);
    assert(custRow3.outstanding === 600, `Customer outstanding restored to 600 (got ${custRow3.outstanding})`);
    assert(custRow3.totalLaterCollections === 0, `totalLaterCollections restored to 0 (got ${custRow3.totalLaterCollections})`);

    // 10. Scenario 9: Overpayment at billing creates Advance
    console.log("\n--- Test 9: Overpayment at billing creates advance ---");
    // First settle Sale 1's 600 outstanding so customer has no prior due
    const settleSale1 = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: testCustomerId,
        amount: 600,
        paymentMode: "Cash",
        clientRequestId: "REQ-SETTLE-SALE-1",
      },
    });
    assert(settleSale1.status === 201, "Sale 1 fully settled with ₹600 collection");

    const sale2Res = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: testCustomerId,
        saleDate: new Date().toISOString(),
        payments: [{ mode: "Cash", amount: 700 }],
        products: [
          {
            productId: testProductId,
            productName: "Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 10,
            rate: 50,
            amount: 500,
          },
        ],
      },
    });
    assert(sale2Res.status === 201, `Sale 2 returned status 201`);
    const sale2Data = sale2Res.data.data;
    assert(sale2Data.grandTotal === 500, "grandTotal is 500");
    assert(sale2Data.paidAmount === 700, "paidAmount is 700");
    assert(sale2Data.paymentApplied === 500, "paymentApplied is 500");
    assert(sale2Data.advanceCreated === 200, "advanceCreated is 200");
    assert(sale2Data.outstandingAmount === 0, "outstandingAmount is 0");
    assert(sale2Data.paymentStatus === "PAID", "paymentStatus is PAID");

    // Verify Customer.balance updated to 200
    const custInDb = await db.collection("MAS_CUSTOMER").findOne({ farmId: TEST_FARM, customerId: testCustomerId });
    assert(custInDb.balance === 200, `Customer.balance in DB is 200 (got ${custInDb.balance})`);

    // 11. Scenario 10: Advance consumption on next bill
    console.log("\n--- Test 10: Advance consumed on next bill ---");
    const sale3Res = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: testCustomerId,
        saleDate: new Date().toISOString(),
        payments: [],
        products: [
          {
            productId: testProductId,
            productName: "Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 6,
            rate: 50,
            amount: 300,
          },
        ],
      },
    });
    assert(sale3Res.status === 201, `Sale 3 returned status 201`);
    const sale3Data = sale3Res.data.data;
    assert(sale3Data.grandTotal === 300, "grandTotal is 300");
    assert(sale3Data.paymentApplied === 0, "paymentApplied is 0");
    assert(sale3Data.advanceUsed === 200, "advanceUsed is 200 (consumed all advance)");
    assert(sale3Data.outstandingAmount === 100, "outstandingAmount is 100");

    // 12. Scenario 11: Attempt to over-collect beyond net outstanding
    console.log("\n--- Test 11: Over-collection rejection check ---");
    // Customer net outstanding: Sale 1 (600) + Sale 3 (100) = 700.
    const overColRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: testCustomerId,
        amount: 800,
        paymentMode: "Cash",
      },
    });
    assert(overColRes.status === 400, `Over-collection returned status 400 (got ${overColRes.status})`);
    assert(overColRes.data.message.includes("cannot exceed net outstanding"), "Clear error message returned");

    // 13. Scenario 12: Customer Ledger formula verification
    console.log("\n--- Test 12: Ledger debit/credit formula check ---");
    const ledgerRes = await api(`/api/ledger?type=customer&partyId=${testCustomerId}`);
    assert(ledgerRes.status === 200, `Ledger returned status 200`);
    const entries = ledgerRes.data.data.transactions || [];

    // Check Sale 1 (grandTotal 1000, paid 400, outstanding 600, advanceUsed 0, advanceCreated 0)
    const ledgerSale1 = entries.find((e) => e.id === sale1Data.saleId);
    assert(ledgerSale1 !== undefined, "Sale 1 in ledger");
    assert(ledgerSale1.debit === 600, `Sale 1 debit is 600 (outstanding + advanceUsed)`);
    assert(ledgerSale1.credit === 0, `Sale 1 credit is 0`);

    // Check Sale 2 (grandTotal 500, paid 700, advanceCreated 200)
    const ledgerSale2 = entries.find((e) => e.id === sale2Data.saleId);
    assert(ledgerSale2 !== undefined, "Sale 2 in ledger");
    assert(ledgerSale2.debit === 0, `Sale 2 debit is 0`);
    assert(ledgerSale2.credit === 200, `Sale 2 credit is 200 (advanceCreated)`);

    // Check Sale 3 (grandTotal 300, advanceUsed 200, outstanding 100)
    const ledgerSale3 = entries.find((e) => e.id === sale3Data.saleId);
    assert(ledgerSale3 !== undefined, "Sale 3 in ledger");
    assert(ledgerSale3.debit === 300, `Sale 3 debit is 300 (outstanding 100 + advanceUsed 200)`);
    assert(ledgerSale3.credit === 0, `Sale 3 credit is 0`);

    // 14. Scenario 13: Concurrent Duplicate-Submit Idempotency (Race condition test)
    console.log("\n--- Test 13: Concurrent Duplicate-Submit Idempotency Test ---");
    const concCustRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "Concurrent Idempotency Customer",
        mobile: "9988776655",
        route: "Route 1",
        openingOutstanding: 500,
      },
    });
    assert(concCustRes.status === 201, "Created customer for concurrent test");
    const concCustomerId = concCustRes.data.data.customerId;

    const duplicateRequestId = `REQ-CONCURRENT-${Date.now()}`;
    const [resA, resB] = await Promise.all([
      api("/api/collections", {
        method: "POST",
        body: {
          customerId: concCustomerId,
          amount: 200,
          paymentMode: "Cash",
          clientRequestId: duplicateRequestId,
          remarks: "Concurrent submission A",
        },
      }),
      api("/api/collections", {
        method: "POST",
        body: {
          customerId: concCustomerId,
          amount: 200,
          paymentMode: "Cash",
          clientRequestId: duplicateRequestId,
          remarks: "Concurrent submission B",
        },
      }),
    ]);

    assert(resA.data.success && resB.data.success, "Both concurrent requests returned success: true");
    const colIdA = resA.data.data.collectionId;
    const colIdB = resB.data.data.collectionId;
    assert(colIdA === colIdB, `Both concurrent requests resolved to same collectionId (${colIdA})`);

    const countInDb = await db.collection("TRN_COLLECTION").countDocuments({
      farmId: TEST_FARM,
      clientRequestId: duplicateRequestId,
    });
    assert(countInDb === 1, `Exactly ONE collection exists in DB for duplicate clientRequestId (got ${countInDb})`);

    // 15. Scenario 14: Manual Outstanding allocation & snapshot verification
    console.log("\n--- Test 14: Manual Outstanding allocation & snapshot verification ---");
    const outResConc = await api("/api/collections/outstanding");
    const concCustRow = outResConc.data.data.find((c) => c.customerId === concCustomerId);
    assert(concCustRow !== undefined, "Found concurrent customer in outstanding list");
    assert(concCustRow.outstanding === 300, `Customer remaining outstanding is 300 (got ${concCustRow.outstanding})`);
    assert(concCustRow.totalLaterCollections === 200, `totalLaterCollections is 200 (got ${concCustRow.totalLaterCollections})`);

    assert(concCustRow.receiptHistory.length === 1, "One collection in receiptHistory");
    const concReceipt = concCustRow.receiptHistory[0];
    assert(concReceipt.sourceType === "COLLECTION", "receipt is COLLECTION");
    assert(concReceipt.amount === 200, "receipt amount is 200");
    assert(concReceipt.previousOutstanding === 500, `receipt previousOutstanding snapshot is 500 (got ${concReceipt.previousOutstanding})`);
    assert(concReceipt.remainingOutstanding === 300, `receipt remainingOutstanding snapshot is 300 (got ${concReceipt.remainingOutstanding})`);
    assert(concReceipt.status === "POSTED", "receipt status is POSTED");
    assert(concReceipt.clientRequestId === duplicateRequestId, "receipt clientRequestId carried correctly");
    assert(Array.isArray(concReceipt.allocations) && concReceipt.allocations.length === 1, "receipt carries allocations");
    assert(concReceipt.allocations[0].sourceType === "MANUAL_OUTSTANDING", "allocation is to MANUAL_OUTSTANDING");
    assert(concReceipt.allocations[0].amountApplied === 200, "allocation applied 200");

    // 16. Scenario 15: Sale + Manual Outstanding FIFO settlement
    console.log("\n--- Test 15: Sale + Manual Outstanding FIFO settlement ---");
    const fifoCustRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "FIFO Test Customer",
        mobile: "9911223344",
        route: "Route 1",
        openingOutstanding: 300,
      },
    });
    assert(fifoCustRes.status === 201, "Created FIFO test customer");
    const fifoCustomerId = fifoCustRes.data.data.customerId;

    const fifoSaleRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: fifoCustomerId,
        saleDate: new Date(Date.now() + 10000).toISOString(),
        payments: [],
        products: [
          {
            productId: testProductId,
            productName: "Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 10,
            rate: 50,
            amount: 500,
          },
        ],
      },
    });
    assert(fifoSaleRes.status === 201, "Created newer sale for FIFO test");
    const fifoSaleData = fifoSaleRes.data.data;

    const fifoColRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: fifoCustomerId,
        amount: 400,
        paymentMode: "UPI",
        clientRequestId: "REQ-FIFO-001",
      },
    });
    assert(fifoColRes.status === 201, "FIFO collection created");
    const fifoColData = fifoColRes.data.data;
    assert(fifoColData.allocations.length === 2, `FIFO collection has 2 allocations (got ${fifoColData.allocations.length})`);

    assert(fifoColData.allocations[0].allocationSequence === 1, "Seq 1");
    assert(fifoColData.allocations[0].sourceType === "MANUAL_OUTSTANDING", "Seq 1 is MANUAL_OUTSTANDING");
    assert(fifoColData.allocations[0].amountApplied === 300, `Seq 1 applied 300 (got ${fifoColData.allocations[0].amountApplied})`);
    assert(fifoColData.allocations[0].outstandingAfter === 0, "Seq 1 outstandingAfter is 0");

    assert(fifoColData.allocations[1].allocationSequence === 2, "Seq 2");
    assert(fifoColData.allocations[1].sourceType === "SALE", "Seq 2 is SALE");
    assert(fifoColData.allocations[1].referenceId === fifoSaleData.saleId, "Seq 2 reference is saleId");
    assert(fifoColData.allocations[1].amountApplied === 100, `Seq 2 applied 100 (got ${fifoColData.allocations[1].amountApplied})`);
    assert(fifoColData.allocations[1].outstandingAfter === 400, "Seq 2 outstandingAfter is 400");

    // 17. Scenario 16: Cancelled Sale exclusion from received-money KPIs
    console.log("\n--- Test 16: Cancelled Sale exclusion from received-money KPIs ---");
    const cancelCustRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "Sale Cancel Customer",
        mobile: "9944332211",
        route: "Route 1",
        openingOutstanding: 0,
      },
    });
    assert(cancelCustRes.status === 201, "Created Sale Cancel test customer");
    const cancelCustomerId = cancelCustRes.data.data.customerId;

    const cancelSaleRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cancelCustomerId,
        saleDate: new Date().toISOString(),
        payments: [{ mode: "Cash", amount: 250 }],
        products: [
          {
            productId: testProductId,
            productName: "Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 12,
            rate: 50,
            amount: 600,
          },
        ],
      },
    });
    assert(cancelSaleRes.status === 201, "Created sale for cancellation");
    const cancelSaleData = cancelSaleRes.data.data;

    const outBeforeCancel = await api("/api/collections/outstanding");
    const cancelCustRowBefore = outBeforeCancel.data.data.find((c) => c.customerId === cancelCustomerId);
    assert(cancelCustRowBefore.totalPaidAtBilling === 250, "totalPaidAtBilling before cancel is 250");
    assert(cancelCustRowBefore.outstanding === 350, "outstanding before cancel is 350");

    const cancelActionRes = await api(`/api/sales/${cancelSaleData.saleId}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Wrong order created" },
    });
    assert(cancelActionRes.status === 200, `Sale cancelled successfully: ${cancelActionRes.status}`);

    const outAfterCancel = await api("/api/collections/outstanding");
    const cancelCustRowAfter = outAfterCancel.data.data.find((c) => c.customerId === cancelCustomerId);
    assert(cancelCustRowAfter.totalPaidAtBilling === 0, `totalPaidAtBilling is 0 after cancel (got ${cancelCustRowAfter.totalPaidAtBilling})`);
    assert(cancelCustRowAfter.outstanding === 0, `outstanding is 0 after cancel (got ${cancelCustRowAfter.outstanding})`);
    assert(cancelCustRowAfter.bills.length === 0, `bills list has 0 bills after cancel (got ${cancelCustRowAfter.bills.length})`);

    // 18. Scenario 17: Legacy Receipt Compatibility (empty allocations fallback)
    console.log("\n--- Test 17: Legacy Receipt Compatibility (empty allocations fallback) ---");
    const legacyCustRes = await api("/api/customers", {
      method: "POST",
      body: {
        name: "Legacy Receipt Customer",
        mobile: "9955667788",
        route: "Route 1",
        openingOutstanding: 0,
      },
    });
    assert(legacyCustRes.status === 201, "Created customer for legacy receipt test");
    const legacyCustomerId = legacyCustRes.data.data.customerId;

    const legacySaleRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: legacyCustomerId,
        saleDate: new Date().toISOString(),
        payments: [],
        products: [
          {
            productId: testProductId,
            productName: "Test Cow Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 10,
            rate: 50,
            amount: 500,
          },
        ],
      },
    });
    assert(legacySaleRes.status === 201, "Created sale for legacy test");
    const legacySaleData = legacySaleRes.data.data;

    const legacyColId = `COL-LEGACY-${Date.now()}`;
    await db.collection("TRN_COLLECTION").insertOne({
      farmId: TEST_FARM,
      collectionId: legacyColId,
      receiptNo: `REC-LEGACY-${Date.now()}`,
      collectionDate: new Date(),
      customerId: legacyCustomerId,
      customerName: "Legacy Receipt Customer",
      customerMobile: "9955667788",
      route: "Route 1",
      salesmanId: "test-admin-user",
      salesmanName: "Admin User",
      amount: 200,
      appliedAmount: 200,
      advanceAmount: 0,
      paymentMode: "Cash",
      status: "POSTED",
      createdBy: "test-admin-user",
      createdRole: "admin",
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const outLegacyRes = await api("/api/collections/outstanding");
    const legacyCustRow = outLegacyRes.data.data.find((c) => c.customerId === legacyCustomerId);
    assert(legacyCustRow !== undefined, "Legacy customer found in outstanding");
    assert(legacyCustRow.outstanding === 300, `Outstanding correctly reduced to 300 by legacy collection (got ${legacyCustRow.outstanding})`);
    assert(legacyCustRow.totalLaterCollections === 200, `totalLaterCollections is 200 (got ${legacyCustRow.totalLaterCollections})`);

    const legacyBill = legacyCustRow.bills.find((b) => b.saleId === legacySaleData.saleId);
    assert(legacyBill.remainingOutstanding === 300, `Bill remainingOutstanding is 300 (got ${legacyBill.remainingOutstanding})`);
    assert(legacyBill.collectionApplied === 200, `Bill collectionApplied is 200 (got ${legacyBill.collectionApplied})`);

    const modernOnLegacyRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: legacyCustomerId,
        amount: 100,
        paymentMode: "Cash",
        clientRequestId: "REQ-MODERN-ON-LEGACY",
      },
    });
    assert(modernOnLegacyRes.status === 201, "Modern collection created on top of legacy collection");
    const modernData = modernOnLegacyRes.data.data;
    assert(modernData.previousOutstanding === 300, `Modern collection saw 300 previousOutstanding (got ${modernData.previousOutstanding})`);
    assert(modernData.remainingOutstanding === 200, `Modern collection left 200 remainingOutstanding (got ${modernData.remainingOutstanding})`);

    console.log("\n=======================================================");
    console.log("ALL 17 BACKEND ACCOUNTING INTEGRATION TESTS PASSED!");
    console.log("=======================================================\n");
  } finally {
    // Clean up test data
    await db.collection("MAS_CUSTOMER").deleteMany({ farmId: TEST_FARM });
    await db.collection("MAS_PRODUCT").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_SALE").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_COLLECTION").deleteMany({ farmId: TEST_FARM });
    await db.collection("TRN_CUSTOMER_OUTSTANDING").deleteMany({ farmId: TEST_FARM });
    await mongoose.disconnect();
    console.log("Cleaned up test data in isolated test farm.");
  }
}

runTests().catch((err) => {
  console.error("Test execution failed:", err);
  process.exit(1);
});
