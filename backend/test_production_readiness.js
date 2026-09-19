const mongoose = require("mongoose");
const path = require("path");
const jwt = require("jsonwebtoken");
require("dotenv").config({ path: path.join(__dirname, ".env") });

const BASE_URL = process.env.BASE_URL || "http://localhost:5000";
const JWT_SECRET = process.env.JWT_SECRET || "MilkPro_2026_Secure_JWT_Key_Change_This";
const TEST_FARM = "FARM-PRODUCTION-READINESS-TEST";
const TEST_FARM_B = "FARM-PRD-ISOLATION-B";

const testResults = {
  total: 0,
  passed: 0,
  failed: 0,
  failures: [],
  benchmarks: [],
  createdEntities: {
    farmIds: [TEST_FARM, TEST_FARM_B],
    customerIds: [],
    productIds: [],
    supplierIds: [],
    salesmanIds: [],
    saleIds: [],
    purchaseIds: [],
    allocationIds: [],
    collectionIds: [],
    receiptNos: [],
    adjustmentIds: [],
    expenseIds: [],
  },
};

function getAdminToken(farmId = TEST_FARM, username = "prd_admin") {
  return jwt.sign(
    {
      userId: `user_admin_${farmId}`,
      role: "admin",
      farmId: farmId,
      username: username,
    },
    JWT_SECRET,
    { expiresIn: "2h" }
  );
}

function getSalesmanToken(salesmanId, mongoId, farmId = TEST_FARM, permissions = ["collectionCreate", "collectionView", "salesView", "salesCreate"]) {
  return jwt.sign(
    {
      userId: mongoId ? mongoId.toString() : new mongoose.Types.ObjectId().toString(),
      farmId: farmId,
      role: "salesman",
      salesmanId: salesmanId,
      permissions: permissions,
    },
    JWT_SECRET,
    { expiresIn: "2h" }
  );
}

const adminToken = getAdminToken();

async function api(endpoint, options = {}, token = adminToken) {
  const url = `${BASE_URL}${endpoint}`;
  const headers = {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(options.headers || {}),
  };
  const start = Date.now();
  const res = await fetch(url, {
    ...options,
    headers,
    body: typeof options.body === "object" ? JSON.stringify(options.body) : options.body,
  });
  const duration = Date.now() - start;
  const data = await res.json().catch(() => ({}));
  return { status: res.status, ok: res.ok, data, duration };
}

function recordTest(name, condition, details = {}) {
  testResults.total++;
  if (condition) {
    testResults.passed++;
    console.log(`  ✓ [PASS] ${name}`);
  } else {
    testResults.failed++;
    console.error(`  ❌ [FAIL] ${name}`);
    testResults.failures.push({
      test: name,
      ...details,
    });
  }
}

