/**
 * TEST_REPORTS.JS
 * Complete Production Test Suite for MilkPro Reports Section
 */

const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, ".env") });

const BASE_URL = `http://localhost:${process.env.PORT || 5000}`;
const MONGO_URI = process.env.MONGODB_URI || "mongodb://localhost:27017/MilkPro";
const JWT_SECRET = process.env.JWT_SECRET || "MilkPro_2026_Secure_JWT_Key_Change_This";

const FARM_A = "FARM-RPT-A";
const FARM_B = "FARM-RPT-B";

function createToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: "2h" });
}

async function api(token, endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
    ...(options.headers || {}),
  };
  const fetchOptions = {
    ...options,
    headers,
  };
  if (fetchOptions.body && typeof fetchOptions.body === "object") {
    fetchOptions.body = JSON.stringify(fetchOptions.body);
  }
  const res = await fetch(url, fetchOptions);
  let data = null;
  try {
    data = await res.json();
  } catch (e) {
    data = null;
  }
  return { status: res.status, data };
}

function assert(condition, message) {
  if (!condition) {
    console.error(`  ✗ FAILED: ${message}`);
    throw new Error(message);
  }
  console.log(`  ✓ ${message}`);
}

async function runReportTests() {
  console.log("=======================================================");
  console.log("STARTING PRODUCTION AUDIT & VERIFICATION OF REPORTS");
  console.log(`Base URL: ${BASE_URL}`);
  console.log("=======================================================\n");

  await mongoose.connect(MONGO_URI);
  const db = mongoose.connection;

  try {
    // -----------------------------------------------------
    // CLEANUP OLD TEST DATA
    // -----------------------------------------------------
    await db.collection("MAS_CUSTOMER").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("MAS_PRODUCT").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("MAS_SUPPLIER").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("MAS_SALESMAN").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("MAS_ROUTE").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("TRN_SALE").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("TRN_PURCHASE").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("TRN_COLLECTION").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("TRN_ALLOCATION").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("TRN_RETURN").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("TRN_EXPENSE").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("TRN_STOCK").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });
    await db.collection("TRN_CUSTOMER_OUTSTANDING").deleteMany({ farmId: { $in: [FARM_A, FARM_B] } });

    // -----------------------------------------------------
    // SETUP TEST FIXTURES IN FARM A
    // -----------------------------------------------------
    console.log("--- Setting up Master Data for Reports ---");

    const salesmanMongoId = new mongoose.Types.ObjectId();
    await db.collection("MAS_SALESMAN").insertOne({
      _id: salesmanMongoId,
      farmId: FARM_A,
      salesmanId: "SLS_A1",
      username: `salesman_a1_${Date.now()}`,
      password: "password123",
      name: "Raju Salesman",
      mobile: "9988776655",
      routes: ["North Route"],
      permissionMode: "custom",
      permissions: ["reportsView", "salesView", "salesCreate", "collectionView", "collectionCreate"],
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    await db.collection("MAS_ROUTE").insertOne({
      farmId: FARM_A,
      routeId: "RT-NORTH",
      routeName: "North Route",
      salesmanId: "SLS_A1",
      salesmanName: "Raju Salesman",
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const adminTokenA = createToken({
      userId: "ADMIN_A",
      username: "admin_a",
      role: "admin",
      farmId: FARM_A,
      permissions: ["reportsView", "salesView", "salesCreate", "collectionView", "collectionCreate", "purchaseView", "stockView"],
    });

    const adminTokenB = createToken({
      userId: "ADMIN_B",
      username: "admin_b",
      role: "admin",
      farmId: FARM_B,
      permissions: ["reportsView", "salesView", "salesCreate", "collectionView", "collectionCreate", "purchaseView", "stockView"],
    });

    const salesmanTokenA = createToken({
      userId: salesmanMongoId.toString(),
      username: "salesman_a1",
      role: "salesman",
      farmId: FARM_A,
      permissions: ["reportsView", "salesView", "salesCreate", "collectionView", "collectionCreate"],
    });

    // Product 1: Price ₹100, Stock 100
    // Product 1: Price ₹100, Stock 300
    const p1Res = await api(adminTokenA, "/api/products", {
      method: "POST",
      body: {
        productName: "Cow Milk 1L",
        category: "Milk",
        unit: "Liter",
        variant: "1L",
        price: 100,
        stock: 100,
        stock: 300,
        lowStockLevel: 20,
      },
    });
    assert(p1Res.status === 201, `Product 1 ready: ${p1Res.data?.data?.productId || p1Res.status}`);
    const prodId1 = p1Res.data.data.productId;

    // Product 2: Price ₹50, Stock 15 (low stock)
    // Product 2: Price ₹50, Stock 50 (low stock)
    const p2Res = await api(adminTokenA, "/api/products", {
      method: "POST",
      body: {
        productName: "Fresh Curd 500g",
        category: "Curd",
        unit: "Pouch",
        variant: "500g",
        price: 50,
        stock: 15,
        lowStockLevel: 20,
        stock: 50,
        lowStockLevel: 50,
      },
    });
    assert(p2Res.status === 201, `Product 2 ready: ${p2Res.data?.data?.productId || p2Res.status}`);
    const prodId2 = p2Res.data.data.productId;

    // Supplier
    const supRes = await api(adminTokenA, "/api/suppliers", {
      method: "POST",
      body: {
        supplierName: "Green Valley Farm",
        mobile: "9876543210",
      },
    });
    assert(supRes.status === 201, `Supplier ready: ${supRes.data?.data?.supplierId || supRes.status}`);
    const supplierId = supRes.data.data.supplierId;

    // Customer
    const custRes = await api(adminTokenA, "/api/customers", {
      method: "POST",
      body: {
        name: "Anand Sweets",
        mobile: "9123456780",
        route: "North Route",
      },
    });
    assert(custRes.status === 201, `Customer 1 ready: ${custRes.data?.data?.customerId || custRes.status}`);
    const customerId = custRes.data.data.customerId;

    // -----------------------------------------------------
    // SECURITY & RBAC TESTS
    // -----------------------------------------------------
    console.log("\n--- TEST 1: Role-Based Access Control (RBAC) & Security ---");

    // 1.1 Salesman requesting Purchase report -> 403
    const slsPurchRes = await api(salesmanTokenA, "/api/reports/purchase?type=purchase-register");
    assert(slsPurchRes.status === 403, "Salesman blocked from Purchase Reports (HTTP 403)");

    // 1.2 Salesman requesting Purchase Trend -> 403
    const slsPurchTrendRes = await api(salesmanTokenA, "/api/reports/trends?type=purchase-trend");
    assert(slsPurchTrendRes.status === 403, "Salesman blocked from Purchase Trends (HTTP 403)");

    // 1.3 Salesman requesting Sales vs Purchase Trend -> 403
    const slsSalesVsPurchRes = await api(salesmanTokenA, "/api/reports/trends?type=sales-vs-purchase");
    assert(slsSalesVsPurchRes.status === 403, "Salesman blocked from Sales-vs-Purchase (HTTP 403)");

    // 1.4 Salesman requesting Expense Report -> 403
    const slsExpenseRes = await api(salesmanTokenA, "/api/reports/operations?type=expense-report");
    assert(slsExpenseRes.status === 403, "Salesman blocked from Company Expense Report (HTTP 403)");

    // 1.5 Farm B Admin cannot see Farm A data
    const farmBReport = await api(adminTokenB, "/api/reports/sales?type=customer-wise-sales");
    assert(farmBReport.status === 200, "Farm B report loaded");
    assert((farmBReport.data?.report?.rows || []).length === 0, "Farm B cannot see Farm A customer sales");

    // -----------------------------------------------------
    // TRANSACTIONS & RECONCILIATION TEST SCENARIO (Rule 26)
    // -----------------------------------------------------
    console.log("\n--- TEST 2: Authoritative Reconciliation Scenario (Rule 26) ---");

    // Bill A: Sales ₹1000 (10 x ₹100), Paid at Billing ₹600 (Cash ₹300, UPI ₹300), Due ₹400
    const saleARes = await api(adminTokenA, "/api/sales", {
      method: "POST",
      body: {
        customerId,
        saleDate: "2026-09-19",
        paymentMode: "Split",
        payments: [
          { mode: "Cash", amount: 300 },
          { mode: "UPI", amount: 300 },
        ],
        products: [
          {
            productId: prodId1,
            quantity: 10,
          },
        ],
      },
    });
    assert(saleARes.status === 201, `Bill A posted (₹1000, Paid ₹600, Due ₹400): ${saleARes.data?.data?.saleId || saleARes.status}`);
    const saleIdA = saleARes.data.data.saleId;

    // Bill B: Sales ₹500 (10 x ₹50), Paid ₹0, Due ₹500
    const saleBRes = await api(adminTokenA, "/api/sales", {
      method: "POST",
      body: {
        customerId,
        saleDate: "2026-09-19",
        paymentMode: "Credit",
        products: [
          {
            productId: prodId2,
            quantity: 10,
          },
        ],
      },
    });
    assert(saleBRes.status === 201, `Bill B posted (₹500, Paid ₹0, Due ₹500): ${saleBRes.data?.data?.saleId || saleBRes.status}`);
    const saleIdB = saleBRes.data.data.saleId;

    // Later Collection: ₹700 (Bill B ₹500, Bill A ₹200)
    const collRes = await api(adminTokenA, "/api/collections", {
      method: "POST",
      body: {
        customerId,
        collectionDate: "2026-09-19",
        amount: 700,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: saleIdB, amountApplied: 500 },
          { sourceType: "SALE", referenceId: saleIdA, amountApplied: 200 },
        ],
      },
    });
    assert(collRes.status === 201, `Later Collection posted (₹700): ${collRes.data?.data?.collectionId || collRes.data?.message || collRes.status}`);

    // -----------------------------------------------------
    // VERIFY RECONCILIATION ACROSS ALL REPORTS
    // -----------------------------------------------------
    console.log("\n--- TEST 3: Verifying Reconciled Balances Across Reports ---");

    // 3.1 Sales Report: Total Sales ₹1500
    const salesRpt = await api(adminTokenA, `/api/reports/sales?type=customer-wise-sales&customerId=${customerId}`);
    assert(salesRpt.status === 200, "Customer sales report 200");
    const custRow = salesRpt.data.report.rows.find(r => r[0] === customerId);
    assert(custRow, "Customer row present in sales report");
    const netSalesVal = typeof custRow[5] === "number" ? custRow[5] : parseFloat(custRow[5].replace(/[₹,]/g, ''));
    assert(netSalesVal === 1500, `Net Sales is 1500 (got ${custRow[5]})`);

    // 3.2 Collection Report: Later Collections ₹700
    const collRpt = await api(adminTokenA, `/api/reports/operations?type=collection-report&customerId=${customerId}`);
    assert(collRpt.status === 200, "Collection report 200");
    const collMetric = collRpt.data.report.metrics.find(m => m.label === "Total Collection" || m.label === "Total Collections");
    assert(collMetric && (collMetric.value === "₹700.00" || collMetric.value === "700"), `Total Later Collections is ₹700.00 (got ${collMetric?.value})`);

    // 3.3 Unified Received Report: Paid At Billing (₹600) + Later Collections (₹700) = ₹1300
    const recRpt = await api(adminTokenA, `/api/reports/operations?type=received-report&customerId=${customerId}`);
    assert(recRpt.status === 200, "Received report 200");
    const totalRecMetric = recRpt.data.report.metrics.find(m => m.label === "Total Money Received");
    const billRecMetric = recRpt.data.report.metrics.find(m => m.label === "Received at Billing");
    const collRecMetric = recRpt.data.report.metrics.find(m => m.label === "Received via Collections");
    assert(totalRecMetric && totalRecMetric.value === "₹1300.00", `Total Received is ₹1300.00 (got ${totalRecMetric?.value})`);
    assert(billRecMetric && billRecMetric.value === "₹600.00", `Received at billing is ₹600.00 (got ${billRecMetric?.value})`);
    assert(collRecMetric && collRecMetric.value === "₹700.00", `Received via collections is ₹700.00 (got ${collRecMetric?.value})`);

    // Verify Split Mode Breakdown in Received Report
    const cashEntries = recRpt.data.report.rows.filter(r => r[5] === "Cash");
    const upiEntries = recRpt.data.report.rows.filter(r => r[5] === "UPI");
    assert(cashEntries.length >= 2, "Cash split and cash collection recorded");
    assert(upiEntries.length >= 1, "UPI split recorded");

    // 3.4 Outstanding Report: Current Gross Outstanding = ₹200
    const outRpt = await api(adminTokenA, `/api/reports/outstanding?type=customer-wise-outstanding&customerId=${customerId}`);
    assert(outRpt.status === 200, "Customer outstanding report 200");
    const outRow = outRpt.data.report.rows.find(r => r[0] === customerId);
    assert(outRow, "Customer found in outstanding report");
    const outVal = typeof outRow[6] === "number" ? outRow[6] : parseFloat(outRow[6].replace(/[₹,]/g, ''));
    assert(outVal === 200, `Net Outstanding is ₹200.00 (got ${outRow[6]})`);

    // 3.5 Ageing Report: Ageing Total = ₹200
    const ageRpt = await api(adminTokenA, `/api/reports/outstanding?type=outstanding-ageing&customerId=${customerId}`);
    assert(ageRpt.status === 200, "Ageing report 200");
    const ageRow = ageRpt.data.report.rows.find(r => r[0] === customerId);
    assert(ageRow, "Customer found in ageing report");
    const ageVal = typeof ageRow[8] === "number" ? ageRow[8] : parseFloat(ageRow[8].replace(/[₹,]/g, ''));
    assert(ageVal === 200, `Ageing Total is ₹200.00 (got ${ageRow[8]})`);

    // -----------------------------------------------------
    // STOCK REPORTS & VALUATION (Rule 1)
    // -----------------------------------------------------
    console.log("\n--- TEST 4: Stock Reports & Valuation ---");

    const stockRpt = await api(adminTokenA, "/api/reports/stock?type=current-stock");
    assert(stockRpt.status === 200, "Current stock report 200");
    assert(stockRpt.data.report.columns.includes("Value at Current Product Rate"), "Valuation column explicitly named 'Value at Current Product Rate'");
    assert(!stockRpt.data.report.columns.includes("Purchase Cost Value"), "Does not invent 'Purchase Cost Value'");

    const lowStockRpt = await api(adminTokenA, "/api/reports/stock?type=low-stock");
    assert(lowStockRpt.status === 200, "Low stock report 200");
    const curdRow = lowStockRpt.data.report.rows.find(r => r[0] === prodId2);
    assert(curdRow, "Low stock item listed");

    // -----------------------------------------------------
    // TRENDS & MARGINS SEMANTICS (Rule 2)
    // -----------------------------------------------------
    console.log("\n--- TEST 5: Trends Reports & Difference Semantics (Rule 2) ---");

    const trendRpt = await api(adminTokenA, "/api/reports/trends?type=sales-vs-purchase");
    assert(trendRpt.status === 200, "Sales vs purchase trend 200");
    assert(trendRpt.data.report.columns.includes("Difference"), "Comparative column is strictly 'Difference'");
    assert(!trendRpt.data.report.columns.includes("Profit"), "Does not label difference as 'Profit'");
    assert(!trendRpt.data.report.columns.includes("Gross Margin"), "Does not label difference as 'Gross Margin'");

    // -----------------------------------------------------
    // ALLOCATION REALIZATION (FIFO Realization - Rule 14)
    // -----------------------------------------------------
    console.log("\n--- TEST 6: Allocation FIFO Realization (Rule 14) ---");

    // Create allocation of 50 units
    const allocRes = await api(adminTokenA, "/api/allocations", {
      method: "POST",
      body: {
        salesmanId: "SLS_A1",
        routeId: "RT-NORTH",
        allocationDate: "2026-09-19",
        products: [
          {
            productId: prodId1,
            quantity: 50,
          },
        ],
      },
    });
    assert(allocRes.status === 201, `Allocation posted (Allocated 50, Returned 5): ${allocRes.data?.data?.allocationId || allocRes.status}`);
    const allocId = allocRes.data.data.allocationId;

    const allocRpt = await api(adminTokenA, "/api/reports/operations?type=allocation-report&salesmanId=SLS_A1");
    assert(allocRpt.status === 200, "Allocation report 200");
    const allocProd = allocRpt.data.report.rows.find(r => r[5] === prodId1);
    assert(allocProd, "Allocation record found in report");
    // Column 9 = Allocated (50), Column 10 = Returned (0), Column 11 = Net Qty
    assert(allocProd[9] === 50, `Allocated is 50 (got ${allocProd[9]})`);
    assert(allocProd[10] === 0, `Returned is 0 (got ${allocProd[10]})`);
    assert(allocProd[11] === allocProd[9] - allocProd[10], `Net quantity follows Allocated - Returned: ${allocProd[11]}`);

    // =====================================================
    // 7. SALESMAN REPORTS VERIFICATION (SR1 to SR15)
    // =====================================================
    console.log("\n=======================================================");
    console.log("STARTING SALESMAN REPORTS VERIFICATION SUITE (SR1-SR15)");
    console.log("=======================================================\n");

    // Setup Salesman 2 (SLS_A2) for cross-salesman testing
    const salesman2MongoId = new mongoose.Types.ObjectId();
    await db.collection("MAS_SALESMAN").insertOne({
      _id: salesman2MongoId,
      farmId: FARM_A,
      salesmanId: "SLS_A2",
      username: `salesman_a2_${Date.now()}`,
      password: "password123",
      name: "Suresh Salesman",
      mobile: "9988776644",
      routes: ["South Route"],
      permissionMode: "custom",
      permissions: ["reportsView", "salesView", "salesCreate", "collectionView", "collectionCreate"],
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    await db.collection("MAS_ROUTE").insertOne({
      farmId: FARM_A,
      routeId: "RT-SOUTH",
      routeName: "South Route",
      salesmanId: "SLS_A2",
      salesmanName: "Suresh Salesman",
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const salesmanTokenA2 = createToken({
      userId: salesman2MongoId.toString(),
      username: "salesman_a2",
      role: "salesman",
      farmId: FARM_A,
      permissions: ["reportsView", "salesView", "salesCreate", "collectionView", "collectionCreate"],
    });

    // Allocate stock for SLS_A1 (Cow Milk 30, Curd 20)
    await api(adminTokenA, "/api/allocations", {
      method: "POST",
      body: {
        salesmanId: "SLS_A1",
        routeId: "RT-NORTH",
        allocationDate: "2026-09-19",
        products: [
          { productId: prodId1, quantity: 30 },
          { productId: prodId2, quantity: 10 },
        ],
      },
    });

    // Allocate stock for SLS_A2 (Cow Milk 50)
    await api(adminTokenA, "/api/allocations", {
      method: "POST",
      body: {
        salesmanId: "SLS_A2",
        routeId: "RT-SOUTH",
        allocationDate: "2026-09-19",
        products: [
          { productId: prodId1, quantity: 50 },
        ],
      },
    });

    // Customer 2 on South Route
    const cust2Res = await api(adminTokenA, "/api/customers", {
      method: "POST",
      body: {
        name: "South Dairy Store",
        mobile: "9123456722",
        route: "South Route",
        priceType: "Retail",
        openingBalance: 0,
      },
    });
    assert(cust2Res.status === 201, "Customer 2 created on South Route");
    const customer2Id = cust2Res.data.data.customerId;

    // Post multi-item Sale 1 for SLS_A1 (Customer 1): Cow Milk 10 Qty @ 100 = 1000, Curd 5 Qty @ 50 = 250. Total = 1250. Paid at Billing = 450, Outstanding = 800.
    const srSale1Res = await api(salesmanTokenA, "/api/sales", {
      method: "POST",
      body: {
        customerId: customerId,
        saleDate: "2026-09-19",
        paymentMode: "Cash",
        products: [
          { productId: prodId1, quantity: 10, rate: 100, amount: 1000 },
          { productId: prodId2, quantity: 5, rate: 50, amount: 250 },
        ],
        grandTotal: 1250,
        paidAmount: 450,
        payments: [{ mode: "Cash", amount: 450 }],
      },
    });
    if (srSale1Res.status !== 201) {
      console.log("srSale1Res failed details:", JSON.stringify(srSale1Res, null, 2));
    }
    assert(srSale1Res.status === 201, `SR Sale 1 posted (1250, paid 450): ${srSale1Res.data?.data?.saleId}`);
    const srSale1Id = srSale1Res.data.data.saleId;

    // Post Sale 2 for SLS_A2 (Customer 2): Cow Milk 20 Qty @ 100 = 2000. Paid at Billing = 2000 (Full paid).
    const srSale2Res = await api(salesmanTokenA2, "/api/sales", {
      method: "POST",
      body: {
        customerId: customer2Id,
        saleDate: "2026-09-19",
        paymentMode: "UPI",
        products: [
          { productId: prodId1, quantity: 20, rate: 100, amount: 2000 },
        ],
        grandTotal: 2000,
        paidAmount: 2000,
        payments: [{ mode: "UPI", amount: 2000 }],
      },
    });
    assert(srSale2Res.status === 201, `SR Sale 2 posted for SLS_A2 (2000, paid 2000): ${srSale2Res.data?.data?.saleId}`);
    const srSale2Id = srSale2Res.data.data.saleId;

    // --- SR1: salesman-route-customer-product-sales grouping validation ---
    console.log("\n--- TEST SR1: Grouping validation on product sales report ---");
    const sr1Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-product-sales&salesmanId=SLS_A1`);
    if (sr1Res.status !== 200) {
      console.log("sr1Res error:", JSON.stringify(sr1Res, null, 2));
    }
    assert(sr1Res.status === 200, "SR1: Product sales report HTTP 200");
    assert(sr1Res.data.report.columns.includes("Salesman") && sr1Res.data.report.columns.includes("Product"), "SR1: Expected columns present");
    const milkRow = sr1Res.data.report.rows.find(r => r[3] === "Cow Milk 1L");
    assert(milkRow && milkRow[5] >= 10, `SR1: Cow Milk row found with qty >= 10 (got ${milkRow?.[5]})`);

    // --- SR2: Cross-customer and cross-route separation in product sales report ---
    console.log("\n--- TEST SR2: Cross-customer and cross-route separation ---");
    const sr2Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-product-sales`);
    assert(sr2Res.status === 200, "SR2: Farm-wide product sales report HTTP 200");
    const slsA1Rows = sr2Res.data.report.rows.filter(r => r[0] === "Raju Salesman");
    const slsA2Rows = sr2Res.data.report.rows.filter(r => r[0] === "Suresh Salesman");
    assert(slsA1Rows.length >= 1, "SR2: Raju Salesman entries isolated");
    assert(slsA2Rows.length >= 1, "SR2: Suresh Salesman entries isolated");
    assert(slsA2Rows.some(r => r[1] === "South Route"), "SR2: South route correctly isolated");

    // --- SR3: Multi-product bill separation ---
    console.log("\n--- TEST SR3: Multi-product bill creates separate product lines ---");
    const srCurdRow = sr1Res.data.report.rows.find(r => r[3] === "Fresh Curd 500g");
    assert(srCurdRow, "SR3: Curd product line from multi-item bill separated");
    assert(srCurdRow[5] === 5, `SR3: Curd quantity is 5 (got ${srCurdRow?.[5]})`);
    assert(srCurdRow[7] === "₹250.00", `SR3: Curd amount is ₹250.00 (got ${srCurdRow?.[7]})`);

    // --- SR4: salesman-route-customer-sales-vs-received direct realization ---
    console.log("\n--- TEST SR4: Direct realization (Paid at Billing) calculation ---");
    const sr4Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-sales-vs-received&salesmanId=SLS_A2`);
    assert(sr4Res.status === 200, "SR4: Sales vs received report HTTP 200");
    const cust2SalesRow = sr4Res.data.report.rows.find(r => r[2].includes(customer2Id));
    assert(cust2SalesRow, "SR4: Customer 2 row present in Sales vs Received");
    assert(cust2SalesRow[4] === "₹2000.00", `SR4: Total Sales is ₹2000.00 (got ${cust2SalesRow?.[4]})`);
    assert(cust2SalesRow[5] === "₹2000.00", `SR4: Paid at Billing is ₹2000.00 (got ${cust2SalesRow?.[5]})`);
    assert(cust2SalesRow[9] === "₹0.00", `SR4: Outstanding is ₹0.00 (got ${cust2SalesRow?.[9]})`);
    assert(cust2SalesRow[11] === "100.0%", `SR4: Settlement % is 100.0% (got ${cust2SalesRow?.[11]})`);

    // --- SR5: Later collections allocated to a salesman's bill ---
    console.log("\n--- TEST SR5: Later collection allocated against salesman bill ---");
    // SLS_A1 collects ₹300 against srSale1Id (Due 800 -> 500)
    const srColl1Res = await api(salesmanTokenA, "/api/collections", {
      method: "POST",
      body: {
        customerId: customerId,
        collectionDate: "2026-09-19",
        amount: 300,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        selectedAllocations: [
          {
            sourceType: "SALE",
            referenceId: srSale1Id,
            referenceNo: "SALE-REF",
            amountApplied: 300,
          },
        ],
      },
    });
    if (srColl1Res.status !== 201) {
      console.log("srColl1Res error:", JSON.stringify(srColl1Res, null, 2));
    }
    assert(srColl1Res.status === 201, `SR Collection 1 posted (300 applied to srSale1Id): ${srColl1Res.data?.data?.collectionId}`);

    const sr5Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-sales-vs-received&salesmanId=SLS_A1`);
    assert(sr5Res.status === 200, "SR5: Sales vs received report HTTP 200");
    const cust1SalesRow = sr5Res.data.report.rows.find(r => r[2].includes(customerId));
    assert(cust1SalesRow, "SR5: Customer 1 row found");
    assert(parseFloat(cust1SalesRow[6].replace(/[₹,]/g, '')) >= 300, `SR5: Later collections reflected (got ${cust1SalesRow?.[6]})`);

    // --- SR6: Admin-collected payment credited to Salesman's bill realization ---
    console.log("\n--- TEST SR6: Admin collection allocated against Salesman bill ---");
    // Admin collects ₹200 against srSale1Id
    const srCollAdminRes = await api(adminTokenA, "/api/collections", {
      method: "POST",
      body: {
        customerId: customerId,
        collectionDate: "2026-09-19",
        amount: 200,
        paymentMode: "UPI",
        allocationMode: "MANUAL",
        selectedAllocations: [
          {
            sourceType: "SALE",
            referenceId: srSale1Id,
            referenceNo: "SALE-REF",
            amountApplied: 200,
          },
        ],
      },
    });
    assert(srCollAdminRes.status === 201, `SR Admin Collection posted (200 applied to srSale1Id): ${srCollAdminRes.data?.data?.collectionId}`);

    const sr6Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-sales-vs-received&salesmanId=SLS_A1`);
    assert(sr6Res.status === 200, "SR6: Sales vs received report HTTP 200");
    const cust1RowAfterAdmin = sr6Res.data.report.rows.find(r => r[2].includes(customerId));
    assert(parseFloat(cust1RowAfterAdmin[6].replace(/[₹,]/g, '')) >= 500, `SR6: Admin collection credited to Salesman sales realization (got ${cust1RowAfterAdmin?.[6]})`);

    // --- SR7: Advance Used separation in Sales vs Received ---
    console.log("\n--- TEST SR7: Advance used separated from direct received money ---");
    const cust3Res = await api(adminTokenA, "/api/customers", {
      method: "POST",
      body: {
        name: "Advance Customer",
        mobile: "9123456799",
        route: "North Route",
        priceType: "Retail",
        openingBalance: 0,
      },
    });
    const customer3Id = cust3Res.data.data.customerId;
    await db.collection("MAS_CUSTOMER").updateOne(
      { farmId: FARM_A, customerId: customer3Id },
      { $set: { balance: 500 } }
    );

    const advSaleRes = await api(salesmanTokenA, "/api/sales", {
      method: "POST",
      body: {
        customerId: customer3Id,
        saleDate: "2026-09-19",
        paymentMode: "Cash",
        products: [{ productId: prodId1, quantity: 6, rate: 100, amount: 600 }],
        grandTotal: 600,
        paidAmount: 100,
        advanceUsed: 500,
        payments: [{ mode: "Cash", amount: 100 }],
      },
    });
    assert(advSaleRes.status === 201, "SR7: Sale with advance used posted");

    const sr7Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-sales-vs-received&customerId=${customer3Id}`);
    assert(sr7Res.status === 200, "SR7: Sales vs received for advance customer HTTP 200");
    const cust3Row = sr7Res.data.report.rows.find(r => r[2].includes(customer3Id));
    assert(cust3Row, "SR7: Advance customer row found");
    assert(cust3Row[4] === "₹600.00", `SR7: Total Sales is ₹600.00 (got ${cust3Row?.[4]})`);
    assert(cust3Row[5] === "₹100.00", `SR7: Paid at Billing is ₹100.00 (got ${cust3Row?.[5]})`);
    assert(cust3Row[8] === "₹500.00", `SR7: Advance Used is ₹500.00 (got ${cust3Row?.[8]})`);
    assert(cust3Row[9] === "₹0.00", `SR7: Outstanding is ₹0.00 (got ${cust3Row?.[9]})`);
    assert(cust3Row[11] === "100.0%", `SR7: Settlement % is 100.0% (got ${cust3Row?.[11]})`);

    // --- SR8: Overpayment creates advance & settlement capped at 100% ---
    console.log("\n--- TEST SR8: Overpayment creates advance and caps settlement % at 100% ---");
    const cust4Res = await api(adminTokenA, "/api/customers", {
      method: "POST",
      body: {
        name: "Overpay Customer",
        mobile: "9123456711",
        route: "North Route",
        priceType: "Retail",
        openingBalance: 0,
      },
    });
    const customer4Id = cust4Res.data.data.customerId;
    const overpaySaleRes = await api(salesmanTokenA, "/api/sales", {
      method: "POST",
      body: {
        customerId: customer4Id,
        saleDate: "2026-09-19",
        paymentMode: "Cash",
        products: [{ productId: prodId1, quantity: 3, rate: 100, amount: 300 }],
        grandTotal: 300,
        paidAmount: 500,
        advanceCreated: 200,
        payments: [{ mode: "Cash", amount: 500 }],
      },
    });
    assert(overpaySaleRes.status === 201, "SR8: Overpayment sale posted");

    const sr8Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-sales-vs-received&customerId=${customer4Id}`);
    assert(sr8Res.status === 200, "SR8: Sales vs received HTTP 200");
    const cust4Row = sr8Res.data.report.rows.find(r => r[2].includes(customer4Id));
    assert(cust4Row, "SR8: Overpay customer row found");
    assert(cust4Row[4] === "₹300.00", `SR8: Total sales is ₹300.00 (got ${cust4Row?.[4]})`);
    assert(cust4Row[7] === "₹500.00", `SR8: Total Received is ₹500.00 (got ${cust4Row?.[7]})`);
    assert(cust4Row[10] === "₹200.00", `SR8: Advance Created is ₹200.00 (got ${cust4Row?.[10]})`);
    assert(cust4Row[11] === "100.0%", `SR8: Settlement % capped at 100.0% (got ${cust4Row?.[11]})`);

    // --- SR9: Cancelled sales excluded from reports ---
    console.log("\n--- TEST SR9: Cancelled sales excluded from reports ---");
    await db.collection("TRN_SALE").insertOne({
      farmId: FARM_A,
      saleId: "CANCELLED-SALE-99",
      saleNo: "CAN-001",
      saleDate: new Date(),
      customerId: customerId,
      customerName: "Test Customer",
      salesmanId: "SLS_A1",
      salesmanName: "Raju Salesman",
      route: "North Route",
      grandTotal: 9999,
      paidAmount: 9999,
      products: [{ productId: prodId1, productName: "Cow Milk 1L", quantity: 99, amount: 9999 }],
      status: "CANCELLED",
      createdAt: new Date(),
    });

    const sr9Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-product-sales&salesmanId=SLS_A1`);
    assert(!sr9Res.data.report.rows.some(r => r[5] >= 99), "SR9: Cancelled sale items excluded from product sales report");

    // --- SR10: Unposted collections excluded from realization ---
    console.log("\n--- TEST SR10: Unposted collections excluded from realization ---");
    await db.collection("TRN_COLLECTION").insertOne({
      farmId: FARM_A,
      collectionId: "DRAFT-COLL-99",
      receiptNo: "DFT-001",
      collectionDate: new Date(),
      customerId: customerId,
      customerName: "Test Customer",
      salesmanId: "SLS_A1",
      amount: 50000,
      status: "DRAFT",
      allocations: [
        {
          sourceType: "SALE",
          referenceId: srSale1Id,
          amountApplied: 50000,
        },
      ],
      createdAt: new Date(),
    });

    const sr10Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-sales-vs-received&salesmanId=SLS_A1`);
    const cust1RowDraft = sr10Res.data.report.rows.find(r => r[2].includes(customerId));
    assert(parseFloat(cust1RowDraft[6].replace(/[₹,]/g, '')) < 10000, "SR10: Draft collection of 50000 excluded from realization");

    // --- SR11: Salesman Performance Summary ---
    console.log("\n--- TEST SR11: Salesman Performance Summary ---");
    const sr11Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-performance-summary`);
    assert(sr11Res.status === 200, "SR11: Performance summary report HTTP 200");
    const sm1Row = sr11Res.data.report.rows.find(r => r[0] === "SLS_A1");
    const sm2Row = sr11Res.data.report.rows.find(r => r[0] === "SLS_A2");
    assert(sm1Row, "SR11: SLS_A1 row present");
    assert(sm2Row, "SR11: SLS_A2 row present");
    assert(sm1Row[4] >= 2, `SR11: SLS_A1 served multiple customers (got ${sm1Row?.[4]})`);
    assert(sm1Row[5] >= 2, `SR11: SLS_A1 total bills >= 2 (got ${sm1Row?.[5]})`);
    assert(sm1Row[13] === sm1Row[10] - sm1Row[11] - sm1Row[12], `SR11: Remaining Stock in Hand formula preserved: ${sm1Row[13]}`);

    // --- SR12: RBAC: Salesman cannot query another salesman's ID ---
    console.log("\n--- TEST SR12: RBAC 403 when Salesman queries other salesman ---");
    const sr12Res = await api(salesmanTokenA, `/api/reports/salesman?type=salesman-route-customer-product-sales&salesmanId=SLS_A2`);
    assert(sr12Res.status === 403, `SR12: Salesman querying another salesman returned 403 (got ${sr12Res.status})`);

    // --- SR13: Salesman querying own report endpoint automatically filters to own data ---
    console.log("\n--- TEST SR13: Salesman querying own report returns only own data ---");
    const sr13Res = await api(salesmanTokenA, `/api/reports/salesman?type=salesman-performance-summary`);
    assert(sr13Res.status === 200, "SR13: Salesman report HTTP 200");
    assert(sr13Res.data.report.rows.length === 1 && sr13Res.data.report.rows[0][0] === "SLS_A1", "SR13: Only SLS_A1 data returned to SLS_A1");

    // --- SR14: Multi-farm tenant isolation ---
    console.log("\n--- TEST SR14: Multi-farm tenant isolation ---");
    const sr14Res = await api(adminTokenB, `/api/reports/salesman?type=salesman-performance-summary`);
    assert(sr14Res.status === 200, "SR14: Farm B report HTTP 200");
    assert(!sr14Res.data.report.rows.some(r => r[0] === "SLS_A1" || r[0] === "SLS_A2"), "SR14: Farm A salesmen do not appear in Farm B report");

    // --- SR15: Date range filtering ---
    console.log("\n--- TEST SR15: Date range filtering (IST Business Dates) ---");
    const pastRes = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-product-sales&from=2020-01-01&to=2020-01-02`);
    assert(pastRes.status === 200, "SR15: Past date range HTTP 200");
    assert(pastRes.data.report.rows.length === 0, "SR15: 0 records found for past date range with no sales");

    // --- SR16: Sales Period Cohort vs Later Collection Date ---
    console.log("\n--- TEST SR16: Sales Period Cohort vs Later Collection Date ---");
    const cust16Res = await api(adminTokenA, "/api/customers", {
      method: "POST",
      body: {
        name: "Customer SR16",
        mobile: "9123456716",
        route: "North Route",
        priceType: "Retail",
        openingBalance: 0,
      },
    });
    const customer16Id = cust16Res.data.data.customerId;

    // Sale on 2026-09-10: GrandTotal ₹1000, Paid at billing ₹400
    const sale16Res = await api(salesmanTokenA, "/api/sales", {
      method: "POST",
      body: {
        customerId: customer16Id,
        saleDate: "2026-09-10",
        paymentMode: "Cash",
        products: [{ productId: prodId1, quantity: 10, rate: 100, amount: 1000 }],
        grandTotal: 1000,
        paidAmount: 400,
        paymentApplied: 400,
        payments: [{ mode: "Cash", amount: 400 }],
      },
    });
    assert(sale16Res.status === 201, "SR16: Sale posted on 2026-09-10");
    const sale16Id = sale16Res.data.data.saleId;

    // Admin collects ₹300 against this sale on 2026-09-18
    const coll16Res = await api(adminTokenA, "/api/collections", {
      method: "POST",
      body: {
        customerId: customer16Id,
        collectionDate: "2026-09-18",
        amount: 300,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        selectedAllocations: [
          {
            sourceType: "SALE",
            referenceId: sale16Id,
            referenceNo: "SALE16",
            amountApplied: 300,
          },
        ],
      },
    });
    assert(coll16Res.status === 201, "SR16: Collection posted on 2026-09-18");

    // Report for sales cohort 2026-09-01 to 2026-09-15
    const sr16Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-sales-vs-received&from=2026-09-01&to=2026-09-15&customerId=${customer16Id}`);
    assert(sr16Res.status === 200, "SR16: Sales vs received HTTP 200");
    const cust16Row = sr16Res.data.report.rows.find(r => r[2].includes(customer16Id));
    assert(cust16Row, "SR16: Customer 16 row found");
    assert(cust16Row[4] === "₹1000.00", `SR16: Sales is ₹1000.00 (got ${cust16Row?.[4]})`);
    assert(cust16Row[5] === "₹400.00", `SR16: Paid at Billing is ₹400.00 (got ${cust16Row?.[5]})`);
    assert(cust16Row[6] === "₹300.00", `SR16: Later Collections is ₹300.00 (got ${cust16Row?.[6]})`);
    assert(cust16Row[7] === "₹700.00", `SR16: Total Received is ₹700.00 (got ${cust16Row?.[7]})`);
    assert(cust16Row[9] === "₹300.00", `SR16: Outstanding is ₹300.00 (got ${cust16Row?.[9]})`);

    // --- SR17: Advance Used Outstanding & Settlement % ---
    console.log("\n--- TEST SR17: Advance Used Outstanding & Settlement % ---");
    const cust17Res = await api(adminTokenA, "/api/customers", {
      method: "POST",
      body: {
        name: "Customer SR17",
        mobile: "9123456717",
        route: "North Route",
        priceType: "Retail",
        openingBalance: 0,
      },
    });
    const customer17Id = cust17Res.data.data.customerId;
    await db.collection("MAS_CUSTOMER").updateOne(
      { farmId: FARM_A, customerId: customer17Id },
      { $set: { balance: 200 } }
    );

    // Sale: ₹300, paymentApplied = 0, advanceUsed = 200, outstandingAmount = 100
    const sale17Res = await api(salesmanTokenA, "/api/sales", {
      method: "POST",
      body: {
        customerId: customer17Id,
        saleDate: "2026-09-19",
        paymentMode: "Credit",
        products: [{ productId: prodId1, quantity: 3, rate: 100, amount: 300 }],
        grandTotal: 300,
        paidAmount: 0,
        paymentApplied: 0,
        advanceUsed: 200,
        outstandingAmount: 100,
      },
    });
    assert(sale17Res.status === 201, "SR17: Sale with advanceUsed posted");

    const sr17Res = await api(adminTokenA, `/api/reports/salesman?type=salesman-route-customer-sales-vs-received&customerId=${customer17Id}`);
    assert(sr17Res.status === 200, "SR17: Sales vs received HTTP 200");
    const cust17Row = sr17Res.data.report.rows.find(r => r[2].includes(customer17Id));
    assert(cust17Row, "SR17: Customer 17 row found");
    assert(cust17Row[4] === "₹300.00", `SR17: Sales is ₹300.00 (got ${cust17Row?.[4]})`);
    assert(cust17Row[5] === "₹0.00", `SR17: Paid At Billing is ₹0.00 (got ${cust17Row?.[5]})`);
    assert(cust17Row[8] === "₹200.00", `SR17: Advance Used is ₹200.00 (got ${cust17Row?.[8]})`);
    assert(cust17Row[7] === "₹0.00", `SR17: Total Received is ₹0.00 (got ${cust17Row?.[7]})`);
    assert(cust17Row[9] === "₹100.00", `SR17: Current Outstanding is ₹100.00 (got ${cust17Row?.[9]})`);
    assert(cust17Row[11] === "66.7%", `SR17: Settlement % is 66.7% (got ${cust17Row?.[11]})`);

    // --- SR18: No TRN_RETURN Assumption (matches live Allocation module) ---
    console.log("\n--- TEST SR18: Performance Summary matches live Allocation module ---");
    const allocListRes = await api(adminTokenA, "/api/allocations");
    assert(allocListRes.status === 200, "SR18: Live allocation module HTTP 200");
    const perfRes = await api(adminTokenA, "/api/reports/salesman?type=salesman-performance-summary");
    assert(perfRes.status === 200, "SR18: Performance summary HTTP 200");
    const sls1Perf = perfRes.data.report.rows.find(r => r[0] === "SLS_A1");
    assert(sls1Perf, "SR18: SLS_A1 row present");
    assert(sls1Perf[13] === sls1Perf[10] - sls1Perf[11] - sls1Perf[12], `SR18: Remaining allocation equals Allocated (${sls1Perf[10]}) - Sold (${sls1Perf[11]}) - Returned (${sls1Perf[12]})`);

    console.log("\n=======================================================");
    console.log("ALL REPORT SUITE INTEGRATION & VERIFICATION TESTS PASSED!");
    console.log("=======================================================\n");

  } catch (error) {
    console.error("Test Suite Error:", error.message);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
}

runReportTests();