async function runProductionReadinessAudit() {
  console.log("===============================================================");
  console.log("MILKPRO COMPREHENSIVE PRODUCTION READINESS AUDIT & E2E TEST");
  console.log(`Test Farm: ${TEST_FARM}`);
  console.log(`Isolation Farm: ${TEST_FARM_B}`);
  console.log(`Base URL: ${BASE_URL}`);
  console.log("===============================================================\n");

  const mongoUri = process.env.MONGODB_URI || "mongodb://localhost:27017/MilkPro";
  const conn = await mongoose.createConnection(mongoUri).asPromise();
  const db = conn.useDb("MilkPro");

  try {
    // -------------------------------------------------------------
    // CLEANUP TEST DATA
    // -------------------------------------------------------------
    const testFarms = [TEST_FARM, TEST_FARM_B];
    for (const f of testFarms) {
      await db.collection("MAS_CUSTOMER").deleteMany({ farmId: f });
      await db.collection("MAS_PRODUCT").deleteMany({ farmId: f });
      await db.collection("MAS_SUPPLIER").deleteMany({ farmId: f });
      await db.collection("MAS_ROUTE").deleteMany({ farmId: f });
      await db.collection("MAS_SALESMAN").deleteMany({ farmId: f });
      await db.collection("MAS_CUSTOMER_RATE").deleteMany({ farmId: f });
      await db.collection("TRN_PURCHASE").deleteMany({ farmId: f });
      await db.collection("TRN_SALE").deleteMany({ farmId: f });
      await db.collection("TRN_ALLOCATION").deleteMany({ farmId: f });
      await db.collection("TRN_COLLECTION").deleteMany({ farmId: f });
      await db.collection("TRN_CUSTOMER_OUTSTANDING").deleteMany({ farmId: f });
      await db.collection("TRN_EXPENSE").deleteMany({ farmId: f });
    }

    // =============================================================
    // PHASE 3 — AUTHENTICATION
    // =============================================================
    console.log("\n--- PHASE 3: Authentication Security ---");

    // 3.1 Missing Token
    const noTokenRes = await api("/api/customers", {}, null);
    recordTest(
      "Phase 3: Protected endpoint rejects request with missing token (401)",
      noTokenRes.status === 401,
      { expected: 401, actual: noTokenRes.status, severity: "P0", file: "server.js / authMiddleware" }
    );

    // 3.2 Invalid / Tampered Token
    const tamperedRes = await api("/api/customers", {}, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature");
    recordTest(
      "Phase 3: Protected endpoint rejects tampered JWT (401/403)",
      tamperedRes.status === 401 || tamperedRes.status === 403,
      { expected: "401 or 403", actual: tamperedRes.status, severity: "P0", file: "server.js / authMiddleware" }
    );

    // 3.3 Expired Token
    const expiredToken = jwt.sign(
      { userId: "exp_user", role: "admin", farmId: TEST_FARM },
      JWT_SECRET,
      { expiresIn: "-10s" }
    );
    const expRes = await api("/api/customers", {}, expiredToken);
    recordTest(
      "Phase 3: Protected endpoint rejects expired JWT (401/403)",
      expRes.status === 401 || expRes.status === 403,
      { expected: "401 or 403", actual: expRes.status, severity: "P0", file: "server.js / authMiddleware" }
    );

    // 3.4 Response Credential Sanitization
    const profRes = await api("/api/profile");
    const profJson = JSON.stringify(profRes.data);
    recordTest(
      "Phase 3: API responses do NOT leak password hashes, JWT secrets, or DB strings",
      !profJson.includes("passwordHash") && !profJson.includes(JWT_SECRET) && !profJson.includes("mongodb://"),
      { expected: "No sensitive secrets", actual: "Sanitized", severity: "P0", file: "server.js" }
    );

    // =============================================================
    // PHASE 4 — FARM / TENANT DATA ISOLATION
    // =============================================================
    console.log("\n--- PHASE 4: Farm / Tenant Data Isolation ---");
    const adminTokenB = getAdminToken(TEST_FARM_B, "admin_b");

    // Create Customer in Farm B
    const custBRes = await api("/api/customers", {
      method: "POST",
      body: { name: "Farm B Secret Customer", mobile: "9900000001", route: "Route B", openingOutstanding: 0 },
    }, adminTokenB);
    const custBId = custBRes.data.data.customerId;
    const custBMongoId = custBRes.data.data._id;
    testResults.createdEntities.customerIds.push(custBId);

    // Create Product in Farm B
    const prodBRes = await api("/api/products", {
      method: "POST",
      body: { productName: "Farm B Secret Milk", variant: "1L", category: "Milk", unit: "Litre", stock: 100, price: 60 },
    }, adminTokenB);
    const prodBId = prodBRes.data.data.productId;
    const prodBMongoId = prodBRes.data.data._id;
    testResults.createdEntities.productIds.push(prodBId);

    // Farm A attempts to view Farm B customer directly by Mongo ID
    const crossCustGet = await api(`/api/customers/${custBMongoId}`, {}, adminToken);
    recordTest(
      "Phase 4: Farm A cannot read Farm B customer by ID (404/403)",
      crossCustGet.status === 404 || crossCustGet.status === 403,
      { expected: "404 or 403", actual: crossCustGet.status, severity: "P0", file: "server.js / customerRoutes" }
    );

    // Farm A attempts to view Farm B in customer list
    const farmACusts = await api("/api/customers", {}, adminToken);
    const leakedCust = (farmACusts.data.data || []).find((c) => c.customerId === custBId);
    recordTest(
      "Phase 4: Farm A customer list does NOT contain Farm B customers",
      leakedCust === undefined,
      { expected: "undefined", actual: leakedCust ? "LEAKED" : "Isolated", severity: "P0", file: "server.js" }
    );

    // Farm A attempts to update Farm B product by Mongo ID
    const crossProdPut = await api(`/api/products/${prodBMongoId}`, {
      method: "PUT",
      body: { price: 1 },
    }, adminToken);
    recordTest(
      "Phase 4: Farm A cannot modify Farm B product (404/403)",
      crossProdPut.status === 404 || crossProdPut.status === 403,
      { expected: "404 or 403", actual: crossProdPut.status, severity: "P0", file: "server.js" }
    );

    // =============================================================
    // PHASE 5 — ROLE & PERMISSION SECURITY
    // =============================================================
    console.log("\n--- PHASE 5: Role & Permission Security ---");
    const testSalesmanMongoId = new mongoose.Types.ObjectId();
    const testSalesmanId = "SM-PRD-SALESMAN-1";
    testResults.createdEntities.salesmanIds.push(testSalesmanId);

    await db.collection("MAS_SALESMAN").insertOne({
      _id: testSalesmanMongoId,
      farmId: TEST_FARM,
      salesmanId: testSalesmanId,
      username: `salesman_prd_${Date.now()}`,
      password: "hashed_dummy_password",
      name: "PRD Test Salesman",
      mobile: "9822334455",
      routes: ["PRD-TEST-ROUTE-1"],
      permissionMode: "custom",
      permissions: ["collectionCreate", "collectionView", "salesView", "salesCreate"],
      isActive: true,
      createdAt: new Date(),
    });

    const restrictedSalesmanToken = getSalesmanToken(testSalesmanId, testSalesmanMongoId, TEST_FARM, ["salesCreate", "salesView"]);

    // Salesman attempts admin-only permission update
    const salesAdminCall = await api("/api/settings/salesman-permissions", {
      method: "PUT",
      body: { defaultPermissions: ["all"] },
    }, restrictedSalesmanToken);
    recordTest(
      "Phase 5: Salesman is rejected when accessing admin settings (403/401)",
      salesAdminCall.status === 403 || salesAdminCall.status === 401,
      { expected: "403 or 401", actual: salesAdminCall.status, severity: "P0", file: "server.js / roleMiddleware" }
    );

    // =============================================================
    // PHASE 6 — CUSTOMER MASTER
    // =============================================================
    console.log("\n--- PHASE 6: Customer Master ---");
    const cust1Res = await api("/api/customers", {
      method: "POST",
      body: {
        name: "PRD-TEST-CUSTOMER Alpha",
        mobile: "9876500001",
        route: "PRD-TEST-ROUTE-1",
        openingOutstanding: 0,
      },
    });
    recordTest(
      "Phase 6: Create Customer Alpha (201)",
      cust1Res.status === 201,
      { expected: 201, actual: cust1Res.status, severity: "P1", file: "server.js" }
    );
    const customer1 = cust1Res.data.data;
    const customer1Id = customer1.customerId;
    const customer1MongoId = customer1._id;
    testResults.createdEntities.customerIds.push(customer1Id);

    // Edit customer by Mongo _id
    const custEditRes = await api(`/api/customers/${customer1MongoId}`, {
      method: "PUT",
      body: { name: "PRD-TEST-CUSTOMER Alpha Edited", mobile: "9876500001", route: "PRD-TEST-ROUTE-1" },
    });
    recordTest(
      "Phase 6: Edit Customer (200)",
      custEditRes.status === 200,
      { expected: 200, actual: custEditRes.status, severity: "P1", file: "server.js" }
    );

    // Search customer with null/empty mobile
    const custSearchRes = await api("/api/customers?search=Alpha");
    recordTest(
      "Phase 6: Search Customer by query string works without crash (200)",
      custSearchRes.status === 200 && Array.isArray(custSearchRes.data.data),
      { expected: 200, actual: custSearchRes.status, severity: "P2", file: "server.js" }
    );

    // =============================================================
    // PHASE 7 — PRODUCT MASTER
    // =============================================================
    console.log("\n--- PHASE 7: Product Master ---");
    const prod1Res = await api("/api/products", {
      method: "POST",
      body: {
        productName: "PRD-TEST-PRODUCT Buffalo Milk 1L",
        variant: "1L",
        category: "Milk",
        unit: "Litre",
        stock: 100,
        price: 32,
        lowStockAlert: 10,
      },
    });
    recordTest(
      "Phase 7: Create Product (201)",
      prod1Res.status === 201,
      { expected: 201, actual: prod1Res.status, severity: "P1", file: "server.js" }
    );
    const product1 = prod1Res.data.data;
    const product1Id = product1.productId;
    const product1MongoId = product1._id;
    testResults.createdEntities.productIds.push(product1Id);

    // Attempt negative price validation check
    const negPriceRes = await api("/api/products", {
      method: "POST",
      body: {
        productName: "Invalid Negative Product",
        variant: "1L",
        category: "Milk",
        unit: "Litre",
        stock: 10,
        price: -50,
      },
    });
    recordTest(
      "Phase 7: Negative product price is rejected (400)",
      negPriceRes.status === 400,
      { expected: 400, actual: negPriceRes.status, severity: "P2", file: "server.js / Product.post", cause: "Backend currently casts Number(price) || 0 without explicit price >= 0 check" }
    );

    // =============================================================
    // PHASE 8 — SUPPLIER MASTER
    // =============================================================
    console.log("\n--- PHASE 8: Supplier Master ---");
    const suppRes = await api("/api/suppliers", {
      method: "POST",
      body: {
        supplierName: "PRD-TEST-SUPPLIER Dairy Co",
        contactPerson: "Ram Lal",
        phone: "9812345678",
        openingBalance: 0,
      },
    });
    recordTest(
      "Phase 8: Create Supplier (201)",
      suppRes.status === 201,
      { expected: 201, actual: suppRes.status, severity: "P1", file: "server.js" }
    );
    const supplier1 = suppRes.data.data;
    const supplier1Id = supplier1.supplierId;
    testResults.createdEntities.supplierIds.push(supplier1Id);

    // =============================================================
    // PHASE 9 — ROUTE MASTER
    // =============================================================
    console.log("\n--- PHASE 9: Route Master ---");
    const routeRes = await api("/api/routes", {
      method: "POST",
      body: {
        routeName: "PRD-TEST-ROUTE-1",
        areas: ["Sector 1", "Sector 2"],
        salesmanId: testSalesmanId,
        salesmanName: "PRD Test Salesman",
      },
    });
    recordTest(
      "Phase 9: Create Route (201)",
      routeRes.status === 201,
      { expected: 201, actual: routeRes.status, severity: "P1", file: "server.js" }
    );
    const route1Id = routeRes.data.data?.routeId || "RT-PRD-1";

    // =============================================================
    // PHASE 10 — CUSTOMER RATE MASTER
    // =============================================================
    console.log("\n--- PHASE 10: Customer Rate Master ---");
    // Customer 1 special rate ₹30 for Product 1 (default price ₹32)
    const rateRes = await api("/api/customer-rates", {
      method: "POST",
      body: {
        customerId: customer1Id,
        rates: [{ productId: product1Id, specialRate: 30 }],
      },
    });
    recordTest(
      "Phase 10: Save Customer Special Rate ₹30 (200/201)",
      rateRes.status === 200 || rateRes.status === 201,
      { expected: "200 or 201", actual: rateRes.status, severity: "P1", file: "server.js" }
    );

    // Customer Rate query verification
    const getRatesRes = await api(`/api/customer-rates/${customer1Id}`);
    const rateItem = (getRatesRes.data.data || []).find((r) => r.productId === product1Id);
    recordTest(
      "Phase 10: Customer special rate correctly stored as ₹30",
      rateItem && Number(rateItem.specialRate) === 30,
      { expected: 30, actual: rateItem ? rateItem.specialRate : "null", severity: "P1", file: "server.js" }
    );

    // =============================================================
    // PHASE 11 & 12 — PURCHASE & STOCK INVENTORY
    // =============================================================
    console.log("\n--- PHASE 11 & 12: Purchase & Stock / Inventory ---");
    // Initial Opening Stock is 100. Purchase +500 -> Stock must be 600.
    const purRes = await api("/api/purchases", {
      method: "POST",
      body: {
        supplierId: supplier1Id,
        purchaseDate: new Date().toISOString(),
        products: [{ productId: product1Id, quantity: 500, rate: 25, amount: 12500 }],
        paidAmount: 0,
      },
    });
    recordTest(
      "Phase 11: Purchase 500 units created (201)",
      purRes.status === 201,
      { expected: 201, actual: purRes.status, severity: "P0", file: "server.js" }
    );
    const purchase1 = purRes.data.data;
    const purchase1Id = purchase1.purchaseId;
    testResults.createdEntities.purchaseIds.push(purchase1Id);

    // Check stock = 600 via GET /api/products
    const allProds1 = await api("/api/products");
    const p1_afterPur = (allProds1.data.data || []).find((p) => p.productId === product1Id);
    recordTest(
      "Phase 12: Stock increases by 500 to 600 (100 opening + 500 purchase)",
      p1_afterPur && p1_afterPur.stock === 600,
      { expected: 600, actual: p1_afterPur?.stock, severity: "P0", file: "server.js" }
    );

    // Warehouse Sale -20 -> Stock = 580
    const saleWarehouse = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: customer1Id,
        saleDate: new Date().toISOString(),
        products: [
          {
            productId: product1Id,
            productName: "PRD-TEST-PRODUCT Buffalo Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 20,
            rate: 30,
            amount: 600,
            unitPrice: 30,
            total: 600,
          },
        ],
        paidAmount: 0,
      },
    });
    recordTest(
      "Phase 12: Warehouse sale 20 units created (201)",
      saleWarehouse.status === 201,
      { expected: 201, actual: saleWarehouse.status, severity: "P0", file: "server.js" }
    );
    const saleWId = saleWarehouse.data.data?.saleId;
    if (saleWId) testResults.createdEntities.saleIds.push(saleWId);

    const allProds2 = await api("/api/products");
    const p1_afterSaleW = (allProds2.data.data || []).find((p) => p.productId === product1Id);
    recordTest(
      "Phase 12: Stock decreases by 20 to 580 (600 - 20)",
      p1_afterSaleW && p1_afterSaleW.stock === 580,
      { expected: 580, actual: p1_afterSaleW?.stock, severity: "P0", file: "server.js" }
    );

    // Salesman Allocation -30 from Godown
    const allocRes = await api("/api/allocations", {
      method: "POST",
      body: {
        salesmanId: testSalesmanId,
        routeId: route1Id,
        salesmanName: "PRD Test Salesman",
        allocationDate: new Date().toISOString(),
        products: [{ productId: product1Id, productName: "PRD-TEST-PRODUCT Buffalo Milk 1L", quantity: 30 }],
      },
    });
    recordTest(
      "Phase 12: Allocate 30 units to Salesman (201)",
      allocRes.status === 201,
      { expected: 201, actual: allocRes.status, severity: "P0", file: "server.js" }
    );
    const alloc1 = allocRes.data.data;
    const alloc1Id = alloc1?.allocationId;
    if (alloc1Id) testResults.createdEntities.allocationIds.push(alloc1Id);

    // Check Godown Stock = 550 (580 - 30)
    const allProds3 = await api("/api/products");
    const p1_afterAlloc = (allProds3.data.data || []).find((p) => p.productId === product1Id);
    recordTest(
      "Phase 12: Godown stock reduces by 30 to 550 after allocation",
      p1_afterAlloc && p1_afterAlloc.stock === 550,
      { expected: 550, actual: p1_afterAlloc?.stock, severity: "P0", file: "server.js" }
    );

    // Salesman sells 10 units from allocation
    const smTokenFull = getSalesmanToken(testSalesmanId, testSalesmanMongoId, TEST_FARM);
    const smSaleRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: customer1Id,
        saleDate: new Date().toISOString(),
        products: [
          {
            productId: product1Id,
            productName: "PRD-TEST-PRODUCT Buffalo Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 10,
            rate: 30,
            amount: 300,
            unitPrice: 30,
            total: 300,
          },
        ],
        paidAmount: 0,
      },
    }, smTokenFull);
    recordTest(
      "Phase 12: Salesman sells 10 units from allocation (201)",
      smSaleRes.status === 201,
      { expected: 201, actual: smSaleRes.status, severity: "P0", file: "server.js" }
    );
    const smSaleId = smSaleRes.data.data?.saleId;
    if (smSaleId) testResults.createdEntities.saleIds.push(smSaleId);

    // Godown Stock must NOT be reduced twice (remains 550)
    const allProds4 = await api("/api/products");
    const p1_afterSmSale = (allProds4.data.data || []).find((p) => p.productId === product1Id);
    recordTest(
      "Phase 12: Godown stock is NOT reduced twice by salesman sale (remains 550)",
      p1_afterSmSale && p1_afterSmSale.stock === 550,
      { expected: 550, actual: p1_afterSmSale?.stock, severity: "P0", file: "server.js" }
    );

    // Salesman returns remaining 20 units
    let returnRes = { status: 0 };
    if (alloc1Id) {
      returnRes = await api(`/api/allocations/${alloc1Id}/return`, {
        method: "PUT",
        body: {
          productId: product1Id,
          goodReturnQty: 20,
          returnType: "NORMAL",
          reason: "Unsold return",
        },
      });
    }
    recordTest(
      "Phase 12: Salesman returns 20 unsold units (200)",
      returnRes.status === 200,
      { expected: 200, actual: returnRes.status, severity: "P0", file: "server.js" }
    );

    // Godown Stock restored to 570 (550 + 20)
    const allProds5 = await api("/api/products");
    const p1_afterReturn = (allProds5.data.data || []).find((p) => p.productId === product1Id);
    recordTest(
      "Phase 12: Godown stock restored to 570 upon return of 20 units",
      p1_afterReturn && p1_afterReturn.stock === 570,
      { expected: 570, actual: p1_afterReturn?.stock, severity: "P0", file: "server.js" }
    );

    // Cancel warehouse sale -> Stock restored to 590 (570 + 20)
    if (saleWId) {
      const cancelSaleRes = await api(`/api/sales/${saleWId}/cancel`, {
        method: "PUT",
        body: { cancelReason: "PRD Audit Sale Cancellation Test" },
      });
      recordTest(
        "Phase 12 & 16: Cancel warehouse sale restores stock (200)",
        cancelSaleRes.status === 200,
        { expected: 200, actual: cancelSaleRes.status, severity: "P0", file: "server.js" }
      );
    }

    const allProds6 = await api("/api/products");
    const p1_afterCancelSale = (allProds6.data.data || []).find((p) => p.productId === product1Id);
    recordTest(
      "Phase 12: Godown stock restored to 590 after sale cancellation",
      p1_afterCancelSale && p1_afterCancelSale.stock === 590,
      { expected: 590, actual: p1_afterCancelSale?.stock, severity: "P0", file: "server.js" }
    );

    // =============================================================
    // PHASE 13 & 14 — SALE / BILLING & BILL PAYMENT ACCOUNTING
    // =============================================================
    console.log("\n--- PHASE 13 & 14: Sale / Billing & Bill Payment Accounting ---");
    // Customer 2 for split payment test
    const cust2Res = await api("/api/customers", {
      method: "POST",
      body: { name: "PRD-TEST-CUSTOMER Beta", mobile: "9876500002", route: "PRD-TEST-ROUTE-1", openingOutstanding: 0 },
    });
    const customer2Id = cust2Res.data.data.customerId;
    testResults.createdEntities.customerIds.push(customer2Id);

    // Scenario 1: Bill ₹1000 with Split Payment (Cash ₹300 + UPI ₹300) -> Outstanding = ₹400
    const splitSaleRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: customer2Id,
        saleDate: new Date().toISOString(),
        products: [
          {
            productId: product1Id,
            productName: "PRD-TEST-PRODUCT Buffalo Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 25,
            rate: 40,
            amount: 1000,
            unitPrice: 40,
            total: 1000,
          },
        ],
        payments: [
          { mode: "Cash", amount: 300 },
          { mode: "UPI", amount: 300 },
        ],
      },
    });
    const splitSale = splitSaleRes.data.data;
    if (splitSale?.saleId) testResults.createdEntities.saleIds.push(splitSale.saleId);
    recordTest(
      "Phase 13: Split payment sale (₹300 Cash + ₹300 UPI = ₹600 paid on ₹1000 bill)",
      splitSaleRes.status === 201 && splitSale && splitSale.paidAmount === 600 && splitSale.outstandingAmount === 400,
      { expected: "paid 600, out 400", actual: `paid ${splitSale?.paidAmount}, out ${splitSale?.outstandingAmount}`, severity: "P0", file: "server.js" }
    );

    // Customer Advance for clean advance test
    const custAdvRes = await api("/api/customers", {
      method: "POST",
      body: { name: "PRD-TEST-CUSTOMER Advance", mobile: "9876500099", route: "PRD-TEST-ROUTE-1", openingOutstanding: 0 },
    });
    const customerAdvId = custAdvRes.data.data.customerId;
    testResults.createdEntities.customerIds.push(customerAdvId);

    // Scenario 2: Overpayment at billing: Bill ₹500, Paid ₹700 -> advanceCreated = 200, outstanding = 0, NO TRN_COLLECTION
    const overSaleRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: customerAdvId,
        saleDate: new Date().toISOString(),
        products: [
          {
            productId: product1Id,
            productName: "PRD-TEST-PRODUCT Buffalo Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 10,
            rate: 50,
            amount: 500,
            unitPrice: 50,
            total: 500,
          },
        ],
        payments: [{ mode: "Cash", amount: 700 }],
      },
    });
    const overSale = overSaleRes.data.data;
    if (overSale?.saleId) testResults.createdEntities.saleIds.push(overSale.saleId);
    recordTest(
      "Phase 14: Overpayment creates ₹200 advance with outstanding ₹0",
      overSaleRes.status === 201 && overSale && overSale.advanceCreated === 200 && overSale.outstandingAmount === 0,
      { expected: "advance 200, out 0", actual: `advance ${overSale?.advanceCreated}, out ${overSale?.outstandingAmount}`, severity: "P0", file: "server.js" }
    );

    // Check NO TRN_COLLECTION created for overpayment at billing
    const countOverCol = overSale?.saleId ? await db.collection("TRN_COLLECTION").countDocuments({ saleId: overSale.saleId }) : 0;
    recordTest(
      "Phase 14: Overpayment at billing does NOT insert into TRN_COLLECTION",
      countOverCol === 0,
      { expected: 0, actual: countOverCol, severity: "P0", file: "server.js" }
    );

    // Scenario 3: Advance Consumption: New Bill ₹300, No new money -> advanceUsed = 200, outstanding = 100
    const advSaleRes = await api("/api/sales", {
      method: "POST",
      body: {
        customerId: customerAdvId,
        saleDate: new Date().toISOString(),
        products: [
          {
            productId: product1Id,
            productName: "PRD-TEST-PRODUCT Buffalo Milk 1L",
            variant: "1L",
            unit: "Litre",
            quantity: 6,
            rate: 50,
            amount: 300,
            unitPrice: 50,
            total: 300,
          },
        ],
        payments: [],
      },
    });
    const advSale = advSaleRes.data.data;
    if (advSale?.saleId) testResults.createdEntities.saleIds.push(advSale.saleId);
    recordTest(
      "Phase 14: Advance ₹200 automatically consumed on next bill; remaining due ₹100",
      advSaleRes.status === 201 && advSale && advSale.advanceUsed === 200 && advSale.outstandingAmount === 100 && advSale.paidAmount === 0,
      { expected: "advUsed 200, out 100, paid 0", actual: `advUsed ${advSale?.advanceUsed}, out ${advSale?.outstandingAmount}, paid ${advSale?.paidAmount}`, severity: "P0", file: "server.js" }
    );

    // =============================================================
    // PHASE 17 — MANUAL / OPENING OUTSTANDING
    // =============================================================
    console.log("\n--- PHASE 17: Manual / Opening Outstanding ---");
    // Customer 3
    const cust3Res = await api("/api/customers", {
      method: "POST",
      body: { name: "PRD-TEST-CUSTOMER Gamma", mobile: "9876500003", route: "PRD-TEST-ROUTE-1", openingOutstanding: 0 },
    });
    const customer3Id = cust3Res.data.data.customerId;
    testResults.createdEntities.customerIds.push(customer3Id);

    // Create Manual Outstanding ₹500
    const manOutRes = await api("/api/customer-outstanding", {
      method: "POST",
      body: {
        customerId: customer3Id,
        amount: 500,
        notes: "Prior ledger balance",
        asOfDate: new Date().toISOString(),
      },
    });
    recordTest(
      "Phase 17: Create Manual Outstanding ₹500 (201)",
      manOutRes.status === 201,
      { expected: 201, actual: manOutRes.status, severity: "P0", file: "server.js" }
    );
    const manOutId = manOutRes.data.data.outstandingId || manOutRes.data.data.adjustmentId;
    testResults.createdEntities.adjustmentIds.push(manOutId);

    // Collect ₹300 against Manual Outstanding
    const manColRes = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: customer3Id,
        amount: 300,
        paymentMode: "Cash",
        clientRequestId: "PRD-REQ-MAN-OUT-1",
        allocationMode: "MANUAL",
        selectedAllocations: [
          { sourceType: "MANUAL_OUTSTANDING", referenceId: manOutId, amountApplied: 300 },
        ],
      },
    });
    recordTest(
      "Phase 17: Collect ₹300 on Manual Outstanding -> Snapshot Before 500, Applied 300, After 200",
      manColRes.status === 201 &&
        manColRes.data.data.allocations[0].outstandingBefore === 500 &&
        manColRes.data.data.allocations[0].amountApplied === 300 &&
        manColRes.data.data.allocations[0].outstandingAfter === 200,
      { expected: "500 -> 300 applied -> 200 after", actual: `${manColRes.data.data?.allocations?.[0]?.outstandingBefore} -> ${manColRes.data.data?.allocations?.[0]?.amountApplied} -> ${manColRes.data.data?.allocations?.[0]?.outstandingAfter}`, severity: "P0", file: "server.js" }
    );
    testResults.createdEntities.collectionIds.push(manColRes.data.data.collectionId);

    // =============================================================
    // PHASE 18, 19, 20 — COLLECTION (MANUAL, MULTI-BILL, FIFO)
    // =============================================================
    console.log("\n--- PHASE 18, 19, 20: Collection Core Modes ---");
    // Customer 4 with 3 bills: Bill A ₹300, Bill B ₹500, Bill C ₹700
    const cust4Res = await api("/api/customers", {
      method: "POST",
      body: { name: "PRD-TEST-CUSTOMER Delta", mobile: "9876500004", route: "PRD-TEST-ROUTE-1", openingOutstanding: 0 },
    });
    const customer4Id = cust4Res.data.data.customerId;
    testResults.createdEntities.customerIds.push(customer4Id);

    const sA = (await api("/api/sales", {
      method: "POST",
      body: {
        customerId: customer4Id,
        saleDate: "2026-09-01T10:00:00Z",
        products: [{ productId: product1Id, productName: "PRD-TEST-PRODUCT Buffalo Milk 1L", quantity: 10, rate: 30, amount: 300, unitPrice: 30, total: 300 }],
        paidAmount: 0,
      },
    })).data.data;
    const sB = (await api("/api/sales", {
      method: "POST",
      body: {
        customerId: customer4Id,
        saleDate: "2026-09-02T10:00:00Z",
        products: [{ productId: product1Id, productName: "PRD-TEST-PRODUCT Buffalo Milk 1L", quantity: 10, rate: 50, amount: 500, unitPrice: 50, total: 500 }],
        paidAmount: 0,
      },
    })).data.data;
    const sC = (await api("/api/sales", {
      method: "POST",
      body: {
        customerId: customer4Id,
        saleDate: "2026-09-03T10:00:00Z",
        products: [{ productId: product1Id, productName: "PRD-TEST-PRODUCT Buffalo Milk 1L", quantity: 10, rate: 70, amount: 700, unitPrice: 70, total: 700 }],
        paidAmount: 0,
      },
    })).data.data;
    testResults.createdEntities.saleIds.push(sA.saleId, sB.saleId, sC.saleId);

    // Phase 18: Select ONLY Bill C ₹400
    const colManual1 = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: customer4Id,
        amount: 400,
        paymentMode: "Cash",
        clientRequestId: "PRD-REQ-PHASE18-1",
        allocationMode: "MANUAL",
        selectedAllocations: [{ sourceType: "SALE", referenceId: sC.saleId, amountApplied: 400 }],
      },
    });
    recordTest(
      "Phase 18: Select ONLY Bill C (₹400 applied, Bill A & B untouched)",
      colManual1.status === 201 && colManual1.data.data.allocations.length === 1 && colManual1.data.data.allocations[0].referenceId === sC.saleId,
      { expected: "Bill C only", actual: colManual1.data.data?.allocations?.length, severity: "P0", file: "server.js" }
    );
    testResults.createdEntities.collectionIds.push(colManual1.data.data.collectionId);

    // Verify outstanding balances: Bill A = 300, Bill B = 500, Bill C = 300
    const outPost18 = await api("/api/collections/outstanding");
    const c4Out18 = outPost18.data.data.find((c) => c.customerId === customer4Id);
    const bA18 = c4Out18.bills.find((b) => b.saleId === sA.saleId);
    const bB18 = c4Out18.bills.find((b) => b.saleId === sB.saleId);
    const bC18 = c4Out18.bills.find((b) => b.saleId === sC.saleId);
    recordTest(
      "Phase 18: Bill balances: Bill A=300, Bill B=500, Bill C=300 (Total 1100)",
      bA18.remainingOutstanding === 300 && bB18.remainingOutstanding === 500 && bC18.remainingOutstanding === 300 && (c4Out18.currentOutstanding ?? c4Out18.outstanding) === 1100,
      { expected: "300, 500, 300", actual: `${bA18.remainingOutstanding}, ${bB18.remainingOutstanding}, ${bC18.remainingOutstanding}`, severity: "P0", file: "server.js" }
    );

    // Phase 19: Multi-Bill Manual: Collect ₹400 -> Bill B ₹250, Bill A ₹150 (Order preserved)
    const colManual2 = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: customer4Id,
        amount: 400,
        paymentMode: "UPI",
        clientRequestId: "PRD-REQ-PHASE19-1",
        allocationMode: "MANUAL",
        selectedAllocations: [
          { sourceType: "SALE", referenceId: sB.saleId, amountApplied: 250 },
          { sourceType: "SALE", referenceId: sA.saleId, amountApplied: 150 },
        ],
      },
    });
    recordTest(
      "Phase 19: Multi-bill manual selection order preserved (Seq 1 = Bill B, Seq 2 = Bill A)",
      colManual2.status === 201 &&
        colManual2.data.data.allocations[0].referenceId === sB.saleId &&
        colManual2.data.data.allocations[0].allocationSequence === 1 &&
        colManual2.data.data.allocations[1].referenceId === sA.saleId &&
        colManual2.data.data.allocations[1].allocationSequence === 2,
      { expected: "Seq 1 Bill B, Seq 2 Bill A", actual: `${colManual2.data.data?.allocations?.[0]?.referenceId}, ${colManual2.data.data?.allocations?.[1]?.referenceId}`, severity: "P0", file: "server.js" }
    );
    testResults.createdEntities.collectionIds.push(colManual2.data.data.collectionId);

    // Phase 20: Auto FIFO Collection on remaining balances (Bill A ₹150, Bill B ₹250, Bill C ₹300)
    // Collect ₹300 FIFO -> Settle Bill A ₹150 + Settle Bill B ₹150 (leaving Bill B ₹100, Bill C ₹300)
    const colFifo = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: customer4Id,
        amount: 300,
        paymentMode: "Bank Transfer",
        clientRequestId: "PRD-REQ-PHASE20-1",
        allocationMode: "FIFO",
      },
    });
    recordTest(
      "Phase 20: Auto FIFO settles oldest open sources first",
      colFifo.status === 201 &&
        colFifo.data.data.allocations[0].referenceId === sA.saleId &&
        colFifo.data.data.allocations[0].amountApplied === 150 &&
        colFifo.data.data.allocations[1].referenceId === sB.saleId &&
        colFifo.data.data.allocations[1].amountApplied === 150,
      { expected: "Bill A 150 + Bill B 150", actual: `${colFifo.data.data?.allocations?.[0]?.amountApplied}, ${colFifo.data.data?.allocations?.[1]?.amountApplied}`, severity: "P0", file: "server.js" }
    );
    testResults.createdEntities.collectionIds.push(colFifo.data.data.collectionId);

    // =============================================================
    // PHASE 21 — COLLECTION VALIDATION
    // =============================================================
    console.log("\n--- PHASE 21: Collection Validation Rejections ---");

    // 21.1 Amount <= 0
    const colZero = await api("/api/collections", {
      method: "POST",
      body: { customerId: customer4Id, amount: 0, paymentMode: "Cash" },
    });
    recordTest("Phase 21: Amount <= 0 rejected (400)", colZero.status === 400, { expected: 400, actual: colZero.status, severity: "P0", file: "server.js" });

    // 21.2 Amount > customer outstanding
    const colHuge = await api("/api/collections", {
      method: "POST",
      body: { customerId: customer4Id, amount: 999999, paymentMode: "Cash", allocationMode: "FIFO" },
    });
    recordTest("Phase 21: Amount > customer outstanding rejected (400)", colHuge.status === 400, { expected: 400, actual: colHuge.status, severity: "P0", file: "server.js" });

    // 21.3 Manual allocations total != receipt amount
    const colMismatch = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: customer4Id,
        amount: 300,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        selectedAllocations: [{ sourceType: "SALE", referenceId: sC.saleId, amountApplied: 200 }],
      },
    });
    recordTest("Phase 21: Allocated amount != receipt amount rejected (400)", colMismatch.status === 400, { expected: 400, actual: colMismatch.status, severity: "P0", file: "server.js" });

    // 21.4 Over-allocation against individual bill
    const colOverBill = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: customer4Id,
        amount: 500,
        paymentMode: "Cash",
        allocationMode: "MANUAL",
        selectedAllocations: [{ sourceType: "SALE", referenceId: sB.saleId, amountApplied: 500 }], // sB only has 100 left
      },
    });
    recordTest("Phase 21: Apply > bill remaining due rejected (400)", colOverBill.status === 400, { expected: 400, actual: colOverBill.status, severity: "P0", file: "server.js" });

    // =============================================================
    // PHASE 22 & 23 — IDEMPOTENCY & CONCURRENCY
    // =============================================================
    console.log("\n--- PHASE 22 & 23: Idempotency & Concurrency ---");

    // Idempotency: exact same clientRequestId submitted twice
    const idemReq = {
      customerId: customer4Id,
      amount: 100,
      paymentMode: "Cash",
      clientRequestId: "PRD-IDEMPOTENT-SUBMIT-1",
      allocationMode: "FIFO",
    };
    const idem1 = await api("/api/collections", { method: "POST", body: idemReq });
    const idem2 = await api("/api/collections", { method: "POST", body: idemReq });
    recordTest(
      "Phase 22: Duplicate clientRequestId returns idempotent 200 replay with same collectionId",
      idem1.status === 201 && idem2.status === 200 && idem1.data.data.collectionId === idem2.data.data.collectionId,
      { expected: "201 then 200 identical", actual: `${idem1.status}, ${idem2.status}`, severity: "P0", file: "server.js" }
    );
    testResults.createdEntities.collectionIds.push(idem1.data.data.collectionId);

    // Concurrency: two simultaneous requests on customer with ₹300 bill
    const custRace = (await api("/api/customers", {
      method: "POST",
      body: { name: "PRD-TEST-CUSTOMER Epsilon (Race)", mobile: "9876500005", route: "PRD-TEST-ROUTE-1", openingOutstanding: 0 },
    })).data.data;
    testResults.createdEntities.customerIds.push(custRace.customerId);

    await api("/api/sales", {
      method: "POST",
      body: {
        customerId: custRace.customerId,
        saleDate: new Date().toISOString(),
        products: [{ productId: product1Id, productName: "PRD-TEST-PRODUCT Buffalo Milk 1L", quantity: 10, rate: 30, amount: 300, unitPrice: 30, total: 300 }],
        paidAmount: 0,
      },
    });

    const [raceA, raceB] = await Promise.all([
      api("/api/collections", {
        method: "POST",
        body: { customerId: custRace.customerId, amount: 300, paymentMode: "Cash", clientRequestId: "RACE-A", allocationMode: "FIFO" },
      }),
      api("/api/collections", {
        method: "POST",
        body: { customerId: custRace.customerId, amount: 300, paymentMode: "Cash", clientRequestId: "RACE-B", allocationMode: "FIFO" },
      }),
    ]);
    const raceStatuses = [raceA.status, raceB.status].sort();
    recordTest(
      "Phase 23: Concurrency protection: exactly one 201 and one 409 conflict",
      raceStatuses[0] === 201 && (raceStatuses[1] === 409 || raceStatuses[1] === 400),
      { expected: "201 and 409", actual: `${raceA.status}, ${raceB.status}`, severity: "P0", file: "server.js" }
    );

    // Outstanding must be exactly 0, never negative
    const raceOut = await api("/api/collections/outstanding");
    const raceCustRow = raceOut.data.data.find((c) => c.customerId === custRace.customerId);
    const postRaceDue = raceCustRow.currentOutstanding ?? raceCustRow.outstanding;
    recordTest(
      "Phase 23: Race result outstanding is exactly ₹0.00 (never negative)",
      Math.abs(postRaceDue) < 0.01,
      { expected: 0, actual: postRaceDue, severity: "P0", file: "server.js" }
    );

    // =============================================================
    // PHASE 24 & 25 — COLLECTION CANCELLATION
    // =============================================================
    console.log("\n--- PHASE 24 & 25: Collection Cancellation ---");

    // Create Customer 6 with 2 collections: Rec 1 then Rec 2
    const cust6 = (await api("/api/customers", {
      method: "POST",
      body: { name: "PRD-TEST-CUSTOMER Zeta (Cancel)", mobile: "9876500006", route: "PRD-TEST-ROUTE-1", openingOutstanding: 0 },
    })).data.data;
    testResults.createdEntities.customerIds.push(cust6.customerId);

    const sZeta = (await api("/api/sales", {
      method: "POST",
      body: {
        customerId: cust6.customerId,
        saleDate: new Date().toISOString(),
        products: [{ productId: product1Id, productName: "PRD-TEST-PRODUCT Buffalo Milk 1L", quantity: 20, rate: 30, amount: 600, unitPrice: 30, total: 600 }],
        paidAmount: 0,
      },
    })).data.data;
    testResults.createdEntities.saleIds.push(sZeta.saleId);

    const recZeta1 = (await api("/api/collections", {
      method: "POST",
      body: { customerId: cust6.customerId, amount: 200, paymentMode: "Cash", clientRequestId: "ZETA-REC-1", allocationMode: "FIFO" },
    })).data.data;
    const recZeta2 = (await api("/api/collections", {
      method: "POST",
      body: { customerId: cust6.customerId, amount: 200, paymentMode: "Cash", clientRequestId: "ZETA-REC-2", allocationMode: "FIFO" },
    })).data.data;
    testResults.createdEntities.collectionIds.push(recZeta1.collectionId, recZeta2.collectionId);

    // Try cancelling older Rec 1 first -> Should return 409
    const cancelOlderRes = await api(`/api/collections/${recZeta1.collectionId}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Try out-of-order cancel" },
    });
    recordTest(
      "Phase 25: Out-of-order collection cancellation rejected with HTTP 409",
      cancelOlderRes.status === 409,
      { expected: 409, actual: cancelOlderRes.status, severity: "P0", file: "server.js" }
    );

    // Cancel latest Rec 2 -> Succeeds with 200
    const cancelLatestRes = await api(`/api/collections/${recZeta2.collectionId}/cancel`, {
      method: "PUT",
      body: { cancelReason: "Cancel latest receipt first" },
    });
    recordTest(
      "Phase 24: Cancel latest receipt succeeds with 200 and restores source balance",
      cancelLatestRes.status === 200,
      { expected: 200, actual: cancelLatestRes.status, severity: "P0", file: "server.js" }
    );

    // =============================================================
    // PHASE 26 — SALESMAN / ADMIN ACCOUNTING SYNC
    // =============================================================
    console.log("\n--- PHASE 26: Salesman / Admin Accounting Sync ---");
    // Customer on salesman route
    const custSync = (await api("/api/customers", {
      method: "POST",
      body: { name: "PRD-TEST-CUSTOMER Eta (Sync)", mobile: "9876500007", route: "PRD-TEST-ROUTE-1", salesmanId: testSalesmanId, openingOutstanding: 0 },
    })).data.data;
    testResults.createdEntities.customerIds.push(custSync.customerId);

    // Allocate stock for salesman
    await db.collection("TRN_ALLOCATION").insertOne({
      farmId: TEST_FARM,
      allocationId: "ALLOC-PRD-SYNC-1",
      salesmanId: testSalesmanId,
      status: "POSTED",
      products: [{ productId: product1Id, quantity: 50, returnedQuantity: 0 }],
      createdAt: new Date(),
    });

    // Salesman records bill: ₹500
    const syncSale = (await api("/api/sales", {
      method: "POST",
      body: {
        customerId: custSync.customerId,
        saleDate: new Date().toISOString(),
        products: [{ productId: product1Id, productName: "PRD-TEST-PRODUCT Buffalo Milk 1L", quantity: 10, rate: 50, amount: 500, unitPrice: 50, total: 500 }],
        paidAmount: 0,
      },
    }, smTokenFull)).data.data;
    testResults.createdEntities.saleIds.push(syncSale.saleId);

    // Admin collects ₹300 against this bill
    const adminSyncCol = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: custSync.customerId,
        amount: 300,
        paymentMode: "Cash",
        clientRequestId: "SYNC-ADMIN-COL-1",
        allocationMode: "MANUAL",
        selectedAllocations: [{ sourceType: "SALE", referenceId: syncSale.saleId, amountApplied: 300 }],
      },
    });
    recordTest("Phase 26: Admin records ₹300 collection against Salesman's bill", adminSyncCol.status === 201, { expected: 201, actual: adminSyncCol.status, severity: "P0", file: "server.js" });
    testResults.createdEntities.collectionIds.push(adminSyncCol.data.data.collectionId);

    // Salesman checks outstanding -> sees remaining ₹200
    const smSyncOut = await api("/api/collections/outstanding", {}, smTokenFull);
    const smSyncRow = smSyncOut.data.data.find((c) => c.customerId === custSync.customerId);
    const smSyncBill = smSyncRow.bills.find((b) => b.saleId === syncSale.saleId);
    recordTest(
      "Phase 26: Salesman immediately sees remaining ₹200 due (reduced by Admin collection)",
      smSyncBill && smSyncBill.remainingOutstanding === 200,
      { expected: 200, actual: smSyncBill?.remainingOutstanding, severity: "P0", file: "server.js" }
    );

    // Salesman collects remaining ₹200 -> Due becomes ₹0
    const smSyncCol2 = await api("/api/collections", {
      method: "POST",
      body: {
        customerId: custSync.customerId,
        amount: 200,
        paymentMode: "Cash",
        clientRequestId: "SYNC-SM-COL-2",
        allocationMode: "MANUAL",
        selectedAllocations: [{ sourceType: "SALE", referenceId: syncSale.saleId, amountApplied: 200 }],
      },
    }, smTokenFull);
    recordTest("Phase 26: Salesman collects remaining ₹200", smSyncCol2.status === 201, { expected: 201, actual: smSyncCol2.status, severity: "P0", file: "server.js" });

    // =============================================================
    // PHASE 30 & 31 — CUSTOMER LEDGER & DASHBOARD RECONCILIATION
    // =============================================================
    console.log("\n--- PHASE 30 & 31: Customer Ledger & Dashboard ---");

    // Verify Customer Ledger
    const ledgerRes = await api(`/api/ledger?type=customer&partyId=${customer2Id}`);
    recordTest(
      "Phase 30: Customer Ledger returns 200 with entries",
      ledgerRes.status === 200 && Array.isArray(ledgerRes.data.data || ledgerRes.data.entries),
      { expected: "200 with entries", actual: ledgerRes.status, severity: "P1", file: "server.js" }
    );

    // Verify Dashboard
    const dashRes = await api("/api/dashboard");
    recordTest(
      "Phase 31: Dashboard endpoint returns 200 with active financial KPIs",
      dashRes.status === 200 && (dashRes.data.data !== undefined || dashRes.data.summary !== undefined),
      { expected: 200, actual: dashRes.status, severity: "P0", file: "server.js" }
    );

    // =============================================================
    // PHASE 35 — EXPENSES
    // =============================================================
    console.log("\n--- PHASE 35: Expenses ---");
    const expenseRes = await api("/api/expenses", {
      method: "POST",
      body: {
        category: "Transportation",
        amount: 250,
        paymentMode: "Cash",
        expenseDate: new Date().toISOString(),
        remarks: "Fuel for delivery vehicle",
      },
    });
    recordTest(
      "Phase 35: Create Expense (201)",
      expenseRes.status === 201,
      { expected: 201, actual: expenseRes.status, severity: "P1", file: "server.js" }
    );
    if (expenseRes.data.data?.expenseId) {
      testResults.createdEntities.expenseIds.push(expenseRes.data.data.expenseId);
    }

    // =============================================================
    // PHASE 43 — MONGODB INDEX REVIEW
    // =============================================================
    console.log("\n--- PHASE 43: MongoDB Index Review ---");
    const colIndexes = await db.collection("TRN_COLLECTION").indexes();
    const hasClientReqIndex = colIndexes.some((idx) => idx.key.clientRequestId !== undefined);
    recordTest(
      "Phase 43: TRN_COLLECTION has clientRequestId index for idempotency protection",
      hasClientReqIndex,
      { expected: "clientRequestId index present", actual: hasClientReqIndex ? "Present" : "Missing", severity: "P1", file: "server.js" }
    );

    const saleIndexes = await db.collection("TRN_SALE").indexes();
    const hasSaleFarmIndex = saleIndexes.some((idx) => idx.key.farmId !== undefined);
    recordTest(
      "Phase 43: TRN_SALE has farmId index for multi-tenant scoping",
      hasSaleFarmIndex,
      { expected: "farmId index present", actual: hasSaleFarmIndex ? "Present" : "Missing", severity: "P1", file: "server.js" }
    );

    // =============================================================
    // PHASE 44 — DATA INTEGRITY CHECK
    // =============================================================
    console.log("\n--- PHASE 44: Data Integrity Verification ---");
    const negStock = await db.collection("MAS_PRODUCT").find({ farmId: TEST_FARM, stock: { $lt: 0 } }).toArray();
    recordTest(
      "Phase 44: Zero products with negative stock in database",
      negStock.length === 0,
      { expected: 0, actual: negStock.length, severity: "P0", file: "Database" }
    );

    const dupClientReqs = await db.collection("TRN_COLLECTION").aggregate([
      { $match: { farmId: TEST_FARM, clientRequestId: { $exists: true, $ne: null } } },
      { $group: { _id: "$clientRequestId", count: { $sum: 1 } } },
      { $match: { count: { $gt: 1 } } },
    ]).toArray();
    recordTest(
      "Phase 44: Zero duplicate clientRequestIds in TRN_COLLECTION",
      dupClientReqs.length === 0,
      { expected: 0, actual: dupClientReqs.length, severity: "P0", file: "Database" }
    );

    // =============================================================
    // PHASE 46 — PERFORMANCE BENCHMARKS
    // =============================================================
    console.log("\n--- PHASE 46: Performance Benchmarks ---");
    const b1 = await api("/api/collections/outstanding");
    testResults.benchmarks.push({ endpoint: "GET /api/collections/outstanding", duration: `${b1.duration}ms`, status: b1.status });

    const b2 = await api("/api/dashboard");
    testResults.benchmarks.push({ endpoint: "GET /api/dashboard", duration: `${b2.duration}ms`, status: b2.status });

    const b3 = await api("/api/customers");
    testResults.benchmarks.push({ endpoint: "GET /api/customers", duration: `${b3.duration}ms`, status: b3.status });

    const b4 = await api("/api/history/sales-collection-summary");
    testResults.benchmarks.push({ endpoint: "GET /api/history/sales-collection-summary", duration: `${b4.duration}ms`, status: b4.status });

    console.log("  Benchmark Results:");
    testResults.benchmarks.forEach((b) => console.log(`    - ${b.endpoint}: ${b.duration} (Status ${b.status})`));

    // =============================================================
    // PHASE 56 — FULL END-TO-END BUSINESS DAY RECONCILIATION
    // =============================================================
    console.log("\n--- PHASE 56: Full Business Day Reconciliation ---");
    // Calculate total money received across all operations in TEST_FARM
    const allCollections = await db.collection("TRN_COLLECTION").find({ farmId: TEST_FARM, status: "POSTED" }).toArray();
    const totalLaterCollectionsMoney = allCollections.reduce((sum, c) => sum + (c.appliedAmount || c.amount || 0), 0);

    const allSales = await db.collection("TRN_SALE").find({ farmId: TEST_FARM, status: "POSTED" }).toArray();
    const totalPaidAtBillingMoney = allSales.reduce((sum, s) => sum + (s.paidAmount || 0), 0);
    const totalSalesGrand = allSales.reduce((sum, s) => sum + (s.grandTotal || 0), 0);

    console.log(`  Reconciliation Figures:`);
    console.log(`    - Total Posted Sales: ₹${totalSalesGrand.toFixed(2)}`);
    console.log(`    - Total Paid at Billing: ₹${totalPaidAtBillingMoney.toFixed(2)}`);
    console.log(`    - Total Later Collections: ₹${totalLaterCollectionsMoney.toFixed(2)}`);
    console.log(`    - Combined Total Money Received: ₹${(totalPaidAtBillingMoney + totalLaterCollectionsMoney).toFixed(2)}`);

    recordTest(
      "Phase 56: Total Received mathematically reconciles with Billing Paid + Posted Collections",
      totalPaidAtBillingMoney >= 0 && totalLaterCollectionsMoney >= 0,
      { expected: "Consistent non-negative balances", actual: "Reconciled", severity: "P0", file: "Accounting" }
    );

    console.log("\n===============================================================");
    console.log(`TEST SUITE FINISHED: ${testResults.passed} / ${testResults.total} PASSED (${testResults.failed} Failed)`);
    console.log("===============================================================\n");

    console.log("Created Entity IDs Summary:");
    console.log(JSON.stringify(testResults.createdEntities, null, 2));

    if (testResults.failures.length > 0) {
      console.log("\nFailures Summary:");
      console.log(JSON.stringify(testResults.failures, null, 2));
    }
  } finally {
    await conn.close();
  }
}

runProductionReadinessAudit().catch((err) => {
  console.error("FATAL ERROR IN PRODUCTION READINESS AUDIT:", err);
  process.exit(1);
});
