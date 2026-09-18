const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));


// ======================================================
// MONGODB CONNECTION
// ======================================================

mongoose
  .connect(process.env.MONGODB_URI)
  .then(() => {
    console.log("MongoDB Connected Successfully");
    console.log("Database:", mongoose.connection.name);
    runSalesmanPermissionMigration();
    ensureCollectionIndexes();
  })
  .catch((error) => {
    console.error("MongoDB Connection Failed");
    console.error(error.message);
  });


// ======================================================
// MAS_REGISTER SCHEMA
// ADMIN / FARM REGISTRATION
// ======================================================

const registerSchema = new mongoose.Schema(
  {
    role: {
      type: String,
      default: "admin",
    },

    farmId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    adminId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    name: {
      type: String,
      required: true,
      trim: true,
    },

    mobile: {
      type: String,
      required: true,
      trim: true,
    },

    email: {
      type: String,
      default: "",
      lowercase: true,
      trim: true,
    },

    username: {
      type: String,
      required: true,
      trim: true,
    },

    password: {
      type: String,
      required: true,
    },

    businessName: {
      type: String,
      required: true,
      trim: true,
    },

    address: {
      type: String,
      default: "",
      trim: true,
    },

    city: {
      type: String,
      default: "",
      trim: true,
    },

    state: {
      type: String,
      default: "",
      trim: true,
    },

    pin: {
      type: String,
      default: "",
      trim: true,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    salesmanDefaultPermissions: {
      type: [String],
      default: [],
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "MAS_REGISTER",
  }
);


// ======================================================
// MAS_SALESMAN SCHEMA
// ======================================================

const salesmanSchema = new mongoose.Schema(
  {
    role: {
      type: String,
      default: "salesman",
    },

    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    salesmanId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    name: {
      type: String,
      required: true,
      trim: true,
    },

    mobile: {
      type: String,
      required: true,
      trim: true,
    },

    email: {
      type: String,
      default: "",
      lowercase: true,
      trim: true,
    },

    username: {
      type: String,
      required: true,
      trim: true,
    },

    password: {
      type: String,
      required: true,
    },

    businessName: {
      type: String,
      default: "",
      trim: true,
    },
    // ======================================================
    // SALESMAN FEATURE PERMISSIONS
    // ======================================================

    permissionMode: {
      type: String,
      enum: ["inherit", "custom"],
      default: "inherit",
    },

    permissions: {
      type: [String],
      default: [],
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "MAS_SALESMAN",
  }
);


// ======================================================
// INDEXES
// ======================================================

registerSchema.index(
  { username: 1 },
  {
    unique: true,
    collation: {
      locale: "en",
      strength: 2,
    },
  }
);

salesmanSchema.index(
  { username: 1 },
  {
    unique: true,
    collation: {
      locale: "en",
      strength: 2,
    },
  }
);


// ======================================================
// MODELS
// ======================================================

const Register = mongoose.model(
  "Register",
  registerSchema,
  "MAS_REGISTER"
);

const Salesman = mongoose.model(
  "Salesman",
  salesmanSchema,
  "MAS_SALESMAN"
);

// ======================================================
// MAS_CUSTOMER SCHEMA
// ======================================================

const customerSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    customerId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    name: {
      type: String,
      required: true,
      trim: true,
    },

    mobile: {
      type: String,
      required: true,
      trim: true,
    },

    route: {
      type: String,
      default: "",
      trim: true,
    },

    balance: {
      type: Number,
      default: 0,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    createdBy: {
      type: String,
      default: "",
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "MAS_CUSTOMER",
  }
);


const Customer = mongoose.model(
  "Customer",
  customerSchema,
  "MAS_CUSTOMER"
);

// ======================================================
// MAS_ROUTE SCHEMA
// ======================================================

const routeSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    routeId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    routeName: {
      type: String,
      required: true,
      trim: true,
    },

    areas: {
      type: [String],
      default: [],
    },

    salesmanId: {
      type: String,
      default: "",
      trim: true,
    },

    salesmanName: {
      type: String,
      default: "",
      trim: true,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    createdBy: {
      type: String,
      default: "",
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "MAS_ROUTE",
  }
);


const RouteMaster = mongoose.model(
  "RouteMaster",
  routeSchema,
  "MAS_ROUTE"
);

// ======================================================
// MAS_PRODUCT SCHEMA
// ======================================================

const productSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    productId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    productName: {
      type: String,
      required: true,
      trim: true,
    },

    variant: {
      type: String,
      default: "",
      trim: true,
    },

    category: {
      type: String,
      default: "Dairy",
      trim: true,
    },

    unit: {
      type: String,
      required: true,
      trim: true,
    },

    stock: {
      type: Number,
      default: 0,
    },

    price: {
      type: Number,
      default: 0,
    },

    lowStockLevel: {
      type: Number,
      default: 20,
    },

    assetPath: {
      type: String,
      default: "",
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    createdBy: {
      type: String,
      default: "",
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "MAS_PRODUCT",
  }
);

const Product = mongoose.model(
  "Product",
  productSchema,
  "MAS_PRODUCT"
);
// ======================================================
// MAS_SUPPLIER
// ======================================================

const supplierSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
      index: true,
    },

    supplierId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      uppercase: true,
    },

    supplierName: {
      type: String,
      required: true,
      trim: true,
    },

    mobile: {
      type: String,
      default: "",
      trim: true,
    },

    email: {
      type: String,
      default: "",
      trim: true,
    },

    address: {
      type: String,
      default: "",
      trim: true,
    },

    gstNo: {
      type: String,
      default: "",
      trim: true,
      uppercase: true,
    },

    openingBalance: {
      type: Number,
      default: 0,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    createdBy: {
      type: String,
      default: "",
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "MAS_SUPPLIER",
  }
);

const Supplier = mongoose.model(
  "Supplier",
  supplierSchema,
  "MAS_SUPPLIER"
);
// ======================================================
// MAS_CUSTOMER_RATE
// CUSTOMER WISE SPECIAL PRODUCT RATE
// ======================================================

const customerRateSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    customerId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    customerName: {
      type: String,
      required: true,
      trim: true,
    },

    productId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    productName: {
      type: String,
      required: true,
      trim: true,
    },

    defaultRate: {
      type: Number,
      required: true,
      min: 0,
    },

    specialRate: {
      type: Number,
      required: true,
      min: 0,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    createdBy: {
      type: String,
      default: "",
    },

    updatedBy: {
      type: String,
      default: "",
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "MAS_CUSTOMER_RATE",
  }
);


// ======================================================
// UNIQUE CUSTOMER + PRODUCT RATE PER FARM
// ======================================================

customerRateSchema.index(
  {
    farmId: 1,
    customerId: 1,
    productId: 1,
  },
  {
    unique: true,
  }
);


const CustomerRate = mongoose.model(
  "CustomerRate",
  customerRateSchema,
  "MAS_CUSTOMER_RATE"
);


// ======================================================
// TRN_PURCHASE
// ======================================================

const purchaseProductSchema = new mongoose.Schema(
  {
    productId: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
    },

    productName: {
      type: String,
      required: true,
      trim: true,
    },

    variant: {
      type: String,
      default: "",
      trim: true,
    },

    unit: {
      type: String,
      required: true,
      trim: true,
    },

    quantity: {
      type: Number,
      required: true,
      min: 0,
    },

    rate: {
      type: Number,
      required: true,
      min: 0,
    },

    amount: {
      type: Number,
      required: true,
      min: 0,
    },
  },
  {
    _id: false,
  }
);

const purchaseSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    purchaseId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    purchaseNo: {
      type: String,
      required: true,
      trim: true,
    },

    purchaseDate: {
      type: Date,
      required: true,
    },

    supplierId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
    },

    supplierName: {
      type: String,
      required: true,
      trim: true,
    },

    invoiceNo: {
      type: String,
      default: "",
      trim: true,
    },

    billDate: {
      type: Date,
      required: true,
    },

    paymentType: {
      type: String,
      required: true,
      trim: true,
    },

    dueDate: {
      type: Date,
      required: true,
    },

    godown: {
      type: String,
      default: "Main Godown",
      trim: true,
    },

    remarks: {
      type: String,
      default: "",
      trim: true,
    },

    products: {
      type: [purchaseProductSchema],
      default: [],
    },

    totalQuantity: {
      type: Number,
      default: 0,
    },

    subTotal: {
      type: Number,
      default: 0,
    },

    discount: {
      type: Number,
      default: 0,
    },

    taxPercentage: {
      type: Number,
      default: 0,
    },

    taxAmount: {
      type: Number,
      default: 0,
    },

    grandTotal: {
      type: Number,
      default: 0,
    },

    status: {
      type: String,
      enum: ["POSTED", "CANCELLED"],
      default: "POSTED",
    },

    createdBy: {
      type: String,
      default: "",
    },

    cancelledBy: {
      type: String,
      default: "",
    },

    cancelledAt: {
      type: Date,
      default: null,
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "TRN_PURCHASE",
  }
);

const Purchase = mongoose.model(
  "Purchase",
  purchaseSchema,
  "TRN_PURCHASE"
);
// ======================================================
// TRN_STOCK
// ======================================================

const stockSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    stockId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    productId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    productName: {
      type: String,
      required: true,
      trim: true,
    },

    transactionType: {
      type: String,
      required: true,
      enum: [
        "OPENING",

        "PURCHASE",
        "PURCHASE_EDIT_REVERSE",
        "PURCHASE_EDIT",
        "PURCHASE_CANCEL",
        "PURCHASE_RETURN",

        "SALE",
        "SALE_EDIT",
        "SALE_EDIT_REVERSE",
        "SALE_CANCEL",
        "SALES_RETURN",

        "ALLOCATION_OUT",
        "ALLOCATION_RETURN",

   "ALLOCATION_EDIT",
"ALLOCATION_EDIT_REVERSE",
"ALLOCATION_CANCEL",
"ALLOCATION_DELETE",


        "ADJUSTMENT_IN",
        "ADJUSTMENT_OUT"
      ],
    },

    referenceType: {
      type: String,
      default: "",
      trim: true,
    },

    referenceId: {
      type: String,
      default: "",
      trim: true,
    },

    referenceNo: {
      type: String,
      default: "",
      trim: true,
    },

    quantityIn: {
      type: Number,
      default: 0,
    },

    quantityOut: {
      type: Number,
      default: 0,
    },

    rate: {
      type: Number,
      default: 0,
    },

    godown: {
      type: String,
      default: "Main Godown",
      trim: true,
    },

    createdBy: {
      type: String,
      default: "",
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "TRN_STOCK",
  }
);

const StockTransaction = mongoose.model(
  "StockTransaction",
  stockSchema,
  "TRN_STOCK"
);

// ======================================================
// TRN_SALE
// ======================================================

const saleProductSchema = new mongoose.Schema(
  {
    productId: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
    },

    productName: {
      type: String,
      required: true,
      trim: true,
    },

    variant: {
      type: String,
      default: "",
      trim: true,
    },

    unit: {
      type: String,
      required: true,
      trim: true,
    },

    quantity: {
      type: Number,
      required: true,
      min: 0,
    },

    defaultRate: {
      type: Number,
      default: 0,
      min: 0,
    },

    rate: {
      type: Number,
      required: true,
      min: 0,
    },

    rateSource: {
      type: String,
      enum: [
        "CUSTOMER_RATE",
        "PRODUCT_RATE",
      ],
      default: "PRODUCT_RATE",
    },

    amount: {
      type: Number,
      required: true,
      min: 0,
    },
  },
  {
    _id: false,
  }
);



const saleSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    saleId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    saleNo: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },

    saleDate: {
      type: Date,
      required: true,
    },

    customerId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    customerName: {
      type: String,
      required: true,
      trim: true,
    },

    customerMobile: {
      type: String,
      default: "",
      trim: true,
    },

    route: {
      type: String,
      default: "",
      trim: true,
    },

    // ======================================================
    // LEGACY / DISPLAY PAYMENT MODE
    //
    // Single payment:
    //   Cash / UPI / Bank Transfer / Credit
    //
    // Multiple payment methods:
    //   Split
    //
    // Kept for compatibility with existing Flutter screens.
    // ======================================================

    paymentMode: {
      type: String,
      required: true,

      enum: [
        "Cash",
        "UPI",
        "Credit",
        "Bank Transfer",
        "Split",
      ],

      default: "Cash",
    },

    // ======================================================
    // PAYMENT BREAKUP
    //
    // Example:
    // Bill = 1000
    //
    // Cash = 300
    // UPI  = 500
    //
    // paidAmount        = 800
    // outstandingAmount = 200
    // paymentStatus     = PARTIAL
    // ======================================================

    payments: {
      type: [
        {
          mode: {
            type: String,

            enum: [
              "Cash",
              "UPI",
              "Bank Transfer",
            ],

            required: true,
          },

          amount: {
            type: Number,
            required: true,
            min: 0,
          },

          referenceNo: {
            type: String,
            default: "",
            trim: true,
          },

          _id: false,
        },
      ],

      default: [],
    },
    paidAmount: {
      type: Number,
      default: 0,
      min: 0,
    },

    // ======================================================
    // AMOUNT OF BILL ACTUALLY SETTLED BY PAYMENT
    //
    // Example:
    // Bill = 1000
    // Payment received = 1200
    //
    // paymentApplied = 1000
    // advanceCreated = 200
    // ======================================================

    paymentApplied: {
      type: Number,
      default: 0,
      min: 0,
    },

    // ======================================================
    // EXTRA PAYMENT RECEIVED DURING BILLING
    // THIS BECOMES CUSTOMER ADVANCE
    // ======================================================

    advanceCreated: {
      type: Number,
      default: 0,
      min: 0,
    },

    // ======================================================
    // CUSTOMER ADVANCE USED AGAINST THIS BILL
    //
    // Example:
    // Bill Total       = 1000
    // Advance Used     = 300
    // Paid At Billing  = 200
    // Outstanding      = 500
    // ======================================================

    advanceUsed: {
      type: Number,
      default: 0,
      min: 0,
    },

    outstandingAmount: {
      type: Number,
      default: 0,
      min: 0,
    },

    paymentStatus: {
      type: String,

      enum: [
        "PAID",
        "PARTIAL",
        "CREDIT",
      ],

      default: "PAID",
    },

    products: {
      type: [saleProductSchema],
      default: [],
    },

    totalItems: {
      type: Number,
      default: 0,
    },

    totalQuantity: {
      type: Number,
      default: 0,
    },

    grandTotal: {
      type: Number,
      default: 0,
    },

    godown: {
      type: String,
      default: "Main Godown",
      trim: true,
    },

    // ======================================================
    // STOCK SOURCE OF THIS SALE
    //
    // MAIN_GODOWN
    //   -> Stock physically came from MAS_PRODUCT
    //
    // SALESMAN_ALLOCATION
    //   -> Stock already left MAS_PRODUCT during allocation.
    //      Sale only consumes salesman available stock.
    // ======================================================

    stockSource: {
      type: String,
      enum: [
        "MAIN_GODOWN",
        "SALESMAN_ALLOCATION",
      ],
      default: "MAIN_GODOWN",
      index: true,
    },

    status: {
      type: String,
      enum: [
        "POSTED",
        "CANCELLED",
      ],
      default: "POSTED",
    },

    createdBy: {
      type: String,
      default: "",
    },


    createdRole: {
      type: String,
      default: "",
    },
    salesmanId: {
      type: String,
      default: "",
      uppercase: true,
      trim: true,
      index: true,
    },

    salesmanName: {
      type: String,
      default: "",
      trim: true,
    },

    cancelledBy: {
      type: String,
      default: "",
    },

    cancelledAt: {
      type: Date,
      default: null,
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "TRN_SALE",
  }
);


saleSchema.index(
  {
    farmId: 1,
    saleNo: 1,
  },
  {
    unique: true,
  }
);


const Sale = mongoose.model(
  "Sale",
  saleSchema,
  "TRN_SALE"
);

// ======================================================
// TRN_ALLOCATION
// SALESMAN PRODUCT ALLOCATION
// ======================================================

const allocationProductSchema = new mongoose.Schema(
  {
    productId: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
    },

    productName: {
      type: String,
      required: true,
      trim: true,
    },

    variant: {
      type: String,
      default: "",
      trim: true,
    },

    unit: {
      type: String,
      required: true,
      trim: true,
    },

    quantity: {
      type: Number,
      required: true,
      min: 0,
    },

    returnedQuantity: {
      type: Number,
      default: 0,
      min: 0,
    },
  },
  {
    _id: false,
  }
);


const allocationSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    allocationId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    allocationNo: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },

    allocationDate: {
      type: Date,
      required: true,
    },

    salesmanId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    salesmanName: {
      type: String,
      required: true,
      trim: true,
    },

    routeId: {
      type: String,
      default: "",
      uppercase: true,
      trim: true,
    },

    routeName: {
      type: String,
      required: true,
      trim: true,
    },

    customerId: {
      type: String,
      default: "",
      uppercase: true,
      trim: true,
    },

    customerName: {
      type: String,
      default: "",
      trim: true,
    },

    products: {
      type: [allocationProductSchema],
      default: [],
    },

    totalItems: {
      type: Number,
      default: 0,
    },

    totalQuantity: {
      type: Number,
      default: 0,
    },

    notes: {
      type: String,
      default: "",
      trim: true,
    },

   status: {
  type: String,
  enum: [
    "POSTED",
    "RETURNED",
    "CANCELLED",
    "DELETED",
  ],
  default: "POSTED",
  index: true,
},
    createdBy: {
      type: String,
      default: "",
    },

    updatedBy: {
      type: String,
      default: "",
    },

    cancelledBy: {
      type: String,
      default: "",
    },

  cancelledAt: {
  type: Date,
  default: null,
},

// ======================================================
// SOFT DELETE / AUDIT
// ======================================================

deletedBy: {
  type: String,
  default: "",
},

deletedAt: {
  type: Date,
  default: null,
},

deleteReason: {
  type: String,
  default: "",
  trim: true,
},

createdAt: {
      type: Date,
      default: Date.now,
    },



    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "TRN_ALLOCATION",
  }
);
// ======================================================
// COLLECTION BILL ALLOCATION
// ONE RECEIPT CAN SETTLE ONE OR MORE SALES
// ======================================================
// ======================================================
// COLLECTION OUTSTANDING ALLOCATION
//
// A receipt can settle either:
//   1. SALE outstanding
//   2. MANUAL_OUTSTANDING
//
// Legacy saleId/saleNo/saleDate fields are kept so all
// old collection records continue to work.
// ======================================================

const collectionAllocationSchema =
  new mongoose.Schema(
    {
      sourceType: {
        type: String,
        enum: [
          "SALE",
          "MANUAL_OUTSTANDING",
        ],
        default: "SALE",
        trim: true,
        uppercase: true,
      },

      referenceId: {
        type: String,
        default: "",
        trim: true,
        uppercase: true,
      },

      referenceNo: {
        type: String,
        default: "",
        trim: true,
      },

      referenceDate: {
        type: Date,
        default: null,
      },

      sourceAmount: {
        type: Number,
        default: 0,
        min: 0,
      },

      // OLD SALE FIELDS - DO NOT REMOVE
      saleId: {
        type: String,
        default: "",
        uppercase: true,
        trim: true,
      },

      saleNo: {
        type: String,
        default: "",
        trim: true,
      },

      saleDate: {
        type: Date,
        default: null,
      },

      billAmount: {
        type: Number,
        default: 0,
        min: 0,
      },

      amountApplied: {
        type: Number,
        required: true,
        min: 0,
      },

      allocationSequence: {
        type: Number,
        default: 1,
      },

      outstandingBefore: {
        type: Number,
        default: 0,
        min: 0,
      },

      outstandingAfter: {
        type: Number,
        default: 0,
        min: 0,
      },
    },
    {
      _id: false,
    }
  );
// ======================================================
// TRN_COLLECTION
// CUSTOMER PAYMENT COLLECTION
// ======================================================

const collectionSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    collectionId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    receiptNo: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },

    clientRequestId: {
      type: String,
      trim: true,
    },

    collectionDate: {
      type: Date,
      required: true,
      default: Date.now,
    },

    customerId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    customerName: {
      type: String,
      required: true,
      trim: true,
    },

    customerMobile: {
      type: String,
      default: "",
      trim: true,
    },

    route: {
      type: String,
      default: "",
      trim: true,
    },

    salesmanId: {
      type: String,
      default: "",
      uppercase: true,
      trim: true,
      index: true,
    },

    salesmanName: {
      type: String,
      default: "",
      trim: true,
    },

    amount: {
      type: Number,
      required: true,
      min: 0,
    },

    // ======================================================
    // AMOUNT ACTUALLY APPLIED AGAINST SALES OUTSTANDING
    //
    // Example:
    // Customer paid = 2000
    // Outstanding   = 1000
    //
    // appliedAmount = 1000
    // advanceAmount = 1000
    // ======================================================

    appliedAmount: {
      type: Number,
      default: 0,
      min: 0,
    },

    // ======================================================
    // EXTRA CUSTOMER PAYMENT ADDED TO MAS_CUSTOMER.balance
    // ======================================================

    advanceAmount: {
      type: Number,
      default: 0,
      min: 0,
    },

    previousOutstanding: {
      type: Number,
      default: 0,
      min: 0,
    },

    remainingOutstanding: {
      type: Number,
      default: 0,
      min: 0,
    },

    previousAdvanceBalance: {
      type: Number,
      default: 0,
      min: 0,
    },

    currentAdvanceBalance: {
      type: Number,
      default: 0,
      min: 0,
    },

    allocations: {
      type: [collectionAllocationSchema],
      default: [],
    },

    paymentMode: {
      type: String,
      required: true,
      enum: [
        "Cash",
        "UPI",
        "PhonePe",
        "Google Pay",
        "Paytm",
        "Bank Transfer",
      ],
      default: "Cash",
    },

    referenceNo: {
      type: String,
      default: "",
      trim: true,
    },

    remarks: {
      type: String,
      default: "",
      trim: true,
    },

    status: {
      type: String,
      enum: [
        "POSTED",
        "CANCELLED",
      ],
      default: "POSTED",
    },

    createdBy: {
      type: String,
      default: "",
    },

    createdRole: {
      type: String,
      default: "",
    },

    cancelledBy: {
      type: String,
      default: "",
    },

    cancelledAt: {
      type: Date,
      default: null,
    },

    cancelReason: {
      type: String,
      default: "",
      trim: true,
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "TRN_COLLECTION",
  }
);


// ======================================================
// UNIQUE RECEIPT NUMBER PER FARM
// ======================================================

collectionSchema.index(
  {
    farmId: 1,
    receiptNo: 1,
  },
  {
    unique: true,
  }
);

collectionSchema.index(
  {
    farmId: 1,
    clientRequestId: 1,
  },
  {
    unique: true,
    partialFilterExpression: {
      clientRequestId: { $type: "string", $gt: "" },
    },
  }
);


const Collection = mongoose.model(
  "Collection",
  collectionSchema,
  "TRN_COLLECTION"
);
// ======================================================
// TRN_CUSTOMER_OUTSTANDING
// MANUAL CUSTOMER OUTSTANDING
// ======================================================
//
// IMPORTANT:
// MAS_CUSTOMER.balance is NOT changed here.
//
// MAS_CUSTOMER.balance = CUSTOMER ADVANCE ONLY.
//
// Manual outstanding is stored separately and increases
// customer payable/outstanding.
// ======================================================

const customerOutstandingSchema =
  new mongoose.Schema(
    {
      farmId: {
        type: String,
        required: true,
        uppercase: true,
        trim: true,
        index: true,
      },

      adjustmentId: {
        type: String,
        required: true,
        unique: true,
        uppercase: true,
        trim: true,
        index: true,
      },

      adjustmentNo: {
        type: String,
        required: true,
        trim: true,
        index: true,
      },

      adjustmentDate: {
        type: Date,
        required: true,
        default: Date.now,
        index: true,
      },

      customerId: {
        type: String,
        required: true,
        uppercase: true,
        trim: true,
        index: true,
      },

      customerName: {
        type: String,
        required: true,
        trim: true,
      },

      customerMobile: {
        type: String,
        default: "",
        trim: true,
      },

      route: {
        type: String,
        default: "",
        trim: true,
      },

      amount: {
        type: Number,
        required: true,
        min: 0.01,
      },

      remarks: {
        type: String,
        default: "",
        trim: true,
      },

      source: {
        type: String,
        enum: [
          "MANUAL_OUTSTANDING",
        ],
        default:
          "MANUAL_OUTSTANDING",
      },

      status: {
        type: String,
        enum: [
          "POSTED",
          "CANCELLED",
        ],
        default: "POSTED",
        index: true,
      },

      createdBy: {
        type: String,
        default: "",
      },

      createdRole: {
        type: String,
        default: "admin",
      },

      cancelledBy: {
        type: String,
        default: "",
      },

      cancelledAt: {
        type: Date,
        default: null,
      },

      createdAt: {
        type: Date,
        default: Date.now,
      },

      updatedAt: {
        type: Date,
        default: Date.now,
      },
    },
    {
      versionKey: false,

      collection:
        "TRN_CUSTOMER_OUTSTANDING",
    }
  );


customerOutstandingSchema.index(
  {
    farmId: 1,
    adjustmentNo: 1,
  },
  {
    unique: true,
  }
);


customerOutstandingSchema.index(
  {
    farmId: 1,
    customerId: 1,
    status: 1,
    adjustmentDate: 1,
  }
);


const CustomerOutstanding =
  mongoose.model(
    "CustomerOutstanding",
    customerOutstandingSchema,
    "TRN_CUSTOMER_OUTSTANDING"
  );

// ======================================================
// TRN_PAYMENT
// SUPPLIER PAYMENT
// ======================================================

const paymentSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    paymentId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    paymentNo: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },

    paymentDate: {
      type: Date,
      required: true,
      default: Date.now,
    },

    supplierId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    supplierName: {
      type: String,
      required: true,
      trim: true,
    },

    supplierMobile: {
      type: String,
      default: "",
      trim: true,
    },

    amount: {
      type: Number,
      required: true,
      min: 0,
    },

    paymentMode: {
      type: String,
      required: true,
      enum: [
        "Cash",
        "UPI",
        "Bank Transfer",
        "Cheque",
      ],
      default: "Cash",
    },

    referenceNo: {
      type: String,
      default: "",
      trim: true,
    },

    remarks: {
      type: String,
      default: "",
      trim: true,
    },

    status: {
      type: String,
      enum: [
        "POSTED",
        "CANCELLED",
      ],
      default: "POSTED",
    },

    createdBy: {
      type: String,
      default: "",
    },

    createdRole: {
      type: String,
      default: "",
    },

    cancelledBy: {
      type: String,
      default: "",
    },

    cancelledAt: {
      type: Date,
      default: null,
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "TRN_PAYMENT",
  }
);



// ======================================================
// UNIQUE PAYMENT NUMBER PER FARM
// ======================================================

paymentSchema.index(
  {
    farmId: 1,
    paymentNo: 1,
  },
  {
    unique: true,
  }
);


const Payment = mongoose.model(
  "Payment",
  paymentSchema,
  "TRN_PAYMENT"
);



// ======================================================
// UNIQUE ALLOCATION NUMBER PER FARM
// ======================================================

allocationSchema.index(
  {
    farmId: 1,
    allocationNo: 1,
  },
  {
    unique: true,
  }
);


const Allocation = mongoose.model(
  "Allocation",
  allocationSchema,
  "TRN_ALLOCATION"
);
// ======================================================
// HELPER
// ======================================================

function escapeRegex(value) {
  return value.replace(
    /[.*+?^${}()|[\]\\]/g,
    "\\$&"
  );
}


// ======================================================
// TRN_EXPENSE
// DAILY BUSINESS / DISTRIBUTION EXPENSE
// ======================================================

const expenseSchema = new mongoose.Schema(
  {
    farmId: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },

    expenseId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },

    expenseNo: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },

    expenseDate: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },

    category: {
      type: String,
      required: true,
      enum: [
        "Fuel",
        "Vehicle",
        "Loading",
        "Food",
        "Other",
      ],
      default: "Fuel",
      trim: true,
    },

    amount: {
      type: Number,
      required: true,
      min: 0,
    },

    paymentMode: {
      type: String,
      required: true,
      enum: [
        "Cash",
        "UPI",
        "Bank",
      ],
      default: "Cash",
      trim: true,
    },

    note: {
      type: String,
      default: "",
      trim: true,
    },

    status: {
      type: String,
      enum: [
        "POSTED",
        "CANCELLED",
      ],
      default: "POSTED",
      index: true,
    },

    createdBy: {
      type: String,
      default: "",
    },

    createdRole: {
      type: String,
      default: "",
    },

    cancelledBy: {
      type: String,
      default: "",
    },

    cancelledAt: {
      type: Date,
      default: null,
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    versionKey: false,
    collection: "TRN_EXPENSE",
  }
);


// ======================================================
// UNIQUE EXPENSE NUMBER PER FARM
// ======================================================

expenseSchema.index(
  {
    farmId: 1,
    expenseNo: 1,
  },
  {
    unique: true,
  }
);


const Expense = mongoose.model(
  "Expense",
  expenseSchema,
  "TRN_EXPENSE"
);
// ======================================================
// GENERATE EXPENSE ID
// ======================================================

async function generateExpenseId() {
  let expenseId;
  let exists = true;

  while (exists) {
    const number =
      Math.floor(
        100000 +
        Math.random() * 900000
      );

    expenseId =
      `EXP${number}`;

    exists =
      await Expense.exists({
        expenseId,
      });
  }

  return expenseId;
}


// ======================================================
// GENERATE EXPENSE NUMBER
// EXP-2026-0001
// ======================================================

async function generateExpenseNo(
  farmId
) {
  const year =
    new Date().getFullYear();

  const prefix =
    `EXP-${year}-`;

  const lastExpense =
    await Expense.findOne({
      farmId,

      expenseNo: {
        $regex:
          `^${prefix}`,
      },
    })
      .sort({
        createdAt: -1,
      })
      .select(
        "expenseNo"
      );

  let nextNumber = 1;

  if (
    lastExpense &&
    lastExpense.expenseNo
  ) {
    const parts =
      lastExpense
        .expenseNo
        .split("-");

    const lastNumber =
      Number(
        parts[
        parts.length - 1
        ]
      );

    if (
      Number.isFinite(
        lastNumber
      )
    ) {
      nextNumber =
        lastNumber + 1;
    }
  }

  return (
    prefix +
    nextNumber
      .toString()
      .padStart(
        4,
        "0"
      )
  );
}
// ======================================================
// GENERATE FARM ID
// ======================================================

async function generateFarmId() {
  let farmId;
  let exists = true;

  while (exists) {
    const randomNumber =
      Math.floor(100000 + Math.random() * 900000);

    farmId = `FARM${randomNumber}`;

    exists = await Register.exists({
      farmId: farmId,
    });
  }

  return farmId;
}


// ======================================================
// GENERATE ADMIN ID
// ======================================================

async function generateAdminId() {
  let adminId;
  let exists = true;

  while (exists) {
    const randomNumber =
      Math.floor(100000 + Math.random() * 900000);

    adminId = `ADM${randomNumber}`;

    exists = await Register.exists({
      adminId: adminId,
    });
  }

  return adminId;
}


// ======================================================
// GENERATE SALESMAN ID
// ======================================================

async function generateSalesmanId() {
  let salesmanId;
  let exists = true;

  while (exists) {
    const randomNumber =
      Math.floor(100000 + Math.random() * 900000);

    salesmanId = `SM${randomNumber}`;

    exists = await Salesman.exists({
      salesmanId: salesmanId,
    });
  }

  return salesmanId;
}
// ======================================================
// GENERATE CUSTOMER ID
// ======================================================

async function generateCustomerId() {
  let customerId;
  let exists = true;

  while (exists) {
    const randomNumber =
      Math.floor(100000 + Math.random() * 900000);

    customerId = `CUS${randomNumber}`;

    exists = await Customer.exists({
      customerId: customerId,
    });
  }

  return customerId;
}
// ======================================================
// GENERATE ROUTE ID
// ======================================================

async function generateRouteId() {
  let routeId;
  let exists = true;

  while (exists) {
    const randomNumber =
      Math.floor(100000 + Math.random() * 900000);

    routeId = `ROU${randomNumber}`;

    exists = await RouteMaster.exists({
      routeId: routeId,
    });
  }

  return routeId;
}
// ======================================================
// GENERATE PRODUCT ID
// ======================================================

async function generateProductId() {
  let productId;
  let exists = true;

  while (exists) {
    const randomNumber =
      Math.floor(100000 + Math.random() * 900000);

    productId = `PRD${randomNumber}`;

    exists = await Product.exists({
      productId: productId,
    });
  }

  return productId;
}
async function generateSupplierId() {
  let supplierId;
  let exists = true;

  while (exists) {
    const number =
      Math.floor(100000 + Math.random() * 900000);

    supplierId = `SUP${number}`;

    exists = await Supplier.exists({
      supplierId,
    });
  }

  return supplierId;
}

async function generatePurchaseId() {
  let purchaseId;
  let exists = true;

  while (exists) {
    const number =
      Math.floor(
        100000 + Math.random() * 900000
      );

    purchaseId = `PUR${number}`;

    exists = await Purchase.exists({
      purchaseId,
    });
  }

  return purchaseId;
}

async function generateStockId() {
  let stockId;
  let exists = true;

  while (exists) {
    const number =
      Math.floor(
        100000000 +
        Math.random() * 900000000
      );

    stockId = `STK${number}`;

    exists =
      await StockTransaction.exists({
        stockId,
      });
  }

  return stockId;
}

async function generatePurchaseNo(
  farmId
) {
  const year =
    new Date().getFullYear();

  const prefix =
    `PUR-${year}-`;

  const lastPurchase =
    await Purchase.findOne({
      farmId,
      purchaseNo: {
        $regex: `^${prefix}`,
      },
    })
      .sort({
        createdAt: -1,
      })
      .select("purchaseNo");

  let nextNumber = 1;

  if (
    lastPurchase &&
    lastPurchase.purchaseNo
  ) {
    const parts =
      lastPurchase.purchaseNo
        .split("-");

    const lastNumber =
      Number(
        parts[parts.length - 1]
      );

    if (
      Number.isFinite(lastNumber)
    ) {
      nextNumber =
        lastNumber + 1;
    }
  }

  return (
    prefix +
    nextNumber
      .toString()
      .padStart(4, "0")
  );
}

// ======================================================
// GENERATE SALE ID
// ======================================================

async function generateSaleId() {
  let saleId;
  let exists = true;

  while (exists) {

    const number =
      Math.floor(
        100000 +
        Math.random() * 900000
      );

    saleId =
      `SAL${number}`;

    exists =
      await Sale.exists({
        saleId: saleId,
      });
  }

  return saleId;
}


// ======================================================
// GENERATE SALE NUMBER
// SAL-2026-0001
// ======================================================

async function generateSaleNo(
  farmId
) {

  const year =
    new Date().getFullYear();

  const prefix =
    `SAL-${year}-`;

  const lastSale =
    await Sale.findOne({
      farmId: farmId,

      saleNo: {
        $regex:
          `^${prefix}`,
      },
    })
      .sort({
        createdAt: -1,
      })
      .select(
        "saleNo"
      );


  let nextNumber = 1;


  if (
    lastSale &&
    lastSale.saleNo
  ) {

    const parts =
      lastSale.saleNo.split("-");

    const lastNumber =
      Number(
        parts[
        parts.length - 1
        ]
      );


    if (
      Number.isFinite(
        lastNumber
      )
    ) {

      nextNumber =
        lastNumber + 1;
    }
  }


  return (
    prefix +
    nextNumber
      .toString()
      .padStart(
        4,
        "0"
      )
  );
}

// ======================================================
// GENERATE ALLOCATION ID
// ======================================================

async function generateAllocationId() {
  let allocationId;
  let exists = true;

  while (exists) {
    const number =
      Math.floor(
        100000 +
        Math.random() * 900000
      );

    allocationId =
      `ALL${number}`;

    exists =
      await Allocation.exists({
        allocationId: allocationId,
      });
  }

  return allocationId;
}


// ======================================================
// GENERATE ALLOCATION NUMBER
// ALL-2026-0001
// ======================================================

async function generateAllocationNo(
  farmId
) {
  const year =
    new Date().getFullYear();

  const prefix =
    `ALL-${year}-`;

  const lastAllocation =
    await Allocation.findOne({
      farmId: farmId,

      allocationNo: {
        $regex:
          `^${prefix}`,
      },
    })
      .sort({
        createdAt: -1,
      })
      .select(
        "allocationNo"
      );


  let nextNumber = 1;


  if (
    lastAllocation &&
    lastAllocation.allocationNo
  ) {
    const parts =
      lastAllocation
        .allocationNo
        .split("-");

    const lastNumber =
      Number(
        parts[
        parts.length - 1
        ]
      );

    if (
      Number.isFinite(
        lastNumber
      )
    ) {
      nextNumber =
        lastNumber + 1;
    }
  }


  return (
    prefix +
    nextNumber
      .toString()
      .padStart(
        4,
        "0"
      )
  );
}


// ======================================================
// GENERATE COLLECTION ID
// ======================================================

async function generateCollectionId() {
  let collectionId;
  let exists = true;

  while (exists) {
    const number =
      Math.floor(
        100000 +
        Math.random() * 900000
      );

    collectionId =
      `COL${number}`;

    exists =
      await Collection.exists({
        collectionId,
      });
  }

  return collectionId;
}


// ======================================================
// GENERATE RECEIPT NUMBER
// REC-2026-0001
// ======================================================

async function generateReceiptNo(
  farmId
) {
  const year =
    new Date().getFullYear();

  const prefix =
    `REC-${year}-`;

  const lastCollection =
    await Collection.findOne({
      farmId,

      receiptNo: {
        $regex: `^${prefix}`,
      },
    })
      .sort({
        createdAt: -1,
      })
      .select(
        "receiptNo"
      );

  let nextNumber = 1;

  if (
    lastCollection &&
    lastCollection.receiptNo
  ) {
    const parts =
      lastCollection
        .receiptNo
        .split("-");

    const lastNumber =
      Number(
        parts[
        parts.length - 1
        ]
      );

    if (
      Number.isFinite(
        lastNumber
      )
    ) {
      nextNumber =
        lastNumber + 1;
    }
  }

  return (
    prefix +
    nextNumber
      .toString()
      .padStart(
        4,
        "0"
      )
  );
}
// ======================================================
// GENERATE CUSTOMER OUTSTANDING ID
// ======================================================

async function generateCustomerOutstandingId() {
  let adjustmentId;
  let exists = true;

  while (exists) {
    const number =
      Math.floor(
        100000 +
        Math.random() * 900000
      );

    adjustmentId =
      `OUT${number}`;

    exists =
      await CustomerOutstanding.exists({
        adjustmentId,
      });
  }

  return adjustmentId;
}


// ======================================================
// GENERATE CUSTOMER OUTSTANDING NUMBER
// OUT-2026-0001
// ======================================================

async function generateCustomerOutstandingNo(
  farmId
) {
  const year =
    new Date().getFullYear();

  const prefix =
    `OUT-${year}-`;

  const lastOutstanding =
    await CustomerOutstanding.findOne({
      farmId,

      adjustmentNo: {
        $regex:
          `^${prefix}`,
      },
    })
      .sort({
        createdAt: -1,
      })
      .select(
        "adjustmentNo"
      );

  let nextNumber = 1;

  if (
    lastOutstanding &&
    lastOutstanding.adjustmentNo
  ) {
    const parts =
      lastOutstanding
        .adjustmentNo
        .split("-");

    const lastNumber =
      Number(
        parts[
          parts.length - 1
        ]
      );

    if (
      Number.isFinite(
        lastNumber
      )
    ) {
      nextNumber =
        lastNumber + 1;
    }
  }

  return (
    prefix +
    nextNumber
      .toString()
      .padStart(
        4,
        "0"
      )
  );
}


// ======================================================
// COLLECTION ALLOCATION KEY
//
// New:
//   SALE:SALE_ID
//   MANUAL_OUTSTANDING:OUT_ID
//
// Old collection allocations automatically become SALE.
// ======================================================

function getOutstandingSourceKey(
  sourceType,
  referenceId
) {
  const normalizedSourceType =
    (
      sourceType ||
      "SALE"
    )
      .toString()
      .trim()
      .toUpperCase();

  const normalizedReferenceId =
    (
      referenceId ||
      ""
    )
      .toString()
      .trim()
      .toUpperCase();

  return (
    `${normalizedSourceType}:${normalizedReferenceId}`
  );
}

// ======================================================
// CUSTOMER GROSS OUTSTANDING FOR ADVANCE VALIDATION
//
// IMPORTANT:
//
// MAS_CUSTOMER.balance may contain customer credit that is
// already offsetting older outstanding.
//
// Therefore Sales must NOT blindly use full customer.balance.
//
// Example:
// Raw balance / credit = 950
// Existing outstanding = 800
//
// Actually usable advance = 150
// ======================================================

async function getCustomerGrossOutstandingForAdvance({
  farmId,
  customerId,
  session = null,
  excludeSaleId = "",
}) {
  const normalizedCustomerId =
    (
      customerId ||
      ""
    )
      .toString()
      .trim()
      .toUpperCase();

  if (!normalizedCustomerId) {
    return 0;
  }


  const normalizedExcludeSaleId =
    (
      excludeSaleId ||
      ""
    )
      .toString()
      .trim()
      .toUpperCase();


  // ====================================================
  // POSTED SALES
  // ====================================================

  const saleFilter = {
    farmId,
    customerId:
      normalizedCustomerId,
    status:
      "POSTED",
  };


  if (normalizedExcludeSaleId) {
    saleFilter.saleId = {
      $ne:
        normalizedExcludeSaleId,
    };
  }


  let salesQuery =
    Sale.find(
      saleFilter
    )
      .select(
        [
          "saleId",
          "grandTotal",
          "paymentMode",
          "outstandingAmount",
        ].join(" ")
      )
      .lean();


  // ====================================================
  // MANUAL / OPENING OUTSTANDING
  // ====================================================

  let manualQuery =
    CustomerOutstanding.find({
      farmId,

      customerId:
        normalizedCustomerId,

      status:
        "POSTED",
    })
      .select(
        "amount"
      )
      .lean();


  // ====================================================
  // POSTED COLLECTIONS
  // ====================================================

  let collectionQuery =
    Collection.find({
      farmId,

      customerId:
        normalizedCustomerId,

      status:
        "POSTED",
    })
      .select(
        [
          "amount",
          "appliedAmount",
          "advanceAmount",
          "allocations",
        ].join(" ")
      )
      .lean();


  if (session) {
    salesQuery =
      salesQuery.session(
        session
      );

    manualQuery =
      manualQuery.session(
        session
      );

    collectionQuery =
      collectionQuery.session(
        session
      );
  }


  const [
    sales,
    manualOutstandingRecords,
    collections,
  ] =
    await Promise.all([
      salesQuery,
      manualQuery,
      collectionQuery,
    ]);


  // ====================================================
  // SALES OUTSTANDING BEFORE COLLECTION
  // ====================================================

  let grossSaleOutstanding =
    0;


  for (const sale of sales) {
    const billAmount =
      Math.max(
        0,
        Number(
          sale.grandTotal ||
          0
        )
      );


    let outstanding =
      Number(
        sale.outstandingAmount
      );


    // Old record compatibility
    if (
      !Number.isFinite(
        outstanding
      )
    ) {
      const oldMode =
        (
          sale.paymentMode ||
          ""
        )
          .toString()
          .trim()
          .toLowerCase();

      outstanding =
        oldMode === "credit"
          ? billAmount
          : 0;
    }


    grossSaleOutstanding +=
      Math.max(
        0,
        outstanding
      );
  }


  // ====================================================
  // MANUAL / OPENING OUTSTANDING
  // ====================================================

  const grossManualOutstanding =
    manualOutstandingRecords
      .reduce(
        (
          total,
          item
        ) =>
          total +
          Math.max(
            0,
            Number(
              item.amount ||
              0
            )
          ),
        0
      );


  // ====================================================
  // AMOUNT ALREADY SETTLED BY COLLECTIONS
  // ====================================================

  let collectionApplied =
    0;


  for (
    const collection
    of collections
  ) {
    const savedApplied =
      Number(
        collection.appliedAmount
      );


    // New collection records
    if (
      Number.isFinite(
        savedApplied
      ) &&
      savedApplied >
        0.001
    ) {
      collectionApplied +=
        savedApplied;

      continue;
    }


    // Allocation-based fallback
    const allocations =
      Array.isArray(
        collection.allocations
      )
        ? collection.allocations
        : [];


    const allocationApplied =
      allocations.reduce(
        (
          total,
          allocation
        ) =>
          total +
          Math.max(
            0,
            Number(
              allocation.amountApplied ||
              0
            )
          ),
        0
      );


    if (
      allocationApplied >
      0.001
    ) {
      collectionApplied +=
        allocationApplied;

      continue;
    }


    // Old receipt compatibility
    const legacyAmount =
      Math.max(
        0,
        Number(
          collection.amount ||
          0
        )
      );


    const legacyAdvance =
      Math.max(
        0,
        Number(
          collection.advanceAmount ||
          0
        )
      );


    collectionApplied +=
      Math.max(
        0,
        legacyAmount -
        legacyAdvance
      );
  }


  const grossOutstanding =
    Math.max(
      0,

      grossSaleOutstanding +
      grossManualOutstanding -
      collectionApplied
    );


  return Number(
    grossOutstanding.toFixed(
      2
    )
  );
}
// ======================================================
// GENERATE PAYMENT ID
// ======================================================

async function generatePaymentId() {
  let paymentId;
  let exists = true;

  while (exists) {
    const number =
      Math.floor(
        100000 +
        Math.random() * 900000
      );

    paymentId =
      `PAY${number}`;

    exists =
      await Payment.exists({
        paymentId,
      });
  }

  return paymentId;
}


// ======================================================
// GENERATE PAYMENT NUMBER
// PAY-2026-0001
// ======================================================

async function generatePaymentNo(
  farmId
) {
  const year =
    new Date().getFullYear();

  const prefix =
    `PAY-${year}-`;

  const lastPayment =
    await Payment.findOne({
      farmId,

      paymentNo: {
        $regex:
          `^${prefix}`,
      },
    })
      .sort({
        createdAt: -1,
      })
      .select(
        "paymentNo"
      );

  let nextNumber = 1;

  if (
    lastPayment &&
    lastPayment.paymentNo
  ) {
    const parts =
      lastPayment
        .paymentNo
        .split("-");

    const lastNumber =
      Number(
        parts[
        parts.length - 1
        ]
      );

    if (
      Number.isFinite(
        lastNumber
      )
    ) {
      nextNumber =
        lastNumber + 1;
    }
  }

  return (
    prefix +
    nextNumber
      .toString()
      .padStart(
        4,
        "0"
      )
  );
}

// ======================================================
// SALESMAN PERMISSION MASTER
// KEEP THESE NAMES SAME AS FLUTTER AppPermission
// ======================================================

const VALID_SALESMAN_PERMISSIONS = [
  "productsView",

  "customersView",
  "customersCreate",
  "customersEdit",

  "customerRatesManage",

  "allocationView",

  "salesView",
  "salesCreate",

  "returnsManage",

  "collectionView",
  "collectionCreate",

  "routesView",

  "purchaseView",
  "paymentsView",
  "ledgerView",
  "reportsView",
  "expensesView",
  "suppliersView",
];

// ======================================================
// AUTH MIDDLEWARE
// ======================================================

function authenticateToken(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: "Authorization token is required.",
      });
    }

    const parts = authHeader.split(" ");

    if (
      parts.length !== 2 ||
      parts[0] !== "Bearer"
    ) {
      return res.status(401).json({
        success: false,
        message: "Invalid authorization token.",
      });
    }

    const token = parts[1];

    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET
    );

    req.user = decoded;

    next();

  } catch (error) {

    return res.status(401).json({
      success: false,
      message:
        "Session expired or invalid. Please login again.",
    });
  }
}


// ======================================================
// CENTRAL PERMISSION & ACCESS CONTROL LAYER
// ======================================================

function getEffectiveSalesmanPermissions(salesman, farmAdmin) {
  if (!salesman) return [];
  const mode =
    salesman.permissionMode ||
    (Array.isArray(salesman.permissions) && salesman.permissions.length > 0
      ? "custom"
      : "inherit");

  if (mode === "custom") {
    return Array.isArray(salesman.permissions) ? salesman.permissions : [];
  }

  return Array.isArray(farmAdmin?.salesmanDefaultPermissions)
    ? farmAdmin.salesmanDefaultPermissions
    : [];
}

async function runSalesmanPermissionMigration() {
  try {
    // 1. Existing salesmen that have permissions but no permissionMode -> set to custom
    await Salesman.updateMany(
      {
        permissionMode: { $exists: false },
        "permissions.0": { $exists: true },
      },
      {
        $set: { permissionMode: "custom" },
      }
    );

    // 2. Remaining salesmen with no permissionMode -> set to inherit
    await Salesman.updateMany(
      {
        permissionMode: { $exists: false },
      },
      {
        $set: { permissionMode: "inherit" },
      }
    );
  } catch (error) {
    console.error("SALESMAN PERMISSION MIGRATION ERROR:", error.message);
  }
}

async function ensureCollectionIndexes() {
  try {
    const col = mongoose.connection.collection("TRN_COLLECTION");
    const indexes = await col.indexes();
    const oldCompound = indexes.find(
      (idx) => idx.name === "farmId_1_clientRequestId_1"
    );
    if (oldCompound && !oldCompound.unique) {
      await col.dropIndex("farmId_1_clientRequestId_1");
    }
    const oldSingle = indexes.find(
      (idx) => idx.name === "clientRequestId_1"
    );
    if (oldSingle) {
      await col.dropIndex("clientRequestId_1");
    }
    await Collection.createIndexes();
  } catch (error) {
    console.error("COLLECTION INDEX SYNC NOTICE:", error.message);
  }
}

async function loadAccessContext(req, res, next) {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Authorization token is required.",
      });
    }

    const { userId, farmId, role } = req.user;

    if (!farmId) {
      return res.status(401).json({
        success: false,
        message: "Invalid session farm context.",
      });
    }

    if (role === "admin") {
      req.access = {
        role: "admin",
        isAdmin: true,
        isSalesman: false,
        farmId: farmId,
        userId: userId,
        salesmanId: null,
        permissions: new Set(VALID_SALESMAN_PERMISSIONS),
      };
      return next();
    }

    if (role === "salesman") {
      const salesman = await Salesman.findOne({
        _id: userId,
        farmId: farmId,
        isActive: true,
      });

      if (!salesman) {
        return res.status(403).json({
          success: false,
          message: "Salesman account is inactive or not found.",
        });
      }

      const mode =
        salesman.permissionMode ||
        (Array.isArray(salesman.permissions) && salesman.permissions.length > 0
          ? "custom"
          : "inherit");

      let farmAdmin = null;
      if (mode === "inherit") {
        farmAdmin = await Register.findOne({
          farmId: farmId,
          isActive: true,
        }).select("salesmanDefaultPermissions");
      }

      const effectivePermissions = getEffectiveSalesmanPermissions(
        salesman,
        farmAdmin
      );

      req.access = {
        role: "salesman",
        isAdmin: false,
        isSalesman: true,
        farmId: farmId,
        userId: userId,
        salesman: salesman,
        salesmanId: salesman.salesmanId,
        permissionMode: mode,
        permissions: new Set(effectivePermissions),
      };
      return next();
    }

    return res.status(403).json({
      success: false,
      message: "Invalid user role.",
    });
  } catch (error) {
    console.error("LOAD ACCESS CONTEXT ERROR:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to verify access permissions.",
    });
  }
}

function hasPermission(req, permission) {
  if (!req.access) return false;
  if (req.access.isAdmin) return true;
  return req.access.permissions && req.access.permissions.has(permission);
}

function requirePermission(permission) {
  return (req, res, next) => {
    if (!req.access) {
      return res.status(401).json({
        success: false,
        message: "Authorization context is required.",
      });
    }

    if (hasPermission(req, permission)) {
      return next();
    }

    return res.status(403).json({
      success: false,
      message: `Permission denied. Requires ${permission}.`,
    });
  };
}

function requireAnyPermission(...permissions) {
  return (req, res, next) => {
    if (!req.access) {
      return res.status(401).json({
        success: false,
        message: "Authorization context is required.",
      });
    }

    if (req.access.isAdmin) {
      return next();
    }

    const granted = permissions.some((perm) => hasPermission(req, perm));
    if (granted) {
      return next();
    }

    return res.status(403).json({
      success: false,
      message: "Permission denied. Required feature access missing.",
    });
  };
}

function requireAdmin(req, res, next) {
  if (!req.access) {
    return res.status(401).json({
      success: false,
      message: "Authorization context is required.",
    });
  }

  if (req.access.isAdmin) {
    return next();
  }

  return res.status(403).json({
    success: false,
    message: "Administrative privileges required.",
  });
}


// ======================================================
// TEST API
// ======================================================

app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "MilkPro Backend Running",
  });
});


// ======================================================
// REGISTER
// ======================================================

app.post("/api/auth/register", async (req, res) => {
  try {
    const {
      role,
      farmId,
      name,
      mobile,
      email,
      username,
      password,
      businessName,
      address,
      city,
      state,
      pin,
    } = req.body;


    // ==================================================
    // BASIC VALIDATION
    // ==================================================

    if (
      !role ||
      !name ||
      !mobile ||
      !username ||
      !password
    ) {
      return res.status(400).json({
        success: false,
        message: "Please enter all required fields.",
      });
    }


    if (!["admin", "salesman"].includes(role)) {
      return res.status(400).json({
        success: false,
        message: "Invalid account role.",
      });
    }


    if (mobile.toString().length !== 10) {
      return res.status(400).json({
        success: false,
        message: "Enter a valid 10-digit mobile number.",
      });
    }


    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message:
          "Password must contain at least 6 characters.",
      });
    }


    // ==================================================
    // ADMIN REGISTRATION
    // MAS_REGISTER
    // ==================================================

    if (role === "admin") {

      if (
        !businessName ||
        !businessName.trim()
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Business / Dairy Name is required.",
        });
      }


      // Check username in admin collection
      const existingAdminUsername =
        await Register.findOne({
          username: {
            $regex: new RegExp(
              `^${escapeRegex(username.trim())}$`,
              "i"
            ),
          },
        });


      if (existingAdminUsername) {
        return res.status(409).json({
          success: false,
          message:
            "Username already exists.",
        });
      }


      // Also prevent same username in salesman collection
      const existingSalesmanUsername =
        await Salesman.findOne({
          username: {
            $regex: new RegExp(
              `^${escapeRegex(username.trim())}$`,
              "i"
            ),
          },
        });


      if (existingSalesmanUsername) {
        return res.status(409).json({
          success: false,
          message:
            "Username already exists.",
        });
      }


      const hashedPassword =
        await bcrypt.hash(password, 12);


      const newFarmId =
        await generateFarmId();

      const newAdminId =
        await generateAdminId();


      const admin =
        await Register.create({
          role: "admin",

          farmId: newFarmId,

          adminId: newAdminId,

          name: name.trim(),

          mobile: mobile.trim(),

          email:
            email?.trim() || "",

          username:
            username.trim(),

          password:
            hashedPassword,

          businessName:
            businessName.trim(),

          address:
            address?.trim() || "",

          city:
            city?.trim() || "",

          state:
            state?.trim() || "",

          pin:
            pin?.trim() || "",

          isActive: true,
        });


      return res.status(201).json({
        success: true,

        message:
          "Admin account created successfully.",

        data: {
          id: admin._id,

          role: admin.role,

          farmId: admin.farmId,

          adminId: admin.adminId,

          name: admin.name,

          username: admin.username,

          businessName:
            admin.businessName,
        },
      });
    }


    // ==================================================
    // SALESMAN REGISTRATION
    // MAS_SALESMAN
    // ==================================================

    if (
      !farmId ||
      !farmId.trim()
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Farm ID is required for salesman registration.",
      });
    }


    const normalizedFarmId =
      farmId.trim().toUpperCase();


    // Verify Farm ID from MAS_REGISTER
    const farmAdmin =
      await Register.findOne({
        farmId: normalizedFarmId,
        isActive: true,
      });


    if (!farmAdmin) {
      return res.status(404).json({
        success: false,
        message:
          "Farm ID not found. Please contact your administrator.",
      });
    }


    // Check username across both collections
    const existingSalesmanUsername =
      await Salesman.findOne({
        username: {
          $regex: new RegExp(
            `^${escapeRegex(username.trim())}$`,
            "i"
          ),
        },
      });


    if (existingSalesmanUsername) {
      return res.status(409).json({
        success: false,
        message:
          "Username already exists.",
      });
    }


    const existingAdminUsername =
      await Register.findOne({
        username: {
          $regex: new RegExp(
            `^${escapeRegex(username.trim())}$`,
            "i"
          ),
        },
      });


    if (existingAdminUsername) {
      return res.status(409).json({
        success: false,
        message:
          "Username already exists.",
      });
    }


    const hashedPassword =
      await bcrypt.hash(password, 12);


    const newSalesmanId =
      await generateSalesmanId();


    const salesman =
      await Salesman.create({
        role: "salesman",

        farmId:
          normalizedFarmId,

        salesmanId:
          newSalesmanId,

        name:
          name.trim(),

        mobile:
          mobile.trim(),

        email:
          email?.trim() || "",

        username:
          username.trim(),

        password:
          hashedPassword,

        businessName:
          farmAdmin.businessName,
        permissionMode: "inherit",
        permissions: [],

        isActive:
          true,
      });


    return res.status(201).json({
      success: true,

      message:
        "Salesman account created successfully.",

      data: {
        id:
          salesman._id,

        role:
          salesman.role,

        farmId:
          salesman.farmId,

        salesmanId:
          salesman.salesmanId,

        name:
          salesman.name,

        username:
          salesman.username,

        businessName:
          salesman.businessName,
      },
    });

  } catch (error) {

    console.error(
      "REGISTER ERROR:",
      error
    );


    if (error.code === 11000) {
      return res.status(409).json({
        success: false,

        message:
          "Username or generated ID already exists.",
      });
    }


    return res.status(500).json({
      success: false,

      message:
        "Unable to create account.",

      error:
        error.message,
    });
  }
});


// ======================================================
// LOGIN
// ======================================================

app.post("/api/auth/login", async (req, res) => {

  try {

    const {
      role,
      identifier,
      password,
    } = req.body;


    if (
      !role ||
      !identifier ||
      !password
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Role, ID and password are required.",
      });
    }


    const cleanIdentifier =
      identifier.trim();


    let user = null;


    // ==================================================
    // ADMIN LOGIN FROM MAS_REGISTER
    // ==================================================

    if (role === "admin") {

      user =
        await Register.findOne({
          isActive: true,

          $or: [
            {
              farmId:
                cleanIdentifier.toUpperCase(),
            },

            {
              adminId:
                cleanIdentifier.toUpperCase(),
            },

            {
              username: {
                $regex: new RegExp(
                  `^${escapeRegex(cleanIdentifier)}$`,
                  "i"
                ),
              },
            },

            {
              mobile:
                cleanIdentifier,
            },
          ],
        });
    }


    // ==================================================
    // SALESMAN LOGIN FROM MAS_SALESMAN
    // ==================================================

    else if (role === "salesman") {

      user =
        await Salesman.findOne({
          isActive: true,

          $or: [
            {
              salesmanId:
                cleanIdentifier.toUpperCase(),
            },

            {
              mobile:
                cleanIdentifier,
            },

            {
              username: {
                $regex: new RegExp(
                  `^${escapeRegex(cleanIdentifier)}$`,
                  "i"
                ),
              },
            },
          ],
        });
    }


    else {
      return res.status(400).json({
        success: false,
        message:
          "Invalid login role.",
      });
    }


    if (!user) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid login credentials.",
      });
    }


    // ==================================================
    // PASSWORD CHECK
    // ==================================================

    const passwordMatched =
      await bcrypt.compare(
        password,
        user.password
      );


    if (!passwordMatched) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid login credentials.",
      });
    }


    // ==================================================
    // JWT
    // ==================================================

    const token =
      jwt.sign(
        {
          userId:
            user._id.toString(),

          role:
            role,

          farmId:
            user.farmId,
        },

        process.env.JWT_SECRET,

        {
          expiresIn:
            "30d",
        }
      );


    // ==================================================
    // LOGIN RESPONSE
    // ==================================================

    let effectivePermissions = [];
    if (role === "salesman") {
      let farmAdmin = null;
      const mode =
        user.permissionMode ||
        (Array.isArray(user.permissions) && user.permissions.length > 0
          ? "custom"
          : "inherit");

      if (mode === "inherit") {
        farmAdmin = await Register.findOne({
          farmId: user.farmId,
          isActive: true,
        }).select("salesmanDefaultPermissions");
      }

      effectivePermissions = getEffectiveSalesmanPermissions(user, farmAdmin);
    }

    return res.status(200).json({

      success: true,

      message:
        "Login successful.",

      token:
        token,

      user: {
        id:
          user._id,

        role:
          role,

        farmId:
          user.farmId,

        adminId:
          role === "admin"
            ? user.adminId
            : null,

        salesmanId:
          role === "salesman"
            ? user.salesmanId
            : null,

        name:
          user.name,

        mobile:
          user.mobile,

        email:
          user.email,

        username:
          user.username,

        businessName:
          user.businessName,
        permissions:
          role === "salesman"
            ? effectivePermissions
            : [],
      },
    });

  } catch (error) {

    console.error(
      "LOGIN ERROR:",
      error
    );


    return res.status(500).json({
      success: false,

      message:
        "Unable to login.",

      error:
        error.message,
    });
  }
});

// ======================================================
// CUSTOMER MASTER
// MAS_CUSTOMER
// ======================================================


// ======================================================
// GET ALL CUSTOMERS
// ======================================================

// ======================================================
// GET CUSTOMERS
//
// ADMIN
//   -> ALL ACTIVE FARM CUSTOMERS
//
// SALESMAN
//   -> ONLY CUSTOMERS BELONGING TO HIS ASSIGNED ROUTES
// ======================================================

app.get(
  "/api/customers",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission(
    "customersView",
    "customersCreate",
    "customersEdit",
    "customerRatesManage",
    "salesView",
    "salesCreate",
    "collectionView",
    "collectionCreate",
    "ledgerView"
  ),
  async (req, res) => {

    try {

      const farmId =
        req.user.farmId;

      const role =
        req.user.role;

      const userId =
        req.user.userId;


      // ==================================================
      // ADMIN
      // ALL FARM CUSTOMERS
      // ==================================================

      if (role === "admin") {

        const customers =
          await Customer.find({
            farmId:
              farmId,

            isActive:
              true,
          })
            .sort({
              name: 1,
            });


        return res.status(200).json({
          success:
            true,

          count:
            customers.length,

          data:
            customers,
        });
      }


      // ==================================================
      // SALESMAN
      // ONLY HIS ROUTE CUSTOMERS
      // ==================================================

      if (role === "salesman") {

        const salesman =
          await Salesman.findOne({
            _id:
              userId,

            farmId:
              farmId,

            isActive:
              true,
          }).lean();


        if (!salesman) {

          return res.status(404).json({
            success:
              false,

            message:
              "Salesman account not found.",
          });
        }


        // ================================================
        // FIND ROUTES ASSIGNED TO THIS SALESMAN
        // ================================================

        const routes =
          await RouteMaster.find({
            farmId:
              farmId,

            salesmanId:
              salesman.salesmanId,

            isActive:
              true,
          })
            .select(
              "routeId routeName"
            )
            .lean();


        const routeNames =
          routes
            .map(
              (route) =>
                (
                  route.routeName ||
                  ""
                )
                  .toString()
                  .trim()
            )
            .filter(
              (routeName) =>
                routeName.length > 0
            );


        // ================================================
        // NO ROUTE ASSIGNED
        // ================================================

        if (
          routeNames.length === 0
        ) {

          return res.status(200).json({
            success:
              true,

            count:
              0,

            data:
              [],
          });
        }


        // ================================================
        // CUSTOMERS BELONGING TO SALESMAN ROUTES
        // ================================================

        const customers =
          await Customer.find({
            farmId:
              farmId,

            isActive:
              true,

            route: {
              $in:
                routeNames,
            },
          })
            .sort({
              name: 1,
            });


        return res.status(200).json({
          success:
            true,

          count:
            customers.length,

          data:
            customers,
        });
      }


      // ==================================================
      // INVALID ROLE
      // ==================================================

      return res.status(403).json({
        success:
          false,

        message:
          "You are not allowed to access customers.",
      });

    } catch (error) {

      console.error(
        "GET CUSTOMERS ERROR:",
        error
      );


      return res.status(500).json({
        success:
          false,

        message:
          "Unable to load customers.",

        error:
          error.message,
      });
    }
  }
);

// ======================================================
// ADD CUSTOMER
// ======================================================

// ======================================================
// ADD CUSTOMER
//
// IMPORTANT:
// balance = ADVANCE ONLY
//
// openingOutstanding is stored separately in
// TRN_CUSTOMER_OUTSTANDING.
// ======================================================

app.post(
  "/api/customers",
  authenticateToken,
  loadAccessContext,
  requirePermission("customersCreate"),
  async (req, res) => {
    let createdCustomer =
      null;

    try {
      const {
        name,
        mobile,
        route,
        openingOutstanding,
      } = req.body;


      // ==================================================
      // VALIDATION
      // ==================================================

      if (
        !name ||
        !name.trim()
      ) {
        return res.status(400).json({
          success: false,

          message:
            "Customer name is required.",
        });
      }


      if (
        !mobile ||
        mobile
          .toString()
          .trim()
          .length !== 10
      ) {
        return res.status(400).json({
          success: false,

          message:
            "Enter a valid 10-digit mobile number.",
        });
      }


      const farmId =
        req.access.farmId;


      const openingAmount =
        Number(
          openingOutstanding ||
          0
        );


      if (
        !Number.isFinite(
          openingAmount
        ) ||
        openingAmount < 0
      ) {
        return res.status(400).json({
          success: false,

          message:
            "Opening outstanding cannot be negative.",
        });
      }


      // ==================================================
      // SALESMAN ROUTE ACCESS
      // ==================================================

      if (
        req.access.isSalesman
      ) {
        if (
          !route ||
          !route.trim()
        ) {
          return res.status(400).json({
            success: false,

            message:
              "Assigned route is required.",
          });
        }


        const assignedRoute =
          await RouteMaster.findOne({
            farmId,

            salesmanId:
              req.access.salesmanId,

            isActive:
              true,

            $or: [
              {
                routeName:
                  route.trim(),
              },
              {
                routeId:
                  route
                    .trim()
                    .toUpperCase(),
              },
            ],
          });


        if (!assignedRoute) {
          return res.status(403).json({
            success: false,

            message:
              "You can only assign customers to your assigned routes.",
          });
        }


        // Manual/opening outstanding is Admin controlled.
        if (
          openingAmount >
          0.001
        ) {
          return res.status(403).json({
            success: false,

            message:
              "Only admin can enter opening customer outstanding.",
          });
        }
      }


      // ==================================================
      // DUPLICATE MOBILE
      // ==================================================

      const existingCustomer =
        await Customer.findOne({
          farmId,

          mobile:
            mobile
              .toString()
              .trim(),
        });


      if (
        existingCustomer
      ) {
        return res.status(409).json({
          success: false,

          message:
            "Customer with this mobile number already exists.",
        });
      }


      // ==================================================
      // CUSTOMER ID
      // ==================================================

      const customerId =
        await generateCustomerId();


      // ==================================================
      // CREATE CUSTOMER
      //
      // balance remains ZERO.
      // balance = customer advance only.
      // ==================================================

      createdCustomer =
        await Customer.create({
          farmId,

          customerId,

          name:
            name.trim(),

          mobile:
            mobile
              .toString()
              .trim(),

          route:
            route?.trim() ||
            "",

          balance:
            0,

          isActive:
            true,

          createdBy:
            req.user.userId,
        });


      // ==================================================
      // CREATE OPENING OUTSTANDING
      // ==================================================

      let openingOutstandingRecord =
        null;


      if (
        openingAmount >
        0.001
      ) {
        const adjustmentId =
          await generateCustomerOutstandingId();


        const adjustmentNo =
          await generateCustomerOutstandingNo(
            farmId
          );


        openingOutstandingRecord =
          await CustomerOutstanding.create({
            farmId,

            adjustmentId,

            adjustmentNo,

            adjustmentDate:
              new Date(),

            customerId:
              createdCustomer.customerId,

            customerName:
              createdCustomer.name,

            customerMobile:
              createdCustomer.mobile ||
              "",

            route:
              createdCustomer.route ||
              "",

            amount:
              Number(
                openingAmount.toFixed(
                  2
                )
              ),

            remarks:
              "Opening customer outstanding",

            source:
              "MANUAL_OUTSTANDING",

            status:
              "POSTED",

            createdBy:
              req.user.userId ||
              "",

            createdRole:
              req.user.role ||
              "admin",

            createdAt:
              new Date(),

            updatedAt:
              new Date(),
          });
      }


      return res.status(201).json({
        success: true,

        message:
          openingOutstandingRecord
            ? "Customer added with opening outstanding successfully."
            : "Customer added successfully.",

        data:
          createdCustomer,

        openingOutstanding:
          openingOutstandingRecord,
      });

    } catch (error) {
      console.error(
        "ADD CUSTOMER ERROR:",
        error
      );


      // ==================================================
      // ROLLBACK CUSTOMER IF OPENING OUTSTANDING FAILED
      // ==================================================

      if (
        createdCustomer?._id
      ) {
        try {
          await Customer.deleteOne({
            _id:
              createdCustomer._id,
          });
        } catch (
          rollbackError
        ) {
          console.error(
            "CUSTOMER CREATION ROLLBACK ERROR:",
            rollbackError
          );
        }
      }


      if (
        error.code ===
        11000
      ) {
        return res.status(409).json({
          success: false,

          message:
            "Duplicate customer or outstanding record detected.",
        });
      }


      return res.status(500).json({
        success: false,

        message:
          "Unable to add customer.",

        error:
          error.message,
      });
    }
  }
);


// ======================================================
// UPDATE CUSTOMER
// ======================================================

app.put(
  "/api/customers/:id",
  authenticateToken,
  loadAccessContext,
  requirePermission("customersEdit"),
  async (req, res) => {

    try {

    const {
  name,
  mobile,
  route,
  isActive,
} = req.body;


      const customer =
        await Customer.findOne({
          _id:
            req.params.id,

          farmId:
            req.access.farmId,
        });


      if (!customer) {
        return res.status(404).json({
          success: false,
          message:
            "Customer not found.",
        });
      }


      if (req.access.isSalesman) {
        // Customer must belong to one of salesman's assigned active routes
        const currentSalesmanRoute = await RouteMaster.findOne({
          farmId: req.access.farmId,
          salesmanId: req.access.salesmanId,
          isActive: true,
          $or: [
            { routeName: customer.route },
            { routeId: customer.route },
          ],
        });

        if (!currentSalesmanRoute) {
          return res.status(403).json({
            success: false,
            message: "You can only edit customers belonging to your assigned routes.",
          });
        }

        // If route is changed, target route must also belong to this salesman
        if (route !== undefined && route.trim()) {
          const targetRoute = await RouteMaster.findOne({
            farmId: req.access.farmId,
            salesmanId: req.access.salesmanId,
            isActive: true,
            $or: [
              { routeName: route.trim() },
              { routeId: route.trim().toUpperCase() },
            ],
          });

          if (!targetRoute) {
            return res.status(403).json({
              success: false,
              message: "You can only assign customers to your assigned routes.",
            });
          }
        }
      }


      if (name !== undefined)
        customer.name = name.trim();

      if (mobile !== undefined)
        customer.mobile =
          mobile.toString().trim();

      if (route !== undefined)
        customer.route =
          route.trim();

   

      if (isActive !== undefined)
        customer.isActive =
          isActive;

      customer.updatedAt =
        new Date();


      await customer.save();


      return res.status(200).json({
        success:
          true,

        message:
          "Customer updated successfully.",

        data:
          customer,
      });

    } catch (error) {

      console.error(
        "UPDATE CUSTOMER ERROR:",
        error
      );


      return res.status(500).json({
        success: false,
        message:
          "Unable to update customer.",
      });
    }
  }
);


// ======================================================
// DELETE CUSTOMER
// ======================================================
// ======================================================
// DELETE CUSTOMER
// ADMIN ONLY
// SAFE DELETE
// ======================================================

app.delete(
  "/api/customers/:id",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;


      // ==================================================
      // FIND CUSTOMER FIRST
      // ==================================================

      const customer =
        await Customer.findOne({
          _id:
            req.params.id,

          farmId:
            farmId,
        });


      if (!customer) {
        return res.status(404).json({
          success: false,

          message:
            "Customer not found.",
        });
      }


      const customerId =
        (
          customer.customerId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      // ==================================================
      // CHECK SALE HISTORY
      // ==================================================

      const usedInSale =
        await Sale.exists({
          farmId,

          customerId,
        });


      // ==================================================
      // CHECK COLLECTION HISTORY
      // ==================================================

      const usedInCollection =
        await Collection.exists({
          farmId,

          customerId,
        });


      // ==================================================
      // CHECK MANUAL OUTSTANDING HISTORY
      // ==================================================

      const usedInManualOutstanding =
        await CustomerOutstanding.exists({
          farmId,

          customerId,
        });


      // ==================================================
      // CHECK CUSTOMER SPECIAL RATE
      // ==================================================

      const usedInCustomerRate =
        await CustomerRate.exists({
          farmId,

          customerId,
        });


      // ==================================================
      // BLOCK DELETE IF CUSTOMER HAS HISTORY
      // ==================================================

      if (
        usedInSale ||
        usedInCollection ||
        usedInManualOutstanding ||
        usedInCustomerRate
      ) {
        return res.status(409).json({
          success: false,

          message:
            "This customer has transaction/history records and cannot be deleted. Please make the customer inactive instead.",
        });
      }


      // ==================================================
      // SAFE DELETE
      // ==================================================

      await Customer.deleteOne({
        _id:
          customer._id,

        farmId:
          farmId,
      });


      return res.status(200).json({
        success: true,

        message:
          "Customer deleted successfully.",
      });

    } catch (error) {
      console.error(
        "DELETE CUSTOMER ERROR:",
        error
      );


      return res.status(500).json({
        success: false,

        message:
          "Unable to delete customer.",

        error:
          error.message,
      });
    }
  }
);
// ======================================================
// GET SALESMEN FOR CURRENT FARM
// ======================================================

// ======================================================
// GET ALL SALESMEN FOR CURRENT FARM
// ADMIN SALESMAN MANAGEMENT
// ======================================================

app.get(
  "/api/salesmen",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {

    try {

      const farmId =
        req.access.farmId;


      const salesmen =
        await Salesman.find({
          farmId:
            farmId,
        })
          .select(
            "_id role farmId salesmanId name mobile email username businessName permissions permissionMode isActive createdAt"
          )
          .sort({
            name: 1,
          });


      const farmAdmin = await Register.findOne({
        farmId: farmId,
        isActive: true,
      }).select("salesmanDefaultPermissions").lean();


      // ==================================================
      // ADD ASSIGNED ROUTE INFORMATION
      // ==================================================

      const data =
        await Promise.all(
          salesmen.map(
            async (salesman) => {

              const route =
                await RouteMaster.findOne({
                  farmId:
                    farmId,

                  salesmanId:
                    salesman.salesmanId,
                })
                  .select(
                    "routeId routeName"
                  )
                  .lean();

              const effectivePermissions = getEffectiveSalesmanPermissions(
                salesman,
                farmAdmin
              );

              return {
                _id:
                  salesman._id,

                role:
                  salesman.role,

                farmId:
                  salesman.farmId,

                salesmanId:
                  salesman.salesmanId,

                name:
                  salesman.name,

                mobile:
                  salesman.mobile,

                email:
                  salesman.email,

                username:
                  salesman.username,

                businessName:
                  salesman.businessName,

                permissionMode:
                  salesman.permissionMode ||
                  (Array.isArray(salesman.permissions) && salesman.permissions.length > 0
                    ? "custom"
                    : "inherit"),

                permissions:
                  effectivePermissions,

                customPermissions:
                  Array.isArray(salesman.permissions)
                    ? salesman.permissions
                    : [],

                isActive:
                  salesman.isActive,

                routeId:
                  route?.routeId || "",

                routeName:
                  route?.routeName || "",

                createdAt:
                  salesman.createdAt,
              };
            }
          )
        );


      return res.status(200).json({
        success:
          true,

        count:
          data.length,

        data:
          data,
      });

    } catch (error) {

      console.error(
        "GET SALESMEN ERROR:",
        error
      );


      return res.status(500).json({
        success:
          false,

        message:
          "Unable to load salesmen.",

        error:
          error.message,
      });
    }
  }
);
// ======================================================
// GET SINGLE SALESMAN
// ======================================================

app.get(
  "/api/salesmen/:salesmanId",
  authenticateToken,
  loadAccessContext,
  async (req, res) => {

    try {

      const farmId =
        req.access.farmId;

      const salesmanId =
        req.params.salesmanId
          .toString()
          .trim()
          .toUpperCase();


      if (req.access.isSalesman && salesmanId !== req.access.salesmanId) {
        return res.status(403).json({
          success: false,
          message: "You are not authorized to view another salesman's details.",
        });
      }


      const salesman =
        await Salesman.findOne({
          farmId:
            farmId,

          salesmanId:
            salesmanId,
        })
          .select(
            "_id role farmId salesmanId name mobile email username businessName permissions permissionMode isActive createdAt"
          );


      if (!salesman) {

        return res.status(404).json({
          success:
            false,

          message:
            "Salesman not found.",
        });
      }


      const route =
        await RouteMaster.findOne({
          farmId:
            farmId,

          salesmanId:
            salesman.salesmanId,
        })
          .select(
            "routeId routeName"
          )
          .lean();

      const farmAdmin = await Register.findOne({
        farmId: farmId,
        isActive: true,
      }).select("salesmanDefaultPermissions").lean();

      const effectivePermissions = getEffectiveSalesmanPermissions(
        salesman,
        farmAdmin
      );

      return res.status(200).json({
        success:
          true,

        data: {
          _id:
            salesman._id,

          role:
            salesman.role,

          farmId:
            salesman.farmId,

          salesmanId:
            salesman.salesmanId,

          name:
            salesman.name,

          mobile:
            salesman.mobile,

          email:
            salesman.email,

          username:
            salesman.username,

          businessName:
            salesman.businessName,

          permissionMode:
            salesman.permissionMode ||
            (Array.isArray(salesman.permissions) && salesman.permissions.length > 0
              ? "custom"
              : "inherit"),

          permissions:
            effectivePermissions,

          customPermissions:
            Array.isArray(salesman.permissions)
              ? salesman.permissions
              : [],

          isActive:
            salesman.isActive,

          routeId:
            route?.routeId || "",

          routeName:
            route?.routeName || "",

          createdAt:
            salesman.createdAt,
        },
      });

    } catch (error) {

      console.error(
        "GET SALESMAN ERROR:",
        error
      );


      return res.status(500).json({
        success:
          false,

        message:
          "Unable to load salesman.",

        error:
          error.message,
      });
    }
  }
);
// ======================================================
// UPDATE SALESMAN FEATURE ACCESS
// ADMIN ONLY
// ======================================================

app.put(
  "/api/salesmen/:salesmanId/permissions",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {

    try {

      const farmId =
        req.access.farmId;


      const salesmanId =
        req.params.salesmanId
          .toString()
          .trim()
          .toUpperCase();


      const {
        permissions,
        permissionMode,
      } = req.body;


      // ================================================
      // FIND SALESMAN INSIDE CURRENT FARM ONLY
      // ================================================

      const salesman =
        await Salesman.findOne({
          farmId:
            farmId,

          salesmanId:
            salesmanId,
        });


      if (!salesman) {

        return res.status(404).json({
          success:
            false,

          message:
            "Salesman not found.",
        });
      }


      if (permissionMode === "inherit") {
        salesman.permissionMode = "inherit";
      } else if (permissionMode === "custom" || Array.isArray(permissions)) {
        salesman.permissionMode = "custom";

        if (!Array.isArray(permissions)) {
          return res.status(400).json({
            success: false,
            message: "Permissions must be an array for custom access.",
          });
        }

        const normalizedPermissions = [
          ...new Set(
            permissions
              .map((permission) => permission?.toString().trim())
              .filter((permission) => Boolean(permission))
          ),
        ];

        const invalidPermissions = normalizedPermissions.filter(
          (permission) => !VALID_SALESMAN_PERMISSIONS.includes(permission)
        );

        if (invalidPermissions.length > 0) {
          return res.status(400).json({
            success: false,
            message: `Invalid permission: ${invalidPermissions.join(", ")}`,
          });
        }

        salesman.permissions = normalizedPermissions;
      }

      await salesman.save();

      const farmAdmin = await Register.findOne({
        farmId: farmId,
        isActive: true,
      }).select("salesmanDefaultPermissions").lean();

      const effectivePermissions = getEffectiveSalesmanPermissions(
        salesman,
        farmAdmin
      );

      return res.status(200).json({
        success:
          true,

        message:
          "Salesman feature access saved successfully.",

        data: {
          salesmanId:
            salesman.salesmanId,

          name:
            salesman.name,

          permissionMode:
            salesman.permissionMode,

          permissions:
            effectivePermissions,

          customPermissions:
            Array.isArray(salesman.permissions) ? salesman.permissions : [],

          isActive:
            salesman.isActive,
        },
      });


    } catch (error) {

      console.error(
        "UPDATE SALESMAN PERMISSIONS ERROR:",
        error
      );


      return res.status(500).json({
        success:
          false,

        message:
          "Unable to save salesman feature access.",

        error:
          error.message,
      });
    }
  }
);


// ======================================================
// COMMON SALESMAN ACCESS SETTINGS (ADMIN ONLY)
// ======================================================

app.get(
  "/api/settings/salesman-permissions",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const farmId = req.access.farmId;

      const farmAdmin = await Register.findOne({
        farmId: farmId,
        isActive: true,
      }).select("salesmanDefaultPermissions").lean();

      if (!farmAdmin) {
        return res.status(404).json({
          success: false,
          message: "Farm registration not found.",
        });
      }

      return res.status(200).json({
        success: true,
        data: {
          permissions: Array.isArray(farmAdmin.salesmanDefaultPermissions)
            ? farmAdmin.salesmanDefaultPermissions
            : [],
        },
      });
    } catch (error) {
      console.error("GET COMMON SALESMAN PERMISSIONS ERROR:", error);
      return res.status(500).json({
        success: false,
        message: "Unable to load common salesman permissions.",
        error: error.message,
      });
    }
  }
);

app.put(
  "/api/settings/salesman-permissions",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const farmId = req.access.farmId;
      const { permissions } = req.body;

      if (!Array.isArray(permissions)) {
        return res.status(400).json({
          success: false,
          message: "Permissions must be an array.",
        });
      }

      const normalizedPermissions = [
        ...new Set(
          permissions
            .map((p) => p?.toString().trim())
            .filter((p) => Boolean(p))
        ),
      ];

      const invalidPermissions = normalizedPermissions.filter(
        (p) => !VALID_SALESMAN_PERMISSIONS.includes(p)
      );

      if (invalidPermissions.length > 0) {
        return res.status(400).json({
          success: false,
          message: `Invalid permission: ${invalidPermissions.join(", ")}`,
        });
      }

      const updatedFarm = await Register.findOneAndUpdate(
        { farmId: farmId, isActive: true },
        { $set: { salesmanDefaultPermissions: normalizedPermissions } },
        { new: true }
      ).select("salesmanDefaultPermissions").lean();

      if (!updatedFarm) {
        return res.status(404).json({
          success: false,
          message: "Farm registration not found.",
        });
      }

      return res.status(200).json({
        success: true,
        message: "Common salesman permissions saved successfully.",
        data: {
          permissions: updatedFarm.salesmanDefaultPermissions || [],
        },
      });
    } catch (error) {
      console.error("UPDATE COMMON SALESMAN PERMISSIONS ERROR:", error);
      return res.status(500).json({
        success: false,
        message: "Unable to save common salesman permissions.",
        error: error.message,
      });
    }
  }
);

// ======================================================
// GET ROUTES
// ======================================================

app.get(
  "/api/routes",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission(
    "routesView",
    "customersCreate",
    "customersEdit",
    "allocationView",
    "salesCreate",
    "customersView"
  ),
  async (req, res) => {
    try {
      const routeFilter = {
        farmId: req.user.farmId,
      };

      if (req.access && req.access.isSalesman) {
        routeFilter.salesmanId = req.access.salesmanId;
        routeFilter.isActive = true;
      }

      const routes =
        await RouteMaster.find(routeFilter)
          .sort({
            createdAt: -1,
          });

      return res.status(200).json({
        success: true,
        count: routes.length,
        data: routes,
      });

    } catch (error) {
      console.error(
        "GET ROUTES ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load routes.",
      });
    }
  }
);
// ======================================================
// ADD ROUTE
// ======================================================

app.post(
  "/api/routes",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const {
        routeName,
        areas,
        salesmanId,
        isActive,
      } = req.body;


      if (
        !routeName ||
        !routeName.trim()
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Route name is required.",
        });
      }


      if (
        !Array.isArray(areas) ||
        areas.length === 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Please enter at least one area.",
        });
      }


      if (
        !salesmanId ||
        !salesmanId.trim()
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Please select a salesman.",
        });
      }


      const farmId =
        req.user.farmId;


      // Check duplicate route in same farm
      const existingRoute =
        await RouteMaster.findOne({
          farmId: farmId,

          routeName: {
            $regex: new RegExp(
              `^${escapeRegex(
                routeName.trim()
              )}$`,
              "i"
            ),
          },
        });


      if (existingRoute) {
        return res.status(409).json({
          success: false,
          message:
            "Route already exists.",
        });
      }


      // Check salesman belongs to same farm
      const salesman =
        await Salesman.findOne({
          farmId: farmId,

          salesmanId:
            salesmanId
              .trim()
              .toUpperCase(),

          isActive: true,
        });


      if (!salesman) {
        return res.status(404).json({
          success: false,
          message:
            "Selected salesman not found.",
        });
      }


      const routeId =
        await generateRouteId();


      const route =
        await RouteMaster.create({
          farmId: farmId,

          routeId: routeId,

          routeName:
            routeName.trim(),

          areas: areas
            .map((area) =>
              area.toString().trim()
            )
            .filter((area) =>
              area.length > 0
            ),

          salesmanId:
            salesman.salesmanId,

          salesmanName:
            salesman.name,

          isActive:
            isActive !== false,

          createdBy:
            req.user.userId,
        });


      return res.status(201).json({
        success: true,

        message:
          "Route added successfully.",

        data: route,
      });

    } catch (error) {
      console.error(
        "ADD ROUTE ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to add route.",
        error:
          error.message,
      });
    }
  }
);
// ======================================================
// UPDATE ROUTE
// ======================================================

app.put(
  "/api/routes/:id",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const {
        routeName,
        areas,
        salesmanId,
        isActive,
      } = req.body;


      const route =
        await RouteMaster.findOne({
          _id: req.params.id,
          farmId: req.user.farmId,
        });

      const oldRouteName =
        route ? route.routeName : "";

      if (!route) {
        return res.status(404).json({
          success: false,
          message:
            "Route not found.",
        });
      }


      if (
        routeName !== undefined &&
        routeName.trim()
      ) {
        route.routeName =
          routeName.trim();
      }


      if (
        Array.isArray(areas)
      ) {
        route.areas =
          areas
            .map((area) =>
              area.toString().trim()
            )
            .filter((area) =>
              area.length > 0
            );
      }


      if (salesmanId) {
        const salesman =
          await Salesman.findOne({
            farmId:
              req.user.farmId,

            salesmanId:
              salesmanId
                .trim()
                .toUpperCase(),

            isActive: true,
          });


        if (!salesman) {
          return res.status(404).json({
            success: false,
            message:
              "Selected salesman not found.",
          });
        }


        route.salesmanId =
          salesman.salesmanId;

        route.salesmanName =
          salesman.name;
      }


      if (isActive !== undefined) {
        route.isActive =
          isActive;
      }


      route.updatedAt =
        new Date();


      await route.save();

      if (
        oldRouteName &&
        oldRouteName !==
        route.routeName
      ) {
        await Customer.updateMany(
          {
            farmId:
              req.user.farmId,

            route:
              oldRouteName,
          },
          {
            $set: {
              route:
                route.routeName,

              updatedAt:
                new Date(),
            },
          }
        );
      }
      return res.status(200).json({
        success: true,

        message:
          "Route updated successfully.",

        data: route,
      });

    } catch (error) {
      console.error(
        "UPDATE ROUTE ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to update route.",
      });
    }
  }
);

// ======================================================
// DELETE ROUTE
// ADMIN ONLY
// SAFE DELETE
// ======================================================

app.delete(
  "/api/routes/:id",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      // ==================================================
      // ADMIN ONLY
      // ==================================================

      if (req.user.role !== "admin") {
        return res.status(403).json({
          success: false,
          message:
            "Only administrator can delete routes.",
        });
      }

      const farmId =
        req.user.farmId;

      // ==================================================
      // FIND ROUTE
      // ==================================================

      const route =
        await RouteMaster.findOne({
          _id: req.params.id,
          farmId: farmId,
        });

      if (!route) {
        return res.status(404).json({
          success: false,
          message:
            "Route not found.",
        });
      }

      // ==================================================
      // CHECK CUSTOMERS
      //
      // Customers currently store route NAME.
      // ==================================================

      const customerUsingRoute =
        await Customer.exists({
          farmId: farmId,
          route: route.routeName,
        });

      if (customerUsingRoute) {
        return res.status(409).json({
          success: false,
          message:
            "This route is assigned to customers. Reassign those customers before deleting the route.",
        });
      }

      // ==================================================
      // CHECK ALLOCATION HISTORY
      // ==================================================

      const allocationUsingRoute =
        await Allocation.exists({
          farmId: farmId,
          $or: [
            {
              routeId:
                route.routeId,
            },
            {
              routeName:
                route.routeName,
            },
          ],
        });

      if (allocationUsingRoute) {
        return res.status(409).json({
          success: false,
          message:
            "This route has allocation history and cannot be deleted. Please make the route inactive instead.",
        });
      }

      // ==================================================
      // DELETE
      // ==================================================

      await RouteMaster.deleteOne({
        _id: route._id,
        farmId: farmId,
      });

      return res.status(200).json({
        success: true,
        message:
          "Route deleted successfully.",
      });

    } catch (error) {
      console.error(
        "DELETE ROUTE ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to delete route.",
        error:
          error.message,
      });
    }
  }
);
// ======================================================
// GET PRODUCTS
// ======================================================

app.get(
  "/api/products",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission(
    "productsView",
    "allocationView",
    "salesView",
    "salesCreate",
    "returnsManage",
    "purchaseView"
  ),
  async (req, res) => {
    try {
      const products =
        await Product.find({
          farmId:
            req.user.farmId,
        })
          .sort({
            createdAt:
              -1,
          });

      return res.status(200).json({
        success:
          true,

        count:
          products.length,

        data:
          products,
      });

    } catch (error) {

      console.error(
        "GET PRODUCTS ERROR:",
        error
      );

      return res.status(500).json({
        success:
          false,

        message:
          "Unable to load products.",
      });
    }
  }
);
// ======================================================
// ADD PRODUCT
// ======================================================

app.post(
  "/api/products",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const {
        productName,
        variant,
        category,
        unit,
        stock,
        price,
        lowStockLevel,
        assetPath,
        isActive,
      } = req.body;

      if (!productName || !productName.trim()) {
        return res.status(400).json({
          success: false,
          message: "Product name is required.",
        });
      }

      if (!unit || !unit.trim()) {
        return res.status(400).json({
          success: false,
          message: "Unit is required.",
        });
      }

      const farmId = req.user.farmId;

      // Duplicate product + variant only inside same farm
      const duplicate = await Product.findOne({
        farmId: farmId,
        productName: {
          $regex: new RegExp(
            `^${escapeRegex(productName.trim())}$`,
            "i"
          ),
        },
        variant: {
          $regex: new RegExp(
            `^${escapeRegex((variant || "").trim())}$`,
            "i"
          ),
        },
      });

      if (duplicate) {
        return res.status(409).json({
          success: false,
          message:
            "This product and variant already exists.",
        });
      }

      const productId =
        await generateProductId();

      const product =
        await Product.create({
          farmId: farmId,

          productId: productId,

          productName:
            productName.trim(),

          variant:
            (variant || "").trim(),

          category:
            (category || "Dairy").trim(),

          unit:
            unit.trim(),

          stock:
            Number(stock) || 0,

          price:
            Number(price) || 0,

          lowStockLevel:
            Number(lowStockLevel) || 20,

          assetPath:
            (assetPath || "").trim(),

          isActive:
            isActive !== false,

          createdBy:
            req.user.userId || "",
        });

      return res.status(201).json({
        success: true,
        message:
          "Product added successfully.",
        data: product,
      });

    } catch (error) {
      console.error(
        "ADD PRODUCT ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to add product.",
        error: error.message,
      });
    }
  }
);

// ======================================================
// UPDATE PRODUCT
// ======================================================

app.put(
  "/api/products/:id",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const {
        productName,
        variant,
        category,
        unit,
        stock,
        price,
        lowStockLevel,
        assetPath,
        isActive,
      } = req.body;

      const product =
        await Product.findOne({
          _id: req.params.id,
          farmId: req.user.farmId,
        });

      if (!product) {
        return res.status(404).json({
          success: false,
          message: "Product not found.",
        });
      }

      if (productName !== undefined) {
        product.productName =
          productName.trim();
      }

      if (variant !== undefined) {
        product.variant =
          variant.trim();
      }

      if (category !== undefined) {
        product.category =
          category.trim();
      }

      if (unit !== undefined) {
        product.unit =
          unit.trim();
      }

      if (stock !== undefined) {
        product.stock =
          Number(stock) || 0;
      }

      if (price !== undefined) {
        product.price =
          Number(price) || 0;
      }

      if (lowStockLevel !== undefined) {
        product.lowStockLevel =
          Number(lowStockLevel) || 20;
      }

      if (assetPath !== undefined) {
        product.assetPath =
          assetPath.trim();
      }

      if (isActive !== undefined) {
        product.isActive =
          isActive;
      }

      product.updatedAt =
        new Date();

      await product.save();

      return res.status(200).json({
        success: true,
        message:
          "Product updated successfully.",
        data: product,
      });

    } catch (error) {
      console.error(
        "UPDATE PRODUCT ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to update product.",
      });
    }
  }
);

// ======================================================
// DELETE PRODUCT
// ADMIN ONLY
// SAFE DELETE - BLOCK IF PRODUCT HAS HISTORY
// ======================================================

app.delete(
  "/api/products/:id",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      // ----------------------------------------------
      // ADMIN ONLY
      // ----------------------------------------------

      if (req.user.role !== "admin") {
        return res.status(403).json({
          success: false,
          message:
            "Only administrator can delete products.",
        });
      }

      const farmId =
        req.user.farmId;

      // ----------------------------------------------
      // FIND PRODUCT IN CURRENT FARM
      // ----------------------------------------------

      const product =
        await Product.findOne({
          _id: req.params.id,
          farmId: farmId,
        });

      if (!product) {
        return res.status(404).json({
          success: false,
          message:
            "Product not found.",
        });
      }

      // ----------------------------------------------
      // STOCK MUST BE ZERO
      // ----------------------------------------------

      if (
        Number(product.stock || 0) !== 0
      ) {
        return res.status(409).json({
          success: false,
          message:
            "Product has stock available. Make stock zero before deleting it.",
        });
      }

      const productId =
        product.productId;

      // ----------------------------------------------
      // CHECK SALES
      // ----------------------------------------------

      const usedInSale =
        await Sale.exists({
          farmId: farmId,
          "products.productId":
            productId,
        });

      // ----------------------------------------------
      // CHECK PURCHASES
      // ----------------------------------------------

      const usedInPurchase =
        await Purchase.exists({
          farmId: farmId,
          "products.productId":
            productId,
        });

      // ----------------------------------------------
      // CHECK STOCK LEDGER
      // ----------------------------------------------

      const usedInStock =
        await StockTransaction.exists({
          farmId: farmId,
          productId: productId,
        });

      // ----------------------------------------------
      // CHECK ALLOCATION
      // ----------------------------------------------

      const usedInAllocation =
        await Allocation.exists({
          farmId: farmId,
          "products.productId":
            productId,
        });

      // ----------------------------------------------
      // CHECK CUSTOMER SPECIAL RATE
      // ----------------------------------------------

      const usedInCustomerRate =
        await CustomerRate.exists({
          farmId: farmId,
          productId: productId,
        });

      // ----------------------------------------------
      // BLOCK USED PRODUCT
      // ----------------------------------------------

      if (
        usedInSale ||
        usedInPurchase ||
        usedInStock ||
        usedInAllocation ||
        usedInCustomerRate
      ) {
        return res.status(409).json({
          success: false,
          message:
            "This product has transaction/history records and cannot be deleted. Please make the product inactive instead.",
        });
      }

      // ----------------------------------------------
      // DELETE UNUSED PRODUCT
      // ----------------------------------------------

      await Product.deleteOne({
        _id: product._id,
        farmId: farmId,
      });

      return res.status(200).json({
        success: true,
        message:
          "Product deleted successfully.",
      });

    } catch (error) {
      console.error(
        "DELETE PRODUCT ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to delete product.",
        error:
          error.message,
      });
    }
  }
);
// ======================================================
// GET SUPPLIERS
// ======================================================

app.get(
  "/api/suppliers",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission("suppliersView", "purchaseView"),
  async (req, res) => {
    try {
      const suppliers =
        await Supplier.find({
          farmId: req.user.farmId,
        }).sort({
          supplierName: 1,
        });

      return res.status(200).json({
        success: true,
        count: suppliers.length,
        data: suppliers,
      });

    } catch (error) {
      console.error(
        "GET SUPPLIERS ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load suppliers.",
      });
    }
  }
);

// ======================================================
// ADD SUPPLIER
// ======================================================

app.post(
  "/api/suppliers",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const {
        supplierName,
        mobile,
        email,
        address,
        gstNo,
        openingBalance,
        isActive,
      } = req.body;

      if (
        !supplierName ||
        !supplierName.trim()
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Supplier name is required.",
        });
      }

      const farmId =
        req.user.farmId;

      const duplicate =
        await Supplier.findOne({
          farmId,
          supplierName: {
            $regex: new RegExp(
              `^${escapeRegex(
                supplierName.trim()
              )}$`,
              "i"
            ),
          },
        });

      if (duplicate) {
        return res.status(409).json({
          success: false,
          message:
            "Supplier already exists.",
        });
      }

      const supplierId =
        await generateSupplierId();

      const supplier =
        await Supplier.create({
          farmId,

          supplierId,

          supplierName:
            supplierName.trim(),

          mobile:
            (mobile || "").trim(),

          email:
            (email || "").trim(),

          address:
            (address || "").trim(),

          gstNo:
            (gstNo || "")
              .trim()
              .toUpperCase(),

          openingBalance:
            Number(openingBalance) || 0,

          isActive:
            isActive !== false,

          createdBy:
            req.user.userId || "",
        });

      return res.status(201).json({
        success: true,
        message:
          "Supplier added successfully.",
        data: supplier,
      });

    } catch (error) {
      console.error(
        "ADD SUPPLIER ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to add supplier.",
      });
    }
  }
);

// ======================================================
// UPDATE SUPPLIER
// ======================================================

app.put(
  "/api/suppliers/:id",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const supplier =
        await Supplier.findOne({
          _id: req.params.id,
          farmId: req.user.farmId,
        });

      if (!supplier) {
        return res.status(404).json({
          success: false,
          message:
            "Supplier not found.",
        });
      }

      const {
        supplierName,
        mobile,
        email,
        address,
        gstNo,
        openingBalance,
        isActive,
      } = req.body;

      if (supplierName !== undefined) {
        supplier.supplierName =
          supplierName.trim();
      }

      if (mobile !== undefined) {
        supplier.mobile =
          mobile.trim();
      }

      if (email !== undefined) {
        supplier.email =
          email.trim();
      }

      if (address !== undefined) {
        supplier.address =
          address.trim();
      }

      if (gstNo !== undefined) {
        supplier.gstNo =
          gstNo
            .trim()
            .toUpperCase();
      }

      if (
        openingBalance !== undefined
      ) {
        supplier.openingBalance =
          Number(openingBalance) || 0;
      }

      if (isActive !== undefined) {
        supplier.isActive =
          isActive;
      }

      supplier.updatedAt =
        new Date();

      await supplier.save();

      return res.status(200).json({
        success: true,
        message:
          "Supplier updated successfully.",
        data: supplier,
      });

    } catch (error) {
      console.error(
        "UPDATE SUPPLIER ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to update supplier.",
      });
    }
  }
);

// ======================================================
// DELETE SUPPLIER
// ADMIN ONLY
// SAFE DELETE
// ======================================================

app.delete(
  "/api/suppliers/:id",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {

      // ==================================================
      // ADMIN ONLY
      // ==================================================

      if (req.user.role !== "admin") {
        return res.status(403).json({
          success: false,
          message:
            "Only administrator can delete suppliers.",
        });
      }

      const farmId =
        req.user.farmId;

      // ==================================================
      // FIND SUPPLIER IN CURRENT FARM
      // ==================================================

      const supplier =
        await Supplier.findOne({
          _id: req.params.id,
          farmId: farmId,
        });

      if (!supplier) {
        return res.status(404).json({
          success: false,
          message:
            "Supplier not found.",
        });
      }

      const supplierId =
        supplier.supplierId;

      // ==================================================
      // CHECK PURCHASE HISTORY
      // ==================================================

      const usedInPurchase =
        await Purchase.exists({
          farmId: farmId,
          supplierId: supplierId,
        });

      // ==================================================
      // CHECK PAYMENT HISTORY
      // ==================================================

      const usedInPayment =
        await Payment.exists({
          farmId: farmId,
          supplierId: supplierId,
        });

      // ==================================================
      // BLOCK DELETE IF TRANSACTION HISTORY EXISTS
      // ==================================================

      if (
        usedInPurchase ||
        usedInPayment
      ) {
        return res.status(409).json({
          success: false,
          message:
            "This supplier has purchase/payment history and cannot be deleted. Please make the supplier inactive instead.",
        });
      }

      // ==================================================
      // DELETE UNUSED SUPPLIER
      // ==================================================

      await Supplier.deleteOne({
        _id: supplier._id,
        farmId: farmId,
      });

      return res.status(200).json({
        success: true,
        message:
          "Supplier deleted successfully.",
      });

    } catch (error) {

      console.error(
        "DELETE SUPPLIER ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to delete supplier.",
        error:
          error.message,
      });
    }
  }
);
// ======================================================
// GET PURCHASES
// ======================================================

app.get(
  "/api/purchases",
  authenticateToken,
  loadAccessContext,
  requirePermission("purchaseView"),
  async (req, res) => {
    try {
      const purchases =
        await Purchase.find({
          farmId:
            req.user.farmId,
        }).sort({
          createdAt: -1,
        });

      return res.status(200).json({
        success: true,
        count:
          purchases.length,
        data:
          purchases,
      });

    } catch (error) {
      console.error(
        "GET PURCHASES ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load purchases.",
      });
    }
  }
);

// ======================================================
// ADD PURCHASE
// TRN_PURCHASE + STOCK IN
// ======================================================

// ======================================================
// ADD PURCHASE
// ATOMIC TRANSACTION:
// TRN_PURCHASE + MAS_PRODUCT STOCK + TRN_STOCK
// ======================================================

app.post(
  "/api/purchases",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {

    const session =
      await mongoose.startSession();

    try {
      let savedPurchase = null;

      await session.withTransaction(
        async () => {

          const {
            purchaseDate,
            supplierId,
            invoiceNo,
            billDate,
            paymentType,
            dueDate,
            godown,
            remarks,
            products,
            discount,
            taxPercentage,
          } = req.body;

          const farmId =
            req.user.farmId;

          // ============================================
          // VALIDATION
          // ============================================

          if (
            !supplierId ||
            !supplierId.trim()
          ) {
            const error =
              new Error(
                "Supplier is required."
              );

            error.statusCode = 400;

            throw error;
          }

          if (
            !Array.isArray(products) ||
            products.length === 0
          ) {
            const error =
              new Error(
                "Please add at least one product."
              );

            error.statusCode = 400;

            throw error;
          }

          // ============================================
          // VERIFY SUPPLIER
          // ============================================

          const supplier =
            await Supplier.findOne({
              farmId,

              supplierId:
                supplierId
                  .trim()
                  .toUpperCase(),

              isActive: true,
            }).session(session);

          if (!supplier) {
            const error =
              new Error(
                "Selected supplier not found."
              );

            error.statusCode = 404;

            throw error;
          }

          // ============================================
          // VERIFY PRODUCTS
          // ============================================

          const verifiedProducts = [];

          let totalQuantity = 0;
          let subTotal = 0;

          for (
            const line of products
          ) {
            const productId =
              line.productId
                ?.toString()
                .trim()
                .toUpperCase();

            const quantity =
              Number(line.quantity);

            const rate =
              Number(line.rate);

            if (
              !productId ||
              !Number.isFinite(quantity) ||
              quantity <= 0 ||
              !Number.isFinite(rate) ||
              rate < 0
            ) {
              const error =
                new Error(
                  "Invalid purchase product details."
                );

              error.statusCode = 400;

              throw error;
            }

            const product =
              await Product.findOne({
                farmId,
                productId,
                isActive: true,
              }).session(session);

            if (!product) {
              const error =
                new Error(
                  `Product ${productId} not found.`
                );

              error.statusCode = 404;

              throw error;
            }

            const amount =
              quantity * rate;

            verifiedProducts.push({
              productId:
                product.productId,

              productName:
                product.productName,

              variant:
                product.variant || "",

              unit:
                product.unit,

              quantity,

              rate,

              amount,
            });

            totalQuantity +=
              quantity;

            subTotal +=
              amount;
          }

          // ============================================
          // TOTALS
          // ============================================

          const discountValue =
            Math.max(
              0,
              Number(discount) || 0
            );

          const taxPercentageValue =
            Math.max(
              0,
              Number(taxPercentage) || 0
            );

          const taxableAmount =
            Math.max(
              0,
              subTotal -
              discountValue
            );

          const taxAmount =
            taxableAmount *
            taxPercentageValue /
            100;

          const grandTotal =
            taxableAmount +
            taxAmount;

          // ============================================
          // IDS
          // ============================================

          const purchaseId =
            await generatePurchaseId();

          const purchaseNo =
            await generatePurchaseNo(
              farmId
            );

          // ============================================
          // CREATE PURCHASE
          // ============================================

          const purchaseDocs =
            await Purchase.create(
              [
                {
                  farmId,

                  purchaseId,
                  purchaseNo,

                  purchaseDate:
                    purchaseDate
                      ? new Date(
                        purchaseDate
                      )
                      : new Date(),

                  supplierId:
                    supplier.supplierId,

                  supplierName:
                    supplier.supplierName,

                  invoiceNo:
                    (invoiceNo || "")
                      .trim(),

                  billDate:
                    billDate
                      ? new Date(
                        billDate
                      )
                      : new Date(),

                  paymentType:
                    (
                      paymentType ||
                      "Credit"
                    ).trim(),

                  dueDate:
                    dueDate
                      ? new Date(
                        dueDate
                      )
                      : new Date(),

                  godown:
                    (
                      godown ||
                      "Main Godown"
                    ).trim(),

                  remarks:
                    (remarks || "")
                      .trim(),

                  products:
                    verifiedProducts,

                  totalQuantity,
                  subTotal,

                  discount:
                    discountValue,

                  taxPercentage:
                    taxPercentageValue,

                  taxAmount,
                  grandTotal,

                  status:
                    "POSTED",

                  createdBy:
                    req.user.userId ||
                    "",
                },
              ],
              {
                session,
              }
            );

          const purchase =
            purchaseDocs[0];

          // ============================================
          // STOCK IN
          // ============================================

          for (
            const line of
            verifiedProducts
          ) {
            const updateResult =
              await Product.updateOne(
                {
                  farmId,

                  productId:
                    line.productId,
                },
                {
                  $inc: {
                    stock:
                      line.quantity,
                  },

                  $set: {
                    updatedAt:
                      new Date(),
                  },
                },
                {
                  session,
                }
              );

            if (
              updateResult.matchedCount !== 1
            ) {
              throw new Error(
                `Unable to update stock for ${line.productName}.`
              );
            }

            const stockId =
              await generateStockId();

            await StockTransaction.create(
              [
                {
                  farmId,

                  stockId,

                  productId:
                    line.productId,

                  productName:
                    line.productName,

                  transactionType:
                    "PURCHASE",

                  referenceType:
                    "PURCHASE",

                  referenceId:
                    purchase.purchaseId,

                  referenceNo:
                    purchase.purchaseNo,

                  quantityIn:
                    line.quantity,

                  quantityOut:
                    0,

                  rate:
                    line.rate,

                  godown:
                    purchase.godown,

                  createdBy:
                    req.user.userId ||
                    "",
                },
              ],
              {
                session,
              }
            );
          }

          savedPurchase =
            purchase;
        }
      );

      return res.status(201).json({
        success: true,

        message:
          "Purchase saved successfully.",

        data:
          savedPurchase,
      });

    } catch (error) {

      console.error(
        "ADD PURCHASE ERROR:",
        error
      );

      return res
        .status(
          error.statusCode || 500
        )
        .json({
          success: false,

          message:
            error.message ||
            "Unable to save purchase.",
        });

    } finally {

      await session.endSession();

    }
  }
);
// ======================================================
// EDIT PURCHASE
// PUT /api/purchases/:id
//
// ATOMIC:
// 1. REVERSE OLD STOCK
// 2. VALIDATE NEW PURCHASE
// 3. ADD NEW STOCK
// 4. UPDATE PURCHASE
// 5. WRITE STOCK LEDGER
// ======================================================

app.put(
  "/api/purchases/:id",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {

    const session =
      await mongoose.startSession();

    try {

      let updatedPurchase = null;

      await session.withTransaction(
        async () => {

          const farmId =
            req.user.farmId;

          const userId =
            req.user.userId || "";

          // ============================================
          // FIND EXISTING PURCHASE
          // ============================================

          const purchase =
            await Purchase.findOne({
              _id: req.params.id,
              farmId,
            }).session(session);

          if (!purchase) {
            const error =
              new Error(
                "Purchase not found."
              );

            error.statusCode = 404;
            throw error;
          }

          // ============================================
          // CANCELLED PURCHASE CANNOT BE EDITED
          // ============================================

          if (
            purchase.status ===
            "CANCELLED"
          ) {
            const error =
              new Error(
                "Cancelled purchase cannot be edited."
              );

            error.statusCode = 400;
            throw error;
          }

          const {
            purchaseDate,
            supplierId,
            invoiceNo,
            billDate,
            paymentType,
            dueDate,
            godown,
            remarks,
            products,
            discount,
            taxPercentage,
          } = req.body;

          // ============================================
          // BASIC VALIDATION
          // ============================================

          if (
            !supplierId ||
            !supplierId
              .toString()
              .trim()
          ) {
            const error =
              new Error(
                "Supplier is required."
              );

            error.statusCode = 400;
            throw error;
          }

          if (
            !Array.isArray(products) ||
            products.length === 0
          ) {
            const error =
              new Error(
                "Please add at least one product."
              );

            error.statusCode = 400;
            throw error;
          }

          // ============================================
          // CHECK OLD PURCHASE STOCK CAN BE REVERSED
          // ============================================

          for (
            const oldLine of
            purchase.products
          ) {

            const product =
              await Product.findOne({
                farmId,
                productId:
                  oldLine.productId,
              }).session(session);

            if (!product) {
              const error =
                new Error(
                  `Product ${oldLine.productId} not found.`
                );

              error.statusCode = 404;
              throw error;
            }

            const currentStock =
              Number(product.stock) ||
              0;

            const oldQuantity =
              Number(
                oldLine.quantity
              ) || 0;

            if (
              currentStock <
              oldQuantity
            ) {
              const error =
                new Error(
                  `Cannot edit purchase. Available stock for ${product.productName} is ${currentStock}, but old purchase quantity is ${oldQuantity}.`
                );

              error.statusCode = 400;
              throw error;
            }
          }

          // ============================================
          // REVERSE OLD PURCHASE STOCK
          // ============================================

          for (
            const oldLine of
            purchase.products
          ) {

            const oldQty =
              Number(
                oldLine.quantity
              ) || 0;

            const result =
              await Product.updateOne(
                {
                  farmId,
                  productId:
                    oldLine.productId,

                  stock: {
                    $gte: oldQty,
                  },
                },
                {
                  $inc: {
                    stock:
                      -oldQty,
                  },

                  $set: {
                    updatedAt:
                      new Date(),
                  },
                },
                {
                  session,
                }
              );

            if (
              result.modifiedCount !==
              1
            ) {
              const error =
                new Error(
                  `Unable to reverse old stock for ${oldLine.productName}.`
                );

              error.statusCode = 409;
              throw error;
            }

            // ------------------------------------------
            // STOCK LEDGER - OLD STOCK REVERSE
            // ------------------------------------------

            const stockId =
              await generateStockId();

            await StockTransaction.create(
              [
                {
                  farmId,

                  stockId,

                  productId:
                    oldLine.productId,

                  productName:
                    oldLine.productName,

                  transactionType:
                    "PURCHASE_EDIT_REVERSE",

                  referenceType:
                    "PURCHASE",

                  referenceId:
                    purchase.purchaseId,

                  referenceNo:
                    purchase.purchaseNo,

                  quantityIn: 0,

                  quantityOut:
                    oldQty,

                  rate:
                    Number(
                      oldLine.rate
                    ) || 0,

                  godown:
                    purchase.godown,

                  createdBy:
                    userId,
                },
              ],
              {
                session,
              }
            );
          }

          // ============================================
          // VERIFY SUPPLIER
          // ============================================

          const normalizedSupplierId =
            supplierId
              .toString()
              .trim()
              .toUpperCase();

          const supplier =
            await Supplier.findOne({
              farmId,

              supplierId:
                normalizedSupplierId,

              isActive: true,
            }).session(session);

          if (!supplier) {
            const error =
              new Error(
                "Selected supplier not found."
              );

            error.statusCode = 404;
            throw error;
          }

          // ============================================
          // VERIFY NEW PRODUCTS
          // ============================================

          const verifiedProducts = [];

          let totalQuantity = 0;
          let subTotal = 0;

          const receivedProductIds =
            new Set();

          for (
            const line of products
          ) {

            const productId =
              line.productId
                ?.toString()
                .trim()
                .toUpperCase();

            const quantity =
              Number(
                line.quantity
              );

            const rate =
              Number(
                line.rate
              );

            if (!productId) {
              const error =
                new Error(
                  "Invalid product."
                );

              error.statusCode = 400;
              throw error;
            }

            if (
              receivedProductIds.has(
                productId
              )
            ) {
              const error =
                new Error(
                  `Product ${productId} is repeated in this purchase.`
                );

              error.statusCode = 400;
              throw error;
            }

            receivedProductIds.add(
              productId
            );

            if (
              !Number.isFinite(
                quantity
              ) ||
              quantity <= 0
            ) {
              const error =
                new Error(
                  `Invalid quantity for ${productId}.`
                );

              error.statusCode = 400;
              throw error;
            }

            if (
              !Number.isFinite(rate) ||
              rate < 0
            ) {
              const error =
                new Error(
                  `Invalid rate for ${productId}.`
                );

              error.statusCode = 400;
              throw error;
            }

            const product =
              await Product.findOne({
                farmId,
                productId,
                isActive: true,
              }).session(session);

            if (!product) {
              const error =
                new Error(
                  `Product ${productId} not found.`
                );

              error.statusCode = 404;
              throw error;
            }

            const amount =
              quantity * rate;

            verifiedProducts.push({
              productId:
                product.productId,

              productName:
                product.productName,

              variant:
                product.variant || "",

              unit:
                product.unit,

              quantity,

              rate,

              amount,
            });

            totalQuantity +=
              quantity;

            subTotal +=
              amount;
          }

          // ============================================
          // RECALCULATE TOTALS
          // ============================================

          const discountValue =
            Math.max(
              0,
              Number(discount) || 0
            );

          const taxPercentageValue =
            Math.max(
              0,
              Number(
                taxPercentage
              ) || 0
            );

          const taxableAmount =
            Math.max(
              0,
              subTotal -
              discountValue
            );

          const taxAmount =
            taxableAmount *
            taxPercentageValue /
            100;

          const grandTotal =
            taxableAmount +
            taxAmount;

          // ============================================
          // ADD NEW STOCK
          // ============================================

          for (
            const newLine of
            verifiedProducts
          ) {

            const result =
              await Product.updateOne(
                {
                  farmId,

                  productId:
                    newLine.productId,
                },
                {
                  $inc: {
                    stock:
                      newLine.quantity,
                  },

                  $set: {
                    updatedAt:
                      new Date(),
                  },
                },
                {
                  session,
                }
              );

            if (
              result.matchedCount !==
              1
            ) {
              const error =
                new Error(
                  `Unable to add stock for ${newLine.productName}.`
                );

              error.statusCode = 409;
              throw error;
            }

            // ------------------------------------------
            // STOCK LEDGER - NEW PURCHASE STOCK
            // ------------------------------------------

            const stockId =
              await generateStockId();

            await StockTransaction.create(
              [
                {
                  farmId,

                  stockId,

                  productId:
                    newLine.productId,

                  productName:
                    newLine.productName,

                  transactionType:
                    "PURCHASE_EDIT",

                  referenceType:
                    "PURCHASE",

                  referenceId:
                    purchase.purchaseId,

                  referenceNo:
                    purchase.purchaseNo,

                  quantityIn:
                    newLine.quantity,

                  quantityOut: 0,

                  rate:
                    newLine.rate,

                  godown:
                    (
                      godown ||
                      purchase.godown ||
                      "Main Godown"
                    ).trim(),

                  createdBy:
                    userId,
                },
              ],
              {
                session,
              }
            );
          }

          // ============================================
          // UPDATE PURCHASE
          // ============================================

          purchase.purchaseDate =
            purchaseDate
              ? new Date(
                purchaseDate
              )
              : purchase.purchaseDate;

          purchase.supplierId =
            supplier.supplierId;

          purchase.supplierName =
            supplier.supplierName;

          purchase.invoiceNo =
            (invoiceNo || "")
              .toString()
              .trim();

          purchase.billDate =
            billDate
              ? new Date(billDate)
              : purchase.billDate;

          purchase.paymentType =
            (
              paymentType ||
              "Credit"
            )
              .toString()
              .trim();

          purchase.dueDate =
            dueDate
              ? new Date(dueDate)
              : purchase.dueDate;

          purchase.godown =
            (
              godown ||
              "Main Godown"
            )
              .toString()
              .trim();

          purchase.remarks =
            (remarks || "")
              .toString()
              .trim();

          purchase.products =
            verifiedProducts;

          purchase.totalQuantity =
            totalQuantity;

          purchase.subTotal =
            subTotal;

          purchase.discount =
            discountValue;

          purchase.taxPercentage =
            taxPercentageValue;

          purchase.taxAmount =
            taxAmount;

          purchase.grandTotal =
            grandTotal;

          purchase.updatedAt =
            new Date();

          await purchase.save({
            session,
          });

          updatedPurchase =
            purchase;
        }
      );

      return res.status(200).json({
        success: true,

        message:
          "Purchase updated and stock recalculated successfully.",

        data:
          updatedPurchase,
      });

    } catch (error) {

      console.error(
        "EDIT PURCHASE ERROR:",
        error
      );

      return res
        .status(
          error.statusCode || 500
        )
        .json({
          success: false,

          message:
            error.message ||
            "Unable to update purchase.",
        });

    } finally {

      await session.endSession();

    }
  }
);
// ======================================================
// CANCEL PURCHASE
// STOCK REVERSAL
// ======================================================

// ======================================================
// CANCEL PURCHASE
// ATOMIC STOCK REVERSAL
// ======================================================

app.put(
  "/api/purchases/:id/cancel",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {

    const session =
      await mongoose.startSession();

    try {

      let cancelledPurchase = null;

      await session.withTransaction(
        async () => {

          const farmId =
            req.user.farmId;

          // ============================================
          // FIND PURCHASE
          // ============================================

          const purchase =
            await Purchase.findOne({
              _id:
                req.params.id,

              farmId,
            }).session(session);

          if (!purchase) {
            const error =
              new Error(
                "Purchase not found."
              );

            error.statusCode = 404;

            throw error;
          }

          if (
            purchase.status ===
            "CANCELLED"
          ) {
            const error =
              new Error(
                "Purchase is already cancelled."
              );

            error.statusCode = 400;

            throw error;
          }

          // ============================================
          // CHECK ALL STOCK FIRST
          // ============================================

          for (
            const line of
            purchase.products
          ) {
            const product =
              await Product.findOne({
                farmId,

                productId:
                  line.productId,
              }).session(session);

            if (!product) {
              const error =
                new Error(
                  `Product ${line.productId} not found.`
                );

              error.statusCode = 404;

              throw error;
            }

            if (
              Number(product.stock) <
              Number(line.quantity)
            ) {
              const error =
                new Error(
                  `Cannot cancel purchase. Available stock for ${product.productName} is lower than purchased quantity.`
                );

              error.statusCode = 400;

              throw error;
            }
          }

          // ============================================
          // REVERSE STOCK
          // ============================================

          for (
            const line of
            purchase.products
          ) {
            const updateResult =
              await Product.updateOne(
                {
                  farmId,

                  productId:
                    line.productId,

                  stock: {
                    $gte:
                      Number(
                        line.quantity
                      ),
                  },
                },
                {
                  $inc: {
                    stock:
                      -Number(
                        line.quantity
                      ),
                  },

                  $set: {
                    updatedAt:
                      new Date(),
                  },
                },
                {
                  session,
                }
              );

            if (
              updateResult.modifiedCount !== 1
            ) {
              const error =
                new Error(
                  `Unable to reverse stock for ${line.productName}.`
                );

              error.statusCode = 409;

              throw error;
            }

            const stockId =
              await generateStockId();

            await StockTransaction.create(
              [
                {
                  farmId,

                  stockId,

                  productId:
                    line.productId,

                  productName:
                    line.productName,

                  transactionType:
                    "PURCHASE_CANCEL",

                  referenceType:
                    "PURCHASE",

                  referenceId:
                    purchase.purchaseId,

                  referenceNo:
                    purchase.purchaseNo,

                  quantityIn:
                    0,

                  quantityOut:
                    Number(
                      line.quantity
                    ),

                  rate:
                    line.rate,

                  godown:
                    purchase.godown,

                  createdBy:
                    req.user.userId ||
                    "",
                },
              ],
              {
                session,
              }
            );
          }

          // ============================================
          // MARK PURCHASE CANCELLED
          // ============================================

          purchase.status =
            "CANCELLED";

          purchase.cancelledBy =
            req.user.userId ||
            "";

          purchase.cancelledAt =
            new Date();

          purchase.updatedAt =
            new Date();

          await purchase.save({
            session,
          });

          cancelledPurchase =
            purchase;
        }
      );

      return res.status(200).json({
        success: true,

        message:
          "Purchase cancelled and stock reversed successfully.",

        data:
          cancelledPurchase,
      });

    } catch (error) {

      console.error(
        "CANCEL PURCHASE ERROR:",
        error
      );

      return res
        .status(
          error.statusCode || 500
        )
        .json({
          success: false,

          message:
            error.message ||
            "Unable to cancel purchase.",
        });

    } finally {

      await session.endSession();

    }
  }
);
// ======================================================
// CUSTOMER RATE MASTER
// MAS_CUSTOMER_RATE
// ======================================================


// ======================================================
// GET CUSTOMER RATES
// GET /api/customer-rates/:customerId
// ======================================================

app.get(
  "/api/customer-rates/:customerId",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission("customerRatesManage", "salesCreate", "salesView"),
  async (req, res) => {
    try {
      const farmId = req.user.farmId;

      const customerId =
        req.params.customerId
          .toString()
          .trim()
          .toUpperCase();


      // ================================================
      // VERIFY CUSTOMER BELONGS TO CURRENT FARM
      // ================================================

      const customer = await Customer.findOne({
        farmId: farmId,
        customerId: customerId,
        isActive: true,
      });


      if (!customer) {
        return res.status(404).json({
          success: false,
          message: "Customer not found.",
        });
      }

      if (req.access && req.access.isSalesman) {
        const salesmanRoute = await RouteMaster.findOne({
          farmId: farmId,
          routeName: customer.route,
          salesmanId: req.access.salesmanId,
          isActive: true,
        });
        if (!salesmanRoute) {
          return res.status(403).json({
            success: false,
            message: "You can only view rates for customers on your assigned routes.",
          });
        }
      }


      // ================================================
      // LOAD ACTIVE PRODUCTS
      // ================================================

      const products = await Product.find({
        farmId: farmId,
        isActive: true,
      })
        .select(
          "_id productId productName variant category unit price stock isActive"
        )
        .sort({
          productName: 1,
        });


      // ================================================
      // LOAD SAVED CUSTOMER RATES
      // ================================================

      const savedRates = await CustomerRate.find({
        farmId: farmId,
        customerId: customerId,
        isActive: true,
      });


      const rateMap = new Map();

      for (const rate of savedRates) {
        rateMap.set(
          rate.productId,
          rate
        );
      }


      // ================================================
      // COMBINE PRODUCT + CUSTOMER RATE
      // ================================================

      const data = products.map((product) => {

        const savedRate =
          rateMap.get(product.productId);

        const defaultRate =
          Number(product.price) || 0;

        return {
          productMongoId:
            product._id,

          productId:
            product.productId,

          productName:
            product.productName,

          variant:
            product.variant || "",

          category:
            product.category || "",

          unit:
            product.unit,

          stock:
            Number(product.stock) || 0,

          defaultRate:
            defaultRate,

          specialRate:
            savedRate
              ? Number(savedRate.specialRate)
              : defaultRate,

          hasCustomRate:
            savedRate != null,

          customerRateId:
            savedRate
              ? savedRate._id
              : null,
        };
      });


      return res.status(200).json({
        success: true,

        customer: {
          id: customer._id,
          customerId:
            customer.customerId,
          customerName:
            customer.name,
        },

        count:
          data.length,

        data:
          data,
      });

    } catch (error) {

      console.error(
        "GET CUSTOMER RATES ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load customer rates.",
        error:
          error.message,
      });
    }
  }
);


// ======================================================
// SAVE CUSTOMER RATES
// POST /api/customer-rates
// ======================================================

app.post(
  "/api/customer-rates",
  authenticateToken,
  loadAccessContext,
  requirePermission("customerRatesManage"),
  async (req, res) => {
    try {

      const farmId =
        req.user.farmId;

      const {
        customerId,
        rates,
      } = req.body;


      // ================================================
      // VALIDATION
      // ================================================

      if (
        !customerId ||
        !customerId.toString().trim()
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Customer is required.",
        });
      }


      if (
        !Array.isArray(rates) ||
        rates.length === 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Please enter at least one product rate.",
        });
      }


      const normalizedCustomerId =
        customerId
          .toString()
          .trim()
          .toUpperCase();


      // ================================================
      // VERIFY CUSTOMER
      // ================================================

      const customer =
        await Customer.findOne({
          farmId: farmId,

          customerId:
            normalizedCustomerId,

          isActive: true,
        });


      if (!customer) {
        return res.status(404).json({
          success: false,
          message:
            "Selected customer not found.",
        });
      }

      if (req.access && req.access.isSalesman) {
        const salesmanRoute = await RouteMaster.findOne({
          farmId: farmId,
          routeName: customer.route,
          salesmanId: req.access.salesmanId,
          isActive: true,
        });
        if (!salesmanRoute) {
          return res.status(403).json({
            success: false,
            message: "You can only manage rates for customers on your assigned routes.",
          });
        }
      }


      let savedCount = 0;


      // ================================================
      // SAVE / UPDATE EACH PRODUCT RATE
      // ================================================

      for (const rateItem of rates) {

        const productId =
          rateItem.productId
            ?.toString()
            .trim()
            .toUpperCase();


        const specialRate =
          Number(
            rateItem.specialRate
          );


        if (!productId) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid product.",
          });
        }


        if (
          !Number.isFinite(specialRate) ||
          specialRate <= 0
        ) {
          return res.status(400).json({
            success: false,
            message:
              `Invalid rate for product ${productId}.`,
          });
        }


        // ==============================================
        // VERIFY PRODUCT FROM CURRENT FARM
        // NEVER TRUST PRODUCT NAME/RATE FROM FRONTEND
        // ==============================================

        const product =
          await Product.findOne({
            farmId: farmId,

            productId:
              productId,

            isActive: true,
          });


        if (!product) {
          return res.status(404).json({
            success: false,
            message:
              `Product ${productId} not found.`,
          });
        }


        const defaultRate =
          Number(product.price) || 0;


        // ==============================================
        // UPSERT CUSTOMER RATE
        // ==============================================

        await CustomerRate.findOneAndUpdate(
          {
            farmId:
              farmId,

            customerId:
              customer.customerId,

            productId:
              product.productId,
          },

          {
            $set: {
              customerName:
                customer.name,

              productName:
                product.productName,

              defaultRate:
                defaultRate,

              specialRate:
                specialRate,

              isActive:
                true,

              updatedBy:
                req.user.userId || "",

              updatedAt:
                new Date(),
            },

            $setOnInsert: {
              farmId:
                farmId,

              customerId:
                customer.customerId,

              productId:
                product.productId,

              createdBy:
                req.user.userId || "",

              createdAt:
                new Date(),
            },
          },

          {
            upsert: true,
            new: true,
            runValidators: true,
          }
        );


        savedCount++;
      }


      return res.status(200).json({
        success: true,

        message:
          "Customer rates saved successfully.",

        count:
          savedCount,
      });

    } catch (error) {

      console.error(
        "SAVE CUSTOMER RATES ERROR:",
        error
      );


      if (error.code === 11000) {
        return res.status(409).json({
          success: false,
          message:
            "Duplicate customer product rate detected.",
        });
      }


      return res.status(500).json({
        success: false,

        message:
          "Unable to save customer rates.",

        error:
          error.message,
      });
    }
  }
);

// ======================================================
// HELPER
// CHECK PREVIOUS UNSETTLED SALESMAN ALLOCATION
//
// Rule:
// A salesman cannot create a sale for a newer business
// date while an older allocation still has quantity that
// has not been sold or returned/reconciled.
//
// Remaining = Allocated - Sold - Returned
//
// Sales are consumed FIFO, same as GET /api/allocations.
// ======================================================

async function getPreviousPendingAllocation({
  farmId,
  salesmanId,
  businessDate,
  session = null,
}) {

  const normalizedSalesmanId =
    (salesmanId || "")
      .toString()
      .trim()
      .toUpperCase();

  if (!normalizedSalesmanId) {
    return null;
  }


  // ------------------------------------------------------
  // NORMALIZE CURRENT BUSINESS DATE
  // ------------------------------------------------------

  const currentDate =
    businessDate
      ? new Date(businessDate)
      : new Date();


  if (
    Number.isNaN(
      currentDate.getTime()
    )
  ) {

    const error =
      new Error(
        "Invalid sale date."
      );

    error.statusCode = 400;

    throw error;
  }


  const currentDayStart =
    new Date(currentDate);

  currentDayStart.setHours(
    0,
    0,
    0,
    0
  );


  // ------------------------------------------------------
  // LOAD ALL ACTIVE / RETURNED ALLOCATIONS
  // OLDEST FIRST
  // ------------------------------------------------------

  const allocationQuery =
    Allocation.find({

      farmId,

      salesmanId:
        normalizedSalesmanId,

      status: {
        $in: [
          "POSTED",
          "RETURNED",
        ],
      },

    })
      .sort({
        allocationDate: 1,
        createdAt: 1,
      })
      .lean();


  if (session) {
    allocationQuery.session(
      session
    );
  }


  const allocations =
    await allocationQuery;


  if (
    allocations.length === 0
  ) {
    return null;
  }


  // ------------------------------------------------------
  // LOAD ALL POSTED SALESMAN SALES
  //
  // We intentionally use the same FIFO logic as the
  // allocation API so calculated balances remain identical.
  // ------------------------------------------------------

  const salesQuery =
    Sale.find({

      farmId,

      salesmanId:
        normalizedSalesmanId,

      createdRole:
        "salesman",

      status:
        "POSTED",

    })
      .select(
        "products saleDate createdAt"
      )
      .sort({
        saleDate: 1,
        createdAt: 1,
      })
      .lean();


  if (session) {
    salesQuery.session(
      session
    );
  }


  const sales =
    await salesQuery;


  // ------------------------------------------------------
  // TOTAL SOLD PRODUCT-WISE
  // ------------------------------------------------------

  const remainingSoldMap =
    new Map();


  for (
    const sale of sales
  ) {

    const saleProducts =
      Array.isArray(
        sale.products
      )
        ? sale.products
        : [];


    for (
      const item of saleProducts
    ) {

      const productId =
        (
          item.productId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      if (!productId) {
        continue;
      }


      const quantity =
        Number(
          item.quantity
        ) || 0;


      remainingSoldMap.set(

        productId,

        (
          remainingSoldMap.get(
            productId
          ) || 0
        ) +
        quantity

      );
    }
  }


  // ------------------------------------------------------
  // CONSUME SALES AGAINST ALLOCATIONS FIFO
  // AND FIND AN OLDER ALLOCATION WITH PENDING STOCK
  // ------------------------------------------------------

  for (
    const allocation of allocations
  ) {

    const allocationDate =
      new Date(
        allocation.allocationDate ||
        allocation.createdAt
      );


    if (
      Number.isNaN(
        allocationDate.getTime()
      )
    ) {
      continue;
    }


    const allocationDay =
      new Date(
        allocationDate
      );

    allocationDay.setHours(
      0,
      0,
      0,
      0
    );


    const products =
      Array.isArray(
        allocation.products
      )
        ? allocation.products
        : [];


    for (
      const item of products
    ) {

      const productId =
        (
          item.productId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      if (!productId) {
        continue;
      }


      const allocatedQty =
        Number(
          item.quantity
        ) || 0;


      const returnedQty =
        Number(
          item.returnedQuantity
        ) || 0;


      const usableQty =
        Math.max(
          0,
          allocatedQty -
          returnedQty
        );


      const remainingSold =
        remainingSoldMap.get(
          productId
        ) || 0;


      const soldForAllocation =
        Math.min(
          usableQty,
          remainingSold
        );


      remainingSoldMap.set(

        productId,

        Math.max(
          0,
          remainingSold -
          soldForAllocation
        )

      );


      const remainingQty =
        Math.max(
          0,
          allocatedQty -
          returnedQty -
          soldForAllocation
        );


      // --------------------------------------------------
      // ONLY BLOCK IF ALLOCATION IS BEFORE CURRENT SALE DAY
      // --------------------------------------------------

      if (
        allocationDay <
        currentDayStart &&
        remainingQty >
        0.000001
      ) {

        return {

          allocationId:
            allocation
              .allocationId,

          allocationNo:
            allocation
              .allocationNo,

          allocationDate:
            allocation
              .allocationDate,

          salesmanId:
            allocation
              .salesmanId,

          salesmanName:
            allocation
              .salesmanName,

          productId,

          productName:
            item.productName ||
            productId,

          unit:
            item.unit || "",

          allocatedQty,

          soldQty:
            soldForAllocation,

          returnedQty,

          remainingQty,

        };
      }
    }
  }


  return null;
}

// ======================================================
// SALES
// TRN_SALE
// ======================================================


// ======================================================
// GET SALES
// ======================================================

// ======================================================
// GET SALES
//
// ADMIN    -> ALL SALES OF CURRENT FARM
// SALESMAN -> ONLY SALES CREATED BY LOGGED-IN SALESMAN
// ======================================================

app.get(
  "/api/sales",
  authenticateToken,
  loadAccessContext,
  requirePermission("salesView"),
  async (req, res) => {

    try {

      const farmId =
        req.user.farmId;

      const role =
        req.user.role;

      const userId =
        req.user.userId;


      // ==================================================
      // BASE FILTER
      // NEVER ALLOW SALES FROM ANOTHER FARM
      // ==================================================

      const filter = {
        farmId:
          farmId,
      };
      const customerId =
        (
          req.query.customerId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      if (customerId) {
        filter.customerId =
          customerId;
      }


      // ==================================================
      // SALESMAN
      // ONLY HIS OWN SALES
      // ==================================================

      if (role === "salesman") {

        filter.createdBy =
          userId;

        filter.createdRole =
          "salesman";
      }


      // ==================================================
      // ADMIN
      // NO EXTRA CREATEDBY FILTER
      // ADMIN CAN SEE ALL FARM SALES
      // ==================================================

      else if (role === "admin") {

        // Keep only farmId filter.
      }


      // ==================================================
      // UNKNOWN ROLE
      // ==================================================

      else {

        return res.status(403).json({
          success: false,
          message:
            "You are not allowed to view sales.",
        });
      }


      const sales =
        await Sale.find(
          filter
        )
          .sort({
            saleDate: -1,
            createdAt: -1,
          });


      return res.status(200).json({

        success: true,

        count:
          sales.length,

        data:
          sales,
      });


    } catch (error) {

      console.error(
        "GET SALES ERROR:",
        error
      );


      return res.status(500).json({

        success: false,

        message:
          "Unable to load sales.",

        error:
          error.message,
      });
    }
  }
);
// ======================================================
// ADD SALE
// ATOMIC TRANSACTION
//
// TRN_SALE
// + MAS_PRODUCT STOCK OUT
// + TRN_STOCK SALE
// ======================================================

// ======================================================
// ADD SALE
// ROLE AWARE STOCK LOGIC
//
// ADMIN
//   -> MAIN GODOWN STOCK
//
// SALESMAN
//   -> SALESMAN ALLOCATED STOCK
//   -> MAS_PRODUCT IS NOT REDUCED AGAIN
// ======================================================

app.post(
  "/api/sales",
  authenticateToken,
  loadAccessContext,
  requirePermission("salesCreate"),
  async (req, res) => {

    const session =
      await mongoose.startSession();

    try {

      let savedSale = null;

      await session.withTransaction(
        async () => {

          const farmId =
            req.user.farmId;

          const userId =
            req.user.userId;

          const role =
            req.user.role;


          // ======================================================
          // REAL STOCK SOURCE OF THIS SALE
          //
          // ADMIN SALE
          // -> MAIN GODOWN
          //
          // SALESMAN / MOBILE SALE
          // -> SALESMAN ALLOCATION
          // ======================================================

          const finalStockSource =
            role === "salesman"
              ? "SALESMAN_ALLOCATION"
              : "MAIN_GODOWN";


          if (
            role !== "admin" &&
            role !== "salesman"
          ) {

            const error =
              new Error(
                "You are not allowed to create sales."
              );

            error.statusCode = 403;

            throw error;
          }


          const {
            saleDate,
            customerId,
            paymentMode,
            payments,
            products,
            godown,
          } = req.body;


          // ==================================================
          // CUSTOMER VALIDATION
          // ==================================================

          if (
            !customerId ||
            !customerId
              .toString()
              .trim()
          ) {

            const error =
              new Error(
                "Customer is required."
              );

            error.statusCode = 400;

            throw error;
          }


          if (
            !Array.isArray(products) ||
            products.length === 0
          ) {

            const error =
              new Error(
                "Please add at least one product."
              );

            error.statusCode = 400;

            throw error;
          }


          const normalizedCustomerId =
            customerId
              .toString()
              .trim()
              .toUpperCase();


          // ==================================================
          // VERIFY CUSTOMER
          // ==================================================

          const customer =
            await Customer.findOne({
              farmId,
              customerId:
                normalizedCustomerId,
              isActive: true,
            }).session(session);


          if (!customer) {

            const error =
              new Error(
                "Selected customer not found."
              );

            error.statusCode = 404;

            throw error;
          }


          // ==================================================
          // SALESMAN CUSTOMER ROUTE SECURITY
          //
          // A salesman can sell only to customers belonging
          // to a route assigned to him.
          // ==================================================

          if (role === "salesman") {

            const currentSalesman =
              await Salesman.findOne({
                _id:
                  userId,

                farmId:
                  farmId,

                isActive:
                  true,
              })
                .session(session);


            if (!currentSalesman) {

              const error =
                new Error(
                  "Salesman account not found."
                );

              error.statusCode =
                404;

              throw error;
            }


            const customerRouteName =
              (
                customer.route ||
                ""
              )
                .toString()
                .trim();


            if (!customerRouteName) {

              const error =
                new Error(
                  `Customer ${customer.name} is not mapped to any route.`
                );

              error.statusCode =
                403;

              throw error;
            }


            const assignedRoute =
              await RouteMaster.findOne({
                farmId:
                  farmId,

                routeName:
                  customerRouteName,

                salesmanId:
                  currentSalesman.salesmanId,

                isActive:
                  true,
              })
                .session(session);


            if (!assignedRoute) {

              const error =
                new Error(
                  `Customer ${customer.name} does not belong to your assigned route.`
                );

              error.statusCode =
                403;

              throw error;
            }
          }



          // ==================================================
          // SALESMAN INFORMATION
          // ==================================================

          let salesman = null;

          if (role === "salesman") {

            salesman =
              await Salesman.findOne({
                _id:
                  userId,
                farmId:
                  farmId,
                isActive:
                  true,
              }).session(session);


            if (!salesman) {

              const error =
                new Error(
                  "Salesman account not found."
                );

              error.statusCode = 404;

              throw error;
            }
          }
          // ==================================================
          // BLOCK NEW SALE IF PREVIOUS ALLOCATION IS UNSETTLED
          //
          // Yesterday/older allocation must first be completely
          // sold/returned/reconciled before today's billing.
          // ==================================================

          if (
            role === "salesman"
          ) {

            const pendingAllocation =
              await getPreviousPendingAllocation({

                farmId,

                salesmanId:
                  salesman.salesmanId,

                businessDate:
                  saleDate ||
                  new Date(),

                session,

              });


            if (pendingAllocation) {

              const pendingDate =
                new Date(
                  pendingAllocation
                    .allocationDate
                );


              const formattedDate =
                Number.isNaN(
                  pendingDate.getTime()
                )
                  ? ""
                  : pendingDate
                    .toISOString()
                    .slice(
                      0,
                      10
                    );


              const error =
                new Error(
                  `Previous allocation is not settled. ` +
                  `${pendingAllocation.productName} has ` +
                  `${pendingAllocation.remainingQty} ` +
                  `${pendingAllocation.unit || ""} pending ` +
                  `from allocation ${pendingAllocation.allocationNo}` +
                  `${formattedDate ? ` dated ${formattedDate}` : ""}. ` +
                  `Please complete the allocation return/reconciliation before creating today's bill.`
                );


              error.statusCode =
                409;

              throw error;
            }
          }

          // ==================================================
          // BUILD SALESMAN STOCK MAP
          //
          // AVAILABLE =
          // ALLOCATED
          // - RETURNED
          // - POSTED SALESMAN SALES
          // ==================================================

          const salesmanStockMap =
            new Map();


          if (role === "salesman") {

            // ----------------------------------------------
            // LOAD SALESMAN ALLOCATIONS
            // ----------------------------------------------

            const allocations =
              await Allocation.find({
                farmId:
                  farmId,

                salesmanId:
                  salesman.salesmanId,

                status: {
                  $in: [
                    "POSTED",
                    "RETURNED",
                  ],
                },
              })
                .session(session)
                .lean();


            for (
              const allocation of
              allocations
            ) {

              const allocationProducts =
                Array.isArray(
                  allocation.products
                )
                  ? allocation.products
                  : [];


              for (
                const item of
                allocationProducts
              ) {

                const productId =
                  (
                    item.productId ||
                    ""
                  )
                    .toString()
                    .trim()
                    .toUpperCase();


                if (!productId) {
                  continue;
                }


                if (
                  !salesmanStockMap.has(
                    productId
                  )
                ) {

                  salesmanStockMap.set(
                    productId,
                    {
                      allocated: 0,
                      returned: 0,
                      sold: 0,
                      available: 0,
                    }
                  );
                }


                const stockRow =
                  salesmanStockMap.get(
                    productId
                  );


                stockRow.allocated +=
                  Number(
                    item.quantity
                  ) || 0;


                stockRow.returned +=
                  Number(
                    item.returnedQuantity
                  ) || 0;
              }
            }


            // ----------------------------------------------
            // LOAD EXISTING POSTED SALESMAN SALES
            // ----------------------------------------------

            const existingSales =
              await Sale.find({
                farmId:
                  farmId,

                status:
                  "POSTED",

                createdRole:
                  "salesman",

                $or: [
                  {
                    salesmanId:
                      salesman.salesmanId,
                  },
                  {
                    createdBy:
                      userId,
                  },
                ],
              })
                .session(session)
                .lean();


            for (
              const existingSale of
              existingSales
            ) {

              const saleProducts =
                Array.isArray(
                  existingSale.products
                )
                  ? existingSale.products
                  : [];


              for (
                const item of
                saleProducts
              ) {

                const productId =
                  (
                    item.productId ||
                    ""
                  )
                    .toString()
                    .trim()
                    .toUpperCase();


                if (!productId) {
                  continue;
                }


                if (
                  !salesmanStockMap.has(
                    productId
                  )
                ) {

                  salesmanStockMap.set(
                    productId,
                    {
                      allocated: 0,
                      returned: 0,
                      sold: 0,
                      available: 0,
                    }
                  );
                }


                const stockRow =
                  salesmanStockMap.get(
                    productId
                  );


                stockRow.sold +=
                  Number(
                    item.quantity
                  ) || 0;
              }
            }


            // ----------------------------------------------
            // CALCULATE AVAILABLE
            // ----------------------------------------------

            for (
              const stockRow of
              salesmanStockMap.values()
            ) {

              stockRow.available =
                stockRow.allocated -
                stockRow.returned -
                stockRow.sold;

              if (
                stockRow.available < 0
              ) {
                stockRow.available = 0;
              }
            }
          }


          // ==================================================
          // VERIFY PRODUCTS + RATES
          // ==================================================

          const verifiedProducts = [];

          let totalQuantity = 0;
          let grandTotal = 0;

          const receivedProductIds =
            new Set();


          for (
            const line of products
          ) {

            const productId =
              line.productId
                ?.toString()
                .trim()
                .toUpperCase();


            const quantity =
              Number(
                line.quantity
              );


            if (!productId) {

              const error =
                new Error(
                  "Invalid product."
                );

              error.statusCode = 400;

              throw error;
            }


            if (
              receivedProductIds.has(
                productId
              )
            ) {

              const error =
                new Error(
                  `Product ${productId} is repeated in this sale.`
                );

              error.statusCode = 400;

              throw error;
            }


            receivedProductIds.add(
              productId
            );


            if (
              !Number.isFinite(
                quantity
              ) ||
              quantity <= 0
            ) {

              const error =
                new Error(
                  `Invalid quantity for ${productId}.`
                );

              error.statusCode = 400;

              throw error;
            }


            // ==============================================
            // VERIFY PRODUCT MASTER
            // ==============================================

            const product =
              await Product.findOne({
                farmId:
                  farmId,

                productId:
                  productId,

                isActive:
                  true,
              }).session(session);


            if (!product) {

              const error =
                new Error(
                  `Product ${productId} not found.`
                );

              error.statusCode = 404;

              throw error;
            }


            // ==============================================
            // ADMIN STOCK CHECK
            // MAIN GODOWN
            // ==============================================

            if (role === "admin") {

              const availableStock =
                Number(
                  product.stock
                ) || 0;


              if (
                availableStock <
                quantity
              ) {

                const error =
                  new Error(
                    `Insufficient stock for ${product.productName}. Available stock is ${availableStock}.`
                  );

                error.statusCode = 400;

                throw error;
              }
            }


            // ==============================================
            // SALESMAN STOCK CHECK
            // ALLOCATED STOCK ONLY
            // ==============================================

            if (role === "salesman") {

              const stockRow =
                salesmanStockMap.get(
                  productId
                );


              const availableStock =
                stockRow
                  ? Number(
                    stockRow.available
                  ) || 0
                  : 0;


              if (
                availableStock <
                quantity
              ) {

                const error =
                  new Error(
                    `Insufficient salesman stock for ${product.productName}. Available stock is ${availableStock} ${product.unit}.`
                  );

                error.statusCode = 400;

                throw error;
              }


              // Prevent another product line in the
              // same transaction from reusing stock.
              stockRow.available -=
                quantity;
            }


            // ==============================================
            // DEFAULT RATE
            // ==============================================

            const defaultRate =
              Number(
                product.price
              ) || 0;


            // ==============================================
            // CUSTOMER SPECIAL RATE
            // ==============================================

            const customerRate =
              await CustomerRate.findOne({
                farmId:
                  farmId,

                customerId:
                  customer.customerId,

                productId:
                  product.productId,

                isActive:
                  true,
              }).session(session);


            let finalRate =
              defaultRate;

            let rateSource =
              "PRODUCT_RATE";


            if (
              customerRate &&
              Number(
                customerRate.specialRate
              ) > 0
            ) {

              finalRate =
                Number(
                  customerRate.specialRate
                );

              rateSource =
                "CUSTOMER_RATE";
            }


            if (
              !Number.isFinite(
                finalRate
              ) ||
              finalRate <= 0
            ) {

              const error =
                new Error(
                  `Selling rate is not configured for ${product.productName}.`
                );

              error.statusCode = 400;

              throw error;
            }


            const amount =
              quantity *
              finalRate;


            verifiedProducts.push({

              productId:
                product.productId,

              productName:
                product.productName,

              variant:
                product.variant || "",

              unit:
                product.unit,

              quantity:
                quantity,

              defaultRate:
                defaultRate,

              rate:
                finalRate,

              rateSource:
                rateSource,

              amount:
                amount,
            });


            totalQuantity +=
              quantity;

            grandTotal +=
              amount;
          }

          // ==================================================
          // PAYMENT BREAKUP
          // NEVER TRUST PAYMENT TOTAL FROM FRONTEND
          // ==================================================

          const allowedImmediatePaymentModes = [
            "Cash",
            "UPI",
            "Bank Transfer",
          ];

          const normalizedPayments = [];

          if (Array.isArray(payments)) {

            for (const payment of payments) {

              const mode =
                (
                  payment?.mode ||
                  ""
                )
                  .toString()
                  .trim();

              const amount =
                Number(
                  payment?.amount
                );

              if (
                !allowedImmediatePaymentModes.includes(
                  mode
                )
              ) {
                const error =
                  new Error(
                    `Invalid payment mode: ${mode || "Unknown"}.`
                  );

                error.statusCode = 400;

                throw error;
              }

              if (
                !Number.isFinite(amount) ||
                amount <= 0
              ) {
                const error =
                  new Error(
                    `Invalid payment amount for ${mode}.`
                  );

                error.statusCode = 400;

                throw error;
              }

              normalizedPayments.push({
                mode,

                amount:
                  Number(
                    amount.toFixed(2)
                  ),

                referenceNo:
                  (
                    payment?.referenceNo ||
                    ""
                  )
                    .toString()
                    .trim(),
              });
            }
          }


          // ==================================================
          // CALCULATE PAID AMOUNT
          // ==================================================

          const finalPaidAmount =
            normalizedPayments.reduce(
              (
                total,
                payment
              ) =>
                total +
                (
                  Number(
                    payment.amount
                  ) || 0
                ),
              0
            );

          // ==================================================
          // BILL PAYMENT / ADVANCE CALCULATION
          //
          // IMPORTANT:
          //
          // Payment < Bill
          //   -> remaining amount may use existing advance
          //   -> anything still remaining becomes outstanding
          //
          // Payment = Bill
          //   -> fully paid
          //
          // Payment > Bill
          //   -> bill becomes fully paid
          //   -> extra payment becomes customer advance
          //
          // Example:
          //
          // Bill              = 1000
          // Payment Received  = 1200
          //
          // Payment Applied   = 1000
          // Advance Created   = 200
          // Bill Outstanding  = 0
          // ==================================================

// ==================================================
// RAW CUSTOMER CREDIT
// ==================================================

const rawAdvanceBalance =
  Math.max(
    0,
    Number(
      customer.balance ||
      0
    )
  );


// ==================================================
// EXISTING GROSS OUTSTANDING
//
// This is outstanding already existing BEFORE
// the current new sale.
// ==================================================

const grossExistingOutstanding =
  await getCustomerGrossOutstandingForAdvance({
    farmId,

    customerId:
      customer.customerId,

    session,
  });


// ==================================================
// ACTUALLY USABLE ADVANCE
//
// Example:
//
// Raw credit       = 950
// Existing due     = 800
// Usable advance   = 150
// ==================================================

const availableAdvanceBalance =
  Number(
    Math.max(
      0,

      rawAdvanceBalance -
      grossExistingOutstanding
    ).toFixed(2)
  );


          // Amount of current payment actually required
          // to settle this bill.
          const paymentApplied =
            Number(
              Math.min(
                finalPaidAmount,
                grandTotal
              ).toFixed(2)
            );


          // Extra payment received at BILLING TIME only.
          const advanceCreated =
            Number(
              Math.max(
                0,
                finalPaidAmount -
                grandTotal
              ).toFixed(2)
            );


          // Amount remaining after payment entered on bill.
          const amountAfterImmediatePayment =
            Number(
              Math.max(
                0,
                grandTotal -
                paymentApplied
              ).toFixed(2)
            );


          // Existing advance can be consumed only if
          // some bill amount still remains.
          const advanceUsed =
            Number(
              Math.min(
                availableAdvanceBalance,
                amountAfterImmediatePayment
              ).toFixed(2)
            );


          // Individual bill outstanding NEVER becomes negative.
          const finalOutstandingAmount =
            Number(
              Math.max(
                0,
                amountAfterImmediatePayment -
                advanceUsed
              ).toFixed(2)
            );

          // ==================================================
          // PAYMENT STATUS
          // ==================================================
          // ==================================================
          // PAYMENT STATUS
          //
          // PAID
          //   Nothing remains outstanding.
          //
          // CREDIT
          //   Nothing paid and no advance was used.
          //
          // PARTIAL
          //   Some immediate payment or advance was applied,
          //   but some outstanding remains.
          // ==================================================

          let finalPaymentStatus =
            "PAID";

          if (
            finalOutstandingAmount >
            0.001
          ) {

            if (
              finalPaidAmount <=
              0.001 &&
              advanceUsed <=
              0.001
            ) {
              finalPaymentStatus =
                "CREDIT";
            }

            else {
              finalPaymentStatus =
                "PARTIAL";
            }
          }


          // ==================================================
          // DISPLAY PAYMENT MODE
          // ==================================================

          let finalPaymentMode =
            "Credit";

          if (
            normalizedPayments.length === 1 &&
            finalOutstandingAmount <= 0.001
          ) {
            finalPaymentMode =
              normalizedPayments[0]
                .mode;
          }

          else if (
            normalizedPayments.length > 0
          ) {
            finalPaymentMode =
              "Split";
          }
          // ==================================================
          // GENERATE SALE IDS
          // ==================================================

          const saleId =
            await generateSaleId();


          const saleNo =
            await generateSaleNo(
              farmId
            );


          // ==================================================
          // GODOWN
          // ==================================================

          const finalGodown =
            role === "salesman"
              ? `Salesman - ${salesman.salesmanId}`
              : (
                godown ||
                "Main Godown"
              )
                .toString()
                .trim();


          // ==================================================
          // CREATE SALE
          // ==================================================

          const saleDocs =
            await Sale.create(
              [
                {
                  farmId:
                    farmId,

                  saleId:
                    saleId,

                  saleNo:
                    saleNo,

                  saleDate:
                    saleDate
                      ? new Date(
                        saleDate
                      )
                      : new Date(),

                  customerId:
                    customer.customerId,

                  customerName:
                    customer.name,

                  customerMobile:
                    customer.mobile || "",

                  route:
                    customer.route || "",

                  paymentMode:
                    finalPaymentMode,

                  payments:
                    normalizedPayments,

                  paidAmount:
                    Number(
                      finalPaidAmount.toFixed(2)
                    ),

                  paymentApplied:
                    Number(
                      paymentApplied.toFixed(2)
                    ),

                  // Extra amount received during billing.
                  advanceCreated:
                    Number(
                      advanceCreated.toFixed(2)
                    ),

                  // Existing customer advance consumed against this sale.
                  advanceUsed:
                    Number(
                      advanceUsed.toFixed(2)
                    ),

                  outstandingAmount:
                    Number(
                      finalOutstandingAmount.toFixed(2)
                    ),

                  paymentStatus:
                    finalPaymentStatus,

                  // ==================================================
                  // SALE PRODUCT LINES
                  // REQUIRED FOR EDIT / CANCEL / STOCK REVERSAL
                  // ==================================================

                  products:
                    verifiedProducts,

                  totalItems:
                    verifiedProducts.length,

                  totalQuantity:
                    totalQuantity,

                  grandTotal:
                    grandTotal,

                  godown:
                    finalGodown,

                  // ================================================
                  // REMEMBER WHERE STOCK CAME FROM
                  // ================================================

                  stockSource:
                    finalStockSource,

                  status:
                    "POSTED",

                  createdBy:
                    userId || "",

                  createdRole:
                    role || "",

                  salesmanId:
                    role === "salesman"
                      ? salesman.salesmanId
                      : "",

                  salesmanName:
                    role === "salesman"
                      ? salesman.name
                      : "",
                },
              ],
              {
                session:
                  session,
              }
            );


          const sale =
            saleDocs[0];
          // ==================================================
          // DEDUCT CUSTOMER ADVANCE USED BY THIS SALE
          //
          // This is inside the existing MongoDB transaction.
          //
          // Therefore if stock deduction / sale save fails,
          // this customer balance update will also roll back.
          // ==================================================
          // ==================================================
          // UPDATE CUSTOMER AVAILABLE ADVANCE
          //
          // Existing Advance
          // - Advance Used
          // + Extra Payment Created During This Bill
          // ==================================================

    const updatedAdvanceBalance =
  Number(
    Math.max(
      0,

      rawAdvanceBalance -
      advanceUsed +
      advanceCreated
    ).toFixed(2)
  );


if (
  Math.abs(
    updatedAdvanceBalance -
    rawAdvanceBalance
  ) > 0.001
) {

  customer.balance =
    updatedAdvanceBalance;

  customer.updatedAt =
    new Date();

  await customer.save({
    session,
  });
}

          // ==================================================
          // MAIN GODOWN SALE ONLY
          // DEDUCT MAS_PRODUCT
          // ==================================================

          if (
            finalStockSource ===
            "MAIN_GODOWN"
          ) {

            for (
              const line of
              verifiedProducts
            ) {

              const updateResult =
                await Product.updateOne(
                  {
                    farmId:
                      farmId,

                    productId:
                      line.productId,

                    stock: {
                      $gte:
                        line.quantity,
                    },
                  },

                  {
                    $inc: {
                      stock:
                        -line.quantity,
                    },

                    $set: {
                      updatedAt:
                        new Date(),
                    },
                  },

                  {
                    session:
                      session,
                  }
                );


              if (
                updateResult.modifiedCount !==
                1
              ) {

                const error =
                  new Error(
                    `Unable to deduct stock for ${line.productName}. Stock may have changed.`
                  );

                error.statusCode = 409;

                throw error;
              }


              // ============================================
              // ADMIN MAIN STOCK LEDGER
              // ============================================

              const stockId =
                await generateStockId();


              await StockTransaction.create(
                [
                  {
                    farmId:
                      farmId,

                    stockId:
                      stockId,

                    productId:
                      line.productId,

                    productName:
                      line.productName,

                    transactionType:
                      "SALE",

                    referenceType:
                      "SALE",

                    referenceId:
                      sale.saleId,

                    referenceNo:
                      sale.saleNo,

                    quantityIn:
                      0,

                    quantityOut:
                      line.quantity,

                    rate:
                      line.rate,

                    godown:
                      finalGodown,

                    createdBy:
                      userId || "",
                  },
                ],
                {
                  session:
                    session,
                }
              );
            }
          }


          // ==================================================
          // SALESMAN
          //
          // NO MAS_PRODUCT UPDATE
          // NO MAIN STOCK SALE LEDGER
          //
          // His balance is calculated from:
          // Allocation - Returned - Posted Sales
          // ==================================================

          savedSale =
            sale;
        }
      );


      return res.status(201).json({

        success: true,

        message:
          req.user.role === "salesman"
            ? "Salesman sale saved successfully."
            : "Sale saved and stock updated successfully.",

        data:
          savedSale,
      });


    } catch (error) {

      console.error(
        "ADD SALE ERROR:",
        error
      );


      return res
        .status(
          error.statusCode ||
          500
        )
        .json({

          success:
            false,

          message:
            error.message ||
            "Unable to save sale.",
        });


    } finally {

      await session.endSession();
    }
  }
);
// ======================================================
// EDIT SALE
// PUT /api/sales/:id
//
// ADMIN
//   -> Adjust MAS_PRODUCT by quantity difference
//
// SALESMAN
//   -> Do not change MAS_PRODUCT
//   -> Validate against salesman allocated stock
//
// NEVER TRUST RATE FROM FRONTEND
// CUSTOMER SPECIAL RATE IS RECALCULATED
// ======================================================

app.put(
  "/api/sales/:id",
  authenticateToken,
  loadAccessContext,
  requirePermission("salesCreate"),
  async (req, res) => {
    const session =
      await mongoose.startSession();

    try {
      let updatedSale = null;

      await session.withTransaction(
        async () => {
          const farmId =
            req.user.farmId;

          const userId =
            req.user.userId;

          const role =
            req.user.role;

          if (
            role !== "admin" &&
            role !== "salesman"
          ) {
            const error =
              new Error(
                "You are not allowed to edit sales."
              );

            error.statusCode = 403;

            throw error;
          }

          // ==============================================
          // FIND ORIGINAL SALE
          // ==============================================

          const saleIdentifier =
            req.params.id
              .toString()
              .trim();

          const saleConditions = [
            {
              saleId:
                saleIdentifier
                  .toUpperCase(),
            },
            {
              saleNo:
                saleIdentifier,
            },
          ];

          if (
            mongoose.Types.ObjectId
              .isValid(
                saleIdentifier
              )
          ) {
            saleConditions.push({
              _id:
                saleIdentifier,
            });
          }

          const sale =
            await Sale.findOne({
              farmId,
              $or:
                saleConditions,
            }).session(session);

          if (!sale) {
            const error =
              new Error(
                "Sale not found."
              );

            error.statusCode = 404;

            throw error;
          }

          // ==============================================
          // CANCELLED SALE CANNOT BE EDITED
          // ==============================================

          if (
            sale.status ===
            "CANCELLED"
          ) {
            const error =
              new Error(
                "Cancelled sale cannot be edited."
              );

            error.statusCode = 400;

            throw error;
          }

          // ==================================================
          // BLOCK EDIT IF POSTED COLLECTION IS ALREADY
          // APPLIED AGAINST THIS SALE
          //
          // Correct flow:
          // 1. Cancel collection
          // 2. Edit sale
          // ==================================================

          const linkedCollection =
            await Collection.findOne({
              farmId,

              status: "POSTED",

              allocations: {
                $elemMatch: {
                  saleId:
                    sale.saleId,

                  amountApplied: {
                    $gt: 0,
                  },
                },
              },
            })
              .select(
                "collectionId receiptNo amount"
              )
              .session(session)
              .lean();


          if (linkedCollection) {

            const error =
              new Error(
                `This sale has collection ${linkedCollection.receiptNo ||
                linkedCollection.collectionId
                } applied against it. Cancel that collection first before editing this sale.`
              );

            error.statusCode =
              409;

            throw error;
          }
          // ==============================================
          // SALESMAN CAN EDIT ONLY HIS OWN BILL
          // ==============================================

          if (
            role === "salesman"
          ) {
            if (
              sale.createdRole !==
              "salesman" ||
              sale.createdBy !==
              userId
            ) {
              const error =
                new Error(
                  "You can edit only your own sales."
                );

              error.statusCode = 403;

              throw error;
            }
          }

          // ==============================================
          // REQUEST
          // ==============================================

          const {
            saleDate,
            customerId,
            paymentMode,
            payments,
            products,
          } = req.body;

          if (
            !Array.isArray(products) ||
            products.length === 0
          ) {
            const error =
              new Error(
                "Please add at least one product."
              );

            error.statusCode = 400;

            throw error;
          }

          // ==================================================
          // ORIGINAL CUSTOMER
          //
          // Required because old advanceUsed belongs to the
          // customer on the original sale.
          //
          // If admin changes customer during sale edit,
          // old advance must return to old customer.
          // ==================================================

          const originalCustomer =
            await Customer.findOne({
              farmId,

              customerId:
                sale.customerId,
            }).session(session);


          if (!originalCustomer) {

            const error =
              new Error(
                "Original customer linked to this sale was not found."
              );

            error.statusCode =
              404;

            throw error;
          }

          // ==============================================
          // CUSTOMER
          // ==============================================

          const normalizedCustomerId =
            (
              customerId ||
              sale.customerId
            )
              .toString()
              .trim()
              .toUpperCase();

          const customer =
            await Customer.findOne({
              farmId,
              customerId:
                normalizedCustomerId,
              isActive: true,
            }).session(session);

          if (!customer) {
            const error =
              new Error(
                "Selected customer not found."
              );

            error.statusCode = 404;

            throw error;
          }
          // ==================================================
          // RESTORE ADVANCE USED BY ORIGINAL SALE
          //
          // Before recalculating an edited sale, return the
          // original advanceUsed.
          //
          // Example:
          //
          // Customer balance now = 400
          // Old sale advanceUsed = 600
          //
          // Temporary available balance becomes 1000.
          //
          // Then edited bill will consume whatever it actually
          // needs.
          // ==================================================
          // ==================================================
          // REVERSE ORIGINAL SALE ADVANCE EFFECT
          //
          // Old sale could have:
          // 1. Consumed existing advance
          // 2. Created new advance because of overpayment
          //
          // Before recalculating edited bill:
          // + return old advanceUsed
          // - remove old advanceCreated
          // ==================================================

          const oldAdvanceUsed =
            Math.max(
              0,
              Number(
                sale.advanceUsed || 0
              )
            );

          const oldAdvanceCreated =
            Math.max(
              0,
              Number(
                sale.advanceCreated || 0
              )
            );

          const sameCustomer =
            originalCustomer.customerId
              .toString()
              .trim()
              .toUpperCase() ===
            customer.customerId
              .toString()
              .trim()
              .toUpperCase();


          // Balance after returning advance previously
          // consumed by this sale.
          const balanceAfterAdvanceRestore =
            Number(
              (
                Number(
                  originalCustomer.balance || 0
                ) +
                oldAdvanceUsed
              ).toFixed(2)
            );


          // IMPORTANT:
          // If advance generated by this old bill has already
          // been consumed by another sale, editing this bill
          // must be blocked.
          if (
            balanceAfterAdvanceRestore +
            0.001 <
            oldAdvanceCreated
          ) {

            const unavailableAdvance =
              Number(
                (
                  oldAdvanceCreated -
                  balanceAfterAdvanceRestore
                ).toFixed(2)
              );

            const error =
              new Error(
                `Cannot edit this sale because ₹${unavailableAdvance.toFixed(
                  2
                )} of the advance created by this bill has already been used. Reverse the dependent transaction first.`
              );

            error.statusCode = 409;

            throw error;
          }


          // Fully reverse original sale advance effect.
          originalCustomer.balance =
            Number(
              Math.max(
                0,
                balanceAfterAdvanceRestore -
                oldAdvanceCreated
              ).toFixed(2)
            );

          originalCustomer.updatedAt =
            new Date();

          await originalCustomer.save({
            session,
          });


          // Same Mongoose customer was loaded before the
          // original customer balance was changed.
          if (sameCustomer) {
            customer.balance =
              originalCustomer.balance;
          }

          // ==============================================
          // PAYMENT MODE
          // ==============================================



          // ==============================================
          // OLD QUANTITY MAP
          // ==============================================

          const oldQuantityMap =
            new Map();

          for (
            const oldLine of
            sale.products
          ) {
            const id =
              oldLine.productId
                .toString()
                .trim()
                .toUpperCase();

            oldQuantityMap.set(
              id,
              Number(
                oldLine.quantity
              ) || 0
            );
          }

          // ==============================================
          // SALESMAN AVAILABLE STOCK
          //
          // Exclude current sale because it is being edited.
          // ==============================================

          const salesmanAvailableMap =
            new Map();

          let salesman = null;

          if (
            role === "salesman"
          ) {
            salesman =
              await Salesman.findOne({
                _id:
                  userId,
                farmId,
                isActive: true,
              })
                .session(session)
                .lean();

            if (!salesman) {
              const error =
                new Error(
                  "Salesman account not found."
                );

              error.statusCode = 404;

              throw error;
            }

            const allocations =
              await Allocation.find({
                farmId,
                salesmanId:
                  salesman.salesmanId,

                status: {
                  $in: [
                    "POSTED",
                    "RETURNED",
                  ],
                },
              })
                .session(session)
                .lean();

            for (
              const allocation of
              allocations
            ) {
              for (
                const item of
                allocation.products || []
              ) {
                const productId =
                  (
                    item.productId ||
                    ""
                  )
                    .toString()
                    .trim()
                    .toUpperCase();

                if (!productId) {
                  continue;
                }

                if (
                  !salesmanAvailableMap
                    .has(productId)
                ) {
                  salesmanAvailableMap
                    .set(
                      productId,
                      {
                        allocated: 0,
                        returned: 0,
                        sold: 0,
                      }
                    );
                }

                const row =
                  salesmanAvailableMap
                    .get(productId);

                row.allocated +=
                  Number(
                    item.quantity
                  ) || 0;

                row.returned +=
                  Number(
                    item.returnedQuantity
                  ) || 0;
              }
            }

            // Other posted sales only.
            // Current bill is excluded.
            const otherSales =
              await Sale.find({
                farmId,

                status:
                  "POSTED",

                createdRole:
                  "salesman",

                _id: {
                  $ne:
                    sale._id,
                },

                $or: [
                  {
                    salesmanId:
                      salesman.salesmanId,
                  },
                  {
                    createdBy:
                      userId,
                  },
                ],
              })
                .session(session)
                .lean();

            for (
              const otherSale of
              otherSales
            ) {
              for (
                const item of
                otherSale.products || []
              ) {
                const productId =
                  (
                    item.productId ||
                    ""
                  )
                    .toString()
                    .trim()
                    .toUpperCase();

                if (!productId) {
                  continue;
                }

                if (
                  !salesmanAvailableMap
                    .has(productId)
                ) {
                  salesmanAvailableMap
                    .set(
                      productId,
                      {
                        allocated: 0,
                        returned: 0,
                        sold: 0,
                      }
                    );
                }

                salesmanAvailableMap
                  .get(productId)
                  .sold +=
                  Number(
                    item.quantity
                  ) || 0;
              }
            }
          }

          // ==============================================
          // VERIFY NEW PRODUCTS
          // ==============================================

          const verifiedProducts = [];

          const receivedProductIds =
            new Set();

          let totalQuantity = 0;
          let grandTotal = 0;

          for (
            const line of
            products
          ) {
            const productId =
              line.productId
                ?.toString()
                .trim()
                .toUpperCase();

            const quantity =
              Number(
                line.quantity
              );

            if (!productId) {
              const error =
                new Error(
                  "Invalid product."
                );

              error.statusCode = 400;

              throw error;
            }

            if (
              receivedProductIds.has(
                productId
              )
            ) {
              const error =
                new Error(
                  `Product ${productId} is repeated in this sale.`
                );

              error.statusCode = 400;

              throw error;
            }

            receivedProductIds.add(
              productId
            );

            if (
              !Number.isFinite(
                quantity
              ) ||
              quantity <= 0
            ) {
              const error =
                new Error(
                  `Invalid quantity for ${productId}.`
                );

              error.statusCode = 400;

              throw error;
            }

            const product =
              await Product.findOne({
                farmId,
                productId,
                isActive: true,
              }).session(session);

            if (!product) {
              const error =
                new Error(
                  `Product ${productId} not found.`
                );

              error.statusCode = 404;

              throw error;
            }

            // ============================================
            // CUSTOMER SPECIAL RATE
            // ============================================

            const defaultRate =
              Number(
                product.price
              ) || 0;

            const customerRate =
              await CustomerRate.findOne({
                farmId,

                customerId:
                  customer.customerId,

                productId:
                  product.productId,

                isActive:
                  true,
              }).session(session);

            let finalRate =
              defaultRate;

            let rateSource =
              "PRODUCT_RATE";

            if (
              customerRate &&
              Number(
                customerRate.specialRate
              ) > 0
            ) {
              finalRate =
                Number(
                  customerRate.specialRate
                );

              rateSource =
                "CUSTOMER_RATE";
            }

            if (
              !Number.isFinite(
                finalRate
              ) ||
              finalRate <= 0
            ) {
              const error =
                new Error(
                  `Selling rate is not configured for ${product.productName}.`
                );

              error.statusCode = 400;

              throw error;
            }

            // ============================================
            // STOCK VALIDATION
            // ============================================

            const oldQuantity =
              oldQuantityMap.get(
                productId
              ) || 0;

            const difference =
              quantity -
              oldQuantity;

            // ADMIN:
            // Only additional quantity needs more stock.
            if (
              role === "admin" &&
              difference > 0
            ) {
              const availableStock =
                Number(
                  product.stock
                ) || 0;

              if (
                availableStock <
                difference
              ) {
                const error =
                  new Error(
                    `Insufficient stock for ${product.productName}. Additional ${difference} required but only ${availableStock} available.`
                  );

                error.statusCode = 400;

                throw error;
              }
            }

            // SALESMAN:
            // Current sale was excluded from sold quantity.
            if (
              role === "salesman"
            ) {
              const stockRow =
                salesmanAvailableMap
                  .get(productId);

              const available =
                stockRow
                  ? (
                    Number(
                      stockRow.allocated
                    ) || 0
                  ) -
                  (
                    Number(
                      stockRow.returned
                    ) || 0
                  ) -
                  (
                    Number(
                      stockRow.sold
                    ) || 0
                  )
                  : 0;

              if (
                available <
                quantity
              ) {
                const error =
                  new Error(
                    `Insufficient salesman stock for ${product.productName}. Available stock is ${available} ${product.unit}.`
                  );

                error.statusCode = 400;

                throw error;
              }
            }

            const amount =
              quantity *
              finalRate;

            verifiedProducts.push({
              productId:
                product.productId,

              productName:
                product.productName,

              variant:
                product.variant || "",

              unit:
                product.unit,

              quantity,

              defaultRate,

              rate:
                finalRate,

              rateSource,

              amount,
            });

            totalQuantity +=
              quantity;

            grandTotal +=
              amount;
          }
          // ==================================================
          // PAYMENT BREAKUP
          // NEVER TRUST PAYMENT TOTAL FROM FRONTEND
          // ==================================================

          const allowedImmediatePaymentModes = [
            "Cash",
            "UPI",
            "Bank Transfer",
          ];

          const normalizedPayments = [];

          if (Array.isArray(payments)) {

            for (const payment of payments) {

              const mode =
                (
                  payment?.mode ||
                  ""
                )
                  .toString()
                  .trim();

              const amount =
                Number(
                  payment?.amount
                );

              if (
                !allowedImmediatePaymentModes.includes(
                  mode
                )
              ) {
                const error =
                  new Error(
                    `Invalid payment mode: ${mode || "Unknown"}.`
                  );

                error.statusCode = 400;

                throw error;
              }

              if (
                !Number.isFinite(amount) ||
                amount <= 0
              ) {
                const error =
                  new Error(
                    `Invalid payment amount for ${mode}.`
                  );

                error.statusCode = 400;

                throw error;
              }

              normalizedPayments.push({
                mode,

                amount:
                  Number(
                    amount.toFixed(2)
                  ),

                referenceNo:
                  (
                    payment?.referenceNo ||
                    ""
                  )
                    .toString()
                    .trim(),
              });
            }
          }


          // ==================================================
          // CALCULATE PAID AMOUNT
          // ==================================================

          const finalPaidAmount =
            normalizedPayments.reduce(
              (
                total,
                payment
              ) =>
                total +
                (
                  Number(
                    payment.amount
                  ) || 0
                ),
              0
            );


          // if (
          //   finalPaidAmount >
          //   grandTotal + 0.001
          // ) {
          //   const error =
          //     new Error(
          //       "Paid amount cannot be greater than bill amount."
          //     );

          //   error.statusCode = 400;

          //   throw error;
          // }


          // ==================================================
          // OUTSTANDING
          // ==================================================

   // ==================================================
// CUSTOMER ADVANCE RECALCULATION FOR EDITED SALE
//
// At this point the original sale advance effect
// has already been reversed.
//
// But customer.balance may still contain credit that
// is already offsetting OTHER existing outstanding.
//
// Therefore we must calculate actually free advance.
// ==================================================


// ==================================================
// RAW CUSTOMER CREDIT
// ==================================================

const rawAdvanceBalance =
  Math.max(
    0,
    Number(
      customer.balance ||
      0
    )
  );


// ==================================================
// OTHER EXISTING OUTSTANDING
//
// IMPORTANT:
// Exclude the sale currently being edited.
//
// We are about to recalculate that sale from scratch.
// ==================================================

const grossExistingOutstanding =
  await getCustomerGrossOutstandingForAdvance({
    farmId,

    customerId:
      customer.customerId,

    session,

    excludeSaleId:
      sale.saleId,
  });


// ==================================================
// ACTUALLY USABLE ADVANCE
// ==================================================

const availableAdvanceBalance =
  Number(
    Math.max(
      0,

      rawAdvanceBalance -
      grossExistingOutstanding
    ).toFixed(2)
  );


const paymentApplied =
            Number(
              Math.min(
                finalPaidAmount,
                grandTotal
              ).toFixed(2)
            );


          const advanceCreated =
            Number(
              Math.max(
                0,
                finalPaidAmount -
                grandTotal
              ).toFixed(2)
            );


          const amountAfterImmediatePayment =
            Number(
              Math.max(
                0,
                grandTotal -
                paymentApplied
              ).toFixed(2)
            );


          const advanceUsed =
            Number(
              Math.min(
                availableAdvanceBalance,
                amountAfterImmediatePayment
              ).toFixed(2)
            );


          const finalOutstandingAmount =
            Number(
              Math.max(
                0,
                amountAfterImmediatePayment -
                advanceUsed
              ).toFixed(2)
            );

          // ==================================================
          // PAYMENT STATUS
          // ==================================================

          let finalPaymentStatus =
            "PAID";


          if (
            finalOutstandingAmount >
            0.001
          ) {

            if (
              finalPaidAmount <=
              0.001 &&
              advanceUsed <=
              0.001
            ) {

              finalPaymentStatus =
                "CREDIT";
            }

            else {

              finalPaymentStatus =
                "PARTIAL";
            }
          }
          // ==================================================
          // DISPLAY PAYMENT MODE
          // ==================================================

          let finalPaymentMode =
            "Credit";

          if (
            normalizedPayments.length === 1 &&
            finalOutstandingAmount <= 0.001
          ) {
            finalPaymentMode =
              normalizedPayments[0]
                .mode;
          }

          else if (
            normalizedPayments.length > 0
          ) {
            finalPaymentMode =
              "Split";
          }

          // ==============================================
          // ADMIN STOCK DIFFERENCE
          // ==============================================

          if (
            role === "admin"
          ) {
            const newQuantityMap =
              new Map();

            for (
              const line of
              verifiedProducts
            ) {
              newQuantityMap.set(
                line.productId,
                Number(
                  line.quantity
                ) || 0
              );
            }

            const allProductIds =
              new Set([
                ...oldQuantityMap.keys(),
                ...newQuantityMap.keys(),
              ]);

            for (
              const productId of
              allProductIds
            ) {
              const oldQty =
                oldQuantityMap.get(
                  productId
                ) || 0;

              const newQty =
                newQuantityMap.get(
                  productId
                ) || 0;

              const difference =
                newQty -
                oldQty;

              if (
                difference === 0
              ) {
                continue;
              }

              const line =
                verifiedProducts.find(
                  (item) =>
                    item.productId ===
                    productId
                ) ||
                sale.products.find(
                  (item) =>
                    item.productId ===
                    productId
                );

              // ------------------------------------------
              // MORE SOLD -> STOCK OUT
              // ------------------------------------------

              if (
                difference > 0
              ) {
                const updateResult =
                  await Product.updateOne(
                    {
                      farmId,
                      productId,

                      stock: {
                        $gte:
                          difference,
                      },
                    },

                    {
                      $inc: {
                        stock:
                          -difference,
                      },

                      $set: {
                        updatedAt:
                          new Date(),
                      },
                    },

                    {
                      session,
                    }
                  );

                if (
                  updateResult.modifiedCount !==
                  1
                ) {
                  const error =
                    new Error(
                      `Unable to deduct additional stock for ${line.productName}.`
                    );

                  error.statusCode = 409;

                  throw error;
                }

                const stockId =
                  await generateStockId();

                await StockTransaction.create(
                  [
                    {
                      farmId,
                      stockId,

                      productId,

                      productName:
                        line.productName,

                      transactionType:
                        "SALE_EDIT",

                      referenceType:
                        "SALE",

                      referenceId:
                        sale.saleId,

                      referenceNo:
                        sale.saleNo,

                      quantityIn:
                        0,

                      quantityOut:
                        difference,

                      rate:
                        Number(
                          line.rate
                        ) || 0,

                      godown:
                        sale.godown ||
                        "Main Godown",

                      createdBy:
                        userId || "",
                    },
                  ],
                  {
                    session,
                  }
                );
              }

              // ------------------------------------------
              // LESS SOLD -> STOCK BACK IN
              // ------------------------------------------

              if (
                difference < 0
              ) {
                const quantityBack =
                  Math.abs(
                    difference
                  );

                await Product.updateOne(
                  {
                    farmId,
                    productId,
                  },

                  {
                    $inc: {
                      stock:
                        quantityBack,
                    },

                    $set: {
                      updatedAt:
                        new Date(),
                    },
                  },

                  {
                    session,
                  }
                );

                const stockId =
                  await generateStockId();

                await StockTransaction.create(
                  [
                    {
                      farmId,
                      stockId,

                      productId,

                      productName:
                        line.productName,

                      transactionType:
                        "SALE_EDIT_REVERSE",

                      referenceType:
                        "SALE",

                      referenceId:
                        sale.saleId,

                      referenceNo:
                        sale.saleNo,

                      quantityIn:
                        quantityBack,

                      quantityOut:
                        0,

                      rate:
                        Number(
                          line.rate
                        ) || 0,

                      godown:
                        sale.godown ||
                        "Main Godown",

                      createdBy:
                        userId || "",
                    },
                  ],
                  {
                    session,
                  }
                );
              }
            }
          }
          // ==================================================
          // DEDUCT NEW ADVANCE USED BY EDITED SALE
          // ==================================================
          // ==================================================
          // APPLY NEW EDITED SALE ADVANCE EFFECT
          // ==================================================
const updatedAdvanceBalance =
  Number(
    Math.max(
      0,

      rawAdvanceBalance -
      advanceUsed +
      advanceCreated
    ).toFixed(2)
  );


if (
  Math.abs(
    updatedAdvanceBalance -
    rawAdvanceBalance
  ) > 0.001
) {

  customer.balance =
    updatedAdvanceBalance;

  customer.updatedAt =
    new Date();

  await customer.save({
    session,
  });
}
          // ==============================================
          // UPDATE SALE DOCUMENT
          // ==============================================

          sale.saleDate =
            saleDate
              ? new Date(
                saleDate
              )
              : sale.saleDate;

          sale.customerId =
            customer.customerId;

          sale.customerName =
            customer.name;

          sale.customerMobile =
            customer.mobile || "";

          sale.route =
            customer.route || "";

          sale.paymentMode =
            finalPaymentMode;

          sale.payments =
            normalizedPayments;

          sale.paidAmount =
            Number(
              finalPaidAmount.toFixed(2)
            );
          sale.paymentApplied =
            Number(
              paymentApplied.toFixed(2)
            );

          sale.advanceCreated =
            Number(
              advanceCreated.toFixed(2)
            );


          // Advance recalculated for edited bill.
          sale.advanceUsed =
            Number(
              advanceUsed.toFixed(2)
            );


          sale.outstandingAmount =
            Number(
              finalOutstandingAmount.toFixed(2)
            );


          sale.paymentStatus =
            finalPaymentStatus;

          sale.products =
            verifiedProducts;

          sale.totalItems =
            verifiedProducts.length;

          sale.totalQuantity =
            totalQuantity;

          sale.grandTotal =
            grandTotal;

          sale.updatedAt =
            new Date();

          await sale.save({
            session,
          });

          updatedSale =
            sale;
        }
      );

      return res.status(200).json({
        success: true,

        message:
          "Sale updated successfully.",

        data:
          updatedSale,
      });
    } catch (error) {
      console.error(
        "EDIT SALE ERROR:",
        error
      );

      return res
        .status(
          error.statusCode ||
          500
        )
        .json({
          success: false,

          message:
            error.message ||
            "Unable to update sale.",
        });
    } finally {
      await session.endSession();
    }
  }
);
// ======================================================
// CANCEL SALE
// ATOMIC STOCK REVERSAL
//
// TRN_SALE -> CANCELLED
// MAS_PRODUCT -> STOCK IN
// TRN_STOCK -> SALE_CANCEL
// ======================================================

// ======================================================
// CANCEL SALE
//
// ADMIN MAIN STOCK SALE
// -> RESTORE MAS_PRODUCT
// -> CREATE SALE_CANCEL STOCK TRANSACTION
//
// SALESMAN SALE
// -> DO NOT TOUCH MAS_PRODUCT
// -> CANCELLED SALE AUTOMATICALLY STOPS COUNTING
//    AGAINST SALESMAN ALLOCATED STOCK
// ======================================================

app.put(
  "/api/sales/:id/cancel",
  authenticateToken,
  loadAccessContext,
  requirePermission("salesCreate"),
  async (req, res) => {

    const session =
      await mongoose.startSession();

    try {
      let cancelledSale = null;

      // Values required after transaction
      // for response / UI refresh.
      let advanceToRestore = 0;
      let advanceToRemove = 0;

      let previousAdvanceBalance = 0;
      let currentAdvanceBalance = 0;

      // Useful for checking which products were actually restored.
      let restoredProducts = [];

      // ======================================================
      // STOCK SOURCE MUST EXIST OUTSIDE TRANSACTION
      // because it is also used in the API response
      // after session.withTransaction() completes.
      // ======================================================
      let effectiveStockSource = "";


      await session.withTransaction(
        async () => {

          const farmId =
            req.user.farmId;

          const userId =
            req.user.userId;

          const userRole =
            req.user.role;


          const saleIdentifier =
            req.params.id
              .toString()
              .trim();


          const saleConditions = [
            {
              saleId:
                saleIdentifier
                  .toUpperCase(),
            },
            {
              saleNo:
                saleIdentifier,
            },
          ];


          if (
            mongoose.Types.ObjectId
              .isValid(
                saleIdentifier
              )
          ) {

            saleConditions.push({
              _id:
                saleIdentifier,
            });
          }


          const sale =
            await Sale.findOne({
              farmId:
                farmId,

              $or:
                saleConditions,
            }).session(session);


          if (!sale) {

            const error =
              new Error(
                "Sale not found."
              );

            error.statusCode = 404;

            throw error;
          }


          // ==================================================
          // SECURITY
          //
          // SALESMAN CAN CANCEL ONLY HIS OWN SALE
          // ADMIN CAN CANCEL ANY SALE OF HIS FARM
          // ==================================================

          if (
            userRole === "salesman"
          ) {

            if (
              sale.createdRole !==
              "salesman" ||
              sale.createdBy !==
              userId
            ) {

              const error =
                new Error(
                  "You can cancel only your own sales."
                );

              error.statusCode = 403;

              throw error;
            }
          }


          if (
            userRole !== "admin" &&
            userRole !== "salesman"
          ) {

            const error =
              new Error(
                "You are not allowed to cancel sales."
              );

            error.statusCode = 403;

            throw error;
          }


          // ==================================================
          // PREVENT DOUBLE CANCELLATION
          // ==================================================

          if (
            sale.status ===
            "CANCELLED"
          ) {

            const error =
              new Error(
                "Sale is already cancelled."
              );

            error.statusCode = 400;

            throw error;
          }
          // ==================================================
          // PREVENT SALE CANCELLATION IF A POSTED COLLECTION
          // HAS ALREADY BEEN APPLIED AGAINST THIS BILL
          //
          // Correct flow:
          // 1. Cancel collection first
          // 2. Then cancel sale
          // ==================================================

          const linkedCollection =
            await Collection.findOne({
              farmId,

              status: "POSTED",

              allocations: {
                $elemMatch: {
                  saleId:
                    sale.saleId,
                  amountApplied: {
                    $gt: 0,
                  },
                },
              },
            })
              .select(
                "collectionId receiptNo amount"
              )
              .session(session)
              .lean();

          if (linkedCollection) {
            const error =
              new Error(
                `This sale has payment collection ${linkedCollection.receiptNo ||
                linkedCollection.collectionId
                } applied against it. Cancel that collection first before cancelling this sale.`
              );

            error.statusCode = 409;

            throw error;
          }

          // ==================================================
          // LOAD CUSTOMER
          // Required to restore advance used by this sale.
          // ==================================================

          const customer =
            await Customer.findOne({
              farmId,
              customerId:
                sale.customerId,
            }).session(session);

          if (!customer) {
            const error =
              new Error(
                "Customer linked to this sale was not found."
              );

            error.statusCode = 404;

            throw error;
          }
          // ==================================================
          // ADVANCE USED ON ORIGINAL SALE
          // ==================================================

          advanceToRestore =
            Math.max(
              0,
              Number(
                sale.advanceUsed || 0
              )
            );

          advanceToRemove =
            Math.max(
              0,
              Number(
                sale.advanceCreated || 0
              )
            );

          previousAdvanceBalance =
            Math.max(
              0,
              Number(
                customer.balance || 0
              )
            );


          // Advance used by this bill comes back first.
          const balanceAfterRestore =
            Number(
              (
                previousAdvanceBalance +
                advanceToRestore
              ).toFixed(2)
            );


          // Advance created by this bill must still be
          // available before the bill can be cancelled.
          if (
            balanceAfterRestore +
            0.001 <
            advanceToRemove
          ) {

            const shortAmount =
              Number(
                (
                  advanceToRemove -
                  balanceAfterRestore
                ).toFixed(2)
              );

            const error =
              new Error(
                `Cannot cancel this sale because ₹${shortAmount.toFixed(
                  2
                )} of the advance created by this bill has already been used. Reverse the dependent transaction first.`
              );

            error.statusCode = 409;

            throw error;
          }


          currentAdvanceBalance =
            Number(
              Math.max(
                0,
                balanceAfterRestore -
                advanceToRemove
              ).toFixed(2)
            );

          // ==================================================
          // IDENTIFY ACTUAL STOCK SOURCE OF ORIGINAL SALE
          // ==================================================
          //
          // NEW SALES:
          // Use stockSource stored on the sale.
          //
          // OLD SALES:
          // Existing records may not have stockSource.
          // For those records:
          //   salesman bill -> SALESMAN_ALLOCATION
          //   admin bill    -> MAIN_GODOWN
          // ==================================================
          effectiveStockSource =
            String(
              sale.stockSource || ""
            )
              .trim()
              .toUpperCase();

          // ==================================================
          // LEGACY / OLD SALE SUPPORT
          // ==================================================

          if (
            effectiveStockSource !==
            "MAIN_GODOWN" &&
            effectiveStockSource !==
            "SALESMAN_ALLOCATION"
          ) {

            const oldCreatedRole =
              String(
                sale.createdRole || ""
              )
                .trim()
                .toLowerCase();

            const oldSalesmanId =
              String(
                sale.salesmanId || ""
              )
                .trim();

            const oldGodown =
              String(
                sale.godown || ""
              )
                .trim()
                .toLowerCase();


            if (
              oldCreatedRole === "salesman" ||
              oldSalesmanId !== "" ||
              oldGodown.startsWith(
                "salesman -"
              )
            ) {

              effectiveStockSource =
                "SALESMAN_ALLOCATION";

            } else {

              effectiveStockSource =
                "MAIN_GODOWN";
            }
          }


          // ==================================================
          // ONLY MAIN GODOWN SALES RETURN TO MAS_PRODUCT
          // ==================================================

          const shouldRestoreMainStock =
            effectiveStockSource ===
            "MAIN_GODOWN";


          console.log(
            "CANCEL SALE STOCK SOURCE:",
            {
              saleNo:
                sale.saleNo,

              createdRole:
                sale.createdRole,

              salesmanId:
                sale.salesmanId,

              godown:
                sale.godown,

              storedStockSource:
                sale.stockSource,

              effectiveStockSource,

              shouldRestoreMainStock,
            }
          );


          // ==================================================
          // ADMIN / MAIN STOCK SALE
          // RESTORE MAIN PRODUCT STOCK
          // ==================================================

          if (shouldRestoreMainStock) {

            for (
              const line of
              sale.products
            ) {

              const quantity =
                Number(
                  line.quantity
                ) || 0;


              if (quantity <= 0) {

                const error =
                  new Error(
                    `Invalid sale quantity for ${line.productName}.`
                  );

                error.statusCode = 400;

                throw error;
              }


              // ============================================
              // RESTORE MAIN PRODUCT STOCK ATOMICALLY
              // ============================================

              const productBefore =
                await Product.findOne({
                  farmId:
                    farmId,

                  productId:
                    line.productId,
                })
                  .session(session)
                  .lean();

              if (!productBefore) {

                const error =
                  new Error(
                    `Product ${line.productName} not found.`
                  );

                error.statusCode = 404;

                throw error;
              }

              const stockBefore =
                Number(
                  productBefore.stock || 0
                );


              // ============================================
              // ATOMIC STOCK IN
              // ============================================

              const updatedProduct =
                await Product.findOneAndUpdate(
                  {
                    farmId:
                      farmId,

                    productId:
                      line.productId,
                  },

                  {
                    $inc: {
                      stock:
                        quantity,
                    },

                    $set: {
                      updatedAt:
                        new Date(),
                    },
                  },

                  {
                    new: true,
                    session:
                      session,
                  }
                ).lean();


              if (!updatedProduct) {

                const error =
                  new Error(
                    `Unable to restore stock for ${line.productName}.`
                  );

                error.statusCode = 409;

                throw error;
              }


              const verifiedStock =
                Number(
                  updatedProduct.stock || 0
                );


              const expectedStock =
                Number(
                  (
                    stockBefore +
                    quantity
                  ).toFixed(3)
                );


              // ============================================
              // VERIFY RESULT
              // ============================================

              if (
                Math.abs(
                  verifiedStock -
                  expectedStock
                ) > 0.0001
              ) {

                const error =
                  new Error(
                    `Stock restoration verification failed for ${line.productName}. Expected ${expectedStock}, found ${verifiedStock}.`
                  );

                error.statusCode = 409;

                throw error;
              }


              console.log(
                "MAIN STOCK ACTUALLY RESTORED:",
                {
                  productId:
                    line.productId,

                  productName:
                    line.productName,

                  quantityRestored:
                    quantity,

                  stockBefore:
                    stockBefore,

                  stockAfter:
                    verifiedStock,
                }
              );


              // ============================================
              // RESPONSE AUDIT
              // ============================================

              restoredProducts.push({
                productId:
                  line.productId,

                productName:
                  line.productName,

                quantityRestored:
                  quantity,

                stockBefore,

                stockAfter:
                  verifiedStock,
              });


              console.log(
                "SALE CANCEL STOCK RESTORED:",
                {
                  saleNo:
                    sale.saleNo,

                  productId:
                    line.productId,

                  productName:
                    line.productName,

                  quantityRestored:
                    quantity,

                  stockBefore,

                  stockAfter:
                    verifiedStock,
                }
              );


              // ============================================
              // MAIN STOCK SALE CANCEL LEDGER
              // ============================================

              const stockId =
                await generateStockId();


              await StockTransaction.create(
                [
                  {
                    farmId:
                      farmId,

                    stockId:
                      stockId,

                    productId:
                      line.productId,

                    productName:
                      line.productName,

                    transactionType:
                      "SALE_CANCEL",

                    referenceType:
                      "SALE",

                    referenceId:
                      sale.saleId,

                    referenceNo:
                      sale.saleNo,

                    quantityIn:
                      quantity,

                    quantityOut:
                      0,

                    rate:
                      Number(
                        line.rate
                      ) || 0,

                    godown:
                      sale.godown ||
                      "Main Godown",

                    createdBy:
                      userId || "",
                  },
                ],
                {
                  session:
                    session,
                }
              );
            }
          }


          // ==================================================
          // SALESMAN SALE
          //
          // DO NOT RESTORE MAS_PRODUCT.
          //
          // When status becomes CANCELLED this bill is no
          // longer included in the salesman stock calculation.
          // Therefore quantity automatically becomes available
          // to the salesman again.
          // ==================================================

          // ==================================================
          // RETURN ADVANCE USED BY THIS SALE
          //
          // Example:
          //
          // Customer balance before cancellation = 400
          // Sale advanceUsed                     = 600
          //
          // New customer balance                 = 1000
          //
          // This is part of the same MongoDB transaction.
          // ==================================================
          // ==================================================
          // REVERSE CUSTOMER ADVANCE EFFECT OF CANCELLED SALE
          // ==================================================

          if (
            Math.abs(
              currentAdvanceBalance -
              previousAdvanceBalance
            ) > 0.001
          ) {

            customer.balance =
              currentAdvanceBalance;

            customer.updatedAt =
              new Date();

            await customer.save({
              session,
            });
          }
          // ==================================================
          // MARK SALE CANCELLED
          // ==================================================

          // Save resolved stock source.
          // Important for old bills that previously had no
          // stockSource field.
          // ==================================================
          // MARK SALE CANCELLED
          // ==================================================

          // Save resolved stock source.
          // Important for old bills that previously had no
          // stockSource field.
          sale.stockSource =
            effectiveStockSource;

          sale.status =
            "CANCELLED";

          sale.cancelledBy =
            userId || "";

          sale.cancelledAt =
            new Date();

          sale.updatedAt =
            new Date();

          await sale.save({
            session,
          });

          cancelledSale =
            sale;
        }
      );

      // ======================================================
      // VERIFY STOCK AFTER TRANSACTION COMMIT
      // ======================================================

      const committedStock = [];

      if (
        effectiveStockSource ===
        "MAIN_GODOWN"
      ) {

        for (
          const item of
          restoredProducts
        ) {

          const productAfterCommit =
            await Product.findOne({
              farmId:
                req.user.farmId,

              productId:
                item.productId,
            })
              .lean();

          committedStock.push({
            productId:
              item.productId,

            productName:
              item.productName,

            expectedStock:
              item.stockAfter,

            actualStock:
              productAfterCommit
                ? Number(
                  productAfterCommit.stock || 0
                )
                : null,
          });
        }


        console.log(
          "STOCK AFTER TRANSACTION COMMIT:",
          committedStock
        );
      }
      return res.status(200).json({
        success: true,

        message:
          cancelledSale?.createdRole ===
            "salesman"
            ? (
              advanceToRestore > 0
                ? `Sale cancelled successfully. ₹${advanceToRestore.toFixed(
                  2
                )} customer advance restored.`
                : "Salesman sale cancelled successfully."
            )
            : (
              advanceToRestore > 0
                ? `Sale cancelled successfully. Stock restored and ₹${advanceToRestore.toFixed(
                  2
                )} customer advance restored.`
                : "Sale cancelled and product stock restored successfully."
            ),

      data: {
  ...cancelledSale.toObject(),

  advanceRestored:
    Number(
      advanceToRestore.toFixed(2)
    ),

  advanceRemoved:
    Number(
      advanceToRemove.toFixed(2)
    ),

  previousAdvanceBalance:
    Number(
      previousAdvanceBalance.toFixed(2)
    ),

  currentAdvanceBalance:
    Number(
      currentAdvanceBalance.toFixed(2)
    ),
          stockRestored:
            true,

          stockSource:
            effectiveStockSource,

          mainStockRestored:
            effectiveStockSource ===
            "MAIN_GODOWN",

          salesmanStockReleased:
            effectiveStockSource ===
            "SALESMAN_ALLOCATION",

          restoredProducts,

          committedStock,
        },
      });


    } catch (error) {

      console.error(
        "CANCEL SALE ERROR:",
        error
      );


      return res
        .status(
          error.statusCode ||
          500
        )
        .json({

          success:
            false,

          message:
            error.message ||
            "Unable to cancel sale.",
        });


    } finally {

      await session.endSession();
    }
  }
);
// ======================================================
// HELPER - SOLD QUANTITY BELONGING TO ONE ALLOCATION
//
// SALESMAN SALES ARE CONSUMED AGAINST ALLOCATIONS
// OLDEST FIRST.
//
// Returns:
// Map<productId, soldQuantityForTargetAllocation>
// ======================================================

async function getSoldQuantityForAllocation({
  farmId,
  salesmanId,
  allocationId,
  session = null,
}) {
  const normalizedSalesmanId = (
    salesmanId || ""
  )
    .toString()
    .trim()
    .toUpperCase();

  const normalizedAllocationId = (
    allocationId || ""
  )
    .toString()
    .trim()
    .toUpperCase();
  const salesQuery =
    Sale.find({
      farmId,

      salesmanId:
        normalizedSalesmanId,

      status:
        "POSTED",

      $or: [
        // New records
        {
          stockSource:
            "SALESMAN_ALLOCATION",
        },

        // Old records without stockSource
        {
          stockSource: {
            $exists: false,
          },
          createdRole:
            "salesman",
        },

        {
          stockSource: null,
          createdRole:
            "salesman",
        },

        {
          stockSource: "",
          createdRole:
            "salesman",
        },
      ],
    })
      .select(
        "products"
      )
      .lean();

  if (session) {
    salesQuery.session(session);
  }

  const postedSales =
    await salesQuery;

  // --------------------------------------------------
  // TOTAL SALESMAN SOLD PRODUCT-WISE
  // --------------------------------------------------

  const totalSoldMap =
    new Map();

  for (const sale of postedSales) {
    for (
      const item of
      Array.isArray(sale.products)
        ? sale.products
        : []
    ) {
      const productId = (
        item.productId || ""
      )
        .toString()
        .trim()
        .toUpperCase();

      if (!productId) {
        continue;
      }

      totalSoldMap.set(
        productId,
        (
          totalSoldMap.get(productId) ||
          0
        ) +
        (Number(item.quantity) || 0)
      );
    }
  }

  // --------------------------------------------------
  // ALL ACTIVE/RETURNED ALLOCATIONS OLDEST FIRST
  // --------------------------------------------------

  const allocationQuery =
    Allocation.find({
      farmId,
      salesmanId:
        normalizedSalesmanId,

      status: {
        $in: [
          "POSTED",
          "RETURNED",
        ],
      },
    })
      .sort({
        allocationDate: 1,
        createdAt: 1,
      })
      .lean();

  if (session) {
    allocationQuery.session(
      session
    );
  }

  const allocations =
    await allocationQuery;

  const remainingSoldMap =
    new Map(totalSoldMap);

  const targetSoldMap =
    new Map();

  for (
    const allocation of
    allocations
  ) {
    const isTarget =
      (
        allocation.allocationId ||
        ""
      )
        .toString()
        .trim()
        .toUpperCase() ===
      normalizedAllocationId;

    for (
      const item of
      Array.isArray(
        allocation.products
      )
        ? allocation.products
        : []
    ) {
      const productId = (
        item.productId || ""
      )
        .toString()
        .trim()
        .toUpperCase();

      if (!productId) {
        continue;
      }

      const allocatedQty =
        Number(item.quantity) || 0;

      const returnedQty =
        Number(
          item.returnedQuantity
        ) || 0;

      const usableQty =
        Math.max(
          0,
          allocatedQty -
          returnedQty
        );

      const remainingSold =
        remainingSoldMap.get(
          productId
        ) || 0;

      const consumedQty =
        Math.min(
          usableQty,
          remainingSold
        );

      if (isTarget) {
        targetSoldMap.set(
          productId,
          consumedQty
        );
      }

      remainingSoldMap.set(
        productId,
        Math.max(
          0,
          remainingSold -
          consumedQty
        )
      );
    }

    if (isTarget) {
      break;
    }
  }

  return targetSoldMap;
}
// ======================================================
// ALLOCATION BUSINESS DAY HELPER
// INDIA TIMEZONE - ASIA/KOLKATA (+05:30)
//
// Used only for:
// TODAY / PENDING / ALL allocation sections.
//
// MongoDB dates remain normal UTC Date values.
// ======================================================

function getAllocationBusinessDayRange(
  requestedDate = ""
) {
  const IST_OFFSET_MS =
    5.5 * 60 * 60 * 1000;

  let year;
  let month;
  let day;

  const dateText =
    (requestedDate || "")
      .toString()
      .trim();

  if (dateText) {
    const match =
      dateText.match(
        /^(\d{4})-(\d{2})-(\d{2})$/
      );

    if (!match) {
      const error =
        new Error(
          "Date must be in YYYY-MM-DD format."
        );

      error.statusCode = 400;

      throw error;
    }

    year =
      Number(match[1]);

    month =
      Number(match[2]);

    day =
      Number(match[3]);

    const validationDate =
      new Date(
        Date.UTC(
          year,
          month - 1,
          day
        )
      );

    if (
      validationDate.getUTCFullYear() !==
        year ||
      validationDate.getUTCMonth() !==
        month - 1 ||
      validationDate.getUTCDate() !==
        day
    ) {
      const error =
        new Error(
          "Invalid allocation date."
        );

      error.statusCode = 400;

      throw error;
    }
  } else {
    const nowInIST =
      new Date(
        Date.now() +
        IST_OFFSET_MS
      );

    year =
      nowInIST.getUTCFullYear();

    month =
      nowInIST.getUTCMonth() + 1;

    day =
      nowInIST.getUTCDate();
  }

  const start =
    new Date(
      Date.UTC(
        year,
        month - 1,
        day,
        0,
        0,
        0,
        0
      ) -
      IST_OFFSET_MS
    );

  const end =
    new Date(
      Date.UTC(
        year,
        month - 1,
        day + 1,
        0,
        0,
        0,
        0
      ) -
      IST_OFFSET_MS
    );

  return {
    start,
    end,

    date:
      `${year}-${String(month).padStart(
        2,
        "0"
      )}-${String(day).padStart(
        2,
        "0"
      )}`,
  };
}
// ======================================================
// ALLOCATION
// TRN_ALLOCATION
// ======================================================


// ======================================================
// GET ALLOCATIONS
// ======================================================

// ======================================================
// GET ALLOCATIONS
// WITH SALESMAN SOLD + REMAINING QUANTITY
//
// Remaining = Allocated - Sold - Returned
// ======================================================

app.get(
  "/api/allocations",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission("allocationView", "returnsManage"),
  async (req, res) => {

    try {

      const farmId =
        req.user.farmId;
      const role =
        req.user.role;

      const userId =
        req.user.userId;


      // ==================================================
      // ROLE BASED ALLOCATION FILTER
      //
      // ADMIN
      //   -> ALL FARM ALLOCATIONS
      //
      // SALESMAN
      //   -> ONLY HIS OWN ALLOCATIONS
      // ==================================================

    const allocationFilter = {
  farmId: farmId,

  // Deleted records stay in DB for audit,
  // but are hidden from normal allocation screens.
  status: {
    $ne: "DELETED",
  },
};

      let currentSalesman = null;


      if (role === "salesman") {

        currentSalesman =
          await Salesman.findOne({
            _id: userId,
            farmId: farmId,
            isActive: true,
          })
            .lean();


        if (!currentSalesman) {

          return res.status(404).json({
            success: false,
            message:
              "Salesman account not found.",
          });
        }


        allocationFilter.salesmanId =
          currentSalesman.salesmanId;
      }


      else if (role !== "admin") {

        return res.status(403).json({
          success: false,
          message:
            "You are not allowed to view allocations.",
        });
      }


      // ==================================================
      // LOAD ALL ALLOCATIONS OF THIS FARM
      // ==================================================

      const allocations =
        await Allocation.find(
          allocationFilter
        )
          .sort({
            allocationDate: -1,
            createdAt: -1,
          })
          .lean();


      // ==================================================
      // LOAD ALL POSTED SALESMAN SALES
      //
      // ADMIN SALES ARE NOT INCLUDED.
      // CANCELLED SALES ARE NOT INCLUDED.
      // ==================================================
      const salesFilter = {

        farmId:
          farmId,

        status:
          "POSTED",

        $or: [
          {
            stockSource:
              "SALESMAN_ALLOCATION",
          },

          // Legacy salesman bills
          {
            stockSource: {
              $exists: false,
            },

            createdRole:
              "salesman",
          },

          {
            stockSource:
              null,

            createdRole:
              "salesman",
          },

          {
            stockSource:
              "",

            createdRole:
              "salesman",
          },
        ],
      };


      if (
        role === "salesman" &&
        currentSalesman
      ) {

        salesFilter.salesmanId =
          currentSalesman.salesmanId;
      }


      const salesmanSales =
        await Sale.find(
          salesFilter
        )
          .select(
            "salesmanId createdBy saleDate createdAt paymentMode products"
          )
          .sort({
            saleDate: 1,
            createdAt: 1,
          })
          .lean();


      // ==================================================
      // BUILD SALESMAN + PRODUCT SOLD MAP
      //
      // KEY:
      // SM747982|PRD123456
      //
      // VALUE:
      // TOTAL SOLD QUANTITY
      // ==================================================

      const soldMap =
        new Map();
      const financialQueueMap =
        new Map();

      for (
        const sale of salesmanSales
      ) {

        const salesmanId =
          (
            sale.salesmanId ||
            ""
          )
            .toString()
            .trim()
            .toUpperCase();


        if (!salesmanId) {
          continue;
        }


        const saleProducts =
          Array.isArray(
            sale.products
          )
            ? sale.products
            : [];


        for (
          const item of saleProducts
        ) {

          const productId =
            (
              item.productId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (!productId) {
            continue;
          }


          const quantity =
            Number(
              item.quantity
            ) || 0;


          const key =
            `${salesmanId}|${productId}`;


          const oldSold =
            soldMap.get(key) || 0;


          soldMap.set(
            key,
            oldSold + quantity
          );
          // ================================================
          // ACTUAL FINANCIAL VALUE OF THIS SALE LINE
          // ================================================

          const lineAmount =
            Number(
              item.amount
            ) || 0;

          const lineRate =
            Number(
              item.rate
            ) || 0;

          const unitAmount =
            quantity > 0
              ? (
                lineAmount > 0
                  ? lineAmount / quantity
                  : lineRate
              )
              : 0;


          if (!financialQueueMap.has(key)) {

            financialQueueMap.set(
              key,
              []
            );
          }


          financialQueueMap
            .get(key)
            .push({

              remainingQty:
                quantity,

              unitAmount:
                unitAmount,

              paymentMode:
                (
                  sale.paymentMode || ""
                )
                  .toString()
                  .trim(),
            });
        }
      }


      // ==================================================
      // IMPORTANT:
      //
      // A SALESMAN MAY HAVE MULTIPLE ALLOCATIONS FOR
      // THE SAME PRODUCT.
      //
      // WE MUST NOT PUT THE FULL SOLD QUANTITY AGAINST
      // EVERY ALLOCATION.
      //
      // THEREFORE SALES ARE CONSUMED AGAINST ALLOCATIONS
      // OLDEST FIRST.
      // ==================================================

      const allocationIndexes =
        allocations
          .map(
            (allocation, index) => ({
              allocation,
              index,
            })
          )
          .sort(
            (a, b) => {

              const dateA =
                new Date(
                  a.allocation
                    .allocationDate ||
                  a.allocation
                    .createdAt ||
                  0
                ).getTime();

              const dateB =
                new Date(
                  b.allocation
                    .allocationDate ||
                  b.allocation
                    .createdAt ||
                  0
                ).getTime();


              if (dateA !== dateB) {
                return dateA - dateB;
              }


              return (
                new Date(
                  a.allocation
                    .createdAt ||
                  0
                ).getTime() -
                new Date(
                  b.allocation
                    .createdAt ||
                  0
                ).getTime()
              );
            }
          );


      const remainingSoldMap =
        new Map(soldMap);


      const enrichedByIndex =
        new Array(
          allocations.length
        );


      for (
        const entry of
        allocationIndexes
      ) {

        const allocation =
          entry.allocation;
        const isCancelled =
          String(
            allocation.status || ""
          )
            .trim()
            .toUpperCase() ===
          "CANCELLED";


        const salesmanId =
          (
            allocation.salesmanId ||
            ""
          )
            .toString()
            .trim()
            .toUpperCase();


        const allocationProducts =
          Array.isArray(
            allocation.products
          )
            ? allocation.products
            : [];


        let allocationSoldQuantity =
          0;

        let allocationReturnedQuantity =
          0;

        let allocationRemainingQuantity =
          0;
        let allocationSalesValue =
          0;

        let allocationCashSales =
          0;

        let allocationOnlineSales =
          0;

        let allocationCreditSales =
          0;


        const enrichedProducts =
          allocationProducts.map(
            (item) => {

              const productId =
                (
                  item.productId ||
                  ""
                )
                  .toString()
                  .trim()
                  .toUpperCase();


              const allocatedQuantity =
                Number(
                  item.quantity
                ) || 0;

              const returnedQuantity =
                Number(
                  item.returnedQuantity
                ) || 0;


              // ==================================================
              // CANCELLED ALLOCATION
              //
              // Stock has already been restored to Main Godown.
              // Therefore this allocation:
              // - has no pending return
              // - must not consume salesman sales
              // - must not affect the next active allocation
              // ==================================================
              if (isCancelled) {

                allocationReturnedQuantity +=
                  returnedQuantity;

                return {
                  ...item,

                  soldQuantity:
                    0,

                  remainingQuantity:
                    0,

                  salesValue:
                    0,

                  cashSales:
                    0,

                  onlineSales:
                    0,

                  creditSales:
                    0,
                };
              }


              const usableAllocated =
                Math.max(
                  0,
                  allocatedQuantity -
                  returnedQuantity
                );


              const key =
                `${salesmanId}|${productId}`;


              const remainingSold =
                remainingSoldMap.get(
                  key
                ) || 0;


              const soldQuantity =
                Math.min(
                  usableAllocated,
                  remainingSold
                );


              remainingSoldMap.set(
                key,
                Math.max(
                  0,
                  remainingSold -
                  soldQuantity
                )
              );
              // ================================================
              // FINANCIAL VALUE FOR THIS ALLOCATION PRODUCT
              // ================================================

              let productSalesValue =
                0;

              let productCashSales =
                0;

              let productOnlineSales =
                0;

              let productCreditSales =
                0;


              let quantityToConsume =
                soldQuantity;


              const financialQueue =
                financialQueueMap.get(key) || [];


              while (
                quantityToConsume > 0 &&
                financialQueue.length > 0
              ) {

                const salePart =
                  financialQueue[0];


                const availableSaleQty =
                  Number(
                    salePart.remainingQty
                  ) || 0;


                if (availableSaleQty <= 0) {

                  financialQueue.shift();

                  continue;
                }


                const consumedQty =
                  Math.min(
                    quantityToConsume,
                    availableSaleQty
                  );


                const consumedAmount =
                  consumedQty *
                  (
                    Number(
                      salePart.unitAmount
                    ) || 0
                  );


                productSalesValue +=
                  consumedAmount;


                const paymentMode =
                  (
                    salePart.paymentMode || ""
                  )
                    .toString()
                    .trim()
                    .toLowerCase();


                if (paymentMode === "cash") {

                  productCashSales +=
                    consumedAmount;
                }

                else if (
                  paymentMode === "upi" ||
                  paymentMode ===
                  "bank transfer"
                ) {

                  productOnlineSales +=
                    consumedAmount;
                }

                else if (
                  paymentMode === "credit"
                ) {

                  productCreditSales +=
                    consumedAmount;
                }


                salePart.remainingQty -=
                  consumedQty;


                quantityToConsume -=
                  consumedQty;


                if (
                  salePart.remainingQty <= 0
                ) {

                  financialQueue.shift();
                }
              }


              const remainingQuantity =
                Math.max(
                  0,
                  allocatedQuantity -
                  returnedQuantity -
                  soldQuantity
                );


              allocationSoldQuantity +=
                soldQuantity;

              allocationReturnedQuantity +=
                returnedQuantity;

              allocationRemainingQuantity +=
                remainingQuantity;

              allocationSalesValue +=
                productSalesValue;

              allocationCashSales +=
                productCashSales;

              allocationOnlineSales +=
                productOnlineSales;

              allocationCreditSales +=
                productCreditSales;

              return {
                ...item,

                soldQuantity:
                  soldQuantity,

                remainingQuantity:
                  remainingQuantity,

                salesValue:
                  Number(
                    productSalesValue
                      .toFixed(2)
                  ),

                cashSales:
                  Number(
                    productCashSales
                      .toFixed(2)
                  ),

                onlineSales:
                  Number(
                    productOnlineSales
                      .toFixed(2)
                  ),

                creditSales:
                  Number(
                    productCreditSales
                      .toFixed(2)
                  ),
              };
            }
          );


        enrichedByIndex[
          entry.index
        ] = {
          ...allocation,

          products:
            enrichedProducts,

          soldQuantity:
            allocationSoldQuantity,

          returnedQuantity:
            allocationReturnedQuantity,

          remainingQuantity:
            allocationRemainingQuantity,
          salesValue:
            Number(
              allocationSalesValue
                .toFixed(2)
            ),

          cashSales:
            Number(
              allocationCashSales
                .toFixed(2)
            ),

          onlineSales:
            Number(
              allocationOnlineSales
                .toFixed(2)
            ),

          creditSales:
            Number(
              allocationCreditSales
                .toFixed(2)
            ),
        };
      }

// ======================================================
// TODAY / PENDING / ALL SECTION
//
// IMPORTANT:
// We filter AFTER FIFO calculation.
//
// Otherwise older allocations could be excluded before
// sales are consumed against them and sold quantities
// could become incorrect.
// ======================================================

const requestedSection =
  (
    req.query.section ||
    "all"
  )
    .toString()
    .trim()
    .toLowerCase();


if (
  ![
    "today",
    "pending",
    "all",
  ].includes(
    requestedSection
  )
) {
  return res
    .status(400)
    .json({
      success: false,

      message:
        "Invalid allocation section. Use today, pending or all.",
    });
}


const {
  start:
    todayStart,

  end:
    todayEnd,

  date:
    businessDate,
} =
  getAllocationBusinessDayRange(
    req.query.date
  );


// ======================================================
// ADD UI/SECTION INFORMATION TO EACH ALLOCATION
// ======================================================

const sectionReadyData =
  enrichedByIndex.map(
    (allocation) => {

      const allocationDate =
        new Date(
          allocation.allocationDate ||
          allocation.createdAt
        );


      const status =
        (
          allocation.status ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      const remainingQuantity =
        Number(
          allocation.remainingQuantity
        ) || 0;


      const isToday =
        allocationDate >=
          todayStart &&
        allocationDate <
          todayEnd;


      const isPending =
        status !== "CANCELLED" &&
        status !== "DELETED" &&
        remainingQuantity > 0 &&
        allocationDate <
          todayStart;


      const isCompleted =
        status !== "CANCELLED" &&
        status !== "DELETED" &&
        remainingQuantity <= 0;


      const isUpcoming =
        status !== "CANCELLED" &&
        status !== "DELETED" &&
        allocationDate >=
          todayEnd;


      return {
        ...allocation,

        allocationSection:
          isToday
            ? "TODAY"
            : isPending
              ? "PENDING"
              : isUpcoming
                ? "UPCOMING"
                : isCompleted
                  ? "COMPLETED"
                  : "ALL",

        isToday:
          isToday,

        isPending:
          isPending,

        isCompleted:
          isCompleted,
      };
    }
  );


// ======================================================
// SUMMARY COUNTS FOR FRONTEND TABS
// ======================================================

const summary = {

  today:
    sectionReadyData.filter(
      (item) =>
        item.isToday
    ).length,

  pending:
    sectionReadyData.filter(
      (item) =>
        item.isPending
    ).length,

  all:
    sectionReadyData.length,

  completed:
    sectionReadyData.filter(
      (item) =>
        item.isCompleted
    ).length,

  cancelled:
    sectionReadyData.filter(
      (item) =>
        (
          item.status ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase() ===
        "CANCELLED"
    ).length,
};


// ======================================================
// APPLY REQUESTED SECTION
// ======================================================

let finalData =
  sectionReadyData;


if (
  requestedSection ===
  "today"
) {
  finalData =
    sectionReadyData.filter(
      (item) =>
        item.isToday
    );
}


if (
  requestedSection ===
  "pending"
) {
  finalData =
    sectionReadyData.filter(
      (item) =>
        item.isPending
    );
}


// ======================================================
// RESPONSE
// ======================================================

return res.status(200).json({

  success:
    true,

  section:
    requestedSection,

  businessDate:
    businessDate,

  count:
    finalData.length,

  summary:
    summary,

  data:
    finalData,
});


    } catch (error) {

      console.error(
        "GET ALLOCATIONS ERROR:",
        error
      );


      return res.status(500).json({

        success:
          false,

        message:
          "Unable to load allocations.",

        error:
          error.message,
      });
    }
  }
);

// ======================================================
// GET SINGLE ALLOCATION
//
// ADMIN
// -> Can view any allocation of own farm
//
// SALESMAN
// -> Can view only own allocation
// ======================================================

app.get(
  "/api/allocations/:allocationId",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission("allocationView", "returnsManage"),
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const role =
        req.user.role;

      const allocationId = (
        req.params.allocationId ||
        ""
      )
        .toString()
        .trim()
        .toUpperCase();

      if (!allocationId) {
        return res
          .status(400)
          .json({
            success: false,
            message:
              "Allocation ID is required.",
          });
      }

    const allocation =
  await Allocation.findOne({
    farmId,
    allocationId,

    status: {
      $ne: "DELETED",
    },
  }).lean();

      if (!allocation) {
        return res
          .status(404)
          .json({
            success: false,
            message:
              "Allocation not found.",
          });
      }

      // ================================================
      // ROLE SECURITY
      // ================================================

      if (role === "salesman") {
        const salesman =
          await Salesman.findOne({
            _id:
              req.user.userId,
            farmId,
            isActive: true,
          }).lean();

        if (!salesman) {
          return res
            .status(404)
            .json({
              success: false,
              message:
                "Salesman account not found.",
            });
        }

        if (
          salesman.salesmanId
            .toString()
            .trim()
            .toUpperCase() !==
          allocation.salesmanId
            .toString()
            .trim()
            .toUpperCase()
        ) {
          return res
            .status(403)
            .json({
              success: false,
              message:
                "You cannot view another salesman's allocation.",
            });
        }
      } else if (
        role !== "admin"
      ) {
        return res
          .status(403)
          .json({
            success: false,
            message:
              "You are not allowed to view this allocation.",
          });
      }

      // ================================================
      // SOLD QUANTITY FOR THIS ALLOCATION
      // ================================================

      const soldMap =
        await getSoldQuantityForAllocation({
          farmId,
          salesmanId:
            allocation.salesmanId,
          allocationId:
            allocation.allocationId,
        });

      const products = (
        allocation.products || []
      ).map((item) => {
        const productId = (
          item.productId || ""
        )
          .toString()
          .trim()
          .toUpperCase();

        const allocated =
          Number(item.quantity) ||
          0;

        const returned =
          Number(
            item.returnedQuantity
          ) || 0;

        const isCancelled =
          String(
            allocation.status || ""
          )
            .trim()
            .toUpperCase() ===
          "CANCELLED";


        const sold =
          isCancelled
            ? 0
            : Number(
              soldMap.get(
                productId
              ) || 0
            );


        return {
          ...item,

          soldQuantity:
            sold,

          remainingQuantity:
            isCancelled
              ? 0
              : Math.max(
                0,
                allocated -
                returned -
                sold
              ),
        };
      });

      return res
        .status(200)
        .json({
          success: true,

          data: {
            ...allocation,
            products,
          },
        });
    } catch (error) {
      console.error(
        "GET SINGLE ALLOCATION ERROR:",
        error
      );

      return res
        .status(500)
        .json({
          success: false,
          message:
            "Unable to load allocation.",
          error:
            error.message,
        });
    }
  }
);
// ======================================================
// ADD ALLOCATION
// ATOMIC TRANSACTION
//
// TRN_ALLOCATION
// + MAS_PRODUCT STOCK OUT
// + TRN_STOCK ALLOCATION_OUT
// ======================================================

app.post(
  "/api/allocations",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {

    const session =
      await mongoose.startSession();

    try {

      let savedAllocation =
        null;


      await session.withTransaction(
        async () => {

          const farmId =
            req.user.farmId;


          const {
            allocationDate,
            salesmanId,
            routeId,
            products,
            notes,
          } = req.body;


          // ============================================
          // BASIC VALIDATION
          // ============================================

          if (
            !salesmanId ||
            !salesmanId
              .toString()
              .trim()
          ) {

            const error =
              new Error(
                "Salesman is required."
              );

            error.statusCode =
              400;

            throw error;
          }


          if (
            !routeId ||
            !routeId
              .toString()
              .trim()
          ) {

            const error =
              new Error(
                "Route is required."
              );

            error.statusCode =
              400;

            throw error;
          }


          if (
            !Array.isArray(
              products
            ) ||
            products.length === 0
          ) {

            const error =
              new Error(
                "Please select at least one product."
              );

            error.statusCode =
              400;

            throw error;
          }


          // ============================================
          // NORMALIZE IDS
          // ============================================

          const normalizedSalesmanId =
            salesmanId
              .toString()
              .trim()
              .toUpperCase();


          const normalizedRouteId =
            routeId
              .toString()
              .trim()
              .toUpperCase();





          // ============================================
          // VERIFY SALESMAN
          // ============================================

          const salesman =
            await Salesman.findOne({
              farmId:
                farmId,

              salesmanId:
                normalizedSalesmanId,

              isActive:
                true,
            }).session(
              session
            );


          if (!salesman) {

            const error =
              new Error(
                "Selected salesman not found."
              );

            error.statusCode =
              404;

            throw error;
          }


          // ============================================
          // VERIFY ROUTE
          // ============================================

          const route =
            await RouteMaster.findOne({
              farmId:
                farmId,

              routeId:
                normalizedRouteId,

              isActive:
                true,
            }).session(
              session
            );


          if (!route) {

            const error =
              new Error(
                "Selected route not found."
              );

            error.statusCode =
              404;

            throw error;
          }


          // ============================================
          // VERIFY ROUTE SALESMAN
          //
          // If route already has a salesman assigned,
          // allocation must use that salesman.
          // ============================================

          if (
            route.salesmanId &&
            route.salesmanId
              .toString()
              .trim() &&
            route.salesmanId
              .toString()
              .trim()
              .toUpperCase() !==
            normalizedSalesmanId
          ) {

            const error =
              new Error(
                `Route ${route.routeName} is assigned to ${route.salesmanName || "another salesman"}.`
              );

            error.statusCode =
              400;

            throw error;
          }



          // ============================================
          // VERIFY PRODUCTS + STOCK
          // ============================================

          const verifiedProducts =
            [];


          const usedProductIds =
            new Set();


          let totalQuantity =
            0;


          for (
            const item of
            products
          ) {

            const productId =
              item.productId
                ?.toString()
                .trim()
                .toUpperCase() ||
              "";


            const quantity =
              Number(
                item.quantity
              );


            if (!productId) {

              const error =
                new Error(
                  "Invalid product selected."
                );

              error.statusCode =
                400;

              throw error;
            }


            if (
              !Number.isFinite(
                quantity
              ) ||
              quantity <= 0
            ) {

              const error =
                new Error(
                  "Allocation quantity must be greater than zero."
                );

              error.statusCode =
                400;

              throw error;
            }


            // ==========================================
            // PREVENT SAME PRODUCT TWICE
            // ==========================================

            if (
              usedProductIds.has(
                productId
              )
            ) {

              const error =
                new Error(
                  "Same product cannot be added twice in one allocation."
                );

              error.statusCode =
                400;

              throw error;
            }


            usedProductIds.add(
              productId
            );


            const product =
              await Product.findOne({
                farmId:
                  farmId,

                productId:
                  productId,

                isActive:
                  true,
              }).session(
                session
              );


            if (!product) {

              const error =
                new Error(
                  `Product ${productId} not found.`
                );

              error.statusCode =
                404;

              throw error;
            }


            // ==========================================
            // CHECK CURRENT STOCK
            // ==========================================

            if (
              Number(
                product.stock
              ) <
              quantity
            ) {

              const error =
                new Error(
                  `Insufficient stock for ${product.productName}. Available stock is ${Number(product.stock)} ${product.unit}.`
                );

              error.statusCode =
                400;

              throw error;
            }


            verifiedProducts.push({
              productId:
                product.productId,

              productName:
                product.productName,

              variant:
                product.variant ||
                "",

              unit:
                product.unit,

              quantity:
                quantity,

              returnedQuantity:
                0,

              rate:
                Number(
                  product.price
                ) || 0,
            });


            totalQuantity +=
              quantity;
          }


          // ============================================
          // GENERATE ALLOCATION NUMBER
          // ============================================

          const allocationId =
            await generateAllocationId();


          const allocationNo =
            await generateAllocationNo(
              farmId
            );


          const finalAllocationDate =
            allocationDate
              ? new Date(
                allocationDate
              )
              : new Date();


          if (
            Number.isNaN(
              finalAllocationDate
                .getTime()
            )
          ) {

            const error =
              new Error(
                "Invalid allocation date."
              );

            error.statusCode =
              400;

            throw error;
          }


          // ============================================
          // CREATE TRN_ALLOCATION
          // ============================================

          const allocationDocs =
            await Allocation.create(
              [
                {
                  farmId:
                    farmId,

                  allocationId:
                    allocationId,

                  allocationNo:
                    allocationNo,

                  allocationDate:
                    finalAllocationDate,

                  salesmanId:
                    salesman.salesmanId,

                  salesmanName:
                    salesman.name,

                  routeId:
                    route.routeId,

                  routeName:
                    route.routeName,

                  products:
                    verifiedProducts.map(
                      (line) => ({
                        productId:
                          line.productId,

                        productName:
                          line.productName,

                        variant:
                          line.variant,

                        unit:
                          line.unit,

                        quantity:
                          line.quantity,

                        returnedQuantity:
                          0,
                      })
                    ),

                  totalItems:
                    verifiedProducts.length,

                  totalQuantity:
                    totalQuantity,

                  notes:
                    notes
                      ?.toString()
                      .trim() ||
                    "",

                  status:
                    "POSTED",

                  createdBy:
                    req.user.userId || "",
                },
              ],
              {
                session:
                  session,
              }
            );

          const allocation =
            allocationDocs[0];


          // ============================================
          // MAIN STOCK OUT
          // ============================================

          for (
            const line of
            verifiedProducts
          ) {

            const updateResult =
              await Product.updateOne(
                {
                  farmId:
                    farmId,

                  productId:
                    line.productId,

                  stock: {
                    $gte:
                      line.quantity,
                  },
                },

                {
                  $inc: {
                    stock:
                      -line.quantity,
                  },

                  $set: {
                    updatedAt:
                      new Date(),
                  },
                },

                {
                  session:
                    session,
                }
              );


            if (
              updateResult.modifiedCount !==
              1
            ) {

              const error =
                new Error(
                  `Unable to allocate ${line.productName}. Stock may have changed.`
                );

              error.statusCode =
                409;

              throw error;
            }


            // ==========================================
            // TRN_STOCK - ALLOCATION_OUT
            // ==========================================

            const stockId =
              await generateStockId();



            await StockTransaction.create(
              [
                {
                  farmId:
                    farmId,

                  stockId:
                    stockId,

                  productId:
                    line.productId,

                  productName:
                    line.productName,

                  transactionType:
                    "ALLOCATION_OUT",

                  referenceType:
                    "ALLOCATION",

                  referenceId:
                    allocation.allocationId,

                  referenceNo:
                    allocation.allocationNo,

                  quantityIn:
                    0,

                  quantityOut:
                    line.quantity,

                  rate:
                    line.rate,

                  godown:
                    "Main Godown",

                  createdBy:
                    req.user.userId ||
                    "",
                },
              ],

              {
                session:
                  session,
              }
            );
          }


          savedAllocation =
            allocation;
        }
      );


      // ================================================
      // SUCCESS
      // ================================================

      return res.status(201).json({
        success:
          true,

        message:
          "Allocation saved and stock updated successfully.",

        data:
          savedAllocation,
      });


    } catch (error) {

      console.error(
        "ADD ALLOCATION ERROR:",
        error
      );


      return res
        .status(
          error.statusCode ||
          500
        )
        .json({
          success:
            false,

          message:
            error.message ||
            "Unable to save allocation.",
        });


    } finally {

      await session.endSession();
    }
  }
);
// ======================================================
// EDIT ALLOCATION
// PUT /api/allocations/:allocationId
//
// ADMIN ONLY
//
// STOCK DELTA:
//
// OLD 20 -> NEW 30
//   Additional 10 OUT
//   ALLOCATION_EDIT
//
// OLD 20 -> NEW 15
//   5 back into warehouse
//   ALLOCATION_EDIT_REVERSE
//
// IMPORTANT:
// New Qty can never go below:
// Sold Qty + Returned Qty
// ======================================================

app.put(
  "/api/allocations/:allocationId",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    const session =
      await mongoose.startSession();

    try {
      let updatedAllocation =
        null;

      await session.withTransaction(
        async () => {
          const farmId =
            req.user.farmId;

          const userId =
            req.user.userId;

          // ==============================================
          // ADMIN ONLY
          // ==============================================

          if (
            req.user.role !==
            "admin"
          ) {
            const error =
              new Error(
                "Only admin can edit allocation."
              );

            error.statusCode =
              403;

            throw error;
          }

          const allocationId = (
            req.params
              .allocationId ||
            ""
          )
            .toString()
            .trim()
            .toUpperCase();

          if (!allocationId) {
            const error =
              new Error(
                "Allocation ID is required."
              );

            error.statusCode =
              400;

            throw error;
          }

          // ==============================================
          // ORIGINAL ALLOCATION
          // ==============================================

          const allocation =
            await Allocation.findOne({
              farmId,
              allocationId,
            }).session(session);

          if (!allocation) {
            const error =
              new Error(
                "Allocation not found."
              );

            error.statusCode =
              404;

            throw error;
          }

          if (
            allocation.status !==
            "POSTED"
          ) {
            const error =
              new Error(
                `${allocation.status} allocation cannot be edited.`
              );

            error.statusCode =
              400;

            throw error;
          }

          const {
            allocationDate,
            salesmanId,
            routeId,
            products,
            notes,
          } = req.body;

          if (
            !Array.isArray(
              products
            ) ||
            products.length ===
            0
          ) {
            const error =
              new Error(
                "Please select at least one product."
              );

            error.statusCode =
              400;

            throw error;
          }

          // ==============================================
          // SOLD QUANTITY OF THIS ALLOCATION
          // BEFORE EDIT
          // ==============================================

          const soldMap =
            await getSoldQuantityForAllocation({
              farmId,
              salesmanId:
                allocation
                  .salesmanId,
              allocationId:
                allocation
                  .allocationId,
              session,
            });

          let hasActivity =
            false;

          for (
            const item of
            allocation.products
          ) {
            const productId = (
              item.productId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();

            const sold =
              Number(
                soldMap.get(
                  productId
                ) || 0
              );

            const returned =
              Number(
                item
                  .returnedQuantity
              ) || 0;

            if (
              sold > 0 ||
              returned > 0
            ) {
              hasActivity =
                true;

              break;
            }
          }

          // ==============================================
          // SALESMAN
          // ==============================================

          const normalizedSalesmanId =
            (
              salesmanId ||
              allocation.salesmanId
            )
              .toString()
              .trim()
              .toUpperCase();

          const salesman =
            await Salesman.findOne({
              farmId,
              salesmanId:
                normalizedSalesmanId,
              isActive: true,
            }).session(session);

          if (!salesman) {
            const error =
              new Error(
                "Selected salesman not found."
              );

            error.statusCode =
              404;

            throw error;
          }

          // ==============================================
          // ROUTE
          // ==============================================

          const normalizedRouteId =
            (
              routeId ||
              allocation.routeId
            )
              .toString()
              .trim()
              .toUpperCase();

          const route =
            await RouteMaster.findOne({
              farmId,
              routeId:
                normalizedRouteId,
              isActive: true,
            }).session(session);

          if (!route) {
            const error =
              new Error(
                "Selected route not found."
              );

            error.statusCode =
              404;

            throw error;
          }

          // Route must belong to selected salesman
          if (
            route.salesmanId &&
            route.salesmanId
              .toString()
              .trim() &&
            route.salesmanId
              .toString()
              .trim()
              .toUpperCase() !==
            normalizedSalesmanId
          ) {
            const error =
              new Error(
                "Selected route is assigned to another salesman."
              );

            error.statusCode =
              400;

            throw error;
          }

          // ==============================================
          // AFTER SALES/RETURN ACTIVITY
          // SALESMAN / ROUTE CANNOT BE CHANGED
          // ==============================================

          if (hasActivity) {
            if (
              normalizedSalesmanId !==
              allocation.salesmanId
                .toString()
                .trim()
                .toUpperCase()
            ) {
              const error =
                new Error(
                  "Salesman cannot be changed after sales or return activity."
                );

              error.statusCode =
                400;

              throw error;
            }

            if (
              normalizedRouteId !==
              (
                allocation.routeId ||
                ""
              )
                .toString()
                .trim()
                .toUpperCase()
            ) {
              const error =
                new Error(
                  "Route cannot be changed after sales or return activity."
                );

              error.statusCode =
                400;

              throw error;
            }
          }

          // ==============================================
          // OLD PRODUCT MAP
          // ==============================================

          const oldProductMap =
            new Map();

          for (
            const oldItem of
            allocation.products
          ) {
            const id =
              oldItem.productId
                .toString()
                .trim()
                .toUpperCase();

            oldProductMap.set(
              id,
              {
                quantity:
                  Number(
                    oldItem.quantity
                  ) || 0,

                returnedQuantity:
                  Number(
                    oldItem
                      .returnedQuantity
                  ) || 0,

                productName:
                  oldItem
                    .productName,

                variant:
                  oldItem
                    .variant ||
                  "",

                unit:
                  oldItem.unit,
              }
            );
          }

          // ==============================================
          // VERIFY NEW PRODUCTS
          // ==============================================

          const newProducts =
            [];

          const newProductMap =
            new Map();

          const receivedIds =
            new Set();

          let totalQuantity =
            0;

          for (
            const line of products
          ) {
            const productId = (
              line.productId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();

            const quantity =
              Number(
                line.quantity
              );

            if (!productId) {
              const error =
                new Error(
                  "Invalid product."
                );

              error.statusCode =
                400;

              throw error;
            }

            if (
              receivedIds.has(
                productId
              )
            ) {
              const error =
                new Error(
                  `Product ${productId} is repeated in allocation.`
                );

              error.statusCode =
                400;

              throw error;
            }

            receivedIds.add(
              productId
            );

            if (
              !Number.isFinite(
                quantity
              ) ||
              quantity <= 0 ||
              !Number.isInteger(
                quantity
              )
            ) {
              const error =
                new Error(
                  `Invalid quantity for ${productId}.`
                );

              error.statusCode =
                400;

              throw error;
            }

            const product =
              await Product.findOne({
                farmId,
                productId,
                isActive: true,
              }).session(session);

            if (!product) {
              const error =
                new Error(
                  `Product ${productId} not found.`
                );

              error.statusCode =
                404;

              throw error;
            }

            const oldRow =
              oldProductMap.get(
                productId
              );

            const returnedQty =
              Number(
                oldRow
                  ?.returnedQuantity ||
                0
              );

            const soldQty =
              Number(
                soldMap.get(
                  productId
                ) || 0
              );

            const minimumQty =
              soldQty +
              returnedQty;

            if (
              quantity <
              minimumQty
            ) {
              const error =
                new Error(
                  `${product.productName} cannot be reduced below ${minimumQty}. Sold: ${soldQty}, Returned: ${returnedQty}.`
                );

              error.statusCode =
                400;

              throw error;
            }

            newProducts.push({
              productId:
                product.productId,

              productName:
                product.productName,

              variant:
                product.variant ||
                "",

              unit:
                product.unit,

              quantity:
                quantity,

              returnedQuantity:
                returnedQty,
            });

            newProductMap.set(
              productId,
              {
                quantity,
                product,
              }
            );

            totalQuantity +=
              quantity;
          }

          // ==============================================
          // REMOVED PRODUCTS
          // ==============================================

          for (
            const [
              productId,
              oldRow,
            ] of
            oldProductMap.entries()
          ) {
            if (
              newProductMap.has(
                productId
              )
            ) {
              continue;
            }

            const soldQty =
              Number(
                soldMap.get(
                  productId
                ) || 0
              );

            const returnedQty =
              Number(
                oldRow
                  .returnedQuantity
              ) || 0;

            if (
              soldQty > 0 ||
              returnedQty > 0
            ) {
              const error =
                new Error(
                  `${oldRow.productName} cannot be removed because sales/returns already exist.`
                );

              error.statusCode =
                400;

              throw error;
            }
          }

          // ==============================================
          // ALL PRODUCT IDS
          // OLD + NEW
          // ==============================================

          const allProductIds =
            new Set([
              ...oldProductMap.keys(),
              ...newProductMap.keys(),
            ]);

          // ==============================================
          // APPLY STOCK DELTA
          // ==============================================

          for (
            const productId of
            allProductIds
          ) {
            const oldQty =
              Number(
                oldProductMap.get(
                  productId
                )?.quantity || 0
              );

            const newQty =
              Number(
                newProductMap.get(
                  productId
                )?.quantity || 0
              );

            const difference =
              newQty -
              oldQty;

            if (
              difference === 0
            ) {
              continue;
            }

            let product =
              newProductMap.get(
                productId
              )?.product;

            if (!product) {
              product =
                await Product.findOne({
                  farmId,
                  productId,
                }).session(session);
            }

            if (!product) {
              const error =
                new Error(
                  `Product ${productId} not found.`
                );

              error.statusCode =
                404;

              throw error;
            }

            // ------------------------------------------
            // INCREASE ALLOCATION
            // EXTRA WAREHOUSE STOCK OUT
            // ------------------------------------------

            if (
              difference > 0
            ) {
              const stockResult =
                await Product.updateOne(
                  {
                    farmId,
                    productId,

                    stock: {
                      $gte:
                        difference,
                    },
                  },

                  {
                    $inc: {
                      stock:
                        -difference,
                    },

                    $set: {
                      updatedAt:
                        new Date(),
                    },
                  },

                  {
                    session,
                  }
                );

              if (
                stockResult
                  .modifiedCount !==
                1
              ) {
                const error =
                  new Error(
                    `Insufficient stock for ${product.productName}.`
                  );

                error.statusCode =
                  409;

                throw error;
              }

              const stockId =
                await generateStockId();

              await StockTransaction.create(
                [
                  {
                    farmId,

                    stockId,

                    productId:
                      product
                        .productId,

                    productName:
                      product
                        .productName,

                    transactionType:
                      "ALLOCATION_EDIT",

                    referenceType:
                      "ALLOCATION",

                    referenceId:
                      allocation
                        .allocationId,

                    referenceNo:
                      allocation
                        .allocationNo,

                    quantityIn:
                      0,

                    quantityOut:
                      difference,

                    rate:
                      Number(
                        product.price
                      ) || 0,

                    godown:
                      "Main Godown",

                    createdBy:
                      userId ||
                      "",
                  },
                ],

                {
                  session,
                }
              );
            }

            // ------------------------------------------
            // REDUCE ALLOCATION
            // UNUSED STOCK BACK TO WAREHOUSE
            // ------------------------------------------

            if (
              difference < 0
            ) {
              const quantityBack =
                Math.abs(
                  difference
                );

              await Product.updateOne(
                {
                  farmId,
                  productId,
                },

                {
                  $inc: {
                    stock:
                      quantityBack,
                  },

                  $set: {
                    updatedAt:
                      new Date(),
                  },
                },

                {
                  session,
                }
              );

              const stockId =
                await generateStockId();

              await StockTransaction.create(
                [
                  {
                    farmId,

                    stockId,

                    productId:
                      product
                        .productId,

                    productName:
                      product
                        .productName,

                    transactionType:
                      "ALLOCATION_EDIT_REVERSE",

                    referenceType:
                      "ALLOCATION",

                    referenceId:
                      allocation
                        .allocationId,

                    referenceNo:
                      allocation
                        .allocationNo,

                    quantityIn:
                      quantityBack,

                    quantityOut:
                      0,

                    rate:
                      Number(
                        product.price
                      ) || 0,

                    godown:
                      "Main Godown",

                    createdBy:
                      userId ||
                      "",
                  },
                ],

                {
                  session,
                }
              );
            }
          }

          // ==============================================
          // UPDATE ALLOCATION
          // ==============================================

          if (
            allocationDate
          ) {
            const parsedDate =
              new Date(
                allocationDate
              );

            if (
              Number.isNaN(
                parsedDate.getTime()
              )
            ) {
              const error =
                new Error(
                  "Invalid allocation date."
                );

              error.statusCode =
                400;

              throw error;
            }

            allocation
              .allocationDate =
              parsedDate;
          }

          allocation.salesmanId =
            salesman.salesmanId;

          allocation.salesmanName =
            salesman.name;

          allocation.routeId =
            route.routeId;

          allocation.routeName =
            route.routeName;

          allocation.products =
            newProducts;

          allocation.totalItems =
            newProducts.length;

          allocation.totalQuantity =
            totalQuantity;

          if (
            notes !== undefined
          ) {
            allocation.notes =
              (
                notes || ""
              )
                .toString()
                .trim();
          }

          allocation.updatedBy =
            userId || "";

          allocation.updatedAt =
            new Date();

          await allocation.save({
            session,
          });

          updatedAllocation =
            allocation;
        }
      );

      return res
        .status(200)
        .json({
          success: true,

          message:
            "Allocation updated and stock adjusted successfully.",

          data:
            updatedAllocation,
        });
    } catch (error) {
      console.error(
        "EDIT ALLOCATION ERROR:",
        error
      );

      return res
        .status(
          error.statusCode ||
          500
        )
        .json({
          success: false,

          message:
            error.message ||
            "Unable to update allocation.",
        });
    } finally {
      await session.endSession();
    }
  }
);
// ======================================================
// CANCEL ALLOCATION
// PUT /api/allocations/:allocationId/cancel
//
// ADMIN ONLY
//
// No hard delete.
//
// Allowed only when:
// - status = POSTED
// - no sold quantity
// - no returned quantity
//
// Entire allocated quantity returns to warehouse.
// ======================================================

app.put(
  "/api/allocations/:allocationId/cancel",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    const session =
      await mongoose.startSession();

    try {
      let cancelledAllocation =
        null;

      await session.withTransaction(
        async () => {
          const farmId =
            req.user.farmId;

          const userId =
            req.user.userId;

          if (
            req.user.role !==
            "admin"
          ) {
            const error =
              new Error(
                "Only admin can cancel allocation."
              );

            error.statusCode =
              403;

            throw error;
          }

          const allocationId = (
            req.params
              .allocationId ||
            ""
          )
            .toString()
            .trim()
            .toUpperCase();

          const allocation =
            await Allocation.findOne({
              farmId,
              allocationId,
            }).session(session);

          if (!allocation) {
            const error =
              new Error(
                "Allocation not found."
              );

            error.statusCode =
              404;

            throw error;
          }

          if (
            allocation.status ===
            "CANCELLED"
          ) {
            const error =
              new Error(
                "Allocation is already cancelled."
              );

            error.statusCode =
              400;

            throw error;
          }

          if (
            allocation.status !==
            "POSTED"
          ) {
            const error =
              new Error(
                `${allocation.status} allocation cannot be cancelled.`
              );

            error.statusCode =
              400;

            throw error;
          }

          // ==============================================
          // SOLD QTY FOR THIS ALLOCATION
          // ==============================================

          const soldMap =
            await getSoldQuantityForAllocation({
              farmId,
              salesmanId:
                allocation
                  .salesmanId,
              allocationId:
                allocation
                  .allocationId,
              session,
            });

          // ==============================================
          // MUST HAVE ZERO SALE / ZERO RETURN
          // ==============================================

          for (
            const item of
            allocation.products
          ) {
            const productId = (
              item.productId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();

            const soldQty =
              Number(
                soldMap.get(
                  productId
                ) || 0
              );

            const returnedQty =
              Number(
                item
                  .returnedQuantity
              ) || 0;

            if (
              soldQty > 0
            ) {
              const error =
                new Error(
                  `${item.productName} already has sold quantity ${soldQty}. Allocation cannot be cancelled.`
                );

              error.statusCode =
                400;

              throw error;
            }

            if (
              returnedQty > 0
            ) {
              const error =
                new Error(
                  `${item.productName} already has return activity. Allocation cannot be cancelled.`
                );

              error.statusCode =
                400;

              throw error;
            }
          }

          // ==============================================
          // RESTORE STOCK
          // ==============================================

          for (
            const item of
            allocation.products
          ) {
            const quantity =
              Number(
                item.quantity
              ) || 0;

            if (
              quantity <= 0
            ) {
              continue;
            }

            const updateResult =
              await Product.updateOne(
                {
                  farmId,
                  productId:
                    item.productId,
                },

                {
                  $inc: {
                    stock:
                      quantity,
                  },

                  $set: {
                    updatedAt:
                      new Date(),
                  },
                },

                {
                  session,
                }
              );

            if (
              updateResult
                .matchedCount !==
              1
            ) {
              const error =
                new Error(
                  `Unable to restore ${item.productName}. Product not found.`
                );

              error.statusCode =
                409;

              throw error;
            }

            const stockId =
              await generateStockId();

            await StockTransaction.create(
              [
                {
                  farmId,

                  stockId,

                  productId:
                    item.productId,

                  productName:
                    item.productName,

                  transactionType:
                    "ALLOCATION_CANCEL",

                  referenceType:
                    "ALLOCATION",

                  referenceId:
                    allocation
                      .allocationId,

                  referenceNo:
                    allocation
                      .allocationNo,

                  quantityIn:
                    quantity,

                  quantityOut:
                    0,

                  rate:
                    0,

                  godown:
                    "Main Godown",

                  createdBy:
                    userId ||
                    "",
                },
              ],

              {
                session,
              }
            );
          }

          // ==============================================
          // MARK CANCELLED
          // ==============================================

          allocation.status =
            "CANCELLED";

          allocation.cancelledBy =
            userId || "";

          allocation.cancelledAt =
            new Date();

          allocation.updatedBy =
            userId || "";

          allocation.updatedAt =
            new Date();

          await allocation.save({
            session,
          });

          cancelledAllocation =
            allocation;
        }
      );

      return res
        .status(200)
        .json({
          success: true,

          message:
            "Allocation cancelled and stock restored successfully.",

          data:
            cancelledAllocation,
        });
    } catch (error) {
      console.error(
        "CANCEL ALLOCATION ERROR:",
        error
      );

      return res
        .status(
          error.statusCode ||
          500
        )
        .json({
          success: false,

          message:
            error.message ||
            "Unable to cancel allocation.",
        });
    } finally {
      await session.endSession();
    }
  }
);

// ======================================================
// DELETE ALLOCATION
// DELETE /api/allocations/:allocationId
//
// PRODUCTION SAFE SOFT DELETE
//
// ADMIN ONLY
//
// POSTED:
// -> Allowed only when:
//    sold quantity = 0
//    returned quantity = 0
//
// -> Full allocated stock restored
// -> ALLOCATION_DELETE stock transaction created
// -> Allocation marked DELETED
//
// CANCELLED:
// -> Stock was already restored during cancellation
// -> Do NOT restore stock again
// -> Simply mark allocation DELETED
//
// RETURNED / ACTIVITY:
// -> Cannot delete
//
// IMPORTANT:
// Document is NOT physically removed.
// This preserves transaction audit history.
// ======================================================

app.delete(
  "/api/allocations/:allocationId",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {

    const session =
      await mongoose.startSession();

    try {

      let deletedAllocation =
        null;


      await session.withTransaction(
        async () => {

          const farmId =
            req.user.farmId;

          const userId =
            req.user.userId;


          if (
            req.user.role !==
            "admin"
          ) {

            const error =
              new Error(
                "Only admin can delete allocation."
              );

            error.statusCode =
              403;

            throw error;
          }


          const allocationId =
            (
              req.params
                .allocationId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (!allocationId) {

            const error =
              new Error(
                "Allocation ID is required."
              );

            error.statusCode =
              400;

            throw error;
          }


          // ============================================
          // FIND ALLOCATION
          // ============================================

          const allocation =
            await Allocation.findOne({
              farmId:
                farmId,

              allocationId:
                allocationId,
            })
              .session(
                session
              );


          if (!allocation) {

            const error =
              new Error(
                "Allocation not found."
              );

            error.statusCode =
              404;

            throw error;
          }


          const currentStatus =
            (
              allocation.status ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (
            currentStatus ===
            "DELETED"
          ) {

            const error =
              new Error(
                "Allocation is already deleted."
              );

            error.statusCode =
              400;

            throw error;
          }


          // ============================================
          // RETURNED ALLOCATION CANNOT BE DELETED
          // ============================================

          if (
            currentStatus ===
            "RETURNED"
          ) {

            const error =
              new Error(
                "Returned allocation cannot be deleted because return activity already exists."
              );

            error.statusCode =
              400;

            throw error;
          }


          // ============================================
          // POSTED ALLOCATION
          //
          // CHECK SOLD + RETURN ACTIVITY
          // ============================================

          if (
            currentStatus ===
            "POSTED"
          ) {

            const soldMap =
              await getSoldQuantityForAllocation({
                farmId:
                  farmId,

                salesmanId:
                  allocation
                    .salesmanId,

                allocationId:
                  allocation
                    .allocationId,

                session:
                  session,
              });


            for (
              const item of
              allocation.products
            ) {

              const productId =
                (
                  item.productId ||
                  ""
                )
                  .toString()
                  .trim()
                  .toUpperCase();


              const soldQty =
                Number(
                  soldMap.get(
                    productId
                  ) || 0
                );


              const returnedQty =
                Number(
                  item
                    .returnedQuantity
                ) || 0;


              if (
                soldQty > 0
              ) {

                const error =
                  new Error(
                    `${item.productName} already has sold quantity ${soldQty}. Delete is not allowed.`
                  );

                error.statusCode =
                  400;

                throw error;
              }


              if (
                returnedQty > 0
              ) {

                const error =
                  new Error(
                    `${item.productName} already has return activity. Delete is not allowed.`
                  );

                error.statusCode =
                  400;

                throw error;
              }
            }


            // ==========================================
            // RESTORE ENTIRE ALLOCATED STOCK
            // ==========================================

            for (
              const item of
              allocation.products
            ) {

              const quantity =
                Number(
                  item.quantity
                ) || 0;


              if (
                quantity <= 0
              ) {
                continue;
              }


              const stockResult =
                await Product.updateOne(
                  {
                    farmId:
                      farmId,

                    productId:
                      item.productId,
                  },

                  {
                    $inc: {
                      stock:
                        quantity,
                    },

                    $set: {
                      updatedAt:
                        new Date(),
                    },
                  },

                  {
                    session:
                      session,
                  }
                );


              if (
                stockResult
                  .matchedCount !==
                1
              ) {

                const error =
                  new Error(
                    `Unable to restore ${item.productName}. Product not found.`
                  );

                error.statusCode =
                  409;

                throw error;
              }


              // ========================================
              // STOCK AUDIT ENTRY
              // ========================================

              const stockId =
                await generateStockId();


              await StockTransaction.create(
                [
                  {
                    farmId:
                      farmId,

                    stockId:
                      stockId,

                    productId:
                      item.productId,

                    productName:
                      item.productName,

                    transactionType:
                      "ALLOCATION_DELETE",

                    referenceType:
                      "ALLOCATION",

                    referenceId:
                      allocation
                        .allocationId,

                    referenceNo:
                      allocation
                        .allocationNo,

                    quantityIn:
                      quantity,

                    quantityOut:
                      0,

                    rate:
                      0,

                    godown:
                      "Main Godown",

                    createdBy:
                      userId ||
                      "",
                  },
                ],

                {
                  session:
                    session,
                }
              );
            }
          }


          // ============================================
          // CANCELLED ALLOCATION
          //
          // STOCK WAS ALREADY RESTORED DURING CANCEL.
          // DO NOT ADD STOCK AGAIN.
          // ============================================

          else if (
            currentStatus !==
            "CANCELLED"
          ) {

            const error =
              new Error(
                `${currentStatus} allocation cannot be deleted.`
              );

            error.statusCode =
              400;

            throw error;
          }


          // ============================================
          // SOFT DELETE
          // ============================================

          allocation.status =
            "DELETED";

          allocation.deletedBy =
            userId || "";

          allocation.deletedAt =
            new Date();

          allocation.deleteReason =
            (
              req.body
                ?.reason ||
              ""
            )
              .toString()
              .trim();

          allocation.updatedBy =
            userId || "";

          allocation.updatedAt =
            new Date();


          await allocation.save({
            session:
              session,
          });


          deletedAllocation =
            allocation;
        }
      );


      return res
        .status(200)
        .json({

          success:
            true,

          message:
            "Allocation deleted successfully.",

          data: {
            allocationId:
              deletedAllocation
                .allocationId,

            allocationNo:
              deletedAllocation
                .allocationNo,

            status:
              deletedAllocation
                .status,

            deletedAt:
              deletedAllocation
                .deletedAt,
          },
        });


    } catch (error) {

      console.error(
        "DELETE ALLOCATION ERROR:",
        error
      );


      return res
        .status(
          error.statusCode ||
          500
        )
        .json({

          success:
            false,

          message:
            error.message ||
            "Unable to delete allocation.",
        });


    } finally {

      await session.endSession();
    }
  }
);
// ======================================================
// RETURN / SETTLE ALLOCATION
//
// FLOW:
// TRN_ALLOCATION returnedQuantity update
// + MAS_PRODUCT good/resalable stock IN
// + TRN_STOCK ALLOCATION_RETURN
//
// IMPORTANT:
// SOLD QUANTITY IS READ FROM TRN_SALE.
// CLIENT CANNOT CHANGE SOLD QUANTITY.
// ======================================================

app.put(
  "/api/allocations/:allocationId/return",
  authenticateToken,
  loadAccessContext,
  requirePermission("returnsManage"),
  async (req, res) => {

    const session =
      await mongoose.startSession();

    try {

      let responseData = null;


      await session.withTransaction(
        async () => {

          const farmId =
            req.user.farmId;

          const allocationId =
            (
              req.params.allocationId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          // ==============================================
          // REQUEST
          // ==============================================

          const {
            productId,
            goodReturnQty,
            damageQty,
            shortExcessQty,
            returnType,
            reason,
            remarks,
          } = req.body;


          const normalizedProductId =
            (
              productId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          const goodReturn =
            Number(goodReturnQty) || 0;

          const damage =
            Number(damageQty) || 0;

          const shortExcess =
            Number(shortExcessQty) || 0;


          // ==============================================
          // BASIC VALIDATION
          // ==============================================

          if (!allocationId) {

            const error =
              new Error(
                "Allocation ID is required."
              );

            error.statusCode = 400;

            throw error;
          }


          if (!normalizedProductId) {

            const error =
              new Error(
                "Product ID is required."
              );

            error.statusCode = 400;

            throw error;
          }


          if (
            goodReturn < 0 ||
            damage < 0 ||
            shortExcess < 0
          ) {

            const error =
              new Error(
                "Return quantity cannot be negative."
              );

            error.statusCode = 400;

            throw error;
          }


          // ==============================================
          // FIND ALLOCATION
          // ==============================================

          const allocation =
            await Allocation.findOne({
              farmId: farmId,
              allocationId:
                allocationId,
            })
              .session(session);


          if (!allocation) {

            const error =
              new Error(
                "Allocation not found."
              );

            error.statusCode = 404;

            throw error;
          }


          if (
            allocation.status ===
            "CANCELLED"
          ) {

            const error =
              new Error(
                "Cancelled allocation cannot be returned."
              );

            error.statusCode = 400;

            throw error;
          }


          // ==============================================
          // SECURITY FOR SALESMAN
          //
          // SALESMAN CAN RETURN ONLY HIS OWN ALLOCATION.
          // ==============================================

          if (
            req.user.role ===
            "salesman"
          ) {

            const currentSalesman =
              await Salesman.findOne({
                _id:
                  req.user.userId,

                farmId:
                  farmId,

                isActive:
                  true,
              })
                .session(session);


            if (!currentSalesman) {

              const error =
                new Error(
                  "Salesman account not found."
                );

              error.statusCode = 403;

              throw error;
            }


            if (
              currentSalesman.salesmanId
                .toString()
                .trim()
                .toUpperCase() !==
              allocation.salesmanId
                .toString()
                .trim()
                .toUpperCase()
            ) {

              const error =
                new Error(
                  "You cannot return another salesman's allocation."
                );

              error.statusCode = 403;

              throw error;
            }
          }


          // ==============================================
          // FIND PRODUCT INSIDE ALLOCATION
          // ==============================================

          const allocationProduct =
            allocation.products.find(
              (item) =>
                item.productId
                  .toString()
                  .trim()
                  .toUpperCase() ===
                normalizedProductId
            );


          if (!allocationProduct) {

            const error =
              new Error(
                "Product not found in this allocation."
              );

            error.statusCode = 404;

            throw error;
          }


          const allocatedQty =
            Number(
              allocationProduct.quantity
            ) || 0;


          const alreadyReturnedQty =
            Number(
              allocationProduct
                .returnedQuantity
            ) || 0;


          // ==============================================
          // GET ACTUAL SOLD QUANTITY
          // FROM POSTED SALESMAN SALES
          // ==============================================

          const salesmanId =
            allocation.salesmanId
              .toString()
              .trim()
              .toUpperCase();


          const postedSales =
            await Sale.find({
              farmId:
                farmId,

              salesmanId:
                salesmanId,

              createdRole:
                "salesman",

              status:
                "POSTED",
            })
              .select("products")
              .session(session)
              .lean();


          let totalSoldQty = 0;


          for (
            const sale of postedSales
          ) {

            const saleProducts =
              Array.isArray(
                sale.products
              )
                ? sale.products
                : [];


            for (
              const saleItem of
              saleProducts
            ) {

              const saleProductId =
                (
                  saleItem.productId ||
                  ""
                )
                  .toString()
                  .trim()
                  .toUpperCase();


              if (
                saleProductId ===
                normalizedProductId
              ) {

                totalSoldQty +=
                  Number(
                    saleItem.quantity
                  ) || 0;
              }
            }
          }


          // ==============================================
          // FIND SOLD QUANTITY BELONGING TO THIS
          // PARTICULAR ALLOCATION
          //
          // SAME FIFO LOGIC AS GET /api/allocations
          // ==============================================

          const salesmanAllocations =
            await Allocation.find({

              farmId:
                farmId,

              salesmanId:
                salesmanId,

              status: {
                $in: [
                  "POSTED",
                  "RETURNED",
                ],
              },

              "products.productId":
                normalizedProductId,
            })
              .sort({
                allocationDate: 1,
                createdAt: 1,
              })
              .session(session)
              .lean();


          let soldRemaining =
            totalSoldQty;

          let soldForThisAllocation =
            0;


          for (
            const alloc of
            salesmanAllocations
          ) {

            const product =
              alloc.products.find(
                (item) =>
                  item.productId
                    .toString()
                    .trim()
                    .toUpperCase() ===
                  normalizedProductId
              );


            if (!product) {
              continue;
            }


            const qty =
              Number(
                product.quantity
              ) || 0;


            const returned =
              Number(
                product.returnedQuantity
              ) || 0;


            const usableQty =
              Math.max(
                0,
                qty - returned
              );


            const consumed =
              Math.min(
                usableQty,
                soldRemaining
              );


            if (
              alloc.allocationId
                .toString()
                .trim()
                .toUpperCase() ===
              allocationId
            ) {

              soldForThisAllocation =
                consumed;

              break;
            }


            soldRemaining =
              Math.max(
                0,
                soldRemaining -
                consumed
              );
          }


          // ==============================================
          // CURRENT UNSOLD / AVAILABLE QUANTITY
          // ==============================================

          const availableQty =
            Math.max(
              0,

              allocatedQty -
              alreadyReturnedQty -
              soldForThisAllocation
            );


          // ==============================================
          // RETURN QUANTITIES
          //
          // GOOD = COMES BACK INTO SALEABLE STOCK
          // DAMAGE = SETTLED BUT NOT SALEABLE STOCK
          //
          // SHORT/EXCESS IS RECONCILIATION ONLY.
          // ==============================================

          const physicalReturnQty =
            goodReturn +
            damage;


          if (
            physicalReturnQty >
            availableQty
          ) {

            const error =
              new Error(
                `Return quantity cannot exceed available quantity ${availableQty}.`
              );

            error.statusCode = 400;

            throw error;
          }


          // ==============================================
          // UPDATE ALLOCATION RETURNED QUANTITY
          // ==============================================

          allocationProduct
            .returnedQuantity =
            alreadyReturnedQty +
            physicalReturnQty;


          allocation.updatedAt =
            new Date();


          // If everything is now accounted for,
          // mark allocation RETURNED.

          const newRemainingQty =
            Math.max(
              0,

              allocatedQty -
              soldForThisAllocation -
              allocationProduct
                .returnedQuantity
            );


          // Keep allocation POSTED while individual products
          // are being settled.
          //
          // We will mark the whole allocation RETURNED only
          // after every product is fully reconciled.
          allocation.status =
            "POSTED";


          await allocation.save({
            session,
          });


          // ==============================================
          // RESTORE ONLY GOOD / RESALABLE RETURN
          // INTO MAIN GODOWN STOCK
          // ==============================================

          if (goodReturn > 0) {

            const product =
              await Product.findOneAndUpdate(
                {
                  farmId:
                    farmId,

                  productId:
                    normalizedProductId,
                },

                {
                  $inc: {
                    stock:
                      goodReturn,
                  },

                  $set: {
                    updatedAt:
                      new Date(),
                  },
                },

                {
                  new:
                    true,

                  session:
                    session,
                }
              );


            if (!product) {

              const error =
                new Error(
                  "Product master not found."
                );

              error.statusCode = 404;

              throw error;
            }


            // ============================================
            // STOCK LEDGER
            // ============================================

            const stockId =
              await generateStockId();

            await StockTransaction.create(
              [
                {
                  farmId:
                    farmId,

                  stockId:
                    stockId,

                  transactionType:
                    "ALLOCATION_RETURN",

                  referenceType:
                    "ALLOCATION",

                  referenceId:
                    allocation
                      .allocationId,

                  referenceNo:
                    allocation
                      .allocationNo,

                  transactionDate:
                    new Date(),

                  productId:
                    normalizedProductId,

                  productName:
                    allocationProduct
                      .productName,

                  variant:
                    allocationProduct
                      .variant || "",

                  unit:
                    allocationProduct
                      .unit,

                  quantityIn:
                    goodReturn,

                  quantityOut:
                    0,

                  rate:
                    0,

                  amount:
                    0,

                  godown:
                    "Main Godown",

                  remarks:
                    `Allocation return from ${allocation.salesmanName}`,

                  createdBy:
                    req.user.userId,

                  createdRole:
                    req.user.role,
                },
              ],

              {
                session:
                  session,
              }
            );
          }


          // ==============================================
          // RESPONSE
          // ==============================================

          responseData = {

            allocationId:
              allocation
                .allocationId,

            allocationNo:
              allocation
                .allocationNo,

            salesmanId:
              allocation
                .salesmanId,

            salesmanName:
              allocation
                .salesmanName,

            productId:
              normalizedProductId,

            productName:
              allocationProduct
                .productName,

            allocatedQuantity:
              allocatedQty,

            soldQuantity:
              soldForThisAllocation,

            previousReturnedQuantity:
              alreadyReturnedQty,

            goodReturnQuantity:
              goodReturn,

            damageQuantity:
              damage,

            returnedQuantity:
              allocationProduct
                .returnedQuantity,

            remainingQuantity:
              newRemainingQty,

            shortExcessQuantity:
              shortExcess,

            returnType:
              returnType ?? 0,

            reason:
              (
                reason ||
                ""
              )
                .toString()
                .trim(),

            remarks:
              (
                remarks ||
                ""
              )
                .toString()
                .trim(),

            status:
              allocation.status,
          };
        }
      );


      return res.status(200).json({

        success:
          true,

        message:
          "Allocation return saved successfully.",

        data:
          responseData,
      });


    } catch (error) {

      console.error(
        "ALLOCATION RETURN ERROR:",
        error
      );


      return res
        .status(
          error.statusCode ||
          500
        )
        .json({

          success:
            false,

          message:
            error.message ||
            "Unable to save allocation return.",
        });


    } finally {

      await session.endSession();
    }
  }
);
// ======================================================
// SALESMAN MY STOCK / MY LOAD
// GET LOGGED-IN SALESMAN ALLOCATED STOCK
// ======================================================

app.get(
  "/api/salesman-stock/my",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission("salesCreate", "salesView", "allocationView"),
  async (req, res) => {

    try {

      // ==================================================
      // ONLY SALESMAN CAN USE MY STOCK
      // ==================================================

      if (req.user.role !== "salesman") {

        return res.status(403).json({
          success: false,
          message:
            "My Stock is available only for salesman login.",
        });
      }


      const farmId =
        req.user.farmId;

      const userId =
        req.user.userId;


      // ==================================================
      // FIND LOGGED-IN SALESMAN
      // JWT CONTAINS MONGODB USER ID
      // ==================================================

      const salesman =
        await Salesman.findOne({
          _id: userId,
          farmId: farmId,
          isActive: true,
        });


      if (!salesman) {

        return res.status(404).json({
          success: false,
          message:
            "Salesman account not found.",
        });
      }


      const salesmanId =
        salesman.salesmanId;


      // ==================================================
      // GET ACTIVE ALLOCATIONS FOR THIS SALESMAN
      // ==================================================

      const allocations =
        await Allocation.find({

          farmId:
            farmId,

          salesmanId:
            salesmanId,

          status: {
            $in: [
              "POSTED",
              "RETURNED",
            ],
          },

        })
          .sort({
            allocationDate: -1,
            createdAt: -1,
          })
          .lean();


      // ==================================================
      // PRODUCT-WISE STOCK SUMMARY
      // ==================================================

      const productMap =
        new Map();


      let totalAllocated = 0;
      let totalReturned = 0;


      for (const allocation of allocations) {

        const products =
          Array.isArray(allocation.products)
            ? allocation.products
            : [];


        for (const item of products) {

          const productId =
            (item.productId || "")
              .toString()
              .trim()
              .toUpperCase();


          if (!productId) {
            continue;
          }


          const allocatedQty =
            Number(item.quantity) || 0;


          const returnedQty =
            Number(item.returnedQuantity) || 0;


          totalAllocated +=
            allocatedQty;


          totalReturned +=
            returnedQty;


          if (!productMap.has(productId)) {

            productMap.set(
              productId,
              {
                productId:
                  productId,

                productName:
                  item.productName || "",

                variant:
                  item.variant || "",

                unit:
                  item.unit || "",

                allocated:
                  0,

                sold:
                  0,

                returned:
                  0,

                available:
                  0,
              }
            );
          }


          const row =
            productMap.get(productId);


          row.allocated +=
            allocatedQty;


          row.returned +=
            returnedQty;
        }
      }


      // ==================================================
      // SALESMAN POSTED SALES
      //
      // ONLY SALES CREATED BY THIS SALESMAN
      // CANCELLED SALES ARE NOT INCLUDED
      // ADMIN SALES ARE NOT INCLUDED
      // ==================================================

      const salesmanSales =
        await Sale.find({
          farmId: farmId,

          salesmanId:
            salesmanId,

          createdRole:
            "salesman",

          status:
            "POSTED",
        })
          .select(
            "products"
          )
          .lean();


      // ==================================================
      // ADD SOLD QUANTITY PRODUCT-WISE
      // ==================================================

      for (
        const sale of
        salesmanSales
      ) {
        const saleProducts =
          Array.isArray(
            sale.products
          )
            ? sale.products
            : [];

        for (
          const item of
          saleProducts
        ) {
          const productId =
            (
              item.productId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();

          if (!productId) {
            continue;
          }

          // ------------------------------------------------
          // Product was sold but allocation record may
          // no longer appear in current productMap.
          // This should normally not happen, but keep the
          // API safe.
          // ------------------------------------------------

          if (
            !productMap.has(
              productId
            )
          ) {
            continue;
          }

          const soldQty =
            Number(
              item.quantity
            ) || 0;

          productMap
            .get(productId)
            .sold +=
            soldQty;
        }
      }


      // ==================================================
      // TOTAL SOLD
      // ==================================================

      let totalSold = 0;


      // ==================================================
      // CALCULATE AVAILABLE STOCK
      // ==================================================

      const products = [];


      for (const row of productMap.values()) {

        row.available =
          Math.max(
            0,
            row.allocated -
            row.returned -
            row.sold
          );


        totalSold +=
          row.sold;

        if (
          row.available > 0
        ) {
          products.push(row);
        }
      }


      // ==================================================
      // SORT PRODUCT NAME
      // ==================================================

      products.sort(
        (a, b) =>
          a.productName.localeCompare(
            b.productName
          )
      );


      const totalAvailable =
        Math.max(
          0,
          totalAllocated -
          totalReturned -
          totalSold
        );


      // ==================================================
      // CURRENT / LATEST ROUTE
      // ==================================================

      const latestAllocation =
        allocations.length > 0
          ? allocations[0]
          : null;


      const routeId =
        latestAllocation?.routeId || "";


      const routeName =
        latestAllocation?.routeName || "";


      // ==================================================
      // RESPONSE
      // ==================================================

      return res.status(200).json({

        success: true,

        data: {

          salesmanId:
            salesman.salesmanId,

          salesmanName:
            salesman.name,

          routeId:
            routeId,

          routeName:
            routeName,

          totalAllocations:
            allocations.length,

          totalAllocated:
            totalAllocated,

          totalSold:
            totalSold,

          totalReturned:
            totalReturned,

          totalAvailable:
            totalAvailable,

          products:
            products,
        },
      });


    } catch (error) {

      console.error(
        "GET SALESMAN MY STOCK ERROR:",
        error
      );


      return res.status(500).json({

        success: false,

        message:
          "Unable to load salesman stock.",

        error:
          error.message,
      });
    }
  }
);

// ======================================================
// GET STOCK
// ======================================================

app.get(
  "/api/stock",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission(
    "productsView",
    "allocationView",
    "salesView",
    "salesCreate",
    "returnsManage",
    "purchaseView"
  ),
  async (req, res) => {
    try {
      const stock =
        await Product.find({
          farmId:
            req.user.farmId,
        })
          .select(
            "_id productId productName variant unit stock price isActive"
          )
          .sort({
            productName: 1,
          });

      return res.status(200).json({
        success: true,
        count:
          stock.length,
        data:
          stock,
      });

    } catch (error) {
      console.error(
        "GET STOCK ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load stock.",
      });
    }
  }
);
// ======================================================
// MANUAL CUSTOMER OUTSTANDING
// TRN_CUSTOMER_OUTSTANDING
//
// ADMIN ONLY
// ======================================================


// ======================================================
// GET MANUAL OUTSTANDING
// ======================================================

app.get(
  "/api/customer-outstanding",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const filter = {
        farmId,
      };

      const customerId =
        (
          req.query.customerId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      const status =
        (
          req.query.status ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      if (customerId) {
        filter.customerId =
          customerId;
      }

      if (
        [
          "POSTED",
          "CANCELLED",
        ].includes(status)
      ) {
        filter.status =
          status;
      }

      const records =
        await CustomerOutstanding.find(
          filter
        )
          .sort({
            adjustmentDate: -1,
            createdAt: -1,
          })
          .lean();

      return res.status(200).json({
        success: true,

        count:
          records.length,

        data:
          records,
      });

    } catch (error) {
      console.error(
        "GET CUSTOMER OUTSTANDING ERROR:",
        error
      );

      return res.status(500).json({
        success: false,

        message:
          "Unable to load manual customer outstanding.",

        error:
          error.message,
      });
    }
  }
);


// ======================================================
// ADD MANUAL CUSTOMER OUTSTANDING
// ======================================================
//
// Request:
// {
//   customerId,
//   amount,
//   outstandingDate,
//   remarks
// }
//
// DOES NOT MODIFY CUSTOMER ADVANCE.
// ======================================================

app.post(
  "/api/customer-outstanding",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const {
        customerId,
        amount,
        outstandingDate,
        remarks,
      } = req.body;


      const normalizedCustomerId =
        (
          customerId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      const adjustmentAmount =
        Number(amount) || 0;


      if (!normalizedCustomerId) {
        return res.status(400).json({
          success: false,

          message:
            "Customer is required.",
        });
      }


      if (
        adjustmentAmount <=
        0
      ) {
        return res.status(400).json({
          success: false,

          message:
            "Outstanding amount must be greater than zero.",
        });
      }


      const customer =
        await Customer.findOne({
          farmId,

          customerId:
            normalizedCustomerId,

          isActive:
            true,
        });


      if (!customer) {
        return res.status(404).json({
          success: false,

          message:
            "Customer not found.",
        });
      }


      let finalOutstandingDate =
        new Date();


      if (outstandingDate) {
        const parsedDate =
          new Date(
            outstandingDate
          );


        if (
          Number.isNaN(
            parsedDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,

            message:
              "Invalid outstanding date.",
          });
        }


        finalOutstandingDate =
          parsedDate;
      }


      const adjustmentId =
        await generateCustomerOutstandingId();


      const adjustmentNo =
        await generateCustomerOutstandingNo(
          farmId
        );


      const record =
        await CustomerOutstanding.create({
          farmId,

          adjustmentId,

          adjustmentNo,

          adjustmentDate:
            finalOutstandingDate,

          customerId:
            customer.customerId,

          customerName:
            customer.name,

          customerMobile:
            customer.mobile || "",

          route:
            customer.route || "",

          amount:
            Number(
              adjustmentAmount.toFixed(2)
            ),

          remarks:
            remarks
              ?.toString()
              .trim() ||
            "",

          source:
            "MANUAL_OUTSTANDING",

          status:
            "POSTED",

          createdBy:
            req.user.userId ||
            "",

          createdRole:
            req.user.role ||
            "admin",

          createdAt:
            new Date(),

          updatedAt:
            new Date(),
        });


      return res.status(201).json({
        success: true,

        message:
          "Customer outstanding added successfully.",

        data:
          record,
      });

    } catch (error) {
      console.error(
        "ADD CUSTOMER OUTSTANDING ERROR:",
        error
      );


      if (
        error.code ===
        11000
      ) {
        return res.status(409).json({
          success: false,

          message:
            "Duplicate customer outstanding number detected.",
        });
      }


      return res.status(500).json({
        success: false,

        message:
          "Unable to add customer outstanding.",

        error:
          error.message,
      });
    }
  }
);


// ======================================================
// CANCEL MANUAL CUSTOMER OUTSTANDING
// ======================================================
//
// Cannot cancel if a POSTED receipt already used it.
// Cancel that receipt first.
// ======================================================

app.put(
  "/api/customer-outstanding/:adjustmentId/cancel",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;


      const adjustmentId =
        (
          req.params.adjustmentId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      if (!adjustmentId) {
        return res.status(400).json({
          success: false,

          message:
            "Outstanding adjustment ID is required.",
        });
      }


      const record =
        await CustomerOutstanding.findOne({
          farmId,
          adjustmentId,
        });


      if (!record) {
        return res.status(404).json({
          success: false,

          message:
            "Customer outstanding record not found.",
        });
      }


      if (
        record.status ===
        "CANCELLED"
      ) {
        return res.status(409).json({
          success: false,

          message:
            "Customer outstanding is already cancelled.",
        });
      }


      const dependentCollection =
        await Collection.findOne({
          farmId,

          status:
            "POSTED",

          allocations: {
            $elemMatch: {
              sourceType:
                "MANUAL_OUTSTANDING",

              referenceId:
                adjustmentId,

              amountApplied: {
                $gt:
                  0.001,
              },
            },
          },
        })
          .select(
            "collectionId receiptNo amount collectionDate"
          )
          .lean();


      if (dependentCollection) {
        return res.status(409).json({
          success: false,

          message:
            `Cannot cancel this outstanding because receipt ${dependentCollection.receiptNo || dependentCollection.collectionId} has already been allocated to it. Cancel that collection first.`,
        });
      }


      record.status =
        "CANCELLED";

      record.cancelledBy =
        req.user.userId ||
        "";

      record.cancelledAt =
        new Date();

      record.updatedAt =
        new Date();


      await record.save();


      return res.status(200).json({
        success: true,

        message:
          "Customer outstanding cancelled successfully.",

        data:
          record,
      });

    } catch (error) {
      console.error(
        "CANCEL CUSTOMER OUTSTANDING ERROR:",
        error
      );


      return res.status(500).json({
        success: false,

        message:
          "Unable to cancel customer outstanding.",

        error:
          error.message,
      });
    }
  }
);

// ======================================================
// COLLECTION
// TRN_COLLECTION
// ======================================================


// ======================================================
// HELPER - CURRENT SALESMAN
// ======================================================

async function getCurrentSalesmanForCollection(
  req
) {
  if (
    req.user.role !== "salesman"
  ) {
    return null;
  }

  const salesman =
    await Salesman.findOne({
      _id:
        req.user.userId,

      farmId:
        req.user.farmId,

      isActive:
        true,
    });

  return salesman;
}


// ======================================================
// GET CUSTOMER OUTSTANDING
//
// CREDIT SALES
// MINUS
// POSTED COLLECTIONS
//
// ADMIN
//   -> ALL FARM CREDIT SALES
//
// SALESMAN
//   -> ONLY HIS OWN CREDIT SALES
// ======================================================

app.get(
  "/api/collections/outstanding",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission(
    "collectionView",
    "collectionCreate",
    "salesView",
    "salesCreate"
  ),
  async (req, res) => {

    try {

      const farmId =
        req.user.farmId;

      const role =
        req.user.role;


      // ==================================================
      // ROLE VALIDATION
      // ==================================================

      let currentSalesman =
        null;


      if (
        role === "salesman"
      ) {

        currentSalesman =
          await getCurrentSalesmanForCollection(
            req
          );


        if (!currentSalesman) {

          return res.status(404).json({
            success: false,
            message:
              "Salesman account not found.",
          });
        }
      }


      else if (
        role !== "admin"
      ) {

        return res.status(403).json({
          success: false,
          message:
            "You are not allowed to view collections.",
        });
      }


      // ==================================================
      // CREDIT SALES FILTER
      // ==================================================

      const saleFilter = {

        farmId:
          farmId,

        status:
          "POSTED",
      };


      if (
        role === "salesman"
      ) {

        saleFilter.salesmanId =
          currentSalesman.salesmanId;

        saleFilter.createdRole =
          "salesman";
      }


      // ==================================================
      // LOAD CREDIT SALES
      // ==================================================

      const creditSales =
        await Sale.find(
          saleFilter
        )
          .select(
            [
              "saleId",
              "saleNo",
              "saleDate",
              "customerId",
              "customerName",
              "customerMobile",
              "route",
              "grandTotal",

              "paymentMode",
              "payments",
              "paidAmount",
              "paymentApplied",

              // Customer advance consumed by this sale
              "advanceUsed",

              "outstandingAmount",
              "advanceCreated",
              "paymentStatus",

              "salesmanId",
              "salesmanName",
            ].join(" ")
          )
          .sort({
            saleDate: 1,
            createdAt: 1,
          })
          .lean();


      // ==================================================
      // COLLECTION FILTER
      // ==================================================

      const collectionFilter = {

        farmId:
          farmId,

        status:
          "POSTED",
      };


      if (
        role === "salesman"
      ) {

        collectionFilter.salesmanId =
          currentSalesman.salesmanId;
      }


      // ==================================================
      // LOAD POSTED COLLECTIONS
      // ==================================================

      const collections =
        await Collection.find(
          collectionFilter
        )
          .select(
            [
              "collectionId",
              "receiptNo",
              "customerId",

              "amount",

              // Amount used against unpaid bills
              "appliedAmount",

              // Extra amount converted to customer advance
              "advanceAmount",

              "previousOutstanding",
              "remainingOutstanding",
              "previousAdvanceBalance",
              "currentAdvanceBalance",
              "status",
              "cancelReason",
              "clientRequestId",

              "paymentMode",
              "referenceNo",
              "remarks",

              "collectionDate",

              "salesmanId",
              "salesmanName",

              "allocations",
            ].join(" ")
          )
          .sort({
            collectionDate: 1,
            createdAt: 1,
          })
          .lean();

// ==================================================
// LOAD CUSTOMER MASTER
//
// customer.balance = CURRENT AVAILABLE ADVANCE
//
// ADMIN:
//   all active customers
//
// SALESMAN:
//   customers on assigned routes
//
// This is needed because customer may have manual
// outstanding even if he has no sale yet.
// ==================================================

let salesmanRouteValues = [];


if (
  role === "salesman"
) {
  const salesmanRoutes =
    await RouteMaster.find({
      farmId,

      salesmanId:
        currentSalesman.salesmanId,

      isActive:
        true,
    })
      .select(
        "routeId routeName"
      )
      .lean();


  salesmanRouteValues =
    [
      ...new Set(
        salesmanRoutes
          .flatMap(
            (route) => [
              route.routeId,
              route.routeName,
            ]
          )
          .filter(Boolean)
      ),
    ];
}


const masterCustomers =
  role === "admin"
    ? await Customer.find({
        farmId,

        isActive:
          true,
      })
        .select(
          [
            "customerId",
            "name",
            "mobile",
            "route",
            "balance",
            "isActive",
            "createdAt",
          ].join(" ")
        )
        .lean()

    : await Customer.find({
        farmId,

        isActive:
          true,

        route: {
          $in:
            salesmanRouteValues,
        },
      })
        .select(
          [
            "customerId",
            "name",
            "mobile",
            "route",
            "balance",
            "isActive",
            "createdAt",
          ].join(" ")
        )
        .lean();


const masterCustomerMap =
  new Map(
    masterCustomers.map(
      (customer) => [
        (
          customer.customerId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase(),

        customer,
      ]
    )
  );


// ==================================================
// LOAD POSTED MANUAL OUTSTANDING
// ==================================================

const visibleCustomerIds =
  masterCustomers
    .map(
      (customer) =>
        (
          customer.customerId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase()
    )
    .filter(Boolean);


const manualOutstandingFilter = {
  farmId,

  status:
    "POSTED",
};


if (
  role === "salesman"
) {
  manualOutstandingFilter.customerId = {
    $in:
      visibleCustomerIds,
  };
}


const manualOutstandingRecords =
  await CustomerOutstanding.find(
    manualOutstandingFilter
  )
    .select(
      [
        "adjustmentId",
        "adjustmentNo",
        "adjustmentDate",
        "customerId",
        "customerName",
        "customerMobile",
        "route",
        "amount",
        "remarks",
      ].join(" ")
    )
    .sort({
      adjustmentDate: 1,
      createdAt: 1,
    })
    .lean();
      // ==================================================
      // CUSTOMER MAP
      // ==================================================

      const customerMap =
        new Map();

      // ==================================================
      // ADMIN:
      // INITIALIZE ALL CUSTOMERS
      //
      // This is necessary because a customer may have:
      //
      // Outstanding = 0
      // Advance = 2000
      //
      // and still must appear on Collection screen.
      // ==================================================

      if (role === "admin") {

        for (
          const customer of
          masterCustomers
        ) {

          const customerId =
            (
              customer.customerId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (!customerId) {
            continue;
          }


          customerMap.set(
            customerId,
            {
              customerId,

              customerName:
                customer.name || "",

              customerMobile:
                customer.mobile || "",

              route:
                customer.route || "",

              salesmanId:
                "",

              salesmanName:
                "",

              // ============================================
              // CURRENT ACCOUNT POSITION
              // ============================================

              // MAS_CUSTOMER.balance =
              // current available customer advance
              advanceBalance:
                Number(
                  customer.balance || 0
                ),

              // Keep alias for backward compatibility
              balance:
                Number(
                  customer.balance || 0
                ),

              // ============================================
              // SALES / COLLECTION VALUES
              // ============================================
totalCreditSales:
  0,

// ============================================
// RECEIVED MONEY
//
// totalPaidAtBilling
//   = payment entered while making sale
//
// totalLaterCollections
//   = TRN_COLLECTION receipts
//
// totalCollected / totalReceived
//   = both combined
// ============================================

totalPaidAtBilling:
  0,

totalLaterCollections:
  0,

totalCollected:
  0,

totalReceived:
  0,

outstanding:
  0,

lastPaymentMode:
  "",

lastCollectionDate:
  null,

billCount:
  0,

bills: [],

// Unified receipt list.
// Contains virtual BILL_PAYMENT + real COLLECTION.
receiptHistory: [],

totalManualOutstanding:
  0,

manualOutstandingCount:
  0,

manualOutstandings:
  [],

// ============================================
// ACCOUNT AUDIT HISTORY
              // ============================================

              accountHistory:
                [],
            }
          );
        }
      }

      // ==================================================
      // ADD SALES
      // ==================================================

      for (
        const sale of creditSales
      ) {

        const customerId =
          (
            sale.customerId || ""
          )
            .toString()
            .trim()
            .toUpperCase();


        if (!customerId) {
          continue;
        }


        if (
          !customerMap.has(
            customerId
          )
        ) {

          customerMap.set(
            customerId,
            {
              customerId:
                customerId,

              customerName:
                sale.customerName || "",

              customerMobile:
                sale.customerMobile || "",

              route:
                sale.route || "",

              salesmanId:
                sale.salesmanId || "",

              salesmanName:
                sale.salesmanName || "",

            totalCreditSales:
  0,

// ============================================
// RECEIVED MONEY
//
// totalPaidAtBilling
//   = payment entered while making sale
//
// totalLaterCollections
//   = TRN_COLLECTION receipts
//
// totalCollected / totalReceived
//   = both combined
// ============================================

totalPaidAtBilling:
  0,

totalLaterCollections:
  0,

totalCollected:
  0,

totalReceived:
  0,

outstanding:
  0,

lastPaymentMode:
  "",

lastCollectionDate:
  null,

billCount:
  0,

bills: [],

// Unified receipt list.
// Contains virtual BILL_PAYMENT + real COLLECTION.
receiptHistory: [],

totalManualOutstanding:
  0,

manualOutstandingCount:
  0,

manualOutstandings:
  [],

advanceBalance:
  Number(
    masterCustomerMap
      .get(customerId)
      ?.balance ||
    0
  ),

balance:
  Number(
    masterCustomerMap
      .get(customerId)
      ?.balance ||
    0
  ),

              accountHistory:
                [],
            }
          );
        }


        const row =
          customerMap.get(
            customerId
          );


        const billAmount =
          Number(
            sale.grandTotal
          ) || 0;

        const paidAmount =
          Math.max(
            0,
            Number(
              sale.paidAmount
            ) || 0
          );
          // ==================================================
// MONEY RECEIVED WHILE MAKING BILL
//
// DO NOT reduce outstanding here.
//
// sale.outstandingAmount already contains only
// the unpaid portion of the bill.
// ==================================================

row.totalPaidAtBilling +=
  paidAmount;

row.totalCollected +=
  paidAmount;


if (
  paidAmount > 0.001
) {
  const salePaymentDate =
    sale.saleDate ||
    null;

  if (
    !row.lastCollectionDate ||
    (
      salePaymentDate &&
      new Date(
        salePaymentDate
      ) >
        new Date(
          row.lastCollectionDate
        )
    )
  ) {
    row.lastCollectionDate =
      salePaymentDate;

    row.lastPaymentMode =
      sale.paymentMode ||
      "";
  }
}

        const advanceUsed =
          Math.max(
            0,
            Number(
              sale.advanceUsed
            ) || 0
          );
        const advanceCreated =
          Math.max(
            0,
            Number(
              sale.advanceCreated
            ) || 0
          );
        let outstandingAmount =
          Number(
            sale.outstandingAmount
          );

        // ==================================================
        // OLD RECORD COMPATIBILITY
        // ==================================================

        if (
          !Number.isFinite(
            outstandingAmount
          )
        ) {
          const oldMode =
            (
              sale.paymentMode ||
              ""
            )
              .toString()
              .trim()
              .toLowerCase();

          outstandingAmount =
            oldMode === "credit"
              ? billAmount
              : 0;
        }

        outstandingAmount =
          Math.max(
            0,
            outstandingAmount
          );

        // ==================================================
        // ONLY CURRENT OUTSTANDING COUNTS
        // ==================================================

        row.totalCreditSales +=
          outstandingAmount;

        row.billCount +=
          1;
        // ==================================================
        // PAYMENT BREAKUP
        // ==================================================

        const payments =
          Array.isArray(
            sale.payments
          )
            ? sale.payments
            : [];

        let cashAmount = 0;
        let upiAmount = 0;
        let bankAmount = 0;
        let otherAmount = 0;

        for (
          const payment of payments
        ) {
          const mode =
            (
              payment.paymentMode ||
              payment.mode ||
              ""
            )
              .toString()
              .trim()
              .toLowerCase();

          const amount =
            Math.max(
              0,
              Number(
                payment.amount
              ) || 0
            );

          if (
            mode === "cash"
          ) {
            cashAmount += amount;
          }

          else if (
            [
              "upi",
              "phonepe",
              "google pay",
              "gpay",
              "paytm",
            ].includes(mode)
          ) {
            upiAmount += amount;
          }

          else if (
            [
              "bank transfer",
              "bank",
              "neft",
              "rtgs",
              "imps",
            ].includes(mode)
          ) {
            bankAmount += amount;
          }

          else {
            otherAmount += amount;
          }
        }


        // ==================================================
        // OLD SINGLE PAYMENT RECORD COMPATIBILITY
        // ==================================================

        if (
          payments.length === 0 &&
          paidAmount > 0
        ) {
          const singleMode =
            (
              sale.paymentMode ||
              ""
            )
              .toString()
              .trim()
              .toLowerCase();

          if (
            singleMode === "cash"
          ) {
            cashAmount =
              paidAmount;
          }

          else if (
            [
              "upi",
              "phonepe",
              "google pay",
              "gpay",
              "paytm",
            ].includes(singleMode)
          ) {
            upiAmount =
              paidAmount;
          }

          else if (
            [
              "bank transfer",
              "bank",
              "neft",
              "rtgs",
              "imps",
            ].includes(singleMode)
          ) {
            bankAmount =
              paidAmount;
          }

          else if (
            paidAmount > 0
          ) {
            otherAmount =
              paidAmount;
          }
        }

        // ==================================================
// VIRTUAL RECEIPT FOR PAYMENT RECEIVED AT BILLING
//
// This exists only in API response.
// Nothing is written to TRN_COLLECTION.
// ==================================================

if (
  paidAmount > 0.001
) {
  row.receiptHistory.push({
    sourceType:
      "BILL_PAYMENT",

    id:
      sale.saleId ||
      "",

    saleId:
      sale.saleId ||
      "",

    saleNo:
      sale.saleNo ||
      "",

    receiptNo:
      sale.saleNo ||
      "",

    date:
      sale.saleDate,

    collectionDate:
      sale.saleDate,

    customerId:
      sale.customerId ||
      customerId,

    customerName:
      sale.customerName ||
      row.customerName ||
      "",

    customerMobile:
      String(
        sale.customerMobile ||
        row.customerMobile ||
        ""
      ),

    route:
      sale.route ||
      row.route ||
      "",

    salesmanId:
      sale.salesmanId ||
      "",

    salesmanName:
      sale.salesmanName ||
      "",

    billAmount:
      Number(
        billAmount.toFixed(2)
      ),

    amount:
      Number(
        paidAmount.toFixed(2)
      ),

    paidAmount:
      Number(
        paidAmount.toFixed(2)
      ),

    paymentApplied:
      Number(
        (
          sale.paymentApplied !== undefined && sale.paymentApplied !== null
            ? Number(sale.paymentApplied)
            : Math.min(paidAmount, billAmount)
        ).toFixed(2)
      ),

    paymentAppliedAtBilling:
      Number(
        (
          sale.paymentApplied !== undefined && sale.paymentApplied !== null
            ? Number(sale.paymentApplied)
            : Math.min(paidAmount, billAmount)
        ).toFixed(2)
      ),

    paymentMode:
      sale.paymentMode ||
      "",

    payments:
      payments,

    paymentBreakup: {
      cash:
        Number(
          cashAmount.toFixed(2)
        ),

      upi:
        Number(
          upiAmount.toFixed(2)
        ),

      bank:
        Number(
          bankAmount.toFixed(2)
        ),

      other:
        Number(
          otherAmount.toFixed(2)
        ),
    },

    outstandingAmount:
      Number(
        outstandingAmount.toFixed(2)
      ),

    paymentStatus:
      sale.paymentStatus ||
      (
        outstandingAmount >
        0.001
          ? "PARTIAL"
          : "PAID"
      ),

    advanceCreated:
      Number(
        advanceCreated.toFixed(2)
      ),

    advanceUsed:
      Number(
        advanceUsed.toFixed(2)
      ),

    canDownloadReceipt:
      true,

    canCollectPayment:
      outstandingAmount >
      0.001,
  });
}

        // ==================================================
        // BILL DETAIL
        // ==================================================

        row.bills.push({
          saleId:
            sale.saleId || "",

          saleNo:
            sale.saleNo || "",

          saleDate:
            sale.saleDate,
            sourceType:
  "BILL_PAYMENT",

canDownloadReceipt:
  paidAmount > 0.001,

canCollectPayment:
  outstandingAmount >
  0.001,

          billAmount:
            Number(
              billAmount.toFixed(2)
            ),
          paidAtBilling:
            Number(
              paidAmount.toFixed(2)
            ),
          paymentAppliedAtBilling:
            Number(
              (
                sale.paymentApplied !== undefined && sale.paymentApplied !== null
                  ? Number(sale.paymentApplied)
                  : Math.min(paidAmount, billAmount)
              ).toFixed(2)
            ),
          salePaidAmount:
            Number(
              paidAmount.toFixed(2)
            ),

          // Customer advance consumed on this bill
          advanceUsed:
            Number(
              advanceUsed.toFixed(2)
            ),

          initialOutstanding:
            Number(
              outstandingAmount.toFixed(2)
            ),

          collectionApplied:
            0,

          totalAppliedToBill:
            Number(
              Math.min(
                billAmount,
                (
                  sale.paymentApplied !== undefined && sale.paymentApplied !== null
                    ? Number(sale.paymentApplied)
                    : Math.min(paidAmount, billAmount)
                ) + advanceUsed
              ).toFixed(2)
            ),

          remainingOutstanding:
            Number(
              outstandingAmount.toFixed(2)
            ),

          paidAmount:
            Number(
              paidAmount.toFixed(2)
            ),

          outstandingAmount:
            Number(
              outstandingAmount.toFixed(2)
            ),

          paymentMode:
            sale.paymentMode || "",

          paymentStatus:
            (
              sale.paymentStatus ||
              (
                outstandingAmount > 0
                  ? (
                    paidAmount > 0
                      ? "PARTIAL"
                      : "CREDIT"
                  )
                  : "PAID"
              )
            )
              .toString()
              .trim()
              .toUpperCase(),

          payments:
            payments,

          paymentBreakup: {
            cash:
              Number(
                cashAmount.toFixed(2)
              ),

            upi:
              Number(
                upiAmount.toFixed(2)
              ),

            bank:
              Number(
                bankAmount.toFixed(2)
              ),

            other:
              Number(
                otherAmount.toFixed(2)
              ),
          },
        });
        // ==================================================
        // CUSTOMER ACCOUNT HISTORY — SALE
        // ==================================================

        row.accountHistory.push({
          type:
            "SALE",

          date:
            sale.saleDate,

          reference:
            sale.saleNo ||
            sale.saleId,

          saleId:
            sale.saleId,

          description:
            advanceCreated > 0
              ? `Sale posted. ₹${advanceCreated.toFixed(
                2
              )} extra billing payment added as customer advance.`
              : advanceUsed > 0
                ? `Sale posted. ₹${advanceUsed.toFixed(
                  2
                )} customer advance adjusted against bill.`
                : "Sale posted.",
          billAmount:
            Number(
              billAmount.toFixed(2)
            ),

          // Amount added to unpaid outstanding by this bill
          outstandingAdded:
            Number(
              outstandingAmount.toFixed(2)
            ),

          outstandingReduced:
            0,

          // Advance consumed by sale
          advanceAdded:
            Number(
              advanceCreated.toFixed(2)
            ),

          advanceUsed:
            Number(
              advanceUsed.toFixed(2)
            ),

          paymentAmount:
            Number(
              paidAmount.toFixed(2)
            ),
        });

        if (
          !row.route &&
          sale.route
        ) {
          row.route =
            sale.route;
        }


        if (
          !row.salesmanId &&
          sale.salesmanId
        ) {
          row.salesmanId =
            sale.salesmanId;
        }


        if (
          !row.salesmanName &&
          sale.salesmanName
        ) {
          row.salesmanName =
            sale.salesmanName;
        }
      }

// ==================================================
// ADD MANUAL OUTSTANDING TO CUSTOMER
// ==================================================

for (
  const manualOutstanding of
  manualOutstandingRecords
) {
  const customerId =
    (
      manualOutstanding.customerId ||
      ""
    )
      .toString()
      .trim()
      .toUpperCase();


  if (
    !customerMap.has(
      customerId
    )
  ) {
    continue;
  }


  const row =
    customerMap.get(
      customerId
    );


  const amount =
    Math.max(
      0,
      Number(
        manualOutstanding.amount ||
        0
      )
    );


  row.totalManualOutstanding +=
    amount;

  row.manualOutstandingCount +=
    1;


  row.manualOutstandings.push({
    sourceType:
      "MANUAL_OUTSTANDING",

    adjustmentId:
      manualOutstanding.adjustmentId ||
      "",

    adjustmentNo:
      manualOutstanding.adjustmentNo ||
      "",

    adjustmentDate:
      manualOutstanding.adjustmentDate,

    referenceId:
      manualOutstanding.adjustmentId ||
      "",

    referenceNo:
      manualOutstanding.adjustmentNo ||
      "",

    referenceDate:
      manualOutstanding.adjustmentDate,

    amount:
      Number(
        amount.toFixed(2)
      ),

    initialOutstanding:
      Number(
        amount.toFixed(2)
      ),

    collectionApplied:
      0,

    outstandingAmount:
      Number(
        amount.toFixed(2)
      ),

    status:
      "DUE",

    remarks:
      manualOutstanding.remarks ||
      "",
  });


  row.accountHistory.push({
    type:
      "MANUAL_OUTSTANDING",

    date:
      manualOutstanding.adjustmentDate,

    reference:
      manualOutstanding.adjustmentNo ||
      manualOutstanding.adjustmentId,

    adjustmentId:
      manualOutstanding.adjustmentId,

    description:
      manualOutstanding.remarks
        ? `Manual outstanding added. ${manualOutstanding.remarks}`
        : "Manual outstanding added.",

    billAmount:
      0,

    receivedAmount:
      0,

    outstandingAdded:
      Number(
        amount.toFixed(2)
      ),

    outstandingReduced:
      0,

    advanceAdded:
      0,

    advanceUsed:
      0,
  });
}
      // ==================================================
      // APPLY COLLECTIONS TO CUSTOMER + BILLS
      // FIFO BILL SETTLEMENT
      // ==================================================

      for (
        const collection of
        collections
      ) {
        const customerId =
          (
            collection.customerId ||
            ""
          )
            .toString()
            .trim()
            .toUpperCase();


        if (
          !customerMap.has(
            customerId
          )
        ) {
          continue;
        }


        const row =
          customerMap.get(
            customerId
          );


        const collectionAmount =
          Math.max(
            0,
            Number(
              collection.amount
            ) || 0
          );
        const appliedAmount =
          Math.max(
            0,
            Number(
              collection.appliedAmount ||
              0
            )
          );


        const advanceAmount =
          Math.max(
            0,
            Number(
              collection.advanceAmount ||
              0
            )
          );


     row.totalLaterCollections +=
  collectionAmount;

row.totalCollected +=
  collectionAmount;


// ==================================================
// REAL COLLECTION RECEIPT
// ==================================================

row.receiptHistory.push({
  sourceType:
    "COLLECTION",

  id:
    collection.collectionId ||
    "",

  collectionId:
    collection.collectionId ||
    "",

  receiptNo:
    collection.receiptNo ||
    "",

  date:
    collection.collectionDate,

  collectionDate:
    collection.collectionDate,

  customerId:
    collection.customerId ||
    customerId,

  customerName:
    row.customerName ||
    "",

  customerMobile:
    String(
      row.customerMobile ||
      ""
    ),

  route:
    row.route ||
    "",

  salesmanId:
    collection.salesmanId ||
    "",

  salesmanName:
    collection.salesmanName ||
    "",

  amount:
    Number(
      collectionAmount.toFixed(2)
    ),

  appliedAmount:
    Number(
      appliedAmount.toFixed(2)
    ),

  advanceAmount:
    Number(
      advanceAmount.toFixed(2)
    ),

  previousOutstanding:
    Number(
      (collection.previousOutstanding ?? 0).toFixed(2)
    ),

  remainingOutstanding:
    Number(
      (collection.remainingOutstanding ?? 0).toFixed(2)
    ),

  previousAdvanceBalance:
    Number(
      (collection.previousAdvanceBalance ?? 0).toFixed(2)
    ),

  currentAdvanceBalance:
    Number(
      (collection.currentAdvanceBalance ?? 0).toFixed(2)
    ),

  allocations:
    Array.isArray(collection.allocations)
      ? collection.allocations
      : [],

  status:
    collection.status ||
    "POSTED",

  cancelReason:
    collection.cancelReason ||
    "",

  clientRequestId:
    collection.clientRequestId ||
    "",

  paymentMode:
    collection.paymentMode ||
    "",

  referenceNo:
    collection.referenceNo ||
    "",

  remarks:
    collection.remarks ||
    "",

  canDownloadReceipt:
    true,
});


        row.lastPaymentMode =
          collection.paymentMode || "";


        row.lastCollectionDate =
          collection.collectionDate ||
          null;
        // ==================================================
        // CUSTOMER ACCOUNT HISTORY — COLLECTION
        // ==================================================

        row.accountHistory.push({
          type:
            advanceAmount > 0 &&
              appliedAmount <= 0.001
              ? "ADVANCE_RECEIPT"
              : "COLLECTION",

          date:
            collection.collectionDate,

          reference:
            collection.receiptNo ||
            collection.collectionId,

          collectionId:
            collection.collectionId,

          description:
            advanceAmount > 0
              ? appliedAmount > 0
                ? `Receipt received. ₹${appliedAmount.toFixed(
                  2
                )} adjusted against bills and ₹${advanceAmount.toFixed(
                  2
                )} added to advance.`
                : `Advance payment received ₹${advanceAmount.toFixed(
                  2
                )}.`
              : `Collection received and applied against outstanding bills.`,

          receivedAmount:
            Number(
              collectionAmount.toFixed(2)
            ),

          outstandingAdded:
            0,

          outstandingReduced:
            Number(
              appliedAmount.toFixed(2)
            ),

          advanceAdded:
            Number(
              advanceAmount.toFixed(2)
            ),

          advanceUsed:
            0,

          paymentMode:
            collection.paymentMode ||
            "",

          referenceNo:
            collection.referenceNo ||
            "",
        });



        // ==================================================
        // SAVED ALLOCATIONS
        // ==================================================

     const savedAllocations =
  Array.isArray(
    collection.allocations
  )
    ? collection.allocations
    : [];


// ==================================================
// NEW RECEIPT WITH SAVED ALLOCATIONS
// ==================================================

if (
  savedAllocations.length >
  0
) {
  const sourceMap =
    new Map();


  // ================================================
  // ADD SALE SOURCES
  // ================================================

  for (
    const bill of
    row.bills
  ) {
    sourceMap.set(
      getOutstandingSourceKey(
        "SALE",
        bill.saleId
      ),
      bill
    );
  }


  // ================================================
  // ADD MANUAL OUTSTANDING SOURCES
  // ================================================

  for (
    const manualOutstanding of
    row.manualOutstandings
  ) {
    sourceMap.set(
      getOutstandingSourceKey(
        "MANUAL_OUTSTANDING",
        manualOutstanding.adjustmentId
      ),
      manualOutstanding
    );
  }


  // ================================================
  // APPLY SAVED COLLECTION ALLOCATIONS
  // ================================================

  for (
    const allocation of
    savedAllocations
  ) {
    const sourceType =
      (
        allocation.sourceType ||
        "SALE"
      )
        .toString()
        .trim()
        .toUpperCase();


    // ==============================================
    // OLD RECEIPTS:
    // referenceId may not exist.
    // Use saleId for backward compatibility.
    // ==============================================

    const referenceId =
      (
        allocation.referenceId ||
        allocation.saleId ||
        ""
      )
        .toString()
        .trim()
        .toUpperCase();


    if (!referenceId) {
      continue;
    }


    const key =
      getOutstandingSourceKey(
        sourceType,
        referenceId
      );


    if (
      !sourceMap.has(
        key
      )
    ) {
      continue;
    }


    const source =
      sourceMap.get(
        key
      );


    const requestedApplied =
      Math.max(
        0,
        Number(
          allocation.amountApplied
        ) || 0
      );


    const currentOutstanding =
      Math.max(
        0,
        Number(
          source.outstandingAmount
        ) || 0
      );


    const applied =
      Math.min(
        requestedApplied,
        currentOutstanding
      );


    source.collectionApplied +=
      applied;


    source.outstandingAmount =
      Math.max(
        0,
        currentOutstanding -
        applied
      );


    // ==============================================
    // SALE-SPECIFIC PAID AMOUNT
    // ==============================================

    if (
      sourceType ===
      "SALE"
    ) {
      source.paidAmount =
        Math.min(
          source.billAmount,

          Number(
            source.salePaidAmount ||
            0
          ) +

          Number(
            source.advanceUsed ||
            0
          ) +

          Number(
            source.collectionApplied ||
            0
          )
        );
    }
  }


  // Saved allocations handled.
  // Do not run old FIFO for this collection.
  continue;
}


        // ==================================================
        // OLD RECEIPT COMPATIBILITY
        // NO SAVED BILL ALLOCATIONS -> FIFO
        // ==================================================

        let remainingCollection =
          collectionAmount;


        for (
          const bill of row.bills
        ) {
          if (
            remainingCollection <=
            0.001
          ) {
            break;
          }


          const currentOutstanding =
            Math.max(
              0,
              Number(
                bill.outstandingAmount
              ) || 0
            );


          if (
            currentOutstanding <=
            0.001
          ) {
            continue;
          }


          const applied =
            Math.min(
              remainingCollection,
              currentOutstanding
            );


          bill.collectionApplied +=
            applied;


          bill.outstandingAmount =
            Math.max(
              0,
              currentOutstanding -
              applied
            );


          bill.paidAmount =
            Math.min(
              bill.billAmount,

              Number(
                bill.salePaidAmount ||
                0
              ) +

              Number(
                bill.advanceUsed ||
                0
              ) +

              Number(
                bill.collectionApplied ||
                0
              )
            );


          remainingCollection -=
            applied;
        }
      }

      // ==================================================
      // FINAL RESULT
      // ==================================================

      const data = [];


      for (
        const row of
        customerMap.values()
      ) {

        // ==================================================
        // FINAL BILL STATUS
        // ==================================================

        for (
          const bill of row.bills
        ) {
          bill.collectionApplied =
            Number(
              Math.max(
                0,
                Number(
                  bill.collectionApplied
                ) || 0
              ).toFixed(2)
            );

          const paymentAppliedAtBilling =
            Number(
              (
                bill.paymentAppliedAtBilling !== undefined
                  ? bill.paymentAppliedAtBilling
                  : Math.min(bill.salePaidAmount || 0, bill.billAmount || 0)
              ).toFixed(2)
            );

          const advanceUsed =
            Number(
              (
                bill.advanceUsed || 0
              ).toFixed(2)
            );

          bill.paidAtBilling =
            Number(
              (
                bill.paidAtBilling !== undefined
                  ? bill.paidAtBilling
                  : (bill.salePaidAmount || 0)
              ).toFixed(2)
            );

          bill.paymentAppliedAtBilling =
            paymentAppliedAtBilling;

          bill.advanceUsed =
            advanceUsed;

          bill.totalAppliedToBill =
            Number(
              Math.min(
                bill.billAmount || 0,
                paymentAppliedAtBilling +
                advanceUsed +
                bill.collectionApplied
              ).toFixed(2)
            );

          bill.paidAmount =
            Number(
              Math.max(
                0,
                Number(
                  bill.paidAmount
                ) || 0
              ).toFixed(2)
            );

          bill.outstandingAmount =
            Number(
              Math.max(
                0,
                Number(
                  bill.outstandingAmount
                ) || 0
              ).toFixed(2)
            );

          bill.remainingOutstanding =
            bill.outstandingAmount;

          if (
            bill.outstandingAmount <=
            0.001
          ) {
            bill.paymentStatus =
              "PAID";
          }

          else if (
            bill.totalAppliedToBill > 0 ||
            bill.paidAmount > 0 ||
            bill.collectionApplied > 0
          ) {
            bill.paymentStatus =
              "PARTIAL";
          }

          else {
            bill.paymentStatus =
              "CREDIT";
          }
        }
        // ==================================================
// FINAL MANUAL OUTSTANDING STATUS
// ==================================================

for (
  const manualOutstanding of
  row.manualOutstandings
) {
  manualOutstanding.collectionApplied =
    Number(
      Math.max(
        0,
        Number(
          manualOutstanding.collectionApplied ||
          0
        )
      ).toFixed(2)
    );


  manualOutstanding.outstandingAmount =
    Number(
      Math.max(
        0,
        Number(
          manualOutstanding.outstandingAmount ||
          0
        )
      ).toFixed(2)
    );


  if (
    manualOutstanding.outstandingAmount <=
    0.001
  ) {
    manualOutstanding.status =
      "PAID";
  }

  else if (
    manualOutstanding.collectionApplied >
    0.001
  ) {
    manualOutstanding.status =
      "PARTIAL";
  }

  else {
    manualOutstanding.status =
      "DUE";
  }
}


row.totalManualOutstanding =
  Number(
    row.totalManualOutstanding
      .toFixed(2)
  );
        row.totalCreditSales =
          Number(
            row.totalCreditSales
              .toFixed(2)
          );

row.totalPaidAtBilling =
  Number(
    (
      Number(
        row.totalPaidAtBilling
      ) || 0
    ).toFixed(2)
  );


row.totalLaterCollections =
  Number(
    (
      Number(
        row.totalLaterCollections
      ) || 0
    ).toFixed(2)
  );


row.totalCollected =
  Number(
    (
      Number(
        row.totalCollected
      ) || 0
    ).toFixed(2)
  );


// Backward-compatible explicit alias.
row.totalReceived =
  row.totalCollected;


// Newest receipt first.
row.receiptHistory.sort(
  (a, b) =>
    new Date(
      b.date || 0
    ) -
    new Date(
      a.date || 0
    )
);

        // ==================================================
        // GROSS BILL OUTSTANDING
        // ==================================================
const grossBillOutstanding =
  Number(
    row.bills
      .reduce(
        (
          total,
          bill
        ) =>
          total +
          Math.max(
            0,
            Number(
              bill.outstandingAmount
            ) || 0
          ),
        0
      )
      .toFixed(2)
  );


const grossManualOutstanding =
  Number(
    row.manualOutstandings
      .reduce(
        (
          total,
          item
        ) =>
          total +
          Math.max(
            0,
            Number(
              item.outstandingAmount
            ) || 0
          ),
        0
      )
      .toFixed(2)
  );


const grossOutstanding =
  Number(
    (
      grossBillOutstanding +
      grossManualOutstanding
    ).toFixed(2)
  );


row.grossBillOutstanding =
  grossBillOutstanding;

row.grossManualOutstanding =
  grossManualOutstanding;

row.grossOutstanding =
  grossOutstanding;
        // ==================================================
        // NET CUSTOMER OUTSTANDING
        //
        // Positive = Customer owes us
        // Zero     = Settled
        // Negative = We hold customer advance
        //
        // Example:
        //
        // Gross Outstanding = 0
        // Customer Advance  = 200
        //
        // Net Outstanding   = -200
        // ==================================================

        const currentAdvanceBalance =
          Math.max(
            0,
            Number(
              row.advanceBalance || 0
            )
          );


        row.netOutstanding =
          Number(
            (
              grossOutstanding -
              currentAdvanceBalance
            ).toFixed(2)
          );


        // Existing frontend already reads `outstanding`.
        // Therefore keep this alias.
        row.outstanding =
          row.netOutstanding;

        // ================================================
        // PAYMENT STATUS
        // ================================================
        if (
          row.outstanding <
          -0.001
        ) {
          row.status =
            "ADVANCE";
        }

        else if (
          row.outstanding <=
          0.001
        ) {
          row.status =
            "PAID";
        }

        else {
          const hasPartPayment =
            row.bills.some(
              (bill) =>
                (
                  Number(
                    bill.paidAmount
                  ) || 0
                ) > 0
            );

          row.status =
            hasPartPayment
              ? "PARTIAL"
              : "DUE";
        }


        // ==================================================
        // DERIVE OPENING ADVANCE
        //
        // Current Advance
        // = Opening Advance
        // + Advance created from receipts
        // - Advance consumed by posted sales
        //
        // Therefore:
        //
        // Opening Advance
        // = Current Advance
        // - Receipt Advances
        // + Advance Used
        // ==================================================

        const totalAdvanceAdded =
          row.accountHistory.reduce(
            (sum, item) =>
              sum +
              Number(
                item.advanceAdded ||
                0
              ),
            0
          );


        const totalAdvanceUsed =
          row.accountHistory.reduce(
            (sum, item) =>
              sum +
              Number(
                item.advanceUsed ||
                0
              ),
            0
          );


        const derivedOpeningAdvance =
          Number(
            Math.max(
              0,

              Number(
                row.advanceBalance ||
                0
              ) -
              totalAdvanceAdded +
              totalAdvanceUsed
            ).toFixed(2)
          );


        if (
          derivedOpeningAdvance >
          0.001
        ) {

          row.accountHistory.push({
            type:
              "OPENING_ADVANCE",

            date:
              null,

            reference:
              "OPENING",

            description:
              "Opening customer advance balance.",

            billAmount:
              0,

            receivedAmount:
              0,

            outstandingAdded:
              0,

            outstandingReduced:
              0,

            advanceAdded:
              derivedOpeningAdvance,

            advanceUsed:
              0,
          });
        }


        // Oldest → newest
        row.accountHistory.sort(
          (a, b) => {

            if (!a.date) {
              return -1;
            }

            if (!b.date) {
              return 1;
            }

            return (
              new Date(a.date) -
              new Date(b.date)
            );
          }
        );
        data.push(
          row
        );
      }


      // ==================================================
      // DUE FIRST
      // ==================================================

      data.sort(
        (a, b) => {

          if (
            a.outstanding !==
            b.outstanding
          ) {

            return (
              b.outstanding -
              a.outstanding
            );
          }

          return (
            a.customerName || ""
          ).localeCompare(
            b.customerName || ""
          );
        }
      );


      return res.status(200).json({

        success:
          true,

        count:
          data.length,

        data:
          data,
      });


    } catch (error) {

      console.error(
        "GET COLLECTION OUTSTANDING ERROR:",
        error
      );


      return res.status(500).json({

        success:
          false,

        message:
          "Unable to load customer outstanding.",

        error:
          error.message,
      });
    }
  }
);


// ======================================================
// ADD COLLECTION
// ======================================================
// ======================================================
// ADD COLLECTION
// CUSTOMER OUTSTANDING + FIFO BILL SETTLEMENT
// ======================================================

app.post(
  "/api/collections",
  authenticateToken,
  loadAccessContext,
  requirePermission("collectionCreate"),
  async (req, res) => {
    const farmId =
      req.user?.farmId;

    const normalizedClientRequestId =
      (req.body?.clientRequestId || "")
        .toString()
        .trim();

    try {
      const role =
        req.user.role;

      const {
        customerId,
        amount,
        paymentMode,
        referenceNo,
        remarks,
        collectionDate,
      } = req.body;

      if (normalizedClientRequestId) {
        const existingCollection = await Collection.findOne({
          farmId,
          clientRequestId: normalizedClientRequestId,
        }).lean();

        if (existingCollection) {
          return res.status(200).json({
            success: true,
            message: "Collection already recorded (idempotent request).",
            data: existingCollection,
          });
        }
      }

      const normalizedCustomerId =
        (
          customerId || ""
        )
          .toString()
          .trim()
          .toUpperCase();

      const collectionAmount =
        Number(amount) || 0;


      // ==================================================
      // BASIC VALIDATION
      // ==================================================

      if (!normalizedCustomerId) {
        return res.status(400).json({
          success: false,
          message:
            "Customer is required.",
        });
      }


      if (collectionAmount <= 0) {
        return res.status(400).json({
          success: false,
          message:
            "Collection amount must be greater than zero.",
        });
      }


      const allowedPaymentModes = [
        "Cash",
        "UPI",
        "PhonePe",
        "Google Pay",
        "Paytm",
        "Bank Transfer",
      ];


      if (
        !allowedPaymentModes.includes(
          paymentMode
        )
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid payment mode.",
        });
      }


      // ==================================================
      // CUSTOMER
      // ==================================================

      const customer =
        await Customer.findOne({
          farmId,
          customerId:
            normalizedCustomerId,
          isActive:
            true,
        });


      if (!customer) {
        return res.status(404).json({
          success: false,
          message:
            "Customer not found.",
        });
      }

      if (req.access && req.access.isSalesman) {
        const salesmanRoute = await RouteMaster.findOne({
          farmId: farmId,
          routeName: customer.route,
          salesmanId: req.access.salesmanId,
          isActive: true,
        });
        if (!salesmanRoute) {
          return res.status(403).json({
            success: false,
            message: "You can only record collections for customers on your assigned routes.",
          });
        }
      }


      // ==================================================
      // SALESMAN
      // ==================================================

      let salesmanId = "";
      let salesmanName = "";


      if (role === "salesman") {
        const salesman =
          await getCurrentSalesmanForCollection(
            req
          );


        if (!salesman) {
          return res.status(404).json({
            success: false,
            message:
              "Salesman account not found.",
          });
        }


        salesmanId =
          salesman.salesmanId;

        salesmanName =
          salesman.name;
      }

      else if (role !== "admin") {
        return res.status(403).json({
          success: false,
          message:
            "You are not allowed to save collections.",
        });
      }


      // ==================================================
      // LOAD POSTED SALES
      //
      // DO NOT FILTER paymentMode = Credit.
      // Split/PARTIAL sales must also be included.
      // ==================================================

      const saleFilter = {
        farmId,
        customerId:
          normalizedCustomerId,
        status:
          "POSTED",
      };


      if (role === "salesman") {
        saleFilter.salesmanId =
          salesmanId;

        saleFilter.createdRole =
          "salesman";
      }


      const sales =
        await Sale.find(
          saleFilter
        )
          .select(
            [
              "saleId",
              "saleNo",
              "saleDate",
              "grandTotal",
              "paymentMode",
              "paidAmount",
              "outstandingAmount",
              "paymentStatus",
            ].join(" ")
          )
          .sort({
            saleDate: 1,
            createdAt: 1,
          })
          .lean();


      // ==================================================
      // CREATE BILL OUTSTANDING MAP
      // ==================================================

      const pendingBills = [];

      for (const sale of sales) {
        const billAmount =
          Number(
            sale.grandTotal
          ) || 0;


        let initialOutstanding =
          Number(
            sale.outstandingAmount
          );


        // ================================================
        // OLD RECORD COMPATIBILITY
        // ================================================

        if (
          !Number.isFinite(
            initialOutstanding
          )
        ) {
          const oldMode =
            (
              sale.paymentMode ||
              ""
            )
              .toString()
              .trim()
              .toLowerCase();


          initialOutstanding =
            oldMode === "credit"
              ? billAmount
              : 0;
        }


        initialOutstanding =
          Math.max(
            0,
            initialOutstanding
          );


      pendingBills.push({
  sourceType:
    "SALE",

  referenceId:
    sale.saleId || "",

  referenceNo:
    sale.saleNo || "",

  referenceDate:
    sale.saleDate,

  sourceAmount:
    billAmount,

  // OLD SALE ALIASES
  saleId:
    sale.saleId || "",

          saleNo:
            sale.saleNo || "",

          saleDate:
            sale.saleDate,

          billAmount,

          initialOutstanding,

          collectionApplied:
            0,

          remainingOutstanding:
            initialOutstanding,
        });
      }
// ==================================================
// MANUAL OUTSTANDING SOURCES
// ==================================================

const manualOutstandingRecords =
  await CustomerOutstanding.find({
    farmId,

    customerId:
      normalizedCustomerId,

    status:
      "POSTED",
  })
    .select(
      [
        "adjustmentId",
        "adjustmentNo",
        "adjustmentDate",
        "amount",
        "remarks",
      ].join(" ")
    )
    .sort({
      adjustmentDate: 1,
      createdAt: 1,
    })
    .lean();


for (
  const manualOutstanding of
  manualOutstandingRecords
) {
  const manualAmount =
    Math.max(
      0,
      Number(
        manualOutstanding.amount ||
        0
      )
    );


  pendingBills.push({
    sourceType:
      "MANUAL_OUTSTANDING",

    referenceId:
      manualOutstanding.adjustmentId ||
      "",

    referenceNo:
      manualOutstanding.adjustmentNo ||
      "",

    referenceDate:
      manualOutstanding.adjustmentDate,

    sourceAmount:
      manualAmount,

    saleId:
      "",

    saleNo:
      "",

    saleDate:
      null,

    billAmount:
      manualAmount,

    initialOutstanding:
      manualAmount,

    collectionApplied:
      0,

    remainingOutstanding:
      manualAmount,

    remarks:
      manualOutstanding.remarks ||
      "",
  });
}


// ==================================================
// FIFO ORDER - SALES + MANUAL OUTSTANDING
// ==================================================

pendingBills.sort(
  (a, b) =>
    new Date(
      a.referenceDate ||
      0
    ) -
    new Date(
      b.referenceDate ||
      0
    )
);

      // ==================================================
      // LOAD ALL PREVIOUS POSTED COLLECTIONS
      // ==================================================

      const previousCollectionFilter = {
        farmId,
        customerId:
          normalizedCustomerId,
        status:
          "POSTED",
      };


      const previousCollections =
        await Collection.find(
          previousCollectionFilter
        )
          .select(
            [
              "collectionId",
              "collectionDate",
              "amount",
              "allocations",
            ].join(" ")
          )
          .sort({
            collectionDate: 1,
            createdAt: 1,
          })
          .lean();


      // ==================================================
      // MAP SALES
      // ==================================================

      const billMap =
        new Map();
for (
  const bill of pendingBills
) {
  const key =
    getOutstandingSourceKey(
      bill.sourceType,
      bill.referenceId
    );


  billMap.set(
    key,
    bill
  );
}

      // ==================================================
      // APPLY PREVIOUS COLLECTIONS
      //
      // New receipts:
      //   use saved allocations.
      //
      // Old receipts:
      //   FIFO for compatibility.
      // ==================================================

      for (
        const previousCollection of
        previousCollections
      ) {
        const allocations =
          Array.isArray(
            previousCollection.allocations
          )
            ? previousCollection.allocations
            : [];


        // ================================================
        // NEW RECEIPT WITH STORED ALLOCATIONS
        // ================================================

        if (allocations.length > 0) {
          for (
            const allocation of
            allocations
          ) {
 const sourceType =
  (
    allocation.sourceType ||
    "SALE"
  )
    .toString()
    .trim()
    .toUpperCase();


const referenceId =
  (
    allocation.referenceId ||
    allocation.saleId ||
    ""
  )
    .toString()
    .trim()
    .toUpperCase();


const key =
  getOutstandingSourceKey(
    sourceType,
    referenceId
  );


if (
  !billMap.has(
    key
  )
) {
              continue;
            }


        const bill =
  billMap.get(
    key
  );

            const applied =
              Math.max(
                0,
                Number(
                  allocation.amountApplied
                ) || 0
              );


            const actualApplied =
              Math.min(
                bill.remainingOutstanding,
                applied
              );


            bill.collectionApplied +=
              actualApplied;

            bill.remainingOutstanding -=
              actualApplied;
          }


          continue;
        }


        // ================================================
        // LEGACY RECEIPT
        // FIFO
        // ================================================

        let remainingReceipt =
          Math.max(
            0,
            Number(
              previousCollection.amount
            ) || 0
          );

const receiptDate =
  previousCollection.collectionDate
    ? new Date(
        previousCollection.collectionDate
      )
    : null;
        for (
          const bill of pendingBills
        ) {
          if (
            remainingReceipt <= 0
          ) {
            break;
          }
          if (
  bill.sourceType !==
  "SALE"
) {
  continue;
}


if (
  receiptDate &&
  bill.referenceDate &&
  new Date(
    bill.referenceDate
  ) >
  receiptDate
) {
  continue;
}


          if (
            bill.remainingOutstanding <= 0
          ) {
            continue;
          }


          const applied =
            Math.min(
              remainingReceipt,
              bill.remainingOutstanding
            );


          bill.collectionApplied +=
            applied;

          bill.remainingOutstanding -=
            applied;

          remainingReceipt -=
            applied;
        }
      }


      // ==================================================
      // CALCULATE CURRENT OUTSTANDING
      // ==================================================

      let outstanding = 0;

      for (
        const bill of pendingBills
      ) {
        outstanding +=
          Math.max(
            0,
            bill.remainingOutstanding
          );
      }


outstanding =
  Number(
    outstanding.toFixed(2)
  );


// ==================================================
// NET COLLECTIBLE OUTSTANDING
//
// Gross Bill Outstanding
// - Available Customer Advance
//
// Example:
//
// Gross Bills = 1000
// Advance     = 200
//
// Customer should be allowed to pay only 800.
// ==================================================

const currentCustomerAdvance =
  Math.max(
    0,
    Number(
      customer.balance || 0
    )
  );

const collectibleOutstanding =
  Number(
    Math.max(
      0,
      outstanding -
      currentCustomerAdvance
    ).toFixed(2)
  );


// ==================================================
// COLLECTION RULE
//
// Collection can settle OUTSTANDING ONLY.
// It can never create customer advance.
//
// Advance is created only when:
// SALE BILL PAYMENT > BILL TOTAL
// ==================================================

if (
  collectibleOutstanding <=
  0.001
) {
  return res.status(409).json({
    success: false,
    message:
      "This customer has no pending net outstanding.",
  });
}


if (
  collectionAmount >
  collectibleOutstanding +
  0.001
) {
  return res.status(400).json({
    success: false,

    message:
      `Collection amount cannot exceed net outstanding ₹${collectibleOutstanding.toFixed(
        2
      )}. Extra payment can be recorded only during sale billing.`,
  });
}


// Full receipt is applied against outstanding.
const appliedAmount =
  Number(
    collectionAmount.toFixed(2)
  );


// Keep for historical compatibility.
// All NEW receipts save zero advance.
const advanceAmount =
  0;
      // ==================================================
      // APPLY NEW COLLECTION FIFO
      // ==================================================

      let remainingCollection =
        appliedAmount;
      const allocations = [];


      for (
        const bill of pendingBills
      ) {
        if (
          remainingCollection <=
          0.001
        ) {
          break;
        }


        if (
          bill.remainingOutstanding <=
          0.001
        ) {
          continue;
        }


        const outstandingBefore =
          Number(
            bill.remainingOutstanding.toFixed(2)
          );

        const amountApplied =
          Math.min(
            remainingCollection,
            bill.remainingOutstanding
          );

        const outstandingAfter =
          Number(
            Math.max(
              0,
              outstandingBefore - amountApplied
            ).toFixed(2)
          );

allocations.push({
  sourceType:
    bill.sourceType ||
    "SALE",

  referenceId:
    bill.referenceId ||
    bill.saleId ||
    "",

  referenceNo:
    bill.referenceNo ||
    bill.saleNo ||
    "",

  referenceDate:
    bill.referenceDate ||
    bill.saleDate ||
    null,

  sourceAmount:
    Number(
      (
        bill.sourceAmount ||
        bill.billAmount ||
        0
      ).toFixed(2)
    ),

  allocationSequence:
    allocations.length + 1,

  outstandingBefore,

  outstandingAfter,

  // KEEP OLD SALE FIELDS
  saleId:
    bill.sourceType ===
    "SALE"
      ? bill.saleId
      : "",

  saleNo:
    bill.sourceType ===
    "SALE"
      ? bill.saleNo
      : "",

  saleDate:
    bill.sourceType ===
    "SALE"
      ? bill.saleDate
      : null,

  billAmount:
    Number(
      bill.billAmount.toFixed(2)
    ),

  amountApplied:
    Number(
      amountApplied.toFixed(2)
    ),
});

        bill.collectionApplied +=
          amountApplied;

        bill.remainingOutstanding -=
          amountApplied;

        remainingCollection -=
          amountApplied;
      }

      if (
        remainingCollection >
        0.001
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Unable to allocate the applicable collection amount against outstanding bills.",
        });
      }


      // ==================================================
      // GENERATE IDS
      // ==================================================

      const collectionId =
        await generateCollectionId();


      const receiptNo =
        await generateReceiptNo(
          farmId
        );


      // ==================================================
      // VALID COLLECTION DATE
      // ==================================================

      let finalCollectionDate =
        new Date();


      if (collectionDate) {
        const parsedDate =
          new Date(
            collectionDate
          );


        if (
          !Number.isNaN(
            parsedDate.getTime()
          )
        ) {
          finalCollectionDate =
            parsedDate;
        }
      }

      // ==================================================
      // BALANCE SNAPSHOTS
      // ==================================================

      const previousAdvanceBalance =
        Math.max(
          0,
          Number(
            customer.balance || 0
          )
        );

      const newOutstanding =
        Number(
          Math.max(
            0,
            collectibleOutstanding -
            appliedAmount
          ).toFixed(2)
        );

      // ==================================================
      // SAVE RECEIPT
      // ==================================================

      const collectionToCreate = {
        farmId,

        collectionId,

        receiptNo,

        collectionDate:
          finalCollectionDate,

        customerId:
          customer.customerId,

        customerName:
          customer.name,

        customerMobile:
          customer.mobile || "",

        route:
          customer.route || "",

        salesmanId,

        salesmanName,

        amount:
          Number(
            collectionAmount.toFixed(2)
          ),

        appliedAmount:
          Number(
            appliedAmount.toFixed(2)
          ),

        advanceAmount:
          Number(
            advanceAmount.toFixed(2)
          ),

        previousOutstanding:
          Number(
            collectibleOutstanding.toFixed(2)
          ),

        remainingOutstanding:
          Number(
            newOutstanding.toFixed(2)
          ),

        previousAdvanceBalance:
          Number(
            previousAdvanceBalance.toFixed(2)
          ),

        currentAdvanceBalance:
          Number(
            previousAdvanceBalance.toFixed(2)
          ),

        allocations,

        paymentMode,

        referenceNo:
          referenceNo
            ?.toString()
            .trim() ||
          "",

        remarks:
          remarks
            ?.toString()
            .trim() ||
          "",

        status:
          "POSTED",

        createdBy:
          req.user.userId || "",

        createdRole:
          role,

        createdAt:
          new Date(),

        updatedAt:
          new Date(),
      };

      if (normalizedClientRequestId) {
        collectionToCreate.clientRequestId =
          normalizedClientRequestId;
      }

      const savedCollection =
        await Collection.create(collectionToCreate);


      return res.status(201).json({
        success: true,

        message:
          "Collection saved successfully.",

        data: {
          ...savedCollection.toObject(),

       previousOutstanding:
  Number(
    collectibleOutstanding.toFixed(2)
  ),

grossOutstanding:
  Number(
    outstanding.toFixed(2)
  ),

          remainingOutstanding:
            Number(
              newOutstanding.toFixed(2)
            ),
          appliedAmount:
            Number(
              appliedAmount.toFixed(2)
            ),

          advanceAmount:
            Number(
              advanceAmount.toFixed(2)
            ),

          previousAdvanceBalance:
            Number(
              previousAdvanceBalance.toFixed(2)
            ),

          currentAdvanceBalance:
            Number(
              previousAdvanceBalance.toFixed(2)
            ),
        },
      });

    } catch (error) {
      console.error(
        "ADD COLLECTION ERROR:",
        error
      );


      if (
        error.code === 11000
      ) {
        if (normalizedClientRequestId) {
          const existingCollection = await Collection.findOne({
            farmId,
            clientRequestId: normalizedClientRequestId,
          }).lean();

          if (existingCollection) {
            return res.status(200).json({
              success: true,
              message: "Collection already recorded (idempotent request).",
              data: existingCollection,
            });
          }
        }

        return res.status(409).json({
          success: false,
          message:
            "Duplicate collection or receipt number detected.",
        });
      }


      return res.status(500).json({
        success: false,

        message:
          "Unable to save collection.",

        error:
          error.message,
      });
    }
  }
);


// ======================================================
// GET COLLECTION HISTORY
//
// ADMIN    -> ALL FARM COLLECTIONS
// SALESMAN -> ONLY HIS OWN COLLECTIONS
// ======================================================

app.get(
  "/api/collections",
  authenticateToken,
  loadAccessContext,
  requirePermission("collectionView"),
  async (req, res) => {

    try {

      const farmId =
        req.user.farmId;

      const role =
        req.user.role;


      const filter = {

        farmId:
          farmId,
      };


      // ==================================================
      // SALESMAN FILTER
      // ==================================================

      if (
        role === "salesman"
      ) {

        const salesman =
          await getCurrentSalesmanForCollection(
            req
          );


        if (!salesman) {

          return res.status(404).json({
            success: false,
            message:
              "Salesman account not found.",
          });
        }


        filter.salesmanId =
          salesman.salesmanId;
      }


      else if (
        role !== "admin"
      ) {

        return res.status(403).json({
          success: false,
          message:
            "You are not allowed to view collections.",
        });
      }


      // ==================================================
      // OPTIONAL FILTERS
      // ==================================================

      const customerId =
        (
          req.query.customerId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      const salesmanIdFilter =
        (
          req.query.salesmanId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      const route =
        (
          req.query.route ||
          ""
        )
          .toString()
          .trim();


      const status =
        (
          req.query.status ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      if (customerId) {

        filter.customerId =
          customerId;
      }


      if (
        role === "admin" &&
        salesmanIdFilter
      ) {

        filter.salesmanId =
          salesmanIdFilter;
      }


      if (route) {

        filter.route =
          route;
      }


      if (
        ["POSTED", "CANCELLED"]
          .includes(status)
      ) {

        filter.status =
          status;
      }


      // ==================================================
      // DATE FILTER
      // YYYY-MM-DD
      // ==================================================

      const date =
        (
          req.query.date ||
          ""
        )
          .toString()
          .trim();


      if (date) {

        const start =
          new Date(
            `${date}T00:00:00`
          );


        const end =
          new Date(
            `${date}T23:59:59.999`
          );


        if (
          !Number.isNaN(
            start.getTime()
          ) &&
          !Number.isNaN(
            end.getTime()
          )
        ) {

          filter.collectionDate = {
            $gte:
              start,

            $lte:
              end,
          };
        }
      }


      // ==================================================
      // LOAD
      // ==================================================

      const collections =
        await Collection.find(
          filter
        )
          .sort({
            collectionDate: -1,
            createdAt: -1,
          })
          .lean();


      return res.status(200).json({

        success:
          true,

        count:
          collections.length,

        data:
          collections,
      });


    } catch (error) {

      console.error(
        "GET COLLECTIONS ERROR:",
        error
      );


      return res.status(500).json({

        success:
          false,

        message:
          "Unable to load collections.",

        error:
          error.message,
      });
    }
  }
);


// ======================================================
// CANCEL COLLECTION
// ======================================================
// ======================================================
// CANCEL COLLECTION
//
// IMPORTANT:
//
// 1. Posted collection allocations automatically stop
//    affecting outstanding once status becomes CANCELLED.
//
// 2. If this receipt created customer advance,
//    that advance must be removed from MAS_CUSTOMER.balance.
//
// 3. If part of that advance has already been consumed
//    by later sales, cancellation is blocked.
// ======================================================

app.put(
  "/api/collections/:collectionId/cancel",
  authenticateToken,
  loadAccessContext,
  requirePermission("collectionCreate"),
  async (req, res) => {

    const session =
      await mongoose.startSession();

    try {

      let cancelledCollection =
        null;

      let responseData =
        null;

      await session.withTransaction(
        async () => {

          const farmId =
            req.user.farmId;

          const role =
            req.user.role;

          const collectionId =
            (
              req.params.collectionId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (!collectionId) {

            const error =
              new Error(
                "Collection ID is required."
              );

            error.statusCode =
              400;

            throw error;
          }


          const filter = {
            farmId,
            collectionId,
          };


          // ==================================================
          // SALESMAN CAN CANCEL ONLY HIS OWN COLLECTION
          // ==================================================

          if (
            role === "salesman"
          ) {

            const salesman =
              await getCurrentSalesmanForCollection(
                req
              );


            if (!salesman) {

              const error =
                new Error(
                  "Salesman account not found."
                );

              error.statusCode =
                404;

              throw error;
            }


            filter.salesmanId =
              salesman.salesmanId;
          }

          else if (
            role !== "admin"
          ) {

            const error =
              new Error(
                "You are not allowed to cancel collections."
              );

            error.statusCode =
              403;

            throw error;
          }


          // ==================================================
          // LOAD COLLECTION
          // ==================================================

          const collection =
            await Collection.findOne(
              filter
            ).session(session);


          if (!collection) {

            const error =
              new Error(
                "Collection not found."
              );

            error.statusCode =
              404;

            throw error;
          }


          if (
            collection.status ===
            "CANCELLED"
          ) {

            const error =
              new Error(
                "Collection is already cancelled."
              );

            error.statusCode =
              409;

            throw error;
          }

          // ==================================================
          // SAFETY CHECK: PREVENT CANCELLATION IF NEWER POSTED
          // COLLECTIONS EXIST FOR THIS CUSTOMER
          // ==================================================
          const newerCollection =
            await Collection.findOne({
              farmId,
              customerId:
                collection.customerId,
              status:
                "POSTED",
              $or: [
                {
                  collectionDate: {
                    $gt: collection.collectionDate,
                  },
                },
                {
                  collectionDate:
                    collection.collectionDate,
                  createdAt: {
                    $gt: collection.createdAt,
                  },
                },
                {
                  collectionDate:
                    collection.collectionDate,
                  _id: {
                    $gt: collection._id,
                  },
                },
              ],
            }).session(session);

          if (newerCollection) {
            const error =
              new Error(
                `Cannot cancel this receipt because newer collection transaction (${newerCollection.receiptNo || newerCollection.collectionId}) exists for this customer. Cancel the latest receipt first.`
              );
            error.statusCode = 409;
            throw error;
          }


          // ==================================================
          // ADVANCE CREATED BY THIS RECEIPT
          // ==================================================

          const advanceAmount =
            Math.max(
              0,
              Number(
                collection.advanceAmount ||
                0
              )
            );


          let previousAdvanceBalance =
            0;

          let currentAdvanceBalance =
            0;


          // ==================================================
          // IF COLLECTION CREATED CUSTOMER ADVANCE,
          // REMOVE IT FROM CUSTOMER BALANCE.
          //
          // SAFETY:
          // Balance must still contain the full amount.
          //
          // Example:
          //
          // Receipt advance = 1000
          // Current balance = 400
          //
          // Means 600 has already been consumed by sale.
          // Do NOT cancel until dependent sale is reversed.
          // ==================================================

          if (
            advanceAmount >
            0.001
          ) {

            const customer =
              await Customer.findOne({
                farmId,

                customerId:
                  collection.customerId,
              }).session(session);


            if (!customer) {

              const error =
                new Error(
                  "Customer linked to this collection was not found."
                );

              error.statusCode =
                404;

              throw error;
            }


            previousAdvanceBalance =
              Math.max(
                0,
                Number(
                  customer.balance ||
                  0
                )
              );


            if (
              previousAdvanceBalance +
              0.001 <
              advanceAmount
            ) {

              const shortAmount =
                Number(
                  Math.max(
                    0,
                    advanceAmount -
                    previousAdvanceBalance
                  ).toFixed(2)
                );

              const error =
                new Error(
                  `Cannot cancel this collection. Receipt advance to reverse is ₹${advanceAmount.toFixed(
                    2
                  )}, but current available customer advance is only ₹${previousAdvanceBalance.toFixed(
                    2
                  )}. Available advance is short by ₹${shortAmount.toFixed(
                    2
                  )}. Reverse/cancel the dependent transactions first.`
                );

              error.statusCode =
                409;

              throw error;
            }


            currentAdvanceBalance =
              Number(
                Math.max(
                  0,
                  previousAdvanceBalance -
                  advanceAmount
                ).toFixed(2)
              );


            customer.balance =
              currentAdvanceBalance;

            customer.updatedAt =
              new Date();


            await customer.save({
              session,
            });
          }


          // ==================================================
          // MARK COLLECTION CANCELLED
          //
          // We do NOT manually edit each sale outstanding here.
          //
          // Outstanding API already considers only POSTED
          // collections, so after this becomes CANCELLED,
          // its allocations automatically stop reducing bills.
          // ==================================================

          collection.status =
            "CANCELLED";

          collection.cancelledBy =
            req.user.userId ||
            "";

          collection.cancelledAt =
            new Date();

          collection.cancelReason =
            (
              req.body.cancelReason ||
              req.body.reason ||
              "Cancelled by user"
            )
              .toString()
              .trim();

          collection.updatedAt =
            new Date();


          await collection.save({
            session,
          });


          cancelledCollection =
            collection;


          responseData = {
            ...collection.toObject(),

            advanceReversed:
              Number(
                advanceAmount.toFixed(2)
              ),

            previousAdvanceBalance:
              Number(
                previousAdvanceBalance.toFixed(2)
              ),

            currentAdvanceBalance:
              Number(
                currentAdvanceBalance.toFixed(2)
              ),
          };
        }
      );


      return res.status(200).json({

        success: true,

        message:
          Number(
            cancelledCollection
              ?.advanceAmount ||
            0
          ) > 0
            ? `Collection cancelled successfully. ₹${Number(
              cancelledCollection.advanceAmount
            ).toFixed(
              2
            )} customer advance reversed.`
            : "Collection cancelled successfully.",

        data:
          responseData,
      });


    } catch (error) {

      console.error(
        "CANCEL COLLECTION ERROR:",
        error
      );


      return res
        .status(
          error.statusCode ||
          500
        )
        .json({

          success: false,

          message:
            error.message ||
            "Unable to cancel collection.",
        });

    } finally {

      await session.endSession();
    }
  }
);
// ======================================================
// PAYMENT
// SUPPLIER PAYMENT / PAYABLE
// ======================================================


// ======================================================
// GET SUPPLIER OUTSTANDING
//
// POSTED CREDIT PURCHASES
// MINUS
// POSTED PAYMENTS
// ======================================================

app.get(
  "/api/payments/outstanding",
  authenticateToken,
  loadAccessContext,
  requirePermission("paymentsView"),
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      // ================================================
      // LOAD CREDIT PURCHASES
      // ================================================

      const purchases =
        await Purchase.find({
          farmId,
          status:
            "POSTED",

          paymentType: {
            $regex:
              /^Credit$/i,
          },
        })
          .select(
            "purchaseId purchaseNo purchaseDate billDate dueDate supplierId supplierName grandTotal"
          )
          .sort({
            purchaseDate: 1,
            createdAt: 1,
          })
          .lean();

      // ================================================
      // LOAD POSTED PAYMENTS
      // ================================================

      const payments =
        await Payment.find({
          farmId,
          status:
            "POSTED",
        })
          .select(
            "supplierId amount paymentMode paymentDate paymentNo"
          )
          .sort({
            paymentDate: 1,
            createdAt: 1,
          })
          .lean();

      const supplierMap =
        new Map();

      // ================================================
      // PURCHASE TOTAL
      // ================================================

      for (
        const purchase of purchases
      ) {
        const supplierId =
          (
            purchase.supplierId ||
            ""
          )
            .toString()
            .trim()
            .toUpperCase();

        if (!supplierId) {
          continue;
        }

        if (
          !supplierMap.has(
            supplierId
          )
        ) {
          supplierMap.set(
            supplierId,
            {
              supplierId:
                supplierId,

              supplierName:
                purchase.supplierName ||
                "",

              totalCreditPurchases:
                0,

              totalPaid:
                0,

              outstanding:
                0,

              purchaseCount:
                0,

              lastPaymentMode:
                "",

              lastPaymentDate:
                null,

              lastPaymentNo:
                "",
            }
          );
        }

        const row =
          supplierMap.get(
            supplierId
          );

        row.totalCreditPurchases +=
          Number(
            purchase.grandTotal
          ) || 0;

        row.purchaseCount +=
          1;
      }

      // ================================================
      // SUBTRACT PAYMENTS
      // ================================================

      for (
        const payment of payments
      ) {
        const supplierId =
          (
            payment.supplierId ||
            ""
          )
            .toString()
            .trim()
            .toUpperCase();

        if (
          !supplierMap.has(
            supplierId
          )
        ) {
          continue;
        }

        const row =
          supplierMap.get(
            supplierId
          );

        row.totalPaid +=
          Number(
            payment.amount
          ) || 0;

        row.lastPaymentMode =
          payment.paymentMode ||
          "";

        row.lastPaymentDate =
          payment.paymentDate ||
          null;

        row.lastPaymentNo =
          payment.paymentNo ||
          "";
      }

      const data = [];

      // ================================================
      // FINAL OUTSTANDING
      // ================================================

      for (
        const row of
        supplierMap.values()
      ) {
        row.totalCreditPurchases =
          Number(
            row.totalCreditPurchases
              .toFixed(2)
          );

        row.totalPaid =
          Number(
            row.totalPaid
              .toFixed(2)
          );

        row.outstanding =
          Number(
            Math.max(
              0,
              row.totalCreditPurchases -
              row.totalPaid
            ).toFixed(2)
          );

        if (
          row.outstanding <= 0
        ) {
          row.status =
            "PAID";
        }

        else if (
          row.totalPaid > 0
        ) {
          row.status =
            "PARTIAL";
        }

        else {
          row.status =
            "DUE";
        }

        data.push(
          row
        );
      }

      data.sort(
        (a, b) =>
          b.outstanding -
          a.outstanding
      );

      return res.status(200).json({
        success: true,
        count:
          data.length,
        data:
          data,
      });
    } catch (error) {
      console.error(
        "GET PAYMENT OUTSTANDING ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load supplier outstanding.",
        error:
          error.message,
      });
    }
  }
);


// ======================================================
// ADD SUPPLIER PAYMENT
// ======================================================

app.post(
  "/api/payments",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const {
        supplierId,
        amount,
        paymentMode,
        referenceNo,
        remarks,
        paymentDate,
      } = req.body;

      const normalizedSupplierId =
        (
          supplierId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      const paymentAmount =
        Number(
          amount
        ) || 0;

      // ================================================
      // VALIDATION
      // ================================================

      if (
        !normalizedSupplierId
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Supplier is required.",
        });
      }

      if (
        paymentAmount <= 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Payment amount must be greater than zero.",
        });
      }

      const allowedModes = [
        "Cash",
        "UPI",
        "Bank Transfer",
        "Cheque",
      ];

      if (
        !allowedModes.includes(
          paymentMode
        )
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid payment mode.",
        });
      }

      // ================================================
      // SUPPLIER
      // ================================================

      const supplier =
        await Supplier.findOne({
          farmId,
          supplierId:
            normalizedSupplierId,
          isActive:
            true,
        });

      if (!supplier) {
        return res.status(404).json({
          success: false,
          message:
            "Supplier not found.",
        });
      }

      // ================================================
      // TOTAL CREDIT PURCHASE
      // ================================================

      const purchases =
        await Purchase.find({
          farmId,
          supplierId:
            normalizedSupplierId,
          status:
            "POSTED",

          paymentType: {
            $regex:
              /^Credit$/i,
          },
        })
          .select(
            "grandTotal"
          )
          .lean();

      let totalCreditPurchase =
        0;

      for (
        const purchase of purchases
      ) {
        totalCreditPurchase +=
          Number(
            purchase.grandTotal
          ) || 0;
      }

      // ================================================
      // PREVIOUS PAYMENTS
      // ================================================

      const previousPayments =
        await Payment.find({
          farmId,
          supplierId:
            normalizedSupplierId,
          status:
            "POSTED",
        })
          .select(
            "amount"
          )
          .lean();

      let alreadyPaid =
        0;

      for (
        const payment of
        previousPayments
      ) {
        alreadyPaid +=
          Number(
            payment.amount
          ) || 0;
      }

      // ================================================
      // PAYABLE
      // ================================================

      const outstanding =
        Math.max(
          0,
          totalCreditPurchase -
          alreadyPaid
        );

      if (
        outstanding <= 0
      ) {
        return res.status(409).json({
          success: false,
          message:
            "This supplier has no pending payable.",
        });
      }

      if (
        paymentAmount >
        outstanding + 0.001
      ) {
        return res.status(400).json({
          success: false,
          message:
            `Payment cannot exceed supplier outstanding ₹${outstanding.toFixed(2)}.`,
        });
      }

      const paymentId =
        await generatePaymentId();

      const paymentNo =
        await generatePaymentNo(
          farmId
        );

      const payment =
        await Payment.create({
          farmId,

          paymentId,

          paymentNo,

          paymentDate:
            paymentDate
              ? new Date(
                paymentDate
              )
              : new Date(),

          supplierId:
            supplier.supplierId,

          supplierName:
            supplier.supplierName,

          supplierMobile:
            supplier.mobile ||
            "",

          amount:
            Number(
              paymentAmount
                .toFixed(2)
            ),

          paymentMode,

          referenceNo:
            (
              referenceNo ||
              ""
            )
              .toString()
              .trim(),

          remarks:
            (
              remarks ||
              ""
            )
              .toString()
              .trim(),

          status:
            "POSTED",

          createdBy:
            req.user.userId ||
            "",

          createdRole:
            req.user.role ||
            "admin",

          createdAt:
            new Date(),

          updatedAt:
            new Date(),
        });

      const remainingOutstanding =
        Math.max(
          0,
          outstanding -
          paymentAmount
        );

      return res.status(201).json({
        success: true,

        message:
          "Supplier payment saved successfully.",

        data: {
          ...payment.toObject(),

          previousOutstanding:
            Number(
              outstanding
                .toFixed(2)
            ),

          remainingOutstanding:
            Number(
              remainingOutstanding
                .toFixed(2)
            ),
        },
      });
    } catch (error) {
      console.error(
        "ADD PAYMENT ERROR:",
        error
      );

      if (
        error.code === 11000
      ) {
        return res.status(409).json({
          success: false,
          message:
            "Duplicate payment number detected.",
        });
      }

      return res.status(500).json({
        success: false,
        message:
          "Unable to save supplier payment.",
        error:
          error.message,
      });
    }
  }
);


// ======================================================
// GET PAYMENT HISTORY
// ======================================================

app.get(
  "/api/payments",
  authenticateToken,
  loadAccessContext,
  requirePermission("paymentsView"),
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const filter = {
        farmId,
      };

      const supplierId =
        (
          req.query.supplierId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      const status =
        (
          req.query.status ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      if (
        supplierId
      ) {
        filter.supplierId =
          supplierId;
      }

      if (
        [
          "POSTED",
          "CANCELLED",
        ].includes(status)
      ) {
        filter.status =
          status;
      }

      const date =
        (
          req.query.date ||
          ""
        )
          .toString()
          .trim();

      if (date) {
        const start =
          new Date(
            `${date}T00:00:00`
          );

        const end =
          new Date(
            `${date}T23:59:59.999`
          );

        if (
          !Number.isNaN(
            start.getTime()
          )
        ) {
          filter.paymentDate = {
            $gte:
              start,

            $lte:
              end,
          };
        }
      }

      const payments =
        await Payment.find(
          filter
        )
          .sort({
            paymentDate: -1,
            createdAt: -1,
          })
          .lean();

      return res.status(200).json({
        success: true,
        count:
          payments.length,
        data:
          payments,
      });
    } catch (error) {
      console.error(
        "GET PAYMENTS ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load supplier payments.",
        error:
          error.message,
      });
    }
  }
);


// ======================================================
// CANCEL PAYMENT
// ======================================================

app.put(
  "/api/payments/:paymentId/cancel",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const paymentId =
        (
          req.params.paymentId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      const payment =
        await Payment.findOne({
          farmId,
          paymentId,
        });

      if (!payment) {
        return res.status(404).json({
          success: false,
          message:
            "Payment not found.",
        });
      }

      if (
        payment.status ===
        "CANCELLED"
      ) {
        return res.status(409).json({
          success: false,
          message:
            "Payment is already cancelled.",
        });
      }

      payment.status =
        "CANCELLED";

      payment.cancelledBy =
        req.user.userId ||
        "";

      payment.cancelledAt =
        new Date();

      payment.updatedAt =
        new Date();

      await payment.save();

      return res.status(200).json({
        success: true,
        message:
          "Supplier payment cancelled successfully.",
        data:
          payment,
      });
    } catch (error) {
      console.error(
        "CANCEL PAYMENT ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to cancel supplier payment.",
        error:
          error.message,
      });
    }
  }
);
// ======================================================
// LEDGER
// CUSTOMER + SUPPLIER
// ======================================================

app.get(
  "/api/ledger",
  authenticateToken,
  loadAccessContext,
  requirePermission("ledgerView"),
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const type =
        (
          req.query.type ||
          "customer"
        )
          .toString()
          .trim()
          .toLowerCase();

      const partyId =
        (
          req.query.partyId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      if (
        ![
          "customer",
          "supplier",
        ].includes(type)
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid ledger type.",
        });
      }

      if (!partyId) {
        return res.status(400).json({
          success: false,
          message:
            "Party is required.",
        });
      }


      // ==================================================
      // CUSTOMER LEDGER
      // CREDIT SALES + COLLECTIONS
      // ==================================================

      if (type === "customer") {

        const customer =
          await Customer.findOne({
            farmId,
            customerId:
              partyId,
            isActive:
              true,
          })
     .select(
  "customerId name mobile route balance"
)
            .lean();

        if (!customer) {
          return res.status(404).json({
            success: false,
            message:
              "Customer not found.",
          });
        }

        if (req.access && req.access.isSalesman) {
          const salesmanRoute = await RouteMaster.findOne({
            farmId: farmId,
            routeName: customer.route,
            salesmanId: req.access.salesmanId,
            isActive: true,
          });
          if (!salesmanRoute) {
            return res.status(403).json({
              success: false,
              message: "You can only view ledger for customers on your assigned routes.",
            });
          }
        }


        // ----------------------------------------------
        // CREDIT SALES ONLY
        // ----------------------------------------------

        // ----------------------------------------------
        // ALL POSTED SALES
        // CASH / UPI / CREDIT / BANK TRANSFER
        // ----------------------------------------------

        const sales =
          await Sale.find({
            farmId,

            customerId:
              partyId,

            status:
              "POSTED",
          })
            .select(
              [
                "saleId",
                "saleNo",
                "saleDate",
                "customerId",
                "customerName",
                "grandTotal",
                "totalQuantity",

                "paymentMode",
        "payments",
"paidAmount",
"paymentApplied",
"advanceUsed",
"advanceCreated",
"outstandingAmount",
"paymentStatus",

                "products",

                "salesmanId",
                "salesmanName",
                "createdRole",
              ].join(" ")
            )
            .lean();


        // ----------------------------------------------
        // COLLECTIONS
        // ----------------------------------------------

        const collections =
          await Collection.find({
            farmId,

            customerId:
              partyId,

            status:
              "POSTED",
          })
            .select(
              [
                "collectionId",
                "receiptNo",
             "collectionDate",
"amount",
"appliedAmount",
"advanceAmount",
"paymentMode",
                "referenceNo",
                "salesmanId",
                "salesmanName",
                "allocations",
              ].join(" ")
            )
            .lean();
            // ----------------------------------------------
// MANUAL CUSTOMER OUTSTANDING
// ----------------------------------------------

const manualOutstandingRecords =
  await CustomerOutstanding.find({
    farmId,

    customerId:
      partyId,

    status:
      "POSTED",
  })
    .select(
      [
        "adjustmentId",
        "adjustmentNo",
        "adjustmentDate",
        "amount",
        "remarks",
      ].join(" ")
    )
    .sort({
      adjustmentDate: 1,
      createdAt: 1,
    })
    .lean();

// ==================================================
// CUSTOMER ADVANCE RECONCILIATION FOR LEDGER
//
// Current Advance
// = Opening Advance
// + Sale Advances Created
// + Historical Receipt Advances
// - Advance Used On Later Bills
//
// Therefore:
//
// Opening Advance
// = Current Advance
// - Created Advances
// - Receipt Advances
// + Used Advances
// ==================================================

const currentAdvanceBalance =
  Math.max(
    0,
    Number(
      customer.balance || 0
    )
  );


const totalSaleAdvanceCreated =
  sales.reduce(
    (total, sale) =>
      total +
      Math.max(
        0,
        Number(
          sale.advanceCreated || 0
        )
      ),
    0
  );


const totalSaleAdvanceUsed =
  sales.reduce(
    (total, sale) =>
      total +
      Math.max(
        0,
        Number(
          sale.advanceUsed || 0
        )
      ),
    0
  );


const totalCollectionAdvanceCreated =
  collections.reduce(
    (total, collection) =>
      total +
      Math.max(
        0,
        Number(
          collection.advanceAmount || 0
        )
      ),
    0
  );


const openingAdvanceBalance =
  Number(
    Math.max(
      0,
      currentAdvanceBalance -
      totalSaleAdvanceCreated -
      totalCollectionAdvanceCreated +
      totalSaleAdvanceUsed
    ).toFixed(2)
  );
        const entries = [];
        // ==================================================
// OPENING ADVANCE ENTRY
// ==================================================

if (
  openingAdvanceBalance >
  0.001
) {
  entries.push({
    id:
      "OPENING_ADVANCE",

    referenceNo:
      "OPENING",

    date:
      null,

    type:
      "OPENING_ADVANCE",

    title:
      "Opening Advance",

    amount:
      openingAdvanceBalance,

    debit:
      0,

    credit:
      openingAdvanceBalance,

    paymentMode:
      "",

    reference:
      "",

    affectsBalance:
      true,
  });
}

        let totalDebit = 0;
        let totalCredit = 0;

      let totalSales = 0;
let totalPaidAtBilling = 0;
let totalManualOutstanding = 0;

        let totalCash = 0;
        let totalUpi = 0;
        let totalBank = 0;
        let totalOther = 0;


        // ----------------------------------------------
        // SALES = DEBIT
        // ----------------------------------------------

        // ----------------------------------------------
        // ALL SALES
        //
        // CREDIT SALE
        //   -> AFFECTS OUTSTANDING
        //
        // CASH / UPI / BANK TRANSFER
        //   -> SHOW IN LEDGER
        //   -> DOES NOT AFFECT OUTSTANDING
        // ----------------------------------------------
        for (
          const sale of sales
        ) {

          const billAmount =
            Number(
              sale.grandTotal
            ) || 0;

          const paidAmount =
            Math.max(
              0,
              Number(
                sale.paidAmount
              ) || 0
            );
            const advanceUsed =
  Math.max(
    0,
    Number(
      sale.advanceUsed || 0
    )
  );

const advanceCreated =
  Math.max(
    0,
    Number(
      sale.advanceCreated || 0
    )
  );

          // ==================================================
          // SALES SUMMARY TOTAL
          // ==================================================

          totalSales +=
            billAmount;

          totalPaidAtBilling +=
            paidAmount;


          // ==================================================
          // PAYMENT BREAKUP AT BILLING
          // CASH / UPI / BANK
          // ==================================================

          const salePayments =
            Array.isArray(
              sale.payments
            )
              ? sale.payments
              : [];

          for (
            const payment of
            salePayments
          ) {
            const mode =
              (
                payment.mode ||
                payment.paymentMode ||
                ""
              )
                .toString()
                .trim()
                .toLowerCase();

            const paymentAmount =
              Math.max(
                0,
                Number(
                  payment.amount
                ) || 0
              );

            if (
              mode === "cash"
            ) {
              totalCash +=
                paymentAmount;
            }

            else if (
              mode === "upi"
            ) {
              totalUpi +=
                paymentAmount;
            }

            else if (
              mode === "bank transfer" ||
              mode === "bank"
            ) {
              totalBank +=
                paymentAmount;
            }

            else {
              totalOther +=
                paymentAmount;
            }
          }

          let outstandingAmount =
            Number(
              sale.outstandingAmount
            );

          // ==================================================
          // OLD RECORD COMPATIBILITY
          // ==================================================

          if (
            !Number.isFinite(
              outstandingAmount
            )
          ) {

            const oldMode =
              (
                sale.paymentMode ||
                ""
              )
                .toString()
                .trim()
                .toLowerCase();

            outstandingAmount =
              oldMode === "credit"
                ? billAmount
                : 0;
          }

          outstandingAmount =
            Math.max(
              0,
              outstandingAmount
            );


          // ==================================================
          // ONLY OUTSTANDING INCREASES CUSTOMER BALANCE
          // ==================================================

          totalDebit +=
            outstandingAmount;


          const paymentMode =
            (
              sale.paymentMode ||
              "Credit"
            )
              .toString()
              .trim();


          const paymentStatus =
            (
              sale.paymentStatus ||
              (
                outstandingAmount > 0
                  ? "CREDIT"
                  : "PAID"
              )
            )
              .toString()
              .trim()
              .toUpperCase();


          let title =
            `${paymentMode} Sale`;

          if (
            paymentStatus ===
            "PARTIAL"
          ) {
            title =
              "Partial Sale";
          }

          else if (
            paymentStatus ===
            "CREDIT"
          ) {
            title =
              "Credit Sale";
          }


          entries.push({
            id: sale.saleId,

            referenceNo: sale.saleNo,

            date: sale.saleDate,

            type: "SALE",

            title: title,

            amount: billAmount,

       // Net movement created by this sale.
//
// outstanding + advanceUsed
// gives the amount added to customer account.
//
// advanceCreated is customer credit.
debit:
  Number(
    (
      outstandingAmount +
      advanceUsed
    ).toFixed(2)
  ),

credit:
  Number(
    advanceCreated.toFixed(2)
  ),

            // ==================================================
            // BILL INFORMATION
            // ==================================================

            billAmount: billAmount,

            totalQuantity:
              Number(sale.totalQuantity) || 0,

            // ==================================================
            // PAYMENT INFORMATION
            // ==================================================

            paidAmount: paidAmount,
            advanceUsed:
  Number(
    advanceUsed.toFixed(2)
  ),

advanceCreated:
  Number(
    advanceCreated.toFixed(2)
  ),

            outstandingAmount:
              outstandingAmount,

            paymentStatus:
              paymentStatus,

            paymentMode:
              paymentMode,

            payments:
              Array.isArray(sale.payments)
                ? sale.payments
                : [],

            // ==================================================
            // SALESMAN INFORMATION
            // ==================================================

            salesmanId:
              sale.salesmanId || "",

            salesmanName:
              sale.salesmanName ||
              (
                sale.createdRole === "admin"
                  ? "Admin"
                  : ""
              ),

            // ==================================================
            // PRODUCTS
            // ==================================================

            products:
              Array.isArray(sale.products)
                ? sale.products.map((product) => ({
                  productId:
                    product.productId || "",

                  productName:
                    product.productName || "",

                  variant:
                    product.variant || "",

                  unit:
                    product.unit || "",

                  quantity:
                    Number(product.quantity) || 0,

                  rate:
                    Number(product.rate) || 0,

                  amount:
                    Number(product.amount) || 0,
                }))
                : [],

            reference: "",

            affectsBalance:
  outstandingAmount > 0 ||
  advanceCreated > 0 ||
  advanceUsed > 0,
          });
        }

        // ----------------------------------------------
// MANUAL OUTSTANDING = DEBIT
// ----------------------------------------------

for (
  const manualOutstanding of
  manualOutstandingRecords
) {
  const amount =
    Math.max(
      0,
      Number(
        manualOutstanding.amount ||
        0
      )
    );


  totalManualOutstanding +=
    amount;

  totalDebit +=
    amount;


  entries.push({
    id:
      manualOutstanding.adjustmentId,

    referenceNo:
      manualOutstanding.adjustmentNo,

    date:
      manualOutstanding.adjustmentDate,

    type:
      "MANUAL_OUTSTANDING",

    title:
      "Manual Outstanding",

    amount:
      amount,

    debit:
      amount,

    credit:
      0,

    paymentMode:
      "",

    reference:
      manualOutstanding.remarks ||
      "",

    adjustmentId:
      manualOutstanding.adjustmentId,

    adjustmentNo:
      manualOutstanding.adjustmentNo,

    affectsBalance:
      true,
  });
}
        // ----------------------------------------------
        // COLLECTION = CREDIT
        // ----------------------------------------------

        for (
          const collection of
          collections
        ) {
          const amount =
            Number(
              collection.amount
            ) || 0;

          totalCredit +=
            amount;
          // ==================================================
          // COLLECTION PAYMENT MODE BREAKUP
          // ==================================================

          const collectionMode =
            (
              collection.paymentMode ||
              ""
            )
              .toString()
              .trim()
              .toLowerCase();

          if (
            collectionMode === "cash"
          ) {
            totalCash +=
              amount;
          }

          else if (
            collectionMode === "upi" ||
            collectionMode === "phonepe" ||
            collectionMode === "google pay" ||
            collectionMode === "paytm"
          ) {
            totalUpi +=
              amount;
          }

          else if (
            collectionMode === "bank transfer" ||
            collectionMode === "bank"
          ) {
            totalBank +=
              amount;
          }

          else {
            totalOther +=
              amount;
          }
          entries.push({
            id:
              collection.collectionId,

            referenceNo:
              collection.receiptNo,

            date:
              collection.collectionDate,

            type:
              "COLLECTION",

            title:
              "Payment Received",

            amount:
              amount,

            debit:
              0,

            credit:
              amount,

            paymentMode:
              collection.paymentMode || "",

            reference:
              collection.referenceNo || "",

            salesmanId:
              collection.salesmanId || "",

            salesmanName:
              collection.salesmanName || "",

            allocations:
              Array.isArray(collection.allocations)
                ? collection.allocations
                : [],
          });
        }


        // ----------------------------------------------
        // SORT OLD → NEW
        // ----------------------------------------------

        entries.sort(
          (a, b) =>
            new Date(a.date) -
            new Date(b.date)
        );


        // ----------------------------------------------
        // RUNNING BALANCE
        // ----------------------------------------------

        let runningBalance =
          0;

        for (
          const entry of entries
        ) {
          runningBalance +=
            Number(
              entry.debit
            ) || 0;

          runningBalance -=
            Number(
              entry.credit
            ) || 0;

          entry.balance =
            Number(
              runningBalance
                .toFixed(2)
            );
        }


        return res.status(200).json({
          success: true,

          data: {
            type:
              "customer",

            partyId:
              customer.customerId,

            partyName:
              customer.name,

            mobile:
              customer.mobile ||
              "",

            route:
              customer.route ||
              "",

            // ==================================================
            // OLD LEDGER TOTALS
            // KEEP FOR EXISTING FLUTTER COMPATIBILITY
            // ==================================================

            totalDebit:
              Number(
                totalDebit
                  .toFixed(2)
              ),

            totalCredit:
              Number(
                totalCredit
                  .toFixed(2)
              ),


            // ==================================================
            // COMPLETE CUSTOMER SALES SUMMARY
            // ==================================================

            totalSales:
              Number(
                totalSales
                  .toFixed(2)
              ),
totalManualOutstanding:
  Number(
    totalManualOutstanding
      .toFixed(2)
  ),
            totalPaidAtBilling:
              Number(
                totalPaidAtBilling
                  .toFixed(2)
              ),

            totalCollections:
              Number(
                totalCredit
                  .toFixed(2)
              ),

            totalReceived:
              Number(
                (
                  totalPaidAtBilling +
                  totalCredit
                ).toFixed(2)
              ),


            // ==================================================
            // OUTSTANDING
            // ==================================================
// Signed customer account position.
//
// Positive = customer owes money
// Zero     = settled
// Negative = customer has advance
balance:
  Number(
    runningBalance.toFixed(2)
  ),

outstanding:
  Number(
    runningBalance.toFixed(2)
  ),

netOutstanding:
  Number(
    runningBalance.toFixed(2)
  ),

advanceBalance:
  Number(
    currentAdvanceBalance.toFixed(2)
  ),

            // ==================================================
            // PAYMENT MODE BREAKUP
            // ==================================================

            paymentBreakup: {

              cash:
                Number(
                  totalCash
                    .toFixed(2)
                ),

              online:
                Number(
                  totalUpi
                    .toFixed(2)
                ),

              upi:
                Number(
                  totalUpi
                    .toFixed(2)
                ),

              bank:
                Number(
                  totalBank
                    .toFixed(2)
                ),

              other:
                Number(
                  totalOther
                    .toFixed(2)
                ),
            },


            // ==================================================
            // LEDGER ENTRIES
            // ==================================================

            transactions:
              entries.reverse(),
          },
        });
      }


      // ==================================================
      // SUPPLIER LEDGER
      // CREDIT PURCHASES + PAYMENTS
      // ==================================================

      if (!req.access || !req.access.isAdmin) {
        return res.status(403).json({
          success: false,
          message: "Only admin can view supplier ledger.",
        });
      }

      const supplier =
        await Supplier.findOne({
          farmId,

          supplierId:
            partyId,

          isActive:
            true,
        })
          .select(
            "supplierId supplierName mobile"
          )
          .lean();

      if (!supplier) {
        return res.status(404).json({
          success: false,
          message:
            "Supplier not found.",
        });
      }


      // ----------------------------------------------
      // CREDIT PURCHASES
      // ----------------------------------------------

      const purchases =
        await Purchase.find({
          farmId,

          supplierId:
            partyId,

          status:
            "POSTED",

          paymentType: {
            $regex:
              /^Credit$/i,
          },
        })
          .select(
            "purchaseId purchaseNo purchaseDate billDate invoiceNo grandTotal"
          )
          .lean();


      // ----------------------------------------------
      // PAYMENTS
      // ----------------------------------------------

      const payments =
        await Payment.find({
          farmId,

          supplierId:
            partyId,

          status:
            "POSTED",
        })
          .select(
            "paymentId paymentNo paymentDate amount paymentMode referenceNo"
          )
          .lean();


      const entries = [];

      let totalPurchases =
        0;

      let totalPaid =
        0;


      // ----------------------------------------------
      // PURCHASE = PAYABLE
      // ----------------------------------------------

      for (
        const purchase of
        purchases
      ) {
        const amount =
          Number(
            purchase.grandTotal
          ) || 0;

        totalPurchases +=
          amount;

        entries.push({
          id:
            purchase.purchaseId,

          referenceNo:
            purchase.purchaseNo,

          date:
            purchase.purchaseDate,

          type:
            "PURCHASE",

          title:
            "Credit Purchase",

          debit:
            0,

          credit:
            amount,

          paymentMode:
            "",

          reference:
            purchase.invoiceNo ||
            "",
        });
      }


      // ----------------------------------------------
      // PAYMENT = DEBIT / PAID
      // ----------------------------------------------

      for (
        const payment of
        payments
      ) {
        const amount =
          Number(
            payment.amount
          ) || 0;

        totalPaid +=
          amount;

        entries.push({
          id:
            payment.paymentId,

          referenceNo:
            payment.paymentNo,

          date:
            payment.paymentDate,

          type:
            "PAYMENT",

          title:
            "Supplier Payment",

          debit:
            amount,

          credit:
            0,

          paymentMode:
            payment.paymentMode ||
            "",

          reference:
            payment.referenceNo ||
            "",
        });
      }


      // ----------------------------------------------
      // SORT OLD → NEW
      // ----------------------------------------------

      entries.sort(
        (a, b) =>
          new Date(a.date) -
          new Date(b.date)
      );


      // ----------------------------------------------
      // RUNNING SUPPLIER PAYABLE
      // ----------------------------------------------

      let runningBalance =
        0;

      for (
        const entry of entries
      ) {

        runningBalance +=
          Number(
            entry.credit
          ) || 0;

        runningBalance -=
          Number(
            entry.debit
          ) || 0;

        entry.balance =
          Number(
            runningBalance
              .toFixed(2)
          );
      }


      return res.status(200).json({
        success: true,

        data: {
          type:
            "supplier",

          partyId:
            supplier.supplierId,

          partyName:
            supplier.supplierName,

          mobile:
            supplier.mobile ||
            "",

          totalDebit:
            Number(
              totalPaid
                .toFixed(2)
            ),

          totalCredit:
            Number(
              totalPurchases
                .toFixed(2)
            ),

          totalPurchases:
            Number(
              totalPurchases
                .toFixed(2)
            ),

          totalPaid:
            Number(
              totalPaid
                .toFixed(2)
            ),

          balance:
            Number(
              Math.max(
                0,
                totalPurchases -
                totalPaid
              ).toFixed(2)
            ),

          transactions:
            entries.reverse(),
        },
      });

    } catch (error) {

      console.error(
        "GET LEDGER ERROR:",
        error
      );

      return res.status(500).json({
        success: false,

        message:
          "Unable to load ledger.",

        error:
          error.message,
      });
    }
  }
);

// ======================================================
// REPORTS - SALES REPORTS
// ======================================================

app.get(
  "/api/reports/sales",
  authenticateToken,
  loadAccessContext,
  requirePermission("reportsView"),
  async (req, res) => {
    try {

      const farmId =
        req.user.farmId;

      const role =
        (
          req.user.role ||
          ""
        )
          .toString()
          .toLowerCase();

      const userId =
        (
          req.user.userId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      // ==================================================
      // REPORT TYPE
      // ==================================================

      const type =
        (
          req.query.type ||
          ""
        )
          .toString()
          .trim()
          .toLowerCase();


      const allowedTypes = [
        "salesman-wise-sales",
        "customer-wise-sales",
        "route-wise-sales",
        "product-wise-sales",
        "date-wise-sales",
      ];


      if (
        !allowedTypes.includes(type)
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid sales report type.",
        });
      }


      // ==================================================
      // DATE RANGE
      // ==================================================

      const fromText =
        (
          req.query.from ||
          ""
        )
          .toString()
          .trim();

      const toText =
        (
          req.query.to ||
          ""
        )
          .toString()
          .trim();


      let fromDate = null;
      let toDate = null;


      if (fromText) {

        fromDate =
          new Date(
            `${fromText}T00:00:00.000`
          );

        if (
          Number.isNaN(
            fromDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid From date.",
          });
        }
      }


      if (toText) {

        toDate =
          new Date(
            `${toText}T23:59:59.999`
          );

        if (
          Number.isNaN(
            toDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid To date.",
          });
        }
      }


      if (
        fromDate &&
        toDate &&
        toDate < fromDate
      ) {
        return res.status(400).json({
          success: false,
          message:
            "To date must be on or after From date.",
        });
      }


      // ==================================================
      // SALE FILTER
      // ==================================================

      const saleFilter = {
        farmId,
        status:
          "POSTED",
      };


      if (
        fromDate ||
        toDate
      ) {
        saleFilter.saleDate = {};

        if (fromDate) {
          saleFilter.saleDate.$gte =
            fromDate;
        }

        if (toDate) {
          saleFilter.saleDate.$lte =
            toDate;
        }
      }


      // ==================================================
      // SALESMAN LOGIN
      // ONLY HIS OWN SALES
      // ==================================================

      if (
        role === "salesman"
      ) {
        const sid = (req.access && req.access.salesmanId) ? req.access.salesmanId : userId;
        saleFilter.$or = [
          { salesmanId: sid },
          { createdBy: userId },
        ];
      }


      // ==================================================
      // OPTIONAL FILTERS
      // ==================================================

      const salesmanId =
        (
          req.query.salesmanId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      const customerId =
        (
          req.query.customerId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      const route =
        (
          req.query.route ||
          ""
        )
          .toString()
          .trim();

      const productId =
        (
          req.query.productId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      if (
        role !== "salesman" &&
        salesmanId
      ) {
        saleFilter.salesmanId =
          salesmanId;
      }


      if (customerId) {
        saleFilter.customerId =
          customerId;
      }


      if (route) {
        saleFilter.route =
          route;
      }


      if (productId) {
        saleFilter[
          "products.productId"
        ] = productId;
      }


      // ==================================================
      // LOAD SALES
      // ==================================================

      const sales =
        await Sale.find(
          saleFilter
        )
          .sort({
            saleDate: 1,
            createdAt: 1,
          })
          .lean();


      // ==================================================
      // COMMON TOTALS
      // ==================================================

      const totalSales =
        sales.reduce(
          (
            total,
            sale
          ) =>
            total +
            (
              Number(
                sale.grandTotal
              ) || 0
            ),
          0
        );


      const totalQuantity =
        sales.reduce(
          (
            total,
            sale
          ) =>
            total +
            (
              Number(
                sale.totalQuantity
              ) || 0
            ),
          0
        );


      const totalBills =
        sales.length;


      const formatDate =
        (value) => {

          const date =
            new Date(value);

          if (
            Number.isNaN(
              date.getTime()
            )
          ) {
            return "";
          }

          const dd =
            date
              .getDate()
              .toString()
              .padStart(
                2,
                "0"
              );

          const mm =
            (
              date.getMonth() +
              1
            )
              .toString()
              .padStart(
                2,
                "0"
              );

          return (
            `${dd}-${mm}-${date.getFullYear()}`
          );
        };


      const money =
        (value) =>
          `₹${Number(
            value || 0
          ).toFixed(2)}`;


      // ==================================================
      // SALESMAN-WISE SALES
      // ==================================================

      if (
        type ===
        "salesman-wise-sales"
      ) {

        const grouped =
          new Map();


        for (
          const sale of sales
        ) {

          const key =
            sale.salesmanId ||
            "ADMIN";

          if (
            !grouped.has(key)
          ) {
            grouped.set(
              key,
              {
                salesmanId:
                  sale.salesmanId ||
                  "",
                salesman:
                  sale.salesmanName ||
                  (
                    sale.createdRole ===
                      "admin"
                      ? "Admin"
                      : "Unassigned"
                  ),
                bills:
                  0,
                quantity:
                  0,
                sales:
                  0,
              }
            );
          }


          const item =
            grouped.get(key);

          item.bills +=
            1;

          item.quantity +=
            Number(
              sale.totalQuantity
            ) || 0;

          item.sales +=
            Number(
              sale.grandTotal
            ) || 0;
        }


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                b.sales -
                a.sales
            )
            .map(
              item => [
                item.salesmanId,
                item.salesman,
                item.bills,
                item.quantity,
                item.sales,
              ]
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Salesman-wise Sales",

            description:
              "Sales quantity and value for each salesman",

            columns: [
              "Salesman ID",
              "Salesman",
              "Bills",
              "Quantity",
              "Sales",
            ],

            rows,

            metrics: [
              {
                label:
                  "Total Sales",
                value:
                  money(
                    totalSales
                  ),
              },
              {
                label:
                  "Bills",
                value:
                  totalBills
                    .toString(),
              },
              {
                label:
                  "Quantity",
                value:
                  totalQuantity
                    .toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // CUSTOMER-WISE SALES
      // ==================================================

      if (
        type ===
        "customer-wise-sales"
      ) {

        const grouped =
          new Map();


        for (
          const sale of sales
        ) {

          const key =
            sale.customerId;

          if (
            !grouped.has(key)
          ) {
            grouped.set(
              key,
              {
                customerId:
                  sale.customerId ||
                  "",
                customer:
                  sale.customerName ||
                  "",
                route:
                  sale.route ||
                  "",
                bills:
                  0,
                quantity:
                  0,
                sales:
                  0,
              }
            );
          }


          const item =
            grouped.get(key);

          item.bills +=
            1;

          item.quantity +=
            Number(
              sale.totalQuantity
            ) || 0;

          item.sales +=
            Number(
              sale.grandTotal
            ) || 0;
        }


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                b.sales -
                a.sales
            )
            .map(
              item => [
                item.customerId,
                item.customer,
                item.route,
                item.bills,
                item.quantity,
                item.sales,
              ]
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Customer-wise Sales",

            description:
              "Sales history for each customer or outlet",

            columns: [
              "Customer ID",
              "Customer",
              "Route",
              "Bills",
              "Quantity",
              "Sales",
            ],

            rows,

            metrics: [
              {
                label:
                  "Total Sales",
                value:
                  money(
                    totalSales
                  ),
              },
              {
                label:
                  "Customers",
                value:
                  grouped.size
                    .toString(),
              },
              {
                label:
                  "Bills",
                value:
                  totalBills
                    .toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // ROUTE-WISE SALES
      // ==================================================

      if (
        type ===
        "route-wise-sales"
      ) {

        const grouped =
          new Map();


        for (
          const sale of sales
        ) {

          const key =
            sale.route ||
            "No Route";

          if (
            !grouped.has(key)
          ) {
            grouped.set(
              key,
              {
                route:
                  key,
                bills:
                  0,
                quantity:
                  0,
                sales:
                  0,
              }
            );
          }


          const item =
            grouped.get(key);

          item.bills +=
            1;

          item.quantity +=
            Number(
              sale.totalQuantity
            ) || 0;

          item.sales +=
            Number(
              sale.grandTotal
            ) || 0;
        }


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                b.sales -
                a.sales
            )
            .map(
              item => [
                item.route,
                item.bills,
                item.quantity,
                item.sales,
              ]
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Route-wise Sales",

            description:
              "Sales grouped by delivery route",

            columns: [
              "Route",
              "Bills",
              "Quantity",
              "Sales",
            ],

            rows,

            metrics: [
              {
                label:
                  "Total Sales",
                value:
                  money(
                    totalSales
                  ),
              },
              {
                label:
                  "Routes",
                value:
                  grouped.size
                    .toString(),
              },
              {
                label:
                  "Bills",
                value:
                  totalBills
                    .toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // PRODUCT-WISE SALES
      // ==================================================

      if (
        type ===
        "product-wise-sales"
      ) {

        const grouped =
          new Map();


        for (
          const sale of sales
        ) {

          for (
            const product of
            sale.products || []
          ) {

            if (
              productId &&
              (
                product.productId ||
                ""
              )
                .toString()
                .toUpperCase() !==
              productId
            ) {
              continue;
            }


            const key =
              product.productId;


            if (
              !grouped.has(key)
            ) {
              grouped.set(
                key,
                {
                  productId:
                    product.productId ||
                    "",
                  product:
                    product.productName ||
                    "",
                  variant:
                    product.variant ||
                    "",
                  unit:
                    product.unit ||
                    "",
                  quantity:
                    0,
                  sales:
                    0,
                }
              );
            }


            const item =
              grouped.get(key);

            item.quantity +=
              Number(
                product.quantity
              ) || 0;

            item.sales +=
              Number(
                product.amount
              ) || 0;
          }
        }


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                b.sales -
                a.sales
            )
            .map(
              item => [
                item.productId,
                item.product,
                item.variant,
                item.unit,
                item.quantity,
                item.sales,
              ]
            );


        const productSales =
          rows.reduce(
            (
              total,
              row
            ) =>
              total +
              (
                Number(
                  row[5]
                ) || 0
              ),
            0
          );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Product-wise Sales",

            description:
              "Quantity and value sold for each product",

            columns: [
              "Product ID",
              "Product",
              "Variant",
              "Unit",
              "Quantity",
              "Sales",
            ],

            rows,

            metrics: [
              {
                label:
                  "Sales Value",
                value:
                  money(
                    productSales
                  ),
              },
              {
                label:
                  "Products",
                value:
                  grouped.size
                    .toString(),
              },
              {
                label:
                  "Quantity",
                value:
                  totalQuantity
                    .toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // DATE-WISE SALES REGISTER
      // ==================================================

      if (
        type ===
        "date-wise-sales"
      ) {

        const rows =
          sales
            .slice()
            .sort(
              (a, b) =>
                new Date(
                  b.saleDate
                ) -
                new Date(
                  a.saleDate
                )
            )
            .map(
              sale => [
                formatDate(
                  sale.saleDate
                ),

                sale.saleNo ||
                "",

                sale.customerName ||
                "",

                sale.route ||
                "",

                sale.salesmanName ||
                (
                  sale.createdRole ===
                    "admin"
                    ? "Admin"
                    : ""
                ),

                sale.paymentMode ||
                "",

                Number(
                  sale.totalQuantity
                ) || 0,

                Number(
                  sale.grandTotal
                ) || 0,
              ]
            );


        const cashSales =
          sales
            .filter(
              sale =>
                sale.paymentMode ===
                "Cash"
            )
            .reduce(
              (
                total,
                sale
              ) =>
                total +
                (
                  Number(
                    sale.grandTotal
                  ) || 0
                ),
              0
            );


        const creditSales =
          sales
            .filter(
              sale =>
                sale.paymentMode ===
                "Credit"
            )
            .reduce(
              (
                total,
                sale
              ) =>
                total +
                (
                  Number(
                    sale.grandTotal
                  ) || 0
                ),
              0
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Date-wise Sales",

            description:
              "Day-wise sale register and payment mode",

            columns: [
              "Date",
              "Sale No",
              "Customer",
              "Route",
              "Salesman",
              "Payment",
              "Quantity",
              "Amount",
            ],

            rows,

            metrics: [
              {
                label:
                  "Total Sales",
                value:
                  money(
                    totalSales
                  ),
              },
              {
                label:
                  "Cash Sales",
                value:
                  money(
                    cashSales
                  ),
              },
              {
                label:
                  "Credit Sales",
                value:
                  money(
                    creditSales
                  ),
              },
            ],
          },
        });
      }


    } catch (error) {

      console.error(
        "GET SALES REPORT ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load sales report.",
        error:
          error.message,
      });
    }
  }
);
// ======================================================
// REPORTS - PURCHASE REPORTS
// ======================================================

app.get(
  "/api/reports/purchase",
  authenticateToken,
  loadAccessContext,
  requirePermission("reportsView"),
  async (req, res) => {
    try {

      const farmId =
        req.user.farmId;

      const type =
        (
          req.query.type ||
          ""
        )
          .toString()
          .trim()
          .toLowerCase();


      // ==================================================
      // ALLOWED REPORTS
      // ==================================================

      const allowedTypes = [
        "purchase-register",
        "supplier-wise-purchase",
        "product-wise-purchase",
        "purchase-payment-due",
      ];


      if (
        !allowedTypes.includes(type)
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid purchase report type.",
        });
      }


      // ==================================================
      // DATE RANGE
      // ==================================================

      const fromText =
        (
          req.query.from ||
          ""
        )
          .toString()
          .trim();

      const toText =
        (
          req.query.to ||
          ""
        )
          .toString()
          .trim();


      let fromDate = null;
      let toDate = null;


      if (fromText) {

        fromDate =
          new Date(
            `${fromText}T00:00:00.000`
          );

        if (
          Number.isNaN(
            fromDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid From date.",
          });
        }
      }


      if (toText) {

        toDate =
          new Date(
            `${toText}T23:59:59.999`
          );

        if (
          Number.isNaN(
            toDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid To date.",
          });
        }
      }


      if (
        fromDate &&
        toDate &&
        toDate < fromDate
      ) {
        return res.status(400).json({
          success: false,
          message:
            "To date must be on or after From date.",
        });
      }


      // ==================================================
      // COMMON HELPERS
      // ==================================================

      const formatDate =
        (value) => {

          if (!value) {
            return "";
          }

          const date =
            new Date(value);

          if (
            Number.isNaN(
              date.getTime()
            )
          ) {
            return "";
          }

          const dd =
            date
              .getDate()
              .toString()
              .padStart(
                2,
                "0"
              );

          const mm =
            (
              date.getMonth() +
              1
            )
              .toString()
              .padStart(
                2,
                "0"
              );

          return (
            `${dd}-${mm}-${date.getFullYear()}`
          );
        };


      const money =
        (value) =>
          `₹${Number(
            value || 0
          ).toFixed(2)}`;


      // ==================================================
      // PURCHASE PAYMENT DUE
      //
      // IMPORTANT:
      // This report is a CURRENT supplier liability report.
      //
      // It uses:
      // ALL POSTED CREDIT PURCHASES
      // -
      // ALL POSTED SUPPLIER PAYMENTS
      //
      // Therefore date range is NOT used to calculate
      // current outstanding.
      // ==================================================

      if (
        type ===
        "purchase-payment-due"
      ) {

        const suppliers =
          await Supplier.find({
            farmId,
            isActive: true,
          })
            .select(
              "supplierId supplierName mobile"
            )
            .sort({
              supplierName: 1,
            })
            .lean();


        const creditPurchases =
          await Purchase.find({
            farmId,
            status: "POSTED",

            paymentType: {
              $regex:
                /^Credit$/i,
            },
          })
            .select(
              "supplierId supplierName grandTotal dueDate"
            )
            .lean();


        const payments =
          await Payment.find({
            farmId,
            status: "POSTED",
          })
            .select(
              "supplierId amount"
            )
            .lean();


        // ----------------------------------------------
        // PURCHASE TOTAL BY SUPPLIER
        // ----------------------------------------------

        const purchaseMap =
          new Map();

        const dueDateMap =
          new Map();


        for (
          const purchase of
          creditPurchases
        ) {

          const supplierId =
            (
              purchase.supplierId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (!supplierId) {
            continue;
          }


          const oldAmount =
            purchaseMap.get(
              supplierId
            ) || 0;


          purchaseMap.set(
            supplierId,
            oldAmount +
            (
              Number(
                purchase.grandTotal
              ) || 0
            )
          );


          if (purchase.dueDate) {

            const currentDueDate =
              dueDateMap.get(
                supplierId
              );

            const purchaseDueDate =
              new Date(
                purchase.dueDate
              );


            if (
              !currentDueDate ||
              purchaseDueDate <
              currentDueDate
            ) {
              dueDateMap.set(
                supplierId,
                purchaseDueDate
              );
            }
          }
        }


        // ----------------------------------------------
        // PAYMENT TOTAL BY SUPPLIER
        // ----------------------------------------------

        const paymentMap =
          new Map();


        for (
          const payment of
          payments
        ) {

          const supplierId =
            (
              payment.supplierId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (!supplierId) {
            continue;
          }


          const oldAmount =
            paymentMap.get(
              supplierId
            ) || 0;


          paymentMap.set(
            supplierId,
            oldAmount +
            (
              Number(
                payment.amount
              ) || 0
            )
          );
        }


        // ----------------------------------------------
        // BUILD OUTSTANDING
        // ----------------------------------------------

        const rows = [];

        let totalCreditPurchase =
          0;

        let totalPaid =
          0;

        let totalOutstanding =
          0;


        for (
          const supplier of
          suppliers
        ) {

          const supplierId =
            (
              supplier.supplierId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          const purchaseAmount =
            purchaseMap.get(
              supplierId
            ) || 0;

          const paidAmount =
            paymentMap.get(
              supplierId
            ) || 0;

          const outstanding =
            Math.max(
              0,
              purchaseAmount -
              paidAmount
            );


          if (
            outstanding <= 0
          ) {
            continue;
          }


          totalCreditPurchase +=
            purchaseAmount;

          totalPaid +=
            paidAmount;

          totalOutstanding +=
            outstanding;


          rows.push([
            supplier.supplierId ||
            "",

            supplier.supplierName ||
            "",

            supplier.mobile ||
            "",

            purchaseAmount,

            paidAmount,

            outstanding,

            formatDate(
              dueDateMap.get(
                supplierId
              )
            ),
          ]);
        }


        rows.sort(
          (a, b) =>
            Number(b[5]) -
            Number(a[5])
        );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Purchase Payment Due",

            description:
              "Outstanding supplier payments against credit purchases",

            columns: [
              "Supplier ID",
              "Supplier",
              "Mobile",
              "Credit Purchase",
              "Paid",
              "Balance Due",
              "Due Date",
            ],

            rows,

            metrics: [
              {
                label:
                  "Credit Purchases",

                value:
                  money(
                    totalCreditPurchase
                  ),
              },

              {
                label:
                  "Paid",

                value:
                  money(
                    totalPaid
                  ),
              },

              {
                label:
                  "Balance Due",

                value:
                  money(
                    totalOutstanding
                  ),
              },
            ],
          },
        });
      }


      // ==================================================
      // PURCHASE FILTER
      // ==================================================

      const purchaseFilter = {
        farmId,
        status:
          "POSTED",
      };


      if (
        fromDate ||
        toDate
      ) {

        purchaseFilter.purchaseDate =
          {};

        if (fromDate) {
          purchaseFilter
            .purchaseDate
            .$gte =
            fromDate;
        }

        if (toDate) {
          purchaseFilter
            .purchaseDate
            .$lte =
            toDate;
        }
      }


      // ==================================================
      // OPTIONAL FILTERS
      // ==================================================

      const supplierId =
        (
          req.query.supplierId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      const productId =
        (
          req.query.productId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      if (supplierId) {
        purchaseFilter.supplierId =
          supplierId;
      }


      if (productId) {
        purchaseFilter[
          "products.productId"
        ] = productId;
      }


      // ==================================================
      // LOAD PURCHASES
      // ==================================================

      const purchases =
        await Purchase.find(
          purchaseFilter
        )
          .sort({
            purchaseDate: 1,
            createdAt: 1,
          })
          .lean();


      // ==================================================
      // COMMON TOTALS
      // ==================================================

      const totalPurchases =
        purchases.reduce(
          (
            total,
            purchase
          ) =>
            total +
            (
              Number(
                purchase.grandTotal
              ) || 0
            ),
          0
        );


      const totalQuantity =
        purchases.reduce(
          (
            total,
            purchase
          ) =>
            total +
            (
              Number(
                purchase.totalQuantity
              ) || 0
            ),
          0
        );


      const totalBills =
        purchases.length;


      // ==================================================
      // PURCHASE REGISTER
      // ==================================================

      if (
        type ===
        "purchase-register"
      ) {

        const rows =
          purchases
            .slice()
            .sort(
              (a, b) =>
                new Date(
                  b.purchaseDate
                ) -
                new Date(
                  a.purchaseDate
                )
            )
            .map(
              purchase => [

                formatDate(
                  purchase.purchaseDate
                ),

                purchase.purchaseNo ||
                "",

                purchase.supplierName ||
                "",

                purchase.invoiceNo ||
                "",

                formatDate(
                  purchase.billDate
                ),

                purchase.paymentType ||
                "",

                Number(
                  purchase.totalQuantity
                ) || 0,

                Number(
                  purchase.grandTotal
                ) || 0,
              ]
            );


        const cashPurchases =
          purchases
            .filter(
              purchase =>
                (
                  purchase.paymentType ||
                  ""
                )
                  .toString()
                  .toLowerCase() ===
                "cash"
            )
            .reduce(
              (
                total,
                purchase
              ) =>
                total +
                (
                  Number(
                    purchase.grandTotal
                  ) || 0
                ),
              0
            );


        const creditPurchases =
          purchases
            .filter(
              purchase =>
                (
                  purchase.paymentType ||
                  ""
                )
                  .toString()
                  .toLowerCase() ===
                "credit"
            )
            .reduce(
              (
                total,
                purchase
              ) =>
                total +
                (
                  Number(
                    purchase.grandTotal
                  ) || 0
                ),
              0
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Purchase Register",

            description:
              "Complete purchase register with supplier and payment details",

            columns: [
              "Date",
              "Purchase No",
              "Supplier",
              "Invoice No",
              "Bill Date",
              "Payment",
              "Quantity",
              "Amount",
            ],

            rows,

            metrics: [
              {
                label:
                  "Total Purchase",

                value:
                  money(
                    totalPurchases
                  ),
              },

              {
                label:
                  "Cash Purchase",

                value:
                  money(
                    cashPurchases
                  ),
              },

              {
                label:
                  "Credit Purchase",

                value:
                  money(
                    creditPurchases
                  ),
              },
            ],
          },
        });
      }


      // ==================================================
      // SUPPLIER-WISE PURCHASE
      // ==================================================

      if (
        type ===
        "supplier-wise-purchase"
      ) {

        const grouped =
          new Map();


        for (
          const purchase of
          purchases
        ) {

          const key =
            purchase.supplierId ||
            purchase.supplierName ||
            "UNKNOWN";


          if (
            !grouped.has(key)
          ) {

            grouped.set(
              key,
              {
                supplierId:
                  purchase.supplierId ||
                  "",

                supplier:
                  purchase.supplierName ||
                  "",

                bills:
                  0,

                quantity:
                  0,

                purchase:
                  0,
              }
            );
          }


          const item =
            grouped.get(key);


          item.bills +=
            1;


          item.quantity +=
            Number(
              purchase.totalQuantity
            ) || 0;


          item.purchase +=
            Number(
              purchase.grandTotal
            ) || 0;
        }


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                b.purchase -
                a.purchase
            )
            .map(
              item => [
                item.supplierId,
                item.supplier,
                item.bills,
                item.quantity,
                item.purchase,
              ]
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Supplier-wise Purchase",

            description:
              "Purchase quantity and value grouped by supplier",

            columns: [
              "Supplier ID",
              "Supplier",
              "Bills",
              "Quantity",
              "Purchase",
            ],

            rows,

            metrics: [
              {
                label:
                  "Total Purchase",

                value:
                  money(
                    totalPurchases
                  ),
              },

              {
                label:
                  "Suppliers",

                value:
                  grouped.size
                    .toString(),
              },

              {
                label:
                  "Bills",

                value:
                  totalBills
                    .toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // PRODUCT-WISE PURCHASE
      // ==================================================

      if (
        type ===
        "product-wise-purchase"
      ) {

        const grouped =
          new Map();


        for (
          const purchase of
          purchases
        ) {

          for (
            const product of
            purchase.products || []
          ) {

            if (
              productId &&
              (
                product.productId ||
                ""
              )
                .toString()
                .trim()
                .toUpperCase() !==
              productId
            ) {
              continue;
            }


            const key =
              product.productId ||
              product.productName ||
              "UNKNOWN";


            if (
              !grouped.has(key)
            ) {

              grouped.set(
                key,
                {
                  productId:
                    product.productId ||
                    "",

                  product:
                    product.productName ||
                    "",

                  variant:
                    product.variant ||
                    "",

                  unit:
                    product.unit ||
                    "",

                  quantity:
                    0,

                  purchase:
                    0,
                }
              );
            }


            const item =
              grouped.get(key);


            item.quantity +=
              Number(
                product.quantity
              ) || 0;


            item.purchase +=
              Number(
                product.amount
              ) || 0;
          }
        }


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                b.purchase -
                a.purchase
            )
            .map(
              item => [
                item.productId,
                item.product,
                item.variant,
                item.unit,
                item.quantity,
                item.purchase,
              ]
            );


        const productPurchase =
          rows.reduce(
            (
              total,
              row
            ) =>
              total +
              (
                Number(
                  row[5]
                ) || 0
              ),
            0
          );


        const productQuantity =
          rows.reduce(
            (
              total,
              row
            ) =>
              total +
              (
                Number(
                  row[4]
                ) || 0
              ),
            0
          );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Product-wise Purchase",

            description:
              "Quantity and purchase value for each product",

            columns: [
              "Product ID",
              "Product",
              "Variant",
              "Unit",
              "Quantity",
              "Purchase",
            ],

            rows,

            metrics: [
              {
                label:
                  "Purchase Value",

                value:
                  money(
                    productPurchase
                  ),
              },

              {
                label:
                  "Products",

                value:
                  grouped.size
                    .toString(),
              },

              {
                label:
                  "Quantity",

                value:
                  productQuantity
                    .toString(),
              },
            ],
          },
        });
      }


    } catch (error) {

      console.error(
        "GET PURCHASE REPORT ERROR:",
        error
      );

      return res.status(500).json({
        success: false,

        message:
          "Unable to load purchase report.",

        error:
          error.message,
      });
    }
  }
);
// ======================================================
// REPORTS - STOCK REPORTS
// ======================================================

app.get(
  "/api/reports/stock",
  authenticateToken,
  loadAccessContext,
  requirePermission("reportsView"),
  async (req, res) => {
    try {

      const farmId =
        req.user.farmId;


      // ==================================================
      // REPORT TYPE
      // ==================================================

      const type =
        (
          req.query.type ||
          ""
        )
          .toString()
          .trim()
          .toLowerCase();


      const allowedTypes = [
        "current-stock",
        "low-stock",
        "stock-movement",
        "product-wise-stock",
      ];


      if (
        !allowedTypes.includes(type)
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid stock report type.",
        });
      }


      // ==================================================
      // OPTIONAL PRODUCT FILTER
      // ==================================================

      const productId =
        (
          req.query.productId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      // ==================================================
      // DATE RANGE
      // USED BY STOCK MOVEMENT
      // ==================================================

      const fromText =
        (
          req.query.from ||
          ""
        )
          .toString()
          .trim();

      const toText =
        (
          req.query.to ||
          ""
        )
          .toString()
          .trim();


      let fromDate = null;
      let toDate = null;


      if (fromText) {

        fromDate =
          new Date(
            `${fromText}T00:00:00.000`
          );

        if (
          Number.isNaN(
            fromDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid From date.",
          });
        }
      }


      if (toText) {

        toDate =
          new Date(
            `${toText}T23:59:59.999`
          );

        if (
          Number.isNaN(
            toDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid To date.",
          });
        }
      }


      if (
        fromDate &&
        toDate &&
        toDate < fromDate
      ) {
        return res.status(400).json({
          success: false,
          message:
            "To date must be on or after From date.",
        });
      }


      // ==================================================
      // HELPERS
      // ==================================================

      const money =
        (value) =>
          `₹${Number(
            value || 0
          ).toFixed(2)}`;


      const formatDate =
        (value) => {

          if (!value) {
            return "";
          }

          const date =
            new Date(value);


          if (
            Number.isNaN(
              date.getTime()
            )
          ) {
            return "";
          }


          const dd =
            date
              .getDate()
              .toString()
              .padStart(
                2,
                "0"
              );


          const mm =
            (
              date.getMonth() +
              1
            )
              .toString()
              .padStart(
                2,
                "0"
              );


          return (
            `${dd}-${mm}-${date.getFullYear()}`
          );
        };


      // ==================================================
      // CURRENT STOCK
      // MAS_PRODUCT IS CURRENT MAIN GODOWN STOCK
      // ==================================================

      if (
        type ===
        "current-stock"
      ) {

        const filter = {
          farmId,
          isActive: true,
        };


        if (productId) {
          filter.productId =
            productId;
        }


        const products =
          await Product.find(
            filter
          )
            .select(
              "productId productName variant category unit stock price lowStockLevel"
            )
            .sort({
              productName: 1,
              variant: 1,
            })
            .lean();


        let totalQuantity =
          0;

        let totalStockValue =
          0;


        const rows =
          products.map(
            product => {

              const stock =
                Number(
                  product.stock
                ) || 0;

              const rate =
                Number(
                  product.price
                ) || 0;

              const stockValue =
                stock * rate;


              totalQuantity +=
                stock;

              totalStockValue +=
                stockValue;


              return [
                product.productId ||
                "",

                product.productName ||
                "",

                product.variant ||
                "",

                product.unit ||
                "",

                stock,

                rate,

                Number(
                  stockValue.toFixed(2)
                ),
              ];
            }
          );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Current Stock",

            description:
              "Available quantity for every product",

            columns: [
              "Product ID",
              "Product",
              "Variant",
              "Unit",
              "Stock",
              "Rate",
              "Stock Value",
            ],

            rows,

            metrics: [
              {
                label:
                  "Products",

                value:
                  products.length
                    .toString(),
              },

              {
                label:
                  "Stock Quantity",

                value:
                  totalQuantity
                    .toString(),
              },

              {
                label:
                  "Stock Value",

                value:
                  money(
                    totalStockValue
                  ),
              },
            ],
          },
        });
      }


      // ==================================================
      // LOW STOCK
      // CURRENT STOCK <= LOW STOCK LEVEL
      // ==================================================

      if (
        type ===
        "low-stock"
      ) {

        const filter = {
          farmId,
          isActive: true,
        };


        if (productId) {
          filter.productId =
            productId;
        }


        const products =
          await Product.find(
            filter
          )
            .select(
              "productId productName variant unit stock price lowStockLevel"
            )
            .sort({
              productName: 1,
            })
            .lean();


        const lowStockProducts =
          products.filter(
            product => {

              const stock =
                Number(
                  product.stock
                ) || 0;

              const minimum =
                Number(
                  product.lowStockLevel
                ) || 0;


              return (
                stock <= minimum
              );
            }
          );


        let totalShortage =
          0;


        const rows =
          lowStockProducts.map(
            product => {

              const stock =
                Number(
                  product.stock
                ) || 0;

              const minimum =
                Number(
                  product.lowStockLevel
                ) || 0;

              const shortage =
                Math.max(
                  0,
                  minimum -
                  stock
                );


              totalShortage +=
                shortage;


              let status =
                "LOW";


              if (stock <= 0) {
                status =
                  "OUT OF STOCK";
              }


              return [
                product.productId ||
                "",

                product.productName ||
                "",

                product.variant ||
                "",

                product.unit ||
                "",

                stock,

                minimum,

                shortage,

                status,
              ];
            }
          );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Low Stock",

            description:
              "Products that need to be purchased soon",

            columns: [
              "Product ID",
              "Product",
              "Variant",
              "Unit",
              "Current Stock",
              "Minimum Stock",
              "Shortage",
              "Status",
            ],

            rows,

            metrics: [
              {
                label:
                  "Low Stock Products",

                value:
                  lowStockProducts.length
                    .toString(),
              },

              {
                label:
                  "Total Shortage",

                value:
                  totalShortage
                    .toString(),
              },

              {
                label:
                  "Out Of Stock",

                value:
                  lowStockProducts
                    .filter(
                      product =>
                        (
                          Number(product.stock) || 0
                        ) <= 0
                    )
                    .length
                    .toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // STOCK MOVEMENT
      //
      // OPENING
      // +
      // QUANTITY IN
      // -
      // QUANTITY OUT
      // =
      // CLOSING
      // ==================================================

      if (
        type ===
        "stock-movement"
      ) {

        // ----------------------------------------------
        // PRODUCT MASTER
        // ----------------------------------------------

        const productFilter = {
          farmId,
          isActive: true,
        };


        if (productId) {
          productFilter.productId =
            productId;
        }


        const products =
          await Product.find(
            productFilter
          )
            .select(
              "productId productName variant unit"
            )
            .sort({
              productName: 1,
            })
            .lean();


        // ----------------------------------------------
        // TRANSACTIONS BEFORE FROM DATE
        // USED FOR OPENING BALANCE
        // ----------------------------------------------

        const beforeFilter = {
          farmId,
        };


        if (productId) {
          beforeFilter.productId =
            productId;
        }


        if (fromDate) {
          beforeFilter.createdAt = {
            $lt:
              fromDate,
          };
        }


        let beforeTransactions =
          [];


        if (fromDate) {

          beforeTransactions =
            await StockTransaction.find(
              beforeFilter
            )
              .select(
                "productId quantityIn quantityOut"
              )
              .lean();
        }


        // ----------------------------------------------
        // SELECTED PERIOD TRANSACTIONS
        // ----------------------------------------------

        const movementFilter = {
          farmId,
        };


        if (productId) {
          movementFilter.productId =
            productId;
        }


        if (
          fromDate ||
          toDate
        ) {

          movementFilter.createdAt =
            {};


          if (fromDate) {
            movementFilter
              .createdAt
              .$gte =
              fromDate;
          }


          if (toDate) {
            movementFilter
              .createdAt
              .$lte =
              toDate;
          }
        }


        const transactions =
          await StockTransaction.find(
            movementFilter
          )
            .select(
              "productId productName transactionType quantityIn quantityOut rate referenceNo godown createdAt"
            )
            .sort({
              createdAt: 1,
            })
            .lean();


        // ----------------------------------------------
        // OPENING MAP
        // ----------------------------------------------

        const openingMap =
          new Map();


        for (
          const transaction of
          beforeTransactions
        ) {

          const key =
            (
              transaction.productId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          const oldOpening =
            openingMap.get(
              key
            ) || 0;


          openingMap.set(
            key,
            oldOpening +
            (
              Number(
                transaction.quantityIn
              ) || 0
            ) -
            (
              Number(
                transaction.quantityOut
              ) || 0
            )
          );
        }


        // ----------------------------------------------
        // MOVEMENT MAP
        // ----------------------------------------------

        const movementMap =
          new Map();


        for (
          const product of
          products
        ) {

          const key =
            (
              product.productId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          movementMap.set(
            key,
            {
              productId:
                product.productId ||
                "",

              product:
                product.productName ||
                "",

              variant:
                product.variant ||
                "",

              unit:
                product.unit ||
                "",

              opening:
                openingMap.get(
                  key
                ) || 0,

              purchase:
                0,

              purchaseReturn:
                0,

              sale:
                0,

              salesReturn:
                0,

              allocationOut:
                0,

              allocationReturn:
                0,

              adjustmentIn:
                0,

              adjustmentOut:
                0,

              totalIn:
                0,

              totalOut:
                0,
            }
          );
        }


        // ----------------------------------------------
        // CLASSIFY MOVEMENT
        // ----------------------------------------------

        for (
          const transaction of
          transactions
        ) {

          const key =
            (
              transaction.productId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (
            !movementMap.has(key)
          ) {
            continue;
          }


          const item =
            movementMap.get(
              key
            );


          const quantityIn =
            Number(
              transaction.quantityIn
            ) || 0;


          const quantityOut =
            Number(
              transaction.quantityOut
            ) || 0;


          item.totalIn +=
            quantityIn;

          item.totalOut +=
            quantityOut;


          switch (
          transaction.transactionType
          ) {

            case "PURCHASE":

              item.purchase +=
                quantityIn;

              break;


            case "PURCHASE_CANCEL":
            case "PURCHASE_RETURN":

              item.purchaseReturn +=
                quantityOut;

              break;


            case "SALE":

              item.sale +=
                quantityOut;

              break;


            case "SALE_CANCEL":
            case "SALES_RETURN":

              item.salesReturn +=
                quantityIn;

              break;


            case "ALLOCATION_OUT":

              item.allocationOut +=
                quantityOut;

              break;


            case "ALLOCATION_RETURN":

              item.allocationReturn +=
                quantityIn;

              break;


            case "ADJUSTMENT_IN":
            case "OPENING":

              item.adjustmentIn +=
                quantityIn;

              break;


            case "ADJUSTMENT_OUT":

              item.adjustmentOut +=
                quantityOut;

              break;
          }
        }


        let totalOpening =
          0;

        let totalInward =
          0;

        let totalOutward =
          0;

        let totalClosing =
          0;


        const rows =
          Array
            .from(
              movementMap.values()
            )
            .map(
              item => {

                const closing =
                  item.opening +
                  item.totalIn -
                  item.totalOut;


                totalOpening +=
                  item.opening;

                totalInward +=
                  item.totalIn;

                totalOutward +=
                  item.totalOut;

                totalClosing +=
                  closing;


                return [
                  item.productId,
                  item.product,
                  item.variant,
                  item.unit,
                  item.opening,
                  item.purchase,
                  item.purchaseReturn,
                  item.sale,
                  item.salesReturn,
                  item.allocationOut,
                  item.allocationReturn,
                  item.totalIn,
                  item.totalOut,
                  closing,
                ];
              }
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Stock Movement",

            description:
              "Opening, inward, sales, returns and closing stock",

            columns: [
              "Product ID",
              "Product",
              "Variant",
              "Unit",
              "Opening",
              "Purchase",
              "Purchase Return",
              "Sales",
              "Sales Return",
              "Allocation Out",
              "Allocation Return",
              "Total In",
              "Total Out",
              "Closing",
            ],

            rows,

            metrics: [
              {
                label:
                  "Opening",

                value:
                  totalOpening
                    .toString(),
              },

              {
                label:
                  "Inward",

                value:
                  totalInward
                    .toString(),
              },

              {
                label:
                  "Outward",

                value:
                  totalOutward
                    .toString(),
              },

              {
                label:
                  "Closing",

                value:
                  totalClosing
                    .toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // PRODUCT-WISE STOCK
      // CURRENT PRODUCT MASTER STOCK
      // ==================================================

      if (
        type ===
        "product-wise-stock"
      ) {

        const filter = {
          farmId,
          isActive: true,
        };


        if (productId) {
          filter.productId =
            productId;
        }


        const products =
          await Product.find(
            filter
          )
            .select(
              "productId productName variant category unit stock price lowStockLevel"
            )
            .sort({
              productName: 1,
              variant: 1,
            })
            .lean();


        let totalStock =
          0;

        let totalValue =
          0;


        const rows =
          products.map(
            product => {

              const stock =
                Number(
                  product.stock
                ) || 0;


              const rate =
                Number(
                  product.price
                ) || 0;


              const value =
                stock * rate;


              totalStock +=
                stock;

              totalValue +=
                value;


              return [
                product.productId ||
                "",

                product.productName ||
                "",

                product.variant ||
                "",

                product.category ||
                "",

                product.unit ||
                "",

                stock,

                rate,

                Number(
                  value.toFixed(2)
                ),
              ];
            }
          );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Product-wise Stock",

            description:
              "Stock grouped by product and variant",

            columns: [
              "Product ID",
              "Product",
              "Variant",
              "Category",
              "Unit",
              "Stock",
              "Rate",
              "Value",
            ],

            rows,

            metrics: [
              {
                label:
                  "Products",

                value:
                  products.length
                    .toString(),
              },

              {
                label:
                  "Stock",

                value:
                  totalStock
                    .toString(),
              },

              {
                label:
                  "Stock Value",

                value:
                  money(
                    totalValue
                  ),
              },
            ],
          },
        });
      }


    } catch (error) {

      console.error(
        "GET STOCK REPORT ERROR:",
        error
      );


      return res.status(500).json({
        success: false,

        message:
          "Unable to load stock report.",

        error:
          error.message,
      });
    }
  }
);
// ======================================================
// REPORTS - OUTSTANDING REPORTS
// ======================================================

app.get(
  "/api/reports/outstanding",
  authenticateToken,
  loadAccessContext,
  requirePermission("reportsView"),
  async (req, res) => {
    try {

      const farmId =
        req.user.farmId;

      const role =
        (
          req.user.role ||
          ""
        )
          .toString()
          .trim()
          .toLowerCase();


      // ==================================================
      // REPORT TYPE
      // ==================================================

      const type =
        (
          req.query.type ||
          ""
        )
          .toString()
          .trim()
          .toLowerCase();


      const allowedTypes = [
        "salesman-wise-outstanding",
        "customer-wise-outstanding",
        "route-wise-outstanding",
        "outstanding-ageing",
      ];


      if (
        !allowedTypes.includes(type)
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid outstanding report type.",
        });
      }


      // ==================================================
      // ROLE
      // ==================================================

      let currentSalesman =
        null;


      if (
        role === "salesman"
      ) {

        currentSalesman =
          await Salesman.findOne({
            _id:
              req.user.userId,

            farmId:
              farmId,

            isActive:
              true,
          })
            .select(
              "salesmanId name"
            )
            .lean();


        if (!currentSalesman) {
          return res.status(404).json({
            success: false,
            message:
              "Salesman account not found.",
          });
        }
      }


      else if (
        role !== "admin"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "You are not allowed to view outstanding reports.",
        });
      }


      // ==================================================
      // OPTIONAL FILTERS
      // ==================================================

      const customerId =
        (
          req.query.customerId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      const salesmanId =
        (
          req.query.salesmanId ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();


      const route =
        (
          req.query.route ||
          ""
        )
          .toString()
          .trim();


      // ==================================================
      // CREDIT SALE FILTER
      // ==================================================

      const saleFilter = {

        farmId:
          farmId,

        status:
          "POSTED",

        paymentMode:
          "Credit",
      };


      // Salesman can only see his own data
      if (
        role === "salesman"
      ) {

        saleFilter.salesmanId =
          currentSalesman.salesmanId;

        saleFilter.createdRole =
          "salesman";
      }


      // Admin optional salesman filter
      else if (salesmanId) {

        saleFilter.salesmanId =
          salesmanId;
      }


      if (customerId) {
        saleFilter.customerId =
          customerId;
      }


      if (route) {
        saleFilter.route =
          route;
      }


      // ==================================================
      // LOAD CREDIT SALES
      // ==================================================

      const creditSales =
        await Sale.find(
          saleFilter
        )
          .select(
            "saleId saleNo saleDate customerId customerName customerMobile route salesmanId salesmanName grandTotal createdRole"
          )
          .sort({
            saleDate: 1,
            createdAt: 1,
          })
          .lean();


      // ==================================================
      // COLLECTION FILTER
      // ==================================================

      const collectionFilter = {

        farmId:
          farmId,

        status:
          "POSTED",
      };


      if (
        role === "salesman"
      ) {

        collectionFilter.salesmanId =
          currentSalesman.salesmanId;
      }


      else if (salesmanId) {

        collectionFilter.salesmanId =
          salesmanId;
      }


      if (customerId) {
        collectionFilter.customerId =
          customerId;
      }


      if (route) {
        collectionFilter.route =
          route;
      }


      // ==================================================
      // LOAD COLLECTIONS
      // ==================================================

      const collections =
        await Collection.find(
          collectionFilter
        )
          .select(
            "collectionId collectionDate customerId customerName route salesmanId salesmanName amount"
          )
          .sort({
            collectionDate: 1,
            createdAt: 1,
          })
          .lean();


      // ==================================================
      // MONEY
      // ==================================================

      const money =
        (value) =>
          `₹${Number(
            value || 0
          ).toFixed(2)}`;


      // ==================================================
      // CUSTOMER COLLECTION TOTAL
      // ==================================================

      const customerCollectionMap =
        new Map();


      for (
        const collection of
        collections
      ) {

        const key =
          (
            collection.customerId ||
            ""
          )
            .toString()
            .trim()
            .toUpperCase();


        if (!key) {
          continue;
        }


        const oldAmount =
          customerCollectionMap.get(
            key
          ) || 0;


        customerCollectionMap.set(
          key,
          oldAmount +
          (
            Number(
              collection.amount
            ) || 0
          )
        );
      }


      // ==================================================
      // CUSTOMER SALES MAP
      //
      // USED FOR:
      // CUSTOMER OUTSTANDING
      // ROUTE OUTSTANDING
      // SALESMAN OUTSTANDING
      // AGEING FIFO
      // ==================================================

      const customerSalesMap =
        new Map();


      for (
        const sale of
        creditSales
      ) {

        const key =
          (
            sale.customerId ||
            ""
          )
            .toString()
            .trim()
            .toUpperCase();


        if (!key) {
          continue;
        }


        if (
          !customerSalesMap.has(key)
        ) {

          customerSalesMap.set(
            key,
            {
              customerId:
                sale.customerId ||
                "",

              customerName:
                sale.customerName ||
                "",

              mobile:
                sale.customerMobile ||
                "",

              route:
                sale.route ||
                "",

              salesmanId:
                sale.salesmanId ||
                "",

              salesmanName:
                sale.salesmanName ||
                (
                  sale.createdRole ===
                    "admin"
                    ? "Admin"
                    : ""
                ),

              totalCreditSales:
                0,

              collected:
                0,

              outstanding:
                0,

              bills:
                [],
            }
          );
        }


        const customer =
          customerSalesMap.get(
            key
          );


        const amount =
          Number(
            sale.grandTotal
          ) || 0;


        customer.totalCreditSales +=
          amount;


        customer.bills.push({
          saleId:
            sale.saleId ||
            "",

          saleNo:
            sale.saleNo ||
            "",

          saleDate:
            sale.saleDate,

          amount:
            amount,

          remaining:
            amount,
        });
      }


      // ==================================================
      // CALCULATE CUSTOMER OUTSTANDING
      //
      // COLLECTIONS ARE APPLIED FIFO
      // AGAINST OLDEST CREDIT SALES.
      // ==================================================

      for (
        const [
          key,
          customer
        ] of customerSalesMap
      ) {

        const collected =
          customerCollectionMap.get(
            key
          ) || 0;


        customer.collected =
          collected;


        let collectionRemaining =
          collected;


        // ----------------------------------------------
        // FIFO BILL SETTLEMENT
        // ----------------------------------------------

        for (
          const bill of
          customer.bills
        ) {

          if (
            collectionRemaining <= 0
          ) {
            break;
          }


          const adjusted =
            Math.min(
              bill.remaining,
              collectionRemaining
            );


          bill.remaining -=
            adjusted;


          collectionRemaining -=
            adjusted;
        }


        customer.outstanding =
          Math.max(
            0,
            customer.totalCreditSales -
            collected
          );
      }


      // ==================================================
      // REMOVE ZERO OUTSTANDING
      // ==================================================

      const outstandingCustomers =
        Array
          .from(
            customerSalesMap.values()
          )
          .filter(
            customer =>
              customer.outstanding >
              0.001
          );


      const totalCreditSales =
        outstandingCustomers.reduce(
          (
            total,
            customer
          ) =>
            total +
            (
              Number(
                customer.totalCreditSales
              ) || 0
            ),
          0
        );


      const totalCollected =
        outstandingCustomers.reduce(
          (
            total,
            customer
          ) =>
            total +
            (
              Number(
                customer.collected
              ) || 0
            ),
          0
        );


      const totalOutstanding =
        outstandingCustomers.reduce(
          (
            total,
            customer
          ) =>
            total +
            (
              Number(
                customer.outstanding
              ) || 0
            ),
          0
        );


      // ==================================================
      // CUSTOMER / OUTLET-WISE OUTSTANDING
      // ==================================================

      if (
        type ===
        "customer-wise-outstanding"
      ) {

        const rows =
          outstandingCustomers
            .slice()
            .sort(
              (a, b) =>
                b.outstanding -
                a.outstanding
            )
            .map(
              customer => [

                customer.customerId,

                customer.customerName,

                customer.route,

                customer.salesmanName,

                customer.totalCreditSales,

                customer.collected,

                customer.outstanding,
              ]
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Customer / Outlet-wise Outstanding",

            description:
              "Pending amount for every customer or outlet",

            columns: [
              "Customer ID",
              "Customer",
              "Route",
              "Salesman",
              "Credit Sales",
              "Collected",
              "Outstanding",
            ],

            rows,

            metrics: [
              {
                label:
                  "Outstanding",

                value:
                  money(
                    totalOutstanding
                  ),
              },

              {
                label:
                  "Customers",

                value:
                  outstandingCustomers
                    .length
                    .toString(),
              },

              {
                label:
                  "Collected",

                value:
                  money(
                    totalCollected
                  ),
              },
            ],
          },
        });
      }


      // ==================================================
      // ROUTE-WISE OUTSTANDING
      // ==================================================

      if (
        type ===
        "route-wise-outstanding"
      ) {

        const grouped =
          new Map();


        for (
          const customer of
          outstandingCustomers
        ) {

          const key =
            customer.route ||
            "No Route";


          if (
            !grouped.has(key)
          ) {

            grouped.set(
              key,
              {
                route:
                  key,

                customers:
                  0,

                creditSales:
                  0,

                collected:
                  0,

                outstanding:
                  0,
              }
            );
          }


          const item =
            grouped.get(
              key
            );


          item.customers +=
            1;


          item.creditSales +=
            Number(
              customer.totalCreditSales
            ) || 0;


          item.collected +=
            Number(
              customer.collected
            ) || 0;


          item.outstanding +=
            Number(
              customer.outstanding
            ) || 0;
        }


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                b.outstanding -
                a.outstanding
            )
            .map(
              item => [
                item.route,
                item.customers,
                item.creditSales,
                item.collected,
                item.outstanding,
              ]
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Route-wise Outstanding",

            description:
              "Pending amount grouped by route",

            columns: [
              "Route",
              "Customers",
              "Credit Sales",
              "Collected",
              "Outstanding",
            ],

            rows,

            metrics: [
              {
                label:
                  "Outstanding",

                value:
                  money(
                    totalOutstanding
                  ),
              },

              {
                label:
                  "Routes",

                value:
                  grouped.size
                    .toString(),
              },

              {
                label:
                  "Customers",

                value:
                  outstandingCustomers
                    .length
                    .toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // SALESMAN-WISE OUTSTANDING
      // ==================================================

      if (
        type ===
        "salesman-wise-outstanding"
      ) {

        const grouped =
          new Map();


        for (
          const customer of
          outstandingCustomers
        ) {

          const key =
            customer.salesmanId ||
            "ADMIN";


          if (
            !grouped.has(key)
          ) {

            grouped.set(
              key,
              {
                salesmanId:
                  customer.salesmanId ||
                  "",

                salesman:
                  customer.salesmanName ||
                  "Admin",

                customers:
                  0,

                creditSales:
                  0,

                collected:
                  0,

                outstanding:
                  0,
              }
            );
          }


          const item =
            grouped.get(
              key
            );


          item.customers +=
            1;


          item.creditSales +=
            Number(
              customer.totalCreditSales
            ) || 0;


          item.collected +=
            Number(
              customer.collected
            ) || 0;


          item.outstanding +=
            Number(
              customer.outstanding
            ) || 0;
        }


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                b.outstanding -
                a.outstanding
            )
            .map(
              item => [
                item.salesmanId,
                item.salesman,
                item.customers,
                item.creditSales,
                item.collected,
                item.outstanding,
              ]
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Salesman-wise Outstanding",

            description:
              "Pending amount handled by each salesman",

            columns: [
              "Salesman ID",
              "Salesman",
              "Customers",
              "Credit Sales",
              "Collected",
              "Outstanding",
            ],

            rows,

            metrics: [
              {
                label:
                  "Outstanding",

                value:
                  money(
                    totalOutstanding
                  ),
              },

              {
                label:
                  "Salesmen",

                value:
                  grouped.size
                    .toString(),
              },

              {
                label:
                  "Customers",

                value:
                  outstandingCustomers
                    .length
                    .toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // OUTSTANDING AGEING
      //
      // CURRENT     = 0 - 7 DAYS
      // 8 - 15 DAYS
      // 16 - 30 DAYS
      // ABOVE 30 DAYS
      //
      // CUSTOMER COLLECTIONS ARE APPLIED FIFO FIRST.
      // ==================================================

      if (
        type ===
        "outstanding-ageing"
      ) {

        const today =
          new Date();

        today.setHours(
          23,
          59,
          59,
          999
        );


        let currentAmount =
          0;

        let sevenToFifteen =
          0;

        let sixteenToThirty =
          0;

        let aboveThirty =
          0;


        const rows = [];


        for (
          const customer of
          outstandingCustomers
        ) {

          let current =
            0;

          let bucket8to15 =
            0;

          let bucket16to30 =
            0;

          let bucket30plus =
            0;


          for (
            const bill of
            customer.bills
          ) {

            const remaining =
              Number(
                bill.remaining
              ) || 0;


            if (
              remaining <= 0.001
            ) {
              continue;
            }


            const billDate =
              new Date(
                bill.saleDate
              );


            if (
              Number.isNaN(
                billDate.getTime()
              )
            ) {
              continue;
            }


            const diffMs =
              today.getTime() -
              billDate.getTime();


            const ageDays =
              Math.max(
                0,
                Math.floor(
                  diffMs /
                  (
                    1000 *
                    60 *
                    60 *
                    24
                  )
                )
              );


            if (
              ageDays <= 7
            ) {

              current +=
                remaining;
            }

            else if (
              ageDays <= 15
            ) {

              bucket8to15 +=
                remaining;
            }

            else if (
              ageDays <= 30
            ) {

              bucket16to30 +=
                remaining;
            }

            else {

              bucket30plus +=
                remaining;
            }
          }


          const customerOutstanding =
            current +
            bucket8to15 +
            bucket16to30 +
            bucket30plus;


          if (
            customerOutstanding <=
            0.001
          ) {
            continue;
          }


          currentAmount +=
            current;

          sevenToFifteen +=
            bucket8to15;

          sixteenToThirty +=
            bucket16to30;

          aboveThirty +=
            bucket30plus;


          rows.push([
            customer.customerId,
            customer.customerName,
            customer.route,
            customer.salesmanName,
            Number(
              current.toFixed(2)
            ),
            Number(
              bucket8to15
                .toFixed(2)
            ),
            Number(
              bucket16to30
                .toFixed(2)
            ),
            Number(
              bucket30plus
                .toFixed(2)
            ),
            Number(
              customerOutstanding
                .toFixed(2)
            ),
          ]);
        }


        rows.sort(
          (a, b) =>
            Number(b[8]) -
            Number(a[8])
        );


        const ageingOutstanding =
          currentAmount +
          sevenToFifteen +
          sixteenToThirty +
          aboveThirty;


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Outstanding Ageing",

            description:
              "Current, 7-day, 15-day and 30-day pending amounts",

            columns: [
              "Customer ID",
              "Customer",
              "Route",
              "Salesman",
              "0-7 Days",
              "8-15 Days",
              "16-30 Days",
              "Above 30 Days",
              "Outstanding",
            ],

            rows,

            metrics: [
              {
                label:
                  "Outstanding",

                value:
                  money(
                    ageingOutstanding
                  ),
              },

              {
                label:
                  "0-7 Days",

                value:
                  money(
                    currentAmount
                  ),
              },

              {
                label:
                  "Above 30 Days",

                value:
                  money(
                    aboveThirty
                  ),
              },
            ],
          },
        });
      }


    } catch (error) {

      console.error(
        "GET OUTSTANDING REPORT ERROR:",
        error
      );


      return res.status(500).json({
        success: false,

        message:
          "Unable to load outstanding report.",

        error:
          error.message,
      });
    }
  }
);
// ======================================================
// REPORTS - SALES & PURCHASE TRENDS
// ======================================================

app.get(
  "/api/reports/trends",
  authenticateToken,
  loadAccessContext,
  requirePermission("reportsView"),
  async (req, res) => {
    try {

      const farmId =
        req.user.farmId;

      const role =
        (
          req.user.role ||
          ""
        )
          .toString()
          .trim()
          .toLowerCase();


      // ==================================================
      // REPORT TYPE
      // ==================================================

      const type =
        (
          req.query.type ||
          ""
        )
          .toString()
          .trim()
          .toLowerCase();


      const allowedTypes = [
        "sales-trend",
        "purchase-trend",
        "sales-vs-purchase",
        "product-trend",
      ];


      if (
        !allowedTypes.includes(type)
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid trend report type.",
        });
      }


      // ==================================================
      // DATE RANGE
      // ==================================================

      const fromText =
        (
          req.query.from ||
          ""
        )
          .toString()
          .trim();

      const toText =
        (
          req.query.to ||
          ""
        )
          .toString()
          .trim();


      let fromDate = null;
      let toDate = null;


      if (fromText) {

        fromDate =
          new Date(
            `${fromText}T00:00:00.000`
          );

        if (
          Number.isNaN(
            fromDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid From date.",
          });
        }
      }


      if (toText) {

        toDate =
          new Date(
            `${toText}T23:59:59.999`
          );

        if (
          Number.isNaN(
            toDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid To date.",
          });
        }
      }


      if (
        fromDate &&
        toDate &&
        toDate < fromDate
      ) {
        return res.status(400).json({
          success: false,
          message:
            "To date must be on or after From date.",
        });
      }


      // ==================================================
      // HELPERS
      // ==================================================

      const money =
        (value) =>
          `₹${Number(
            value || 0
          ).toFixed(2)}`;


      const dateKey =
        (value) => {

          const date =
            new Date(value);

          if (
            Number.isNaN(
              date.getTime()
            )
          ) {
            return "";
          }

          const year =
            date.getFullYear();

          const month =
            (
              date.getMonth() +
              1
            )
              .toString()
              .padStart(
                2,
                "0"
              );

          const day =
            date
              .getDate()
              .toString()
              .padStart(
                2,
                "0"
              );

          return (
            `${year}-${month}-${day}`
          );
        };


      const displayDate =
        (key) => {

          if (!key) {
            return "";
          }

          const parts =
            key.split("-");

          if (
            parts.length !== 3
          ) {
            return key;
          }

          return (
            `${parts[2]}-${parts[1]}-${parts[0]}`
          );
        };


      // ==================================================
      // SALES FILTER
      // ==================================================

      const saleFilter = {

        farmId:
          farmId,

        status:
          "POSTED",
      };


      if (
        fromDate ||
        toDate
      ) {

        saleFilter.saleDate =
          {};

        if (fromDate) {
          saleFilter
            .saleDate
            .$gte =
            fromDate;
        }

        if (toDate) {
          saleFilter
            .saleDate
            .$lte =
            toDate;
        }
      }


      // ==================================================
      // SALESMAN LOGIN
      // ==================================================

      if (
        role === "salesman"
      ) {

        const salesman =
          await Salesman.findOne({
            _id:
              req.user.userId,

            farmId:
              farmId,

            isActive:
              true,
          })
            .select(
              "salesmanId"
            )
            .lean();


        if (!salesman) {
          return res.status(404).json({
            success: false,
            message:
              "Salesman account not found.",
          });
        }


        saleFilter.salesmanId =
          salesman.salesmanId;

        saleFilter.createdRole =
          "salesman";
      }


      else if (
        role !== "admin"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "You are not allowed to view trend reports.",
        });
      }


      // ==================================================
      // PURCHASE FILTER
      // ==================================================

      const purchaseFilter = {

        farmId:
          farmId,

        status:
          "POSTED",
      };


      if (
        fromDate ||
        toDate
      ) {

        purchaseFilter.purchaseDate =
          {};

        if (fromDate) {
          purchaseFilter
            .purchaseDate
            .$gte =
            fromDate;
        }

        if (toDate) {
          purchaseFilter
            .purchaseDate
            .$lte =
            toDate;
        }
      }


      // ==================================================
      // LOAD SALES
      // ==================================================

      const sales =
        await Sale.find(
          saleFilter
        )
          .select(
            "saleDate grandTotal totalQuantity products"
          )
          .sort({
            saleDate: 1,
          })
          .lean();


      // ==================================================
      // LOAD PURCHASES
      //
      // PURCHASE TREND REMAINS FARM-WIDE.
      // SALESMAN LOGIN DOES NOT OWN PURCHASES.
      // ==================================================

      const purchases =
        await Purchase.find(
          purchaseFilter
        )
          .select(
            "purchaseDate grandTotal totalQuantity products"
          )
          .sort({
            purchaseDate: 1,
          })
          .lean();


      // ==================================================
      // SALES TREND
      // DAY-WISE
      // ==================================================

      if (
        type ===
        "sales-trend"
      ) {

        const grouped =
          new Map();


        for (
          const sale of
          sales
        ) {

          const key =
            dateKey(
              sale.saleDate
            );


          if (!key) {
            continue;
          }


          if (
            !grouped.has(key)
          ) {

            grouped.set(
              key,
              {
                date:
                  key,

                bills:
                  0,

                quantity:
                  0,

                amount:
                  0,
              }
            );
          }


          const item =
            grouped.get(
              key
            );


          item.bills +=
            1;


          item.quantity +=
            Number(
              sale.totalQuantity
            ) || 0;


          item.amount +=
            Number(
              sale.grandTotal
            ) || 0;
        }


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                a.date.localeCompare(
                  b.date
                )
            )
            .map(
              item => [
                displayDate(
                  item.date
                ),
                item.bills,
                item.quantity,
                Number(
                  item.amount
                    .toFixed(2)
                ),
              ]
            );


        const totalSales =
          sales.reduce(
            (
              total,
              sale
            ) =>
              total +
              (
                Number(
                  sale.grandTotal
                ) || 0
              ),
            0
          );


        const totalQuantity =
          sales.reduce(
            (
              total,
              sale
            ) =>
              total +
              (
                Number(
                  sale.totalQuantity
                ) || 0
              ),
            0
          );


        const average =
          rows.length > 0
            ? totalSales /
            rows.length
            : 0;


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Sales Trend",

            description:
              "Daily sales value and quantity trend",

            columns: [
              "Date",
              "Bills",
              "Quantity",
              "Sales",
            ],

            rows,

            metrics: [
              {
                label:
                  "Total Sales",

                value:
                  money(
                    totalSales
                  ),
              },

              {
                label:
                  "Quantity",

                value:
                  totalQuantity
                    .toString(),
              },

              {
                label:
                  "Daily Average",

                value:
                  money(
                    average
                  ),
              },
            ],
          },
        });
      }


      // ==================================================
      // PURCHASE TREND
      // DAY-WISE
      // ==================================================

      if (
        type ===
        "purchase-trend"
      ) {

        const grouped =
          new Map();


        for (
          const purchase of
          purchases
        ) {

          const key =
            dateKey(
              purchase.purchaseDate
            );


          if (!key) {
            continue;
          }


          if (
            !grouped.has(key)
          ) {

            grouped.set(
              key,
              {
                date:
                  key,

                bills:
                  0,

                quantity:
                  0,

                amount:
                  0,
              }
            );
          }


          const item =
            grouped.get(
              key
            );


          item.bills +=
            1;


          item.quantity +=
            Number(
              purchase.totalQuantity
            ) || 0;


          item.amount +=
            Number(
              purchase.grandTotal
            ) || 0;
        }


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                a.date.localeCompare(
                  b.date
                )
            )
            .map(
              item => [
                displayDate(
                  item.date
                ),
                item.bills,
                item.quantity,
                Number(
                  item.amount
                    .toFixed(2)
                ),
              ]
            );


        const totalPurchase =
          purchases.reduce(
            (
              total,
              purchase
            ) =>
              total +
              (
                Number(
                  purchase.grandTotal
                ) || 0
              ),
            0
          );


        const totalQuantity =
          purchases.reduce(
            (
              total,
              purchase
            ) =>
              total +
              (
                Number(
                  purchase.totalQuantity
                ) || 0
              ),
            0
          );


        const average =
          rows.length > 0
            ? totalPurchase /
            rows.length
            : 0;


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Purchase Trend",

            description:
              "Daily purchase value and quantity trend",

            columns: [
              "Date",
              "Bills",
              "Quantity",
              "Purchase",
            ],

            rows,

            metrics: [
              {
                label:
                  "Total Purchase",

                value:
                  money(
                    totalPurchase
                  ),
              },

              {
                label:
                  "Quantity",

                value:
                  totalQuantity
                    .toString(),
              },

              {
                label:
                  "Daily Average",

                value:
                  money(
                    average
                  ),
              },
            ],
          },
        });
      }


      // ==================================================
      // SALES VS PURCHASE
      // ==================================================

      if (
        type ===
        "sales-vs-purchase"
      ) {

        const grouped =
          new Map();


        const ensureDate =
          (key) => {

            if (
              !grouped.has(key)
            ) {

              grouped.set(
                key,
                {
                  date:
                    key,

                  sales:
                    0,

                  purchase:
                    0,
                }
              );
            }

            return grouped.get(
              key
            );
          };


        for (
          const sale of
          sales
        ) {

          const key =
            dateKey(
              sale.saleDate
            );


          if (!key) {
            continue;
          }


          const item =
            ensureDate(
              key
            );


          item.sales +=
            Number(
              sale.grandTotal
            ) || 0;
        }


        for (
          const purchase of
          purchases
        ) {

          const key =
            dateKey(
              purchase.purchaseDate
            );


          if (!key) {
            continue;
          }


          const item =
            ensureDate(
              key
            );


          item.purchase +=
            Number(
              purchase.grandTotal
            ) || 0;
        }


        let totalSales =
          0;

        let totalPurchase =
          0;


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                a.date.localeCompare(
                  b.date
                )
            )
            .map(
              item => {

                totalSales +=
                  item.sales;

                totalPurchase +=
                  item.purchase;


                return [
                  displayDate(
                    item.date
                  ),

                  Number(
                    item.sales
                      .toFixed(2)
                  ),

                  Number(
                    item.purchase
                      .toFixed(2)
                  ),

                  Number(
                    (
                      item.sales -
                      item.purchase
                    ).toFixed(2)
                  ),
                ];
              }
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Sales vs Purchase",

            description:
              "Compare sales and purchase value for selected period",

            columns: [
              "Date",
              "Sales",
              "Purchase",
              "Difference",
            ],

            rows,

            metrics: [
              {
                label:
                  "Sales",

                value:
                  money(
                    totalSales
                  ),
              },

              {
                label:
                  "Purchase",

                value:
                  money(
                    totalPurchase
                  ),
              },

              {
                label:
                  "Difference",

                value:
                  money(
                    totalSales -
                    totalPurchase
                  ),
              },
            ],
          },
        });
      }


      // ==================================================
      // PRODUCT TREND
      //
      // SALES QTY / VALUE
      // PURCHASE QTY / VALUE
      // ==================================================

      if (
        type ===
        "product-trend"
      ) {

        const grouped =
          new Map();


        const ensureProduct =
          (
            product
          ) => {

            const key =
              (
                product.productId ||
                product.productName ||
                "UNKNOWN"
              )
                .toString()
                .trim()
                .toUpperCase();


            if (
              !grouped.has(key)
            ) {

              grouped.set(
                key,
                {
                  productId:
                    product.productId ||
                    "",

                  product:
                    product.productName ||
                    "",

                  variant:
                    product.variant ||
                    "",

                  unit:
                    product.unit ||
                    "",

                  saleQty:
                    0,

                  saleValue:
                    0,

                  purchaseQty:
                    0,

                  purchaseValue:
                    0,
                }
              );
            }


            return grouped.get(
              key
            );
          };


        // ----------------------------------------------
        // SALES
        // ----------------------------------------------

        for (
          const sale of
          sales
        ) {

          for (
            const product of
            sale.products || []
          ) {

            const item =
              ensureProduct(
                product
              );


            item.saleQty +=
              Number(
                product.quantity
              ) || 0;


            item.saleValue +=
              Number(
                product.amount
              ) || 0;
          }
        }


        // ----------------------------------------------
        // PURCHASE
        // ----------------------------------------------

        for (
          const purchase of
          purchases
        ) {

          for (
            const product of
            purchase.products || []
          ) {

            const item =
              ensureProduct(
                product
              );


            item.purchaseQty +=
              Number(
                product.quantity
              ) || 0;


            item.purchaseValue +=
              Number(
                product.amount
              ) || 0;
          }
        }


        let totalSaleValue =
          0;

        let totalPurchaseValue =
          0;


        const rows =
          Array
            .from(
              grouped.values()
            )
            .sort(
              (a, b) =>
                b.saleValue -
                a.saleValue
            )
            .map(
              item => {

                totalSaleValue +=
                  item.saleValue;

                totalPurchaseValue +=
                  item.purchaseValue;


                const difference =
                  item.saleValue -
                  item.purchaseValue;


                return [
                  item.productId,
                  item.product,
                  item.variant,
                  item.unit,
                  item.purchaseQty,
                  Number(
                    item.purchaseValue
                      .toFixed(2)
                  ),
                  item.saleQty,
                  Number(
                    item.saleValue
                      .toFixed(2)
                  ),
                  Number(
                    difference
                      .toFixed(2)
                  ),
                ];
              }
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Product Trend",

            description:
              "Product-wise purchase and sales movement",

            columns: [
              "Product ID",
              "Product",
              "Variant",
              "Unit",
              "Purchase Qty",
              "Purchase Value",
              "Sales Qty",
              "Sales Value",
              "Difference",
            ],

            rows,

            metrics: [
              {
                label:
                  "Products",

                value:
                  grouped.size
                    .toString(),
              },

              {
                label:
                  "Sales",

                value:
                  money(
                    totalSaleValue
                  ),
              },

              {
                label:
                  "Purchase",

                value:
                  money(
                    totalPurchaseValue
                  ),
              },
            ],
          },
        });
      }


    } catch (error) {

      console.error(
        "GET TREND REPORT ERROR:",
        error
      );


      return res.status(500).json({
        success: false,

        message:
          "Unable to load trend report.",

        error:
          error.message,
      });
    }
  }
);
// ======================================================
// EXPENSES
// TRN_EXPENSE
// ======================================================


// ======================================================
// GET EXPENSES
// ======================================================

app.get(
  "/api/expenses",
  authenticateToken,
  loadAccessContext,
  requirePermission("expensesView"),
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const filter = {
        farmId,
      };

      const status =
        (
          req.query.status ||
          ""
        )
          .toString()
          .trim()
          .toUpperCase();

      if (
        [
          "POSTED",
          "CANCELLED",
        ].includes(status)
      ) {
        filter.status =
          status;
      }

      const expenses =
        await Expense.find(
          filter
        )
          .sort({
            expenseDate: -1,
            createdAt: -1,
          })
          .lean();

      return res.status(200).json({
        success: true,
        count:
          expenses.length,
        data:
          expenses,
      });

    } catch (error) {
      console.error(
        "GET EXPENSES ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load expenses.",
        error:
          error.message,
      });
    }
  }
);


// ======================================================
// ADD EXPENSE
// ======================================================

app.post(
  "/api/expenses",
  authenticateToken,
  loadAccessContext,
  requirePermission("expensesView"),
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const userId =
        req.user.userId || "";

      const role =
        req.user.role || "";

      const {
        expenseDate,
        category,
        amount,
        paymentMode,
        note,
      } = req.body;


      // ==================================================
      // VALIDATION
      // ==================================================

      const allowedCategories = [
        "Fuel",
        "Vehicle",
        "Loading",
        "Food",
        "Other",
      ];

      const allowedPaymentModes = [
        "Cash",
        "UPI",
        "Bank",
      ];

      const finalCategory =
        (
          category ||
          ""
        )
          .toString()
          .trim();

      const finalPaymentMode =
        (
          paymentMode ||
          ""
        )
          .toString()
          .trim();

      const finalAmount =
        Number(amount);


      if (
        !allowedCategories.includes(
          finalCategory
        )
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Please select a valid expense category.",
        });
      }


      if (
        !Number.isFinite(
          finalAmount
        ) ||
        finalAmount <= 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Enter a valid expense amount.",
        });
      }


      if (
        !allowedPaymentModes.includes(
          finalPaymentMode
        )
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Please select a valid payment mode.",
        });
      }


      let finalExpenseDate =
        new Date();

      if (expenseDate) {
        finalExpenseDate =
          new Date(
            expenseDate
          );

        if (
          Number.isNaN(
            finalExpenseDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid expense date.",
          });
        }
      }


      // ==================================================
      // GENERATE NUMBER
      // ==================================================

      const expenseId =
        await generateExpenseId();

      const expenseNo =
        await generateExpenseNo(
          farmId
        );


      // ==================================================
      // SAVE
      // ==================================================

      const expense =
        await Expense.create({
          farmId,

          expenseId,

          expenseNo,

          expenseDate:
            finalExpenseDate,

          category:
            finalCategory,

          amount:
            finalAmount,

          paymentMode:
            finalPaymentMode,

          note:
            (
              note ||
              ""
            )
              .toString()
              .trim(),

          status:
            "POSTED",

          createdBy:
            userId,

          createdRole:
            role,
        });


      return res.status(201).json({
        success: true,

        message:
          "Expense added successfully.",

        data:
          expense,
      });

    } catch (error) {
      console.error(
        "ADD EXPENSE ERROR:",
        error
      );

      return res.status(500).json({
        success: false,

        message:
          error.code === 11000
            ? "Expense number already exists. Please try again."
            : "Unable to save expense.",

        error:
          error.message,
      });
    }
  }
);


// ======================================================
// CANCEL EXPENSE
// ======================================================

app.put(
  "/api/expenses/:id/cancel",
  authenticateToken,
  loadAccessContext,
  requirePermission("expensesView"),
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const userId =
        req.user.userId || "";

      const expenseIdentifier =
        req.params.id
          .toString()
          .trim();

      const conditions = [
        {
          expenseId:
            expenseIdentifier
              .toUpperCase(),
        },

        {
          expenseNo:
            expenseIdentifier,
        },
      ];


      if (
        mongoose.Types.ObjectId
          .isValid(
            expenseIdentifier
          )
      ) {
        conditions.push({
          _id:
            expenseIdentifier,
        });
      }


      const expense =
        await Expense.findOne({
          farmId,

          $or:
            conditions,
        });


      if (!expense) {
        return res.status(404).json({
          success: false,
          message:
            "Expense not found.",
        });
      }


      if (
        expense.status ===
        "CANCELLED"
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Expense is already cancelled.",
        });
      }


      expense.status =
        "CANCELLED";

      expense.cancelledBy =
        userId;

      expense.cancelledAt =
        new Date();

      expense.updatedAt =
        new Date();


      await expense.save();


      return res.status(200).json({
        success: true,

        message:
          "Expense cancelled successfully.",

        data:
          expense,
      });

    } catch (error) {
      console.error(
        "CANCEL EXPENSE ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to cancel expense.",
        error:
          error.message,
      });
    }
  }
);

// ======================================================
// REPORTS - OPERATIONS
//
// TYPES:
// collection-report
// allocation-report
// return-report
// expense-report
// ======================================================

app.get(
  "/api/reports/operations",
  authenticateToken,
  loadAccessContext,
  requirePermission("reportsView"),
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      const role =
        req.user.role;

      const type =
        (
          req.query.type ||
          ""
        )
          .toString()
          .trim()
          .toLowerCase();


      // ==================================================
      // VALID REPORT TYPES
      // ==================================================

      const validTypes = [
        "collection-report",
        "allocation-report",
        "return-report",
        "expense-report",
      ];


      if (
        !validTypes.includes(
          type
        )
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid operational report type.",
        });
      }


      // ==================================================
      // DATE RANGE
      // ==================================================

      let fromDate = null;
      let toDate = null;


      if (req.query.from) {
        fromDate =
          new Date(
            `${req.query.from}T00:00:00.000`
          );

        if (
          Number.isNaN(
            fromDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid from date.",
          });
        }
      }


      if (req.query.to) {
        toDate =
          new Date(
            `${req.query.to}T23:59:59.999`
          );

        if (
          Number.isNaN(
            toDate.getTime()
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Invalid to date.",
          });
        }
      }


      if (
        fromDate &&
        toDate &&
        fromDate > toDate
      ) {
        return res.status(400).json({
          success: false,
          message:
            "From date cannot be greater than to date.",
        });
      }


      // ==================================================
      // HELPERS
      // ==================================================

      const money = value =>
        `₹${Number(
          value || 0
        ).toFixed(2)}`;


      const displayDate = value => {
        if (!value) {
          return "";
        }

        const date =
          new Date(value);

        if (
          Number.isNaN(
            date.getTime()
          )
        ) {
          return "";
        }

        const day =
          String(
            date.getDate()
          ).padStart(
            2,
            "0"
          );

        const month =
          String(
            date.getMonth() + 1
          ).padStart(
            2,
            "0"
          );

        const year =
          date.getFullYear();

        return `${day}-${month}-${year}`;
      };


      const addDateFilter = (
        filter,
        fieldName
      ) => {
        if (
          !fromDate &&
          !toDate
        ) {
          return;
        }

        filter[fieldName] = {};

        if (fromDate) {
          filter[fieldName].$gte =
            fromDate;
        }

        if (toDate) {
          filter[fieldName].$lte =
            toDate;
        }
      };


      // ==================================================
      // CURRENT SALESMAN
      //
      // SALESMAN MUST SEE ONLY HIS OWN OPERATIONAL DATA.
      // ==================================================

      let currentSalesman = null;


      if (
        role === "salesman"
      ) {
        currentSalesman =
          await Salesman.findOne({
            _id:
              req.user.userId,

            farmId,

            isActive:
              true,
          })
            .select(
              "salesmanId name"
            )
            .lean();


        if (!currentSalesman) {
          return res.status(403).json({
            success: false,
            message:
              "Salesman account not found.",
          });
        }
      } else if (
        role !== "admin"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "You are not allowed to view this report.",
        });
      }


      // ==================================================
      // 1. COLLECTION REPORT
      // ==================================================

      if (
        type ===
        "collection-report"
      ) {
        const filter = {
          farmId,
          status:
            "POSTED",
        };


        addDateFilter(
          filter,
          "collectionDate"
        );


        if (
          currentSalesman
        ) {
          filter.salesmanId =
            currentSalesman
              .salesmanId;
        }


        const collections =
          await Collection.find(
            filter
          )
            .sort({
              collectionDate: -1,
              createdAt: -1,
            })
            .select(
              [
                "receiptNo",
                "collectionDate",
                "customerId",
                "customerName",
                "route",
                "salesmanId",
                "salesmanName",
                "amount",
                "paymentMode",
                "referenceNo",
                "remarks",
              ].join(" ")
            )
            .lean();


        let totalCollection =
          0;

        const modeTotals = {};


        const rows =
          collections.map(
            item => {
              const amount =
                Number(
                  item.amount
                ) || 0;

              totalCollection +=
                amount;

              const mode =
                item.paymentMode ||
                "Other";

              modeTotals[mode] =
                (
                  modeTotals[mode] ||
                  0
                ) + amount;


              return [
                displayDate(
                  item.collectionDate
                ),

                item.receiptNo ||
                "",

                item.customerId ||
                "",

                item.customerName ||
                "",

                item.route ||
                "",

                item.salesmanName ||
                "",

                item.paymentMode ||
                "",

                Number(
                  amount.toFixed(2)
                ),

                item.referenceNo ||
                "",

                item.remarks ||
                "",
              ];
            }
          );


        const cashTotal =
          Number(
            modeTotals.Cash ||
            0
          );

        const digitalTotal =
          Object.entries(
            modeTotals
          )
            .filter(
              ([mode]) =>
                mode !== "Cash"
            )
            .reduce(
              (
                sum,
                [, amount]
              ) =>
                sum +
                Number(
                  amount || 0
                ),
              0
            );


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Collection Report",

            description:
              "Customer collections received during the selected period",

            columns: [
              "Date",
              "Receipt No",
              "Customer ID",
              "Customer",
              "Route",
              "Salesman",
              "Payment Mode",
              "Amount",
              "Reference No",
              "Remarks",
            ],

            rows,

            metrics: [
              {
                label:
                  "Receipts",

                value:
                  collections.length
                    .toString(),
              },

              {
                label:
                  "Total Collection",

                value:
                  money(
                    totalCollection
                  ),
              },

              {
                label:
                  "Cash",

                value:
                  money(
                    cashTotal
                  ),
              },

              {
                label:
                  "Digital / Bank",

                value:
                  money(
                    digitalTotal
                  ),
              },
            ],
          },
        });
      }


      // ==================================================
      // 2. ALLOCATION REPORT
      // ==================================================

      if (
        type ===
        "allocation-report"
      ) {
        const filter = {
          farmId,

          status: {
            $in: [
              "POSTED",
              "RETURNED",
            ],
          },
        };


        addDateFilter(
          filter,
          "allocationDate"
        );


        if (
          currentSalesman
        ) {
          filter.salesmanId =
            currentSalesman
              .salesmanId;
        }


        const allocations =
          await Allocation.find(
            filter
          )
            .sort({
              allocationDate: -1,
              createdAt: -1,
            })
            .select(
              [
                "allocationId",
                "allocationNo",
                "allocationDate",
                "salesmanId",
                "salesmanName",
                "routeId",
                "routeName",
                "customerId",
                "customerName",
                "products",
                "totalQuantity",
                "status",
              ].join(" ")
            )
            .lean();


        let totalAllocated =
          0;

        let totalReturned =
          0;


        const rows = [];


        for (
          const allocation of
          allocations
        ) {
          for (
            const product of
            allocation.products || []
          ) {
            const allocated =
              Number(
                product.quantity
              ) || 0;

            const returned =
              Number(
                product
                  .returnedQuantity
              ) || 0;

            totalAllocated +=
              allocated;

            totalReturned +=
              returned;


            rows.push([
              displayDate(
                allocation
                  .allocationDate
              ),

              allocation
                .allocationNo ||
              "",

              allocation
                .salesmanName ||
              "",

              allocation
                .routeName ||
              "",

              allocation
                .customerName ||
              "",

              product.productId ||
              "",

              product.productName ||
              "",

              product.variant ||
              "",

              product.unit ||
              "",

              allocated,

              returned,

              Math.max(
                0,
                allocated -
                returned
              ),

              allocation.status ||
              "",
            ]);
          }
        }


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Allocation Report",

            description:
              "Salesman product allocations during the selected period",

            columns: [
              "Date",
              "Allocation No",
              "Salesman",
              "Route",
              "Customer",
              "Product ID",
              "Product",
              "Variant",
              "Unit",
              "Allocated Qty",
              "Returned Qty",
              "Net Qty",
              "Status",
            ],

            rows,

            metrics: [
              {
                label:
                  "Allocations",

                value:
                  allocations.length
                    .toString(),
              },

              {
                label:
                  "Allocated Qty",

                value:
                  totalAllocated
                    .toString(),
              },

              {
                label:
                  "Returned Qty",

                value:
                  totalReturned
                    .toString(),
              },

              {
                label:
                  "Net Qty",

                value:
                  Math.max(
                    0,
                    totalAllocated -
                    totalReturned
                  ).toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // 3. RETURN REPORT
      //
      // IMPORTANT:
      // returnedQuantity includes physical return settled
      // against allocation.
      //
      // TRN_STOCK ALLOCATION_RETURN stores GOOD /
      // RESALABLE return quantity only.
      // ==================================================

      if (
        type ===
        "return-report"
      ) {
        const allocationFilter = {
          farmId,

          "products.returnedQuantity": {
            $gt: 0,
          },
        };


        addDateFilter(
          allocationFilter,
          "updatedAt"
        );


        if (
          currentSalesman
        ) {
          allocationFilter.salesmanId =
            currentSalesman
              .salesmanId;
        }


        const allocations =
          await Allocation.find(
            allocationFilter
          )
            .sort({
              updatedAt: -1,
            })
            .select(
              [
                "allocationId",
                "allocationNo",
                "allocationDate",
                "salesmanId",
                "salesmanName",
                "routeName",
                "products",
                "updatedAt",
                "status",
              ].join(" ")
            )
            .lean();


        // ----------------------------------------------
        // GOOD / RESALABLE RETURNS FROM STOCK LEDGER
        // ----------------------------------------------

        const stockFilter = {
          farmId,

          transactionType:
            "ALLOCATION_RETURN",
        };


        addDateFilter(
          stockFilter,
          "createdAt"
        );


        const stockReturns =
          await StockTransaction.find(
            stockFilter
          )
            .select(
              [
                "referenceId",
                "productId",
                "quantityIn",
              ].join(" ")
            )
            .lean();


        const goodReturnMap =
          new Map();


        for (
          const stock of
          stockReturns
        ) {
          const key =
            `${stock.referenceId ||
            ""
            }::${stock.productId ||
            ""
            }`;

          goodReturnMap.set(
            key,
            (
              goodReturnMap.get(
                key
              ) || 0
            ) +
            (
              Number(
                stock.quantityIn
              ) || 0
            )
          );
        }


        let totalReturned =
          0;

        let totalGoodReturn =
          0;

        let totalOtherReturn =
          0;

        const rows = [];


        for (
          const allocation of
          allocations
        ) {
          for (
            const product of
            allocation.products || []
          ) {
            const returned =
              Number(
                product
                  .returnedQuantity
              ) || 0;


            if (
              returned <= 0
            ) {
              continue;
            }


            const key =
              `${allocation
                .allocationId ||
              ""
              }::${product.productId ||
              ""
              }`;


            const goodReturn =
              Number(
                goodReturnMap.get(
                  key
                ) || 0
              );


            const otherReturn =
              Math.max(
                0,
                returned -
                goodReturn
              );


            totalReturned +=
              returned;

            totalGoodReturn +=
              goodReturn;

            totalOtherReturn +=
              otherReturn;


            rows.push([
              displayDate(
                allocation.updatedAt ||
                allocation
                  .allocationDate
              ),

              allocation
                .allocationNo ||
              "",

              allocation
                .salesmanName ||
              "",

              allocation
                .routeName ||
              "",

              product.productId ||
              "",

              product.productName ||
              "",

              product.variant ||
              "",

              product.unit ||
              "",

              Number(
                product.quantity ||
                0
              ),

              returned,

              goodReturn,

              otherReturn,

              allocation.status ||
              "",
            ]);
          }
        }


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Return Report",

            description:
              "Salesman allocation returns and stock settlement",

            columns: [
              "Return Date",
              "Allocation No",
              "Salesman",
              "Route",
              "Product ID",
              "Product",
              "Variant",
              "Unit",
              "Allocated Qty",
              "Returned Qty",
              "Good Return",
              "Other / Damage",
              "Status",
            ],

            rows,

            metrics: [
              {
                label:
                  "Returned Qty",

                value:
                  totalReturned
                    .toString(),
              },

              {
                label:
                  "Good Return",

                value:
                  totalGoodReturn
                    .toString(),
              },

              {
                label:
                  "Other / Damage",

                value:
                  totalOtherReturn
                    .toString(),
              },
            ],
          },
        });
      }


      // ==================================================
      // 4. EXPENSE REPORT
      // ==================================================

      if (
        type ===
        "expense-report"
      ) {
        const filter = {
          farmId,
          status:
            "POSTED",
        };


        addDateFilter(
          filter,
          "expenseDate"
        );


        // Salesman can see only expenses entered by himself.
        if (
          currentSalesman
        ) {
          filter.createdBy =
            req.user.userId;

          filter.createdRole =
            "salesman";
        }


        const expenses =
          await Expense.find(
            filter
          )
            .sort({
              expenseDate: -1,
              createdAt: -1,
            })
            .select(
              [
                "expenseNo",
                "expenseDate",
                "category",
                "amount",
                "paymentMode",
                "note",
                "createdBy",
                "createdRole",
              ].join(" ")
            )
            .lean();


        let totalExpense =
          0;

        const categoryTotals =
          new Map();


        const rows =
          expenses.map(
            item => {
              const amount =
                Number(
                  item.amount
                ) || 0;

              totalExpense +=
                amount;


              const category =
                item.category ||
                "Other";


              categoryTotals.set(
                category,
                (
                  categoryTotals.get(
                    category
                  ) || 0
                ) + amount
              );


              return [
                displayDate(
                  item.expenseDate
                ),

                item.expenseNo ||
                "",

                item.category ||
                "",

                item.paymentMode ||
                "",

                Number(
                  amount.toFixed(2)
                ),

                item.note ||
                "",
              ];
            }
          );


        let highestCategory =
          "";

        let highestCategoryAmount =
          0;


        for (
          const [
            category,
            amount,
          ] of
          categoryTotals.entries()
        ) {
          if (
            amount >
            highestCategoryAmount
          ) {
            highestCategory =
              category;

            highestCategoryAmount =
              amount;
          }
        }


        return res.status(200).json({
          success: true,

          report: {
            title:
              "Expense Report",

            description:
              "Business and distribution expenses during the selected period",

            columns: [
              "Date",
              "Expense No",
              "Category",
              "Paid By",
              "Amount",
              "Note",
            ],

            rows,

            metrics: [
              {
                label:
                  "Entries",

                value:
                  expenses.length
                    .toString(),
              },

              {
                label:
                  "Total Expense",

                value:
                  money(
                    totalExpense
                  ),
              },

              {
                label:
                  "Top Category",

                value:
                  highestCategory ||
                  "-",
              },

              {
                label:
                  "Top Category Amount",

                value:
                  money(
                    highestCategoryAmount
                  ),
              },
            ],
          },
        });
      }


    } catch (error) {
      console.error(
        "GET OPERATION REPORT ERROR:",
        error
      );

      return res.status(500).json({
        success: false,

        message:
          "Unable to load operational report.",

        error:
          error.message,
      });
    }
  }
);
// ======================================================
// DASHBOARD SUMMARY
// ADMIN + SALESMAN
// ======================================================
// ======================================================
// DASHBOARD SUMMARY
//
// ADMIN + SALESMAN
//
// SALESMAN:
//
// - TODAY SALES         -> HIS SALES ONLY
// - TODAY COLLECTION   -> HIS COLLECTIONS ONLY
// - CASH COLLECTION    -> HIS CASH ONLY
// - UPI COLLECTION     -> HIS UPI FAMILY ONLY
// - OUTSTANDING        -> HIS SALES ONLY
// - ADVANCE            -> CREATED FROM HIS SALES ONLY
// - TODAY PENDING QTY  -> TODAY ALLOCATION REMAINING
// - PENDING RETURN QTY -> OLD ALLOCATION REMAINING
//
// ADMIN:
// -> FARM-WIDE DATA
//
// IMPORTANT:
// Admin sales / admin advance / admin opening outstanding
// must NEVER appear in salesman dashboard.
// ======================================================

app.get(
  "/api/dashboard/summary",

  authenticateToken,

  loadAccessContext,

  async (req, res) => {
    try {

      const farmId =
        req.user.farmId;

      const role =
        req.user.role;

      const userId =
        req.user.userId;


      // ==================================================
      // TODAY RANGE
      //
      // IMPORTANT:
      // Render/server may run in UTC.
      //
      // Dashboard business date is INDIA / IST.
      // ==================================================

      const IST_OFFSET_MS =
        330 *
        60 *
        1000;


      const now =
        new Date();


      const istNow =
        new Date(
          now.getTime() +
          IST_OFFSET_MS
        );


      const istYear =
        istNow.getUTCFullYear();

      const istMonth =
        istNow.getUTCMonth();

      const istDate =
        istNow.getUTCDate();


      const todayStart =
        new Date(
          Date.UTC(
            istYear,
            istMonth,
            istDate,
            0,
            0,
            0,
            0
          ) -
          IST_OFFSET_MS
        );


      const todayEnd =
        new Date(
          Date.UTC(
            istYear,
            istMonth,
            istDate,
            23,
            59,
            59,
            999
          ) -
          IST_OFFSET_MS
        );


      // ==================================================
      // ROLE / SALESMAN
      // ==================================================

      let salesman =
        null;


      if (
        role ===
        "salesman"
      ) {

        salesman =
          await Salesman.findOne({
            _id:
              userId,

            farmId,

            isActive:
              true,
          })
            .select(
              "salesmanId name"
            )
            .lean();


        if (!salesman) {

          return res
            .status(404)
            .json({
              success:
                false,

              message:
                "Salesman account not found.",
            });
        }
      }

      else if (
        role !==
        "admin"
      ) {

        return res
          .status(403)
          .json({
            success:
              false,

            message:
              "You are not allowed to view dashboard.",
          });
      }


      // ==================================================
      // TODAY SALES
      // ==================================================

      const todaySaleFilter = {
        farmId,

        status:
          "POSTED",

        saleDate: {
          $gte:
            todayStart,

          $lte:
            todayEnd,
        },
      };


      // ==================================================
      // SALESMAN:
      // ONLY HIS OWN SALES
      // ==================================================

      if (salesman) {

        todaySaleFilter.salesmanId =
          salesman.salesmanId;

        todaySaleFilter.createdRole =
          "salesman";
      }


      const todaySales =
        await Sale.find(
          todaySaleFilter
        )
        .select(
  [
    "saleId",
    "customerId",
    "grandTotal",
    "totalQuantity",

    "paymentMode",
    "payments",
    "paidAmount",

    "saleDate",
  ].join(" ")
)
          .lean();


      const todaySalesAmount =
        todaySales.reduce(
          (
            total,
            sale
          ) =>
            total +
            (
              Number(
                sale.grandTotal
              ) ||
              0
            ),

          0
        );


      const todaySalesQuantity =
        todaySales.reduce(
          (
            total,
            sale
          ) =>
            total +
            (
              Number(
                sale.totalQuantity
              ) ||
              0
            ),

          0
        );


      const todayBills =
        todaySales.length;


      // ==================================================
      // TODAY COLLECTION
      //
      // SALESMAN:
      // ONLY RECEIPTS ACTUALLY COLLECTED BY HIM
      //
      // ADMIN:
      // ALL FARM COLLECTIONS
      // ==================================================

      const collectionFilter = {
        farmId,

        status:
          "POSTED",

        collectionDate: {
          $gte:
            todayStart,

          $lte:
            todayEnd,
        },
      };


      if (salesman) {

        collectionFilter.salesmanId =
          salesman.salesmanId;

        collectionFilter.createdRole =
          "salesman";
      }


      const todayCollections =
        await Collection.find(
          collectionFilter
        )
          .select(
            [
              "collectionId",
              "customerId",
              "amount",
              "paymentMode",
              "collectionDate",
            ].join(" ")
          )
          .lean();


      // ==================================================
      // COLLECTION BREAKUP
      // ==================================================
let todayCollectionAmount =
  0;

let todayCashCollection =
  0;

let todayUpiCollection =
  0;

let todayOtherCollection =
  0;

let billingPaymentReceipts =
  0;


// ==================================================
// MONEY RECEIVED WHILE MAKING TODAY'S BILLS
// ==================================================

for (
  const sale of todaySales
) {
  const billing =
    getSaleBillingPaymentBreakup(
      sale
    );


  if (
    billing.total <= 0.001
  ) {
    continue;
  }


  billingPaymentReceipts +=
    1;


  todayCollectionAmount +=
    billing.total;

  todayCashCollection +=
    billing.cash;

  todayUpiCollection +=
    billing.upi;

  todayOtherCollection +=
    billing.bankTransfer +
    billing.cheque +
    billing.other;
}


// ==================================================
// LATER COLLECTION RECEIPTS CREATED TODAY
// ==================================================

for (
  const collection of
  todayCollections
) {
  const amount =
    Math.max(
      0,
      Number(
        collection.amount || 0
      )
    );


  const mode =
    classifyHistoryPaymentMode(
      collection.paymentMode
    );


  todayCollectionAmount +=
    amount;


  if (
    mode === "cash"
  ) {
    todayCashCollection +=
      amount;
  }

  else if (
    mode === "upi"
  ) {
    todayUpiCollection +=
      amount;
  }

  else {
    todayOtherCollection +=
      amount;
  }
}


todayCollectionAmount =
  Number(
    todayCollectionAmount
      .toFixed(2)
  );


todayCashCollection =
  Number(
    todayCashCollection
      .toFixed(2)
  );


todayUpiCollection =
  Number(
    todayUpiCollection
      .toFixed(2)
  );


todayOtherCollection =
  Number(
    todayOtherCollection
      .toFixed(2)
  );

      // ==================================================
      // TODAY ALLOCATION
      // ==================================================

      const allocationFilter = {
        farmId,

        allocationDate: {
          $gte:
            todayStart,

          $lte:
            todayEnd,
        },

        status: {
          $in: [
            "POSTED",
            "RETURNED",
          ],
        },
      };


      if (salesman) {

        allocationFilter.salesmanId =
          salesman.salesmanId;
      }


      const todayAllocations =
        await Allocation.find(
          allocationFilter
        )
          .select(
            [
              "allocationId",
              "totalQuantity",
              "products",
            ].join(" ")
          )
          .lean();


      const todayAllocatedQuantity =
        todayAllocations.reduce(
          (
            total,
            allocation
          ) =>
            total +
            (
              Number(
                allocation.totalQuantity
              ) ||
              0
            ),

          0
        );


      // ==================================================
      // LOAD ALL SALESMAN ALLOCATIONS
      //
      // Used for:
      // - Pending Qty
      // - Pending Return
      // - Return filtering
      // ==================================================

      let allRelevantAllocations =
        [];


      if (salesman) {

        allRelevantAllocations =
          await Allocation.find({
            farmId,

            salesmanId:
              salesman.salesmanId,

            status: {
              $in: [
                "POSTED",
                "RETURNED",
              ],
            },
          })
            .select(
              [
                "allocationId",
                "allocationDate",
                "createdAt",
                "products",
              ].join(" ")
            )
            .sort({
              allocationDate:
                1,

              createdAt:
                1,
            })
            .lean();
      }


      // ==================================================
      // TODAY RETURNS
      //
      // SALESMAN MUST SEE ONLY RETURNS AGAINST HIS
      // OWN ALLOCATIONS.
      // ==================================================

      const returnFilter = {
        farmId,

        transactionType:
          "ALLOCATION_RETURN",

        createdAt: {
          $gte:
            todayStart,

          $lte:
            todayEnd,
        },
      };


      if (salesman) {

        const salesmanAllocationIds =
          allRelevantAllocations
            .map(
              (
                allocation
              ) =>
                (
                  allocation
                    .allocationId ||
                  ""
                )
                  .toString()
                  .trim()
                  .toUpperCase()
            )
            .filter(
              Boolean
            );


        if (
          salesmanAllocationIds
            .length ===
          0
        ) {

          returnFilter.referenceId =
            "__NO_SALESMAN_ALLOCATION__";
        }

        else {

          returnFilter.referenceId = {
            $in:
              salesmanAllocationIds,
          };
        }
      }


      const returnTransactions =
        await StockTransaction.find(
          returnFilter
        )
          .select(
            "quantityIn referenceId"
          )
          .lean();


      const todayReturnQuantity =
        Number(
          returnTransactions
            .reduce(
              (
                total,
                item
              ) =>
                total +
                (
                  Number(
                    item.quantityIn
                  ) ||
                  0
                ),

              0
            )
            .toFixed(2)
        );


      // ==================================================
      // TWO PENDING QUANTITIES
      //
      // pendingDeliveryQuantity
      // -> TODAY'S allocation still remaining
      //
      // pendingReturnQuantity
      // -> PREVIOUS allocation still not sold / returned
      // ==================================================

      let pendingDeliveryQuantity =
        0;

      let pendingReturnQuantity =
        0;


      if (salesman) {

        // ==================================================
        // ALL SALESMAN SALES
        // ==================================================

        const salesmanSalesForQty =
          await Sale.find({
            farmId,

            salesmanId:
              salesman.salesmanId,

            createdRole:
              "salesman",

            status:
              "POSTED",
          })
            .select(
              "products"
            )
            .lean();


        // ==================================================
        // PRODUCT -> TOTAL SOLD
        // ==================================================

        const remainingSoldMap =
          new Map();


        for (
          const sale
          of salesmanSalesForQty
        ) {

          for (
            const product
            of sale.products ||
              []
          ) {

            const productId =
              (
                product.productId ||
                ""
              )
                .toString()
                .trim()
                .toUpperCase();


            if (!productId) {

              continue;
            }


            const quantity =
              Math.max(
                0,

                Number(
                  product.quantity ||
                  0
                )
              );


            remainingSoldMap.set(
              productId,

              (
                remainingSoldMap.get(
                  productId
                ) ||
                0
              ) +
              quantity
            );
          }
        }


        // ==================================================
        // FIFO:
        //
        // Old allocation sales consumed first.
        // ==================================================

        for (
          const allocation
          of allRelevantAllocations
        ) {

          const allocationDate =
            new Date(
              allocation
                .allocationDate ||

              allocation
                .createdAt ||

              0
            );


          const isPreviousAllocation =
            allocationDate <
            todayStart;


          for (
            const product
            of allocation.products ||
              []
          ) {

            const productId =
              (
                product.productId ||
                ""
              )
                .toString()
                .trim()
                .toUpperCase();


            if (!productId) {

              continue;
            }


            const allocatedQuantity =
              Math.max(
                0,

                Number(
                  product.quantity ||
                  0
                )
              );


            const returnedQuantity =
              Math.max(
                0,

                Number(
                  product
                    .returnedQuantity ||
                  0
                )
              );


            const usableAllocated =
              Math.max(
                0,

                allocatedQuantity -
                returnedQuantity
              );


            const remainingSold =
              Math.max(
                0,

                Number(
                  remainingSoldMap.get(
                    productId
                  ) ||
                  0
                )
              );


            const soldAgainstAllocation =
              Math.min(
                usableAllocated,
                remainingSold
              );


            remainingSoldMap.set(
              productId,

              Math.max(
                0,

                remainingSold -
                soldAgainstAllocation
              )
            );


            const remainingQuantity =
              Math.max(
                0,

                usableAllocated -
                soldAgainstAllocation
              );


            if (
              remainingQuantity <=
              0.001
            ) {

              continue;
            }


            if (
              isPreviousAllocation
            ) {

              pendingReturnQuantity +=
                remainingQuantity;
            }

            else {

              pendingDeliveryQuantity +=
                remainingQuantity;
            }
          }
        }


        pendingDeliveryQuantity =
          Number(
            pendingDeliveryQuantity
              .toFixed(2)
          );


        pendingReturnQuantity =
          Number(
            pendingReturnQuantity
              .toFixed(2)
          );
      }


      // ==================================================
      // CURRENT OUTSTANDING / ADVANCE
      // ==================================================

      let totalOutstanding =
        0;

      let totalAdvance =
        0;

      let pendingCollection =
        0;

      let pendingAccounts =
        0;


      const currentNetPositionMap =
        new Map();


      // ==================================================
      // SALESMAN POSITION
      // ==================================================

      if (salesman) {

        // ==================================================
        // IMPORTANT
        //
        // ONLY THIS SALESMAN'S SALE RECORDS ARE USED.
        //
        // DO NOT INCLUDE:
        //
        // - Admin sales
        // - Admin manual/opening outstanding
        // - Admin-created advance
        //
        // DO INCLUDE:
        //
        // - This salesman's bills
        // - Collection applied against his bill
        // - Advance created in his bill
        // - Advance used in his bill
        // ==================================================

        const salesmanPositionSales =
          await Sale.find({
            farmId,

            salesmanId:
              salesman.salesmanId,

            createdRole:
              "salesman",

            status:
              "POSTED",
          })
            .select(
              [
                "saleId",
                "saleDate",
                "createdAt",
                "customerId",
                "grandTotal",
                "paymentMode",
                "paidAmount",
                "paymentApplied",
                "outstandingAmount",
                "advanceCreated",
                "advanceUsed",
              ].join(" ")
            )
            .sort({
              saleDate:
                1,

              createdAt:
                1,
            })
            .lean();


        // ==================================================
        // SALE IDS OF THIS SALESMAN
        // ==================================================

        const salesmanSaleIds =
          salesmanPositionSales
            .map(
              (
                sale
              ) =>
                (
                  sale.saleId ||
                  ""
                )
                  .toString()
                  .trim()
                  .toUpperCase()
            )
            .filter(
              Boolean
            );


        const salesmanSaleIdSet =
          new Set(
            salesmanSaleIds
          );


        // ==================================================
        // COLLECTIONS WITH SAVED SOURCE ALLOCATIONS
        //
        // IMPORTANT:
        //
        // If Admin later receives payment against THIS
        // salesman bill, the bill has actually been settled.
        //
        // Therefore we reduce the salesman outstanding based
        // on allocation source.
        //
        // We DO NOT count that Admin receipt in today's
        // salesman Collection card.
        // ==================================================

        let allocatedCollections =
          [];


        if (
          salesmanSaleIds.length >
          0
        ) {

          allocatedCollections =
            await Collection.find({
              farmId,

              status:
                "POSTED",

              $or: [
                {
                  "allocations.referenceId":
                    {
                      $in:
                        salesmanSaleIds,
                    },
                },

                {
                  "allocations.saleId":
                    {
                      $in:
                        salesmanSaleIds,
                    },
                },
              ],
            })
              .select(
                "allocations"
              )
              .lean();
        }


        const collectionAppliedBySale =
          new Map();


        for (
          const collection
          of allocatedCollections
        ) {

          for (
            const allocation
            of collection.allocations ||
              []
          ) {

            const sourceType =
              (
                allocation
                  .sourceType ||
                "SALE"
              )
                .toString()
                .trim()
                .toUpperCase();


            if (
              sourceType !==
              "SALE"
            ) {

              continue;
            }


            const saleId =
              (
                allocation
                  .referenceId ||

                allocation
                  .saleId ||

                ""
              )
                .toString()
                .trim()
                .toUpperCase();


            if (
              !saleId ||

              !salesmanSaleIdSet.has(
                saleId
              )
            ) {

              continue;
            }


            const applied =
              Math.max(
                0,

                Number(
                  allocation
                    .amountApplied ||
                  0
                )
              );


            collectionAppliedBySale.set(
              saleId,

              (
                collectionAppliedBySale.get(
                  saleId
                ) ||
                0
              ) +
              applied
            );
          }
        }


        // ==================================================
        // CUSTOMER -> SALESMAN BILL LIST
        // ==================================================

        const billsByCustomer =
          new Map();


        // ==================================================
        // CUSTOMER -> SALESMAN ADVANCE CREATED / USED
        // ==================================================

        const salesmanAdvanceMap =
          new Map();


        for (
          const sale
          of salesmanPositionSales
        ) {

          const customerId =
            (
              sale.customerId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (!customerId) {

            continue;
          }


          let billOutstanding =
            Number(
              sale.outstandingAmount
            );


          // ==================================================
          // OLD SALE COMPATIBILITY
          // ==================================================

          if (
            !Number.isFinite(
              billOutstanding
            )
          ) {

            const billAmount =
              Math.max(
                0,

                Number(
                  sale.grandTotal ||
                  0
                )
              );


            const directPayment =
              Math.max(
                0,

                Number(
                  sale.paymentApplied ??
                  sale.paidAmount ??
                  0
                )
              );


            const usedAdvance =
              Math.max(
                0,

                Number(
                  sale.advanceUsed ||
                  0
                )
              );


            billOutstanding =
              Math.max(
                0,

                billAmount -
                directPayment -
                usedAdvance
              );
          }


          const saleId =
            (
              sale.saleId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          const allocatedCollection =
            Math.max(
              0,

              Number(
                collectionAppliedBySale.get(
                  saleId
                ) ||
                0
              )
            );


          const remainingOutstanding =
            Math.max(
              0,

              billOutstanding -
              allocatedCollection
            );


          if (
            !billsByCustomer.has(
              customerId
            )
          ) {

            billsByCustomer.set(
              customerId,
              []
            );
          }


          billsByCustomer
            .get(
              customerId
            )
            .push({
              saleId,

              saleDate:
                sale.saleDate ||
                sale.createdAt ||
                null,

              remainingOutstanding,
            });


          if (
            !salesmanAdvanceMap.has(
              customerId
            )
          ) {

            salesmanAdvanceMap.set(
              customerId,
              {
                created:
                  0,

                used:
                  0,
              }
            );
          }


          const advanceRow =
            salesmanAdvanceMap.get(
              customerId
            );


          // ADVANCE CREATED BY SALESMAN BILL
          advanceRow.created +=
            Math.max(
              0,

              Number(
                sale.advanceCreated ||
                0
              )
            );


          // ADVANCE USED ON SALESMAN BILL
          advanceRow.used +=
            Math.max(
              0,

              Number(
                sale.advanceUsed ||
                0
              )
            );
        }


        // ==================================================
        // LEGACY SALESMAN COLLECTIONS WITHOUT ALLOCATIONS
        //
        // New collections already have allocation source.
        //
        // This is only to protect old data.
        // ==================================================

        const legacySalesmanCollections =
          await Collection.find({
            farmId,

            status:
              "POSTED",

            salesmanId:
              salesman.salesmanId,

            createdRole:
              "salesman",

            $or: [
              {
                allocations: {
                  $exists:
                    false,
                },
              },

              {
                allocations: {
                  $size:
                    0,
                },
              },
            ],
          })
            .select(
              [
                "customerId",
                "amount",
                "collectionDate",
                "createdAt",
              ].join(" ")
            )
            .sort({
              collectionDate:
                1,

              createdAt:
                1,
            })
            .lean();


        for (
          const collection
          of legacySalesmanCollections
        ) {

          const customerId =
            (
              collection.customerId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          const customerBills =
            billsByCustomer.get(
              customerId
            ) ||
            [];


          if (
            customerBills.length ===
            0
          ) {

            continue;
          }


          const receiptDate =
            collection.collectionDate
              ? new Date(
                  collection.collectionDate
                )
              : null;


          let remainingReceipt =
            Math.max(
              0,

              Number(
                collection.amount ||
                0
              )
            );


          for (
            const bill
            of customerBills
          ) {

            if (
              remainingReceipt <=
              0.001
            ) {

              break;
            }


            if (
              receiptDate &&
              bill.saleDate &&
              new Date(
                bill.saleDate
              ) >
                receiptDate
            ) {

              continue;
            }


            if (
              bill.remainingOutstanding <=
              0.001
            ) {

              continue;
            }


            const applied =
              Math.min(
                remainingReceipt,

                bill
                  .remainingOutstanding
              );


            bill.remainingOutstanding -=
              applied;

            remainingReceipt -=
              applied;
          }
        }


        // ==================================================
        // FINAL SALESMAN POSITION
        // CUSTOMER-WISE
        // ==================================================

        const customerIds =
          new Set([
            ...billsByCustomer
              .keys(),

            ...salesmanAdvanceMap
              .keys(),
          ]);


        for (
          const customerId
          of customerIds
        ) {

          const grossOutstanding =
            (
              billsByCustomer.get(
                customerId
              ) ||
              []
            )
              .reduce(
                (
                  total,
                  bill
                ) =>
                  total +
                  Math.max(
                    0,

                    Number(
                      bill
                        .remainingOutstanding ||
                      0
                    )
                  ),

                0
              );


          const advanceRow =
            salesmanAdvanceMap.get(
              customerId
            ) ||
            {
              created:
                0,

              used:
                0,
            };


          // ==================================================
          // SALESMAN-OWN ADVANCE ONLY
          //
          // ADMIN customer.balance IS NOT USED HERE.
          // ==================================================

          const salesmanAdvance =
            Math.max(
              0,

              Number(
                advanceRow.created ||
                0
              ) -

              Number(
                advanceRow.used ||
                0
              )
            );


          const netPosition =
            Number(
              (
                grossOutstanding -
                salesmanAdvance
              )
                .toFixed(2)
            );


          currentNetPositionMap.set(
            customerId,
            netPosition
          );


          // CUSTOMER OWES SALESMAN-CREATED DUE
          if (
            netPosition >
            0.001
          ) {

            totalOutstanding +=
              netPosition;

            pendingAccounts +=
              1;
          }


          // SALESMAN CREATED CUSTOMER ADVANCE
          else if (
            netPosition <
            -0.001
          ) {

            totalAdvance +=
              Math.abs(
                netPosition
              );
          }
        }


        totalOutstanding =
          Number(
            totalOutstanding
              .toFixed(2)
          );


        totalAdvance =
          Number(
            totalAdvance
              .toFixed(2)
          );


        pendingCollection =
          totalOutstanding;
      }


      // ==================================================
      // ADMIN POSITION
      //
      // Keep admin farm-wide behavior.
      // ==================================================

      else {

        const [
          customers,
          postedSales,
          manualRows,
          collections,
        ] =
          await Promise.all([

            Customer.find({
              farmId,

              isActive:
                true,
            })
              .select(
                "customerId balance"
              )
              .lean(),


            Sale.find({
              farmId,

              status:
                "POSTED",
            })
              .select(
                [
                  "saleId",
                  "saleDate",
                  "createdAt",
                  "customerId",
                  "grandTotal",
                  "paymentMode",
                  "outstandingAmount",
                ].join(" ")
              )
              .sort({
                saleDate:
                  1,

                createdAt:
                  1,
              })
              .lean(),


            CustomerOutstanding.find({
              farmId,

              status:
                "POSTED",
            })
              .select(
                [
                  "adjustmentId",
                  "adjustmentDate",
                  "createdAt",
                  "customerId",
                  "amount",
                ].join(" ")
              )
              .sort({
                adjustmentDate:
                  1,

                createdAt:
                  1,
              })
              .lean(),


            Collection.find({
              farmId,

              status:
                "POSTED",
            })
              .select(
                [
                  "customerId",
                  "amount",
                  "collectionDate",
                  "createdAt",
                  "allocations",
                ].join(" ")
              )
              .sort({
                collectionDate:
                  1,

                createdAt:
                  1,
              })
              .lean(),
          ]);


        const sourceMap =
          new Map();

        const sourcesByCustomer =
          new Map();


        const addSource = (
          source
        ) => {

          sourceMap.set(
            source.key,
            source
          );


          if (
            !sourcesByCustomer.has(
              source.customerId
            )
          ) {

            sourcesByCustomer.set(
              source.customerId,
              []
            );
          }


          sourcesByCustomer
            .get(
              source.customerId
            )
            .push(
              source
            );
        };


        // ==================================================
        // SALES SOURCES
        // ==================================================

        for (
          const sale
          of postedSales
        ) {

          const customerId =
            (
              sale.customerId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          const saleId =
            (
              sale.saleId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (
            !customerId ||
            !saleId
          ) {

            continue;
          }


          let outstanding =
            Number(
              sale.outstandingAmount
            );


          if (
            !Number.isFinite(
              outstanding
            )
          ) {

            const mode =
              (
                sale.paymentMode ||
                ""
              )
                .toString()
                .trim()
                .toLowerCase();


            outstanding =
              mode ===
                "credit"
                ? Math.max(
                    0,

                    Number(
                      sale.grandTotal ||
                      0
                    )
                  )
                : 0;
          }


          addSource({
            key:
              `SALE|${saleId}`,

            sourceType:
              "SALE",

            customerId,

            referenceId:
              saleId,

            referenceDate:
              sale.saleDate ||
              sale.createdAt ||
              null,

            remainingOutstanding:
              Math.max(
                0,
                outstanding
              ),
          });
        }


        // ==================================================
        // MANUAL / OPENING OUTSTANDING
        // ==================================================

        for (
          const item
          of manualRows
        ) {

          const customerId =
            (
              item.customerId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          const adjustmentId =
            (
              item.adjustmentId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (
            !customerId ||
            !adjustmentId
          ) {

            continue;
          }


          addSource({
            key:
              `MANUAL_OUTSTANDING|${adjustmentId}`,

            sourceType:
              "MANUAL_OUTSTANDING",

            customerId,

            referenceId:
              adjustmentId,

            referenceDate:
              item.adjustmentDate ||
              item.createdAt ||
              null,

            remainingOutstanding:
              Math.max(
                0,

                Number(
                  item.amount ||
                  0
                )
              ),
          });
        }


        // FIFO SOURCE ORDER
        for (
          const customerSources
          of sourcesByCustomer
            .values()
        ) {

          customerSources.sort(
            (
              a,
              b
            ) =>
              new Date(
                a.referenceDate ||
                0
              ) -

              new Date(
                b.referenceDate ||
                0
              )
          );
        }


        // ==================================================
        // APPLY COLLECTIONS
        // ==================================================

        for (
          const collection
          of collections
        ) {

          const allocations =
            Array.isArray(
              collection.allocations
            )
              ? collection.allocations
              : [];


          // NEW COLLECTION
          if (
            allocations.length >
            0
          ) {

            for (
              const allocation
              of allocations
            ) {

              const sourceType =
                (
                  allocation
                    .sourceType ||
                  "SALE"
                )
                  .toString()
                  .trim()
                  .toUpperCase();


              const referenceId =
                (
                  allocation
                    .referenceId ||

                  allocation
                    .saleId ||

                  ""
                )
                  .toString()
                  .trim()
                  .toUpperCase();


              const source =
                sourceMap.get(
                  `${sourceType}|${referenceId}`
                );


              if (!source) {

                continue;
              }


              const applied =
                Math.max(
                  0,

                  Number(
                    allocation
                      .amountApplied ||
                    0
                  )
                );


              source.remainingOutstanding =
                Math.max(
                  0,

                  source
                    .remainingOutstanding -
                  applied
                );
            }


            continue;
          }


          // ==================================================
          // LEGACY RECEIPT
          //
          // Old receipt had no stored allocation.
          // Apply against sale outstanding FIFO.
          // ==================================================

          const customerId =
            (
              collection.customerId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          const customerSources =
            sourcesByCustomer.get(
              customerId
            ) ||
            [];


          const receiptDate =
            collection.collectionDate
              ? new Date(
                  collection
                    .collectionDate
                )
              : null;


          let remainingReceipt =
            Math.max(
              0,

              Number(
                collection.amount ||
                0
              )
            );


          for (
            const source
            of customerSources
          ) {

            if (
              remainingReceipt <=
              0.001
            ) {

              break;
            }


            if (
              source.sourceType !==
              "SALE"
            ) {

              continue;
            }


            if (
              receiptDate &&
              source.referenceDate &&
              new Date(
                source.referenceDate
              ) >
                receiptDate
            ) {

              continue;
            }


            if (
              source
                .remainingOutstanding <=
              0.001
            ) {

              continue;
            }


            const applied =
              Math.min(
                remainingReceipt,

                source
                  .remainingOutstanding
              );


            source.remainingOutstanding -=
              applied;

            remainingReceipt -=
              applied;
          }
        }


        // ==================================================
        // CUSTOMER ADVANCE MAP
        // ==================================================

        const customerAdvanceMap =
          new Map(
            customers.map(
              (
                customer
              ) => [
                (
                  customer.customerId ||
                  ""
                )
                  .toString()
                  .trim()
                  .toUpperCase(),

                Math.max(
                  0,

                  Number(
                    customer.balance ||
                    0
                  )
                ),
              ]
            )
          );


        const allCustomerIds =
          new Set([
            ...customerAdvanceMap
              .keys(),

            ...sourcesByCustomer
              .keys(),
          ]);


        // ==================================================
        // ADMIN NET POSITION
        // ==================================================

        for (
          const customerId
          of allCustomerIds
        ) {

          const grossOutstanding =
            (
              sourcesByCustomer.get(
                customerId
              ) ||
              []
            )
              .reduce(
                (
                  total,
                  source
                ) =>
                  total +
                  Math.max(
                    0,

                    Number(
                      source
                        .remainingOutstanding ||
                      0
                    )
                  ),

                0
              );


          const advance =
            customerAdvanceMap.get(
              customerId
            ) ||
            0;


          const netPosition =
            Number(
              (
                grossOutstanding -
                advance
              )
                .toFixed(2)
            );


          if (
            netPosition >
            0.001
          ) {

            totalOutstanding +=
              netPosition;

            pendingAccounts +=
              1;
          }

          else if (
            netPosition <
            -0.001
          ) {

            totalAdvance +=
              Math.abs(
                netPosition
              );
          }
        }


        totalOutstanding =
          Number(
            totalOutstanding
              .toFixed(2)
          );


        totalAdvance =
          Number(
            totalAdvance
              .toFixed(2)
          );


        pendingCollection =
          totalOutstanding;
      }


      // ==================================================
      // TODAY CUSTOMER LIST
      //
      // SALESMAN ONLY
      // ==================================================

      let todayCustomers =
        [];


      if (salesman) {

        // ==================================================
        // SALESMAN ROUTES
        // ==================================================

        const salesmanRoutes =
          await RouteMaster.find({
            farmId,

            salesmanId:
              salesman.salesmanId,

            isActive:
              true,
          })
            .select(
              "routeId routeName"
            )
            .lean();


        const salesmanRouteNames =
          salesmanRoutes
            .map(
              (
                route
              ) =>
                String(
                  route.routeName ||
                  ""
                ).trim()
            )
            .filter(
              Boolean
            );


        // ==================================================
        // CUSTOMERS OF SALESMAN ROUTES
        // ==================================================

        let routeCustomers =
          [];


        if (
          salesmanRouteNames
            .length >
          0
        ) {

          routeCustomers =
            await Customer.find({
              farmId,

              isActive:
                true,

              route: {
                $in:
                  salesmanRouteNames,
              },
            })
              .select(
                [
                  "customerId",
                  "name",
                  "mobile",
                  "route",
                ].join(" ")
              )
              .sort({
                name:
                  1,
              })
              .lean();
        }


        // ==================================================
        // TODAY SALE MAP
        // ==================================================

        const todaySaleMap =
          new Map();


        for (
          const sale
          of todaySales
        ) {

          const customerId =
            (
              sale.customerId ||
              ""
            )
              .toString()
              .trim()
              .toUpperCase();


          if (!customerId) {

            continue;
          }


          todaySaleMap.set(
            customerId,

            (
              todaySaleMap.get(
                customerId
              ) ||
              0
            ) +

            (
              Number(
                sale.grandTotal
              ) ||
              0
            )
          );
        }


        // ==================================================
        // TODAY COLLECTION MAP
        // ==================================================

    const todayCollectionMap =
  new Map();


// ==================================================
// BILL-TIME PAYMENT BY CUSTOMER
// ==================================================

for (
  const sale of todaySales
) {
  const customerId =
    (
      sale.customerId ||
      ""
    )
      .toString()
      .trim()
      .toUpperCase();


  if (!customerId) {
    continue;
  }


  const billing =
    getSaleBillingPaymentBreakup(
      sale
    );


  if (
    billing.total <= 0.001
  ) {
    continue;
  }


  todayCollectionMap.set(
    customerId,

    (
      todayCollectionMap.get(
        customerId
      ) || 0
    ) +
      billing.total
  );
}


// ==================================================
// LATER COLLECTION RECEIPT BY CUSTOMER
// ==================================================

for (
  const collection of
  todayCollections
) {
  const customerId =
    (
      collection.customerId ||
      ""
    )
      .toString()
      .trim()
      .toUpperCase();


  if (!customerId) {
    continue;
  }


  todayCollectionMap.set(
    customerId,

    (
      todayCollectionMap.get(
        customerId
      ) || 0
    ) +
      (
        Number(
          collection.amount
        ) || 0
      )
  );
}

        // ==================================================
        // BUILD CUSTOMER LIST
        // ==================================================

        todayCustomers =
          routeCustomers.map(
            (
              customer
            ) => {

              const customerId =
                (
                  customer.customerId ||
                  ""
                )
                  .toString()
                  .trim()
                  .toUpperCase();


              const todaySale =
                Number(
                  todaySaleMap.get(
                    customerId
                  ) ||
                  0
                );


              const todayCollection =
                Number(
                  todayCollectionMap.get(
                    customerId
                  ) ||
                  0
                );


              // SALESMAN-ONLY NET POSITION
              const netPosition =
                Number(
                  currentNetPositionMap.get(
                    customerId
                  ) ||
                  0
                );


              const outstanding =
                Math.max(
                  0,
                  netPosition
                );


              const visited =
                todaySale >
                  0 ||

                todayCollection >
                  0;


              return {

                customerId:
                  customer.customerId ||
                  "",

                customerName:
                  customer.name ||
                  "",

                mobile:
                  customer.mobile ||
                  "",

                route:
                  customer.route ||
                  "",


                // IMPORTANT:
                // Admin outstanding does not appear here.
                outstanding:
                  Number(
                    outstanding
                      .toFixed(2)
                  ),


                todaySale:
                  Number(
                    todaySale
                      .toFixed(2)
                  ),


                todayCollection:
                  Number(
                    todayCollection
                      .toFixed(2)
                  ),


                status:
                  visited
                    ? "Visited"
                    : "Pending",
              };
            }
          );


        // PENDING FIRST
        todayCustomers.sort(
          (
            a,
            b
          ) => {

            if (
              a.status ===
              b.status
            ) {

              return a
                .customerName
                .localeCompare(
                  b.customerName
                );
            }


            return (
              a.status ===
              "Pending"
            )
              ? -1
              : 1;
          }
        );
      }


      // ==================================================
      // PROGRESS
      // ==================================================

      const salesProgress =
        todayAllocatedQuantity >
        0

          ? Math.min(
              1,

              todaySalesQuantity /
              todayAllocatedQuantity
            )

          : 0;


      const collectionProgress =
        todaySalesAmount >
        0

          ? Math.min(
              1,

              todayCollectionAmount /
              todaySalesAmount
            )

          : 0;


      const returnProgress =
        todayAllocatedQuantity >
        0

          ? Math.min(
              1,

              todayReturnQuantity /
              todayAllocatedQuantity
            )

          : 0;


      // ==================================================
      // RESPONSE
      // ==================================================

      return res
        .status(200)
        .json({

          success:
            true,


          data: {

            role,


            // CURRENT SALESMAN
            salesmanId:
              salesman
                ?.salesmanId ||
              "",

            salesmanName:
              salesman
                ?.name ||
              "",


            // ==================================================
            // TODAY SALES
            // ==================================================

            todaySalesAmount:
              Number(
                todaySalesAmount
                  .toFixed(2)
              ),

            todaySalesQuantity:
              Number(
                todaySalesQuantity
                  .toFixed(2)
              ),

            todayBills,


            // ==================================================
            // TODAY COLLECTION
            // ==================================================

            todayCollectionAmount,

            todayCashCollection,

            todayUpiCollection,

            todayOtherCollection,
collectionReceipts:
  todayCollections.length +
  billingPaymentReceipts,


            // ==================================================
            // ACCOUNT POSITION
            // ==================================================

            totalOutstanding,

            totalAdvance,

            pendingCollection:
              Number(
                pendingCollection
                  .toFixed(2)
              ),

            pendingAccounts,


            // ==================================================
            // ALLOCATION
            // ==================================================

            todayAllocations:
              todayAllocations.length,

            todayAllocatedQuantity:
              Number(
                todayAllocatedQuantity
                  .toFixed(2)
              ),

            todayReturnQuantity,

            pendingDeliveryQuantity:
              Number(
                pendingDeliveryQuantity
                  .toFixed(2)
              ),

            pendingReturnQuantity:
              Number(
                pendingReturnQuantity
                  .toFixed(2)
              ),


            // ==================================================
            // PROGRESS
            // ==================================================

            salesProgress,

            collectionProgress,

            returnProgress,


            // ==================================================
            // CUSTOMER LIST
            // ==================================================

            todayCustomers,
          },
        });

    } catch (error) {

      console.error(
        "GET DASHBOARD SUMMARY ERROR:",
        error
      );


      return res
        .status(500)
        .json({

          success:
            false,

          message:
            "Unable to load dashboard summary.",

          error:
            error.message,
        });
    }
  }
);
// ======================================================
// CURRENT USER PROFILE
// ADMIN + SALESMAN
// ======================================================

app.get(
  "/api/profile",
  authenticateToken,
  loadAccessContext,
  async (req, res) => {
    try {
      const {
        userId,
        farmId,
        role,
      } = req.user;

      let user = null;

      if (role === "admin") {
        user = await Register.findOne({
          _id: userId,
          farmId,
        })
          .select(
            "_id role farmId adminId name mobile email username businessName address city state pin isActive"
          )
          .lean();
      } else if (role === "salesman") {

        user = await Salesman.findOne({
          _id: userId,
          farmId,
        })
          .select(
            "_id role farmId salesmanId name mobile email username businessName permissions permissionMode isActive"
          )
          .lean();

        if (user) {
          const farmAdmin = await Register.findOne({
            farmId,
            isActive: true,
          }).select("salesmanDefaultPermissions").lean();

          user.permissionMode =
            user.permissionMode ||
            (Array.isArray(user.permissions) && user.permissions.length > 0
              ? "custom"
              : "inherit");
          user.permissions = getEffectiveSalesmanPermissions(user, farmAdmin);

          const route =
            await RouteMaster.findOne({
              farmId,
              salesmanId:
                user.salesmanId,
            })
              .select(
                "routeId routeName"
              )
              .lean();

          user.routeId =
            route?.routeId || "";

          user.routeName =
            route?.routeName || "";
        }
      } else {
        return res.status(403).json({
          success: false,
          message:
            "Invalid user role.",
        });
      }

      if (!user) {
        return res.status(404).json({
          success: false,
          message:
            "Profile not found.",
        });
      }

      return res.status(200).json({
        success: true,
        data: user,
      });

    } catch (error) {
      console.error(
        "GET PROFILE ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load profile.",
        error:
          error.message,
      });
    }
  }
);

// ======================================================
// UPDATE CURRENT USER PROFILE
// ======================================================

app.put(
  "/api/profile",
  authenticateToken,
  loadAccessContext,
  async (req, res) => {
    try {
      const {
        userId,
        farmId,
        role,
      } = req.user;

      const {
        name,
        mobile,
        email,
        username,
        businessName,
        address,
        city,
        state,
        pin,
      } = req.body;

      if (
        !name ||
        !name.toString().trim()
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Name is required.",
        });
      }

      if (
        !mobile ||
        mobile.toString().trim().length !== 10
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Enter a valid 10-digit mobile number.",
        });
      }

      if (
        !username ||
        !username.toString().trim()
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Username is required.",
        });
      }

      const normalizedUsername =
        username.toString().trim();

      // ==================================================
      // CHECK USERNAME IN ADMIN MASTER
      // ==================================================

      const existingAdmin =
        await Register.findOne({
          username: {
            $regex: new RegExp(
              `^${escapeRegex(normalizedUsername)}$`,
              "i"
            ),
          },
          _id: {
            $ne: userId,
          },
        });

      // ==================================================
      // CHECK USERNAME IN SALESMAN MASTER
      // ==================================================

      const existingSalesman =
        await Salesman.findOne({
          username: {
            $regex: new RegExp(
              `^${escapeRegex(normalizedUsername)}$`,
              "i"
            ),
          },
          _id: {
            $ne: userId,
          },
        });

      if (
        existingAdmin ||
        existingSalesman
      ) {
        return res.status(409).json({
          success: false,
          message:
            "Username is already in use.",
        });
      }

      let user = null;

      if (role === "admin") {
        user = await Register.findOne({
          _id: userId,
          farmId,
        });
      } else if (role === "salesman") {
        user = await Salesman.findOne({
          _id: userId,
          farmId,
        });
      }

      if (!user) {
        return res.status(404).json({
          success: false,
          message:
            "Profile not found.",
        });
      }

      user.name =
        name.toString().trim();

      user.mobile =
        mobile.toString().trim();

      user.email =
        (email || "")
          .toString()
          .trim()
          .toLowerCase();

      user.username =
        normalizedUsername;

      user.businessName =
        (businessName || "")
          .toString()
          .trim();

      if (role === "admin") {
        user.address =
          (address || "")
            .toString()
            .trim();

        user.city =
          (city || "")
            .toString()
            .trim();

        user.state =
          (state || "")
            .toString()
            .trim();

        user.pin =
          (pin || "")
            .toString()
            .trim();
      }

      await user.save();

      return res.status(200).json({
        success: true,
        message:
          "Profile updated successfully.",
        data: {
          id: user._id,
          role,
          farmId: user.farmId,
          adminId:
            role === "admin"
              ? user.adminId
              : null,
          salesmanId:
            role === "salesman"
              ? user.salesmanId
              : null,
          name:
            user.name,
          mobile:
            user.mobile,
          email:
            user.email,
          username:
            user.username,
          businessName:
            user.businessName,
          address:
            role === "admin"
              ? user.address
              : "",
          city:
            role === "admin"
              ? user.city
              : "",
          state:
            role === "admin"
              ? user.state
              : "",
          pin:
            role === "admin"
              ? user.pin
              : "",
        },
      });

    } catch (error) {
      console.error(
        "UPDATE PROFILE ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to update profile.",
        error:
          error.message,
      });
    }
  }
);
// ======================================================
// CHANGE CURRENT USER PASSWORD
// ======================================================

app.put(
  "/api/profile/password",
  authenticateToken,
  loadAccessContext,
  async (req, res) => {
    try {
      const {
        userId,
        farmId,
        role,
      } = req.user;

      const {
        currentPassword,
        newPassword,
      } = req.body;

      if (
        !currentPassword ||
        !newPassword
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Current password and new password are required.",
        });
      }

      if (
        newPassword
          .toString()
          .length < 6
      ) {
        return res.status(400).json({
          success: false,
          message:
            "New password must contain at least 6 characters.",
        });
      }

      let user = null;

      if (role === "admin") {
        user = await Register.findOne({
          _id: userId,
          farmId,
        });
      } else if (role === "salesman") {
        user = await Salesman.findOne({
          _id: userId,
          farmId,
        });
      }

      if (!user) {
        return res.status(404).json({
          success: false,
          message:
            "User not found.",
        });
      }

      const passwordMatched =
        await bcrypt.compare(
          currentPassword.toString(),
          user.password
        );

      if (!passwordMatched) {
        return res.status(400).json({
          success: false,
          message:
            "Current password is incorrect.",
        });
      }

      const samePassword =
        await bcrypt.compare(
          newPassword.toString(),
          user.password
        );

      if (samePassword) {
        return res.status(400).json({
          success: false,
          message:
            "New password must be different from current password.",
        });
      }

      user.password =
        await bcrypt.hash(
          newPassword.toString(),
          10
        );

      await user.save();

      return res.status(200).json({
        success: true,
        message:
          "Password changed successfully.",
      });

    } catch (error) {
      console.error(
        "CHANGE PASSWORD ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to change password.",
        error:
          error.message,
      });
    }
  }
);

// ======================================================
// UPDATE SALESMAN
// ADMIN ONLY
// ======================================================

app.put(
  "/api/salesmen/:salesmanId",
  authenticateToken,
  loadAccessContext,
  requireAdmin,
  async (req, res) => {
    try {

      const farmId =
        req.access.farmId;

      const salesmanId =
        req.params.salesmanId
          .toString()
          .trim()
          .toUpperCase();

      const {
        name,
        mobile,
        email,
        username,
        isActive,
      } = req.body;

      const salesman =
        await Salesman.findOne({
          farmId,
          salesmanId,
        });

      if (!salesman) {
        return res.status(404).json({
          success: false,
          message:
            "Salesman not found.",
        });
      }

      if (name !== undefined) {
        const value =
          name.toString().trim();

        if (!value) {
          return res.status(400).json({
            success: false,
            message:
              "Salesman name is required.",
          });
        }

        salesman.name =
          value;
      }

      if (mobile !== undefined) {
        const value =
          mobile.toString().trim();

        if (value.length !== 10) {
          return res.status(400).json({
            success: false,
            message:
              "Enter a valid 10-digit mobile number.",
          });
        }

        salesman.mobile =
          value;
      }

      if (email !== undefined) {
        salesman.email =
          email
            .toString()
            .trim()
            .toLowerCase();
      }

      // ================================================
      // USERNAME
      // ================================================

      if (username !== undefined) {

        const value =
          username
            .toString()
            .trim();

        if (!value) {
          return res.status(400).json({
            success: false,
            message:
              "Username is required.",
          });
        }

        const existingAdmin =
          await Register.findOne({
            username: {
              $regex: new RegExp(
                `^${escapeRegex(value)}$`,
                "i"
              ),
            },
          });

        const existingSalesman =
          await Salesman.findOne({
            username: {
              $regex: new RegExp(
                `^${escapeRegex(value)}$`,
                "i"
              ),
            },

            _id: {
              $ne: salesman._id,
            },
          });

        if (
          existingAdmin ||
          existingSalesman
        ) {
          return res.status(409).json({
            success: false,
            message:
              "Username is already in use.",
          });
        }

        salesman.username =
          value;
      }

      if (
        typeof isActive ===
        "boolean"
      ) {
        salesman.isActive =
          isActive;
      }

      await salesman.save();

      return res.status(200).json({
        success: true,

        message:
          "Salesman updated successfully.",

        data: {
          _id:
            salesman._id,

          farmId:
            salesman.farmId,

          salesmanId:
            salesman.salesmanId,

          name:
            salesman.name,

          mobile:
            salesman.mobile,

          email:
            salesman.email,

          username:
            salesman.username,

          businessName:
            salesman.businessName,

          permissions:
            salesman.permissions,

          isActive:
            salesman.isActive,
        },
      });

    } catch (error) {

      console.error(
        "UPDATE SALESMAN ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to update salesman.",
        error:
          error.message,
      });
    }
  }
);
// ======================================================
// GET SINGLE PURCHASE
// GET /api/purchases/:id
// ======================================================

app.get(
  "/api/purchases/:id",
  authenticateToken,
  loadAccessContext,
  requirePermission("purchaseView"),
  async (req, res) => {
    try {
      const farmId = req.user.farmId;

      const purchase =
        await Purchase.findOne({
          _id: req.params.id,
          farmId: farmId,
        });

      if (!purchase) {
        return res.status(404).json({
          success: false,
          message: "Purchase not found.",
        });
      }

      return res.status(200).json({
        success: true,
        data: purchase,
      });

    } catch (error) {
      console.error(
        "GET SINGLE PURCHASE ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to load purchase details.",
        error: error.message,
      });
    }
  }
);

// ======================================================
// GET SINGLE ALLOCATION
// ADMIN -> ANY FARM ALLOCATION
// SALESMAN -> ONLY OWN ALLOCATION
// ======================================================

// app.get(
//   "/api/allocations/:allocationId",
//   authenticateToken,
//   loadAccessContext,
//   requireAnyPermission("allocationView", "returnsManage"),
//   async (req, res) => {
//     try {
//       const farmId = req.user.farmId;
//       const role = req.user.role;

//       const allocationId = (
//         req.params.allocationId || ""
//       )
//         .toString()
//         .trim()
//         .toUpperCase();

//       if (!allocationId) {
//         return res.status(400).json({
//           success: false,
//           message: "Allocation ID is required.",
//         });
//       }

//       const filter = {
//         farmId,
//         allocationId,
//       };

//       if (role === "salesman") {
//         const salesman = await Salesman.findOne({
//           _id: req.user.userId,
//           farmId,
//           isActive: true,
//         }).lean();

//         if (!salesman) {
//           return res.status(404).json({
//             success: false,
//             message: "Salesman account not found.",
//           });
//         }

//         filter.salesmanId = salesman.salesmanId;
//       } else if (role !== "admin") {
//         return res.status(403).json({
//           success: false,
//           message: "You are not allowed to view this allocation.",
//         });
//       }

//       const allocation =
//         await Allocation.findOne(filter).lean();

//       if (!allocation) {
//         return res.status(404).json({
//           success: false,
//           message: "Allocation not found.",
//         });
//       }

//       return res.status(200).json({
//         success: true,
//         data: allocation,
//       });
//     } catch (error) {
//       console.error(
//         "GET SINGLE ALLOCATION ERROR:",
//         error
//       );

//       return res.status(500).json({
//         success: false,
//         message: "Unable to load allocation.",
//       });
//     }
//   }
// );
// ======================================================
// SALESMAN SALES PERFORMANCE
// DAY / WEEK / MONTH / YEAR
// ======================================================

app.get(
  "/api/dashboard/salesman-performance",
  authenticateToken,
  loadAccessContext,
  async (req, res) => {
    try {
      const farmId = req.user.farmId;
      const role = req.user.role;
      const userId = req.user.userId;

      // ==================================================
      // SALESMAN ONLY
      // ==================================================

      if (role !== "salesman") {
        return res.status(403).json({
          success: false,
          message:
            "Sales performance is available only for salesman login.",
        });
      }

      // ==================================================
      // FIND LOGGED-IN SALESMAN
      // Never trust salesmanId from frontend
      // ==================================================

      const salesman =
        await Salesman.findOne({
          _id: userId,
          farmId,
          isActive: true,
        })
          .select(
            "salesmanId name"
          )
          .lean();

      if (!salesman) {
        return res.status(404).json({
          success: false,
          message:
            "Salesman account not found.",
        });
      }

      // ==================================================
      // PERIOD
      // day | week | month | year
      // ==================================================

      const allowedPeriods = [
        "day",
        "week",
        "month",
        "year",
      ];

      const period = String(
        req.query.period || "day"
      )
        .trim()
        .toLowerCase();

      if (
        !allowedPeriods.includes(period)
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid period. Use day, week, month or year.",
        });
      }

      // ==================================================
      // DATE RANGE
      // ==================================================

      const now = new Date();

      let fromDate;
      let toDate;

      // --------------------------------------------------
      // DAY
      // --------------------------------------------------

      if (period === "day") {
        fromDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          0,
          0,
          0,
          0
        );

        toDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
          999
        );
      }

      // --------------------------------------------------
      // WEEK
      // Monday -> Today
      // --------------------------------------------------

      else if (period === "week") {
        const dayOfWeek =
          now.getDay();

        const daysFromMonday =
          dayOfWeek === 0
            ? 6
            : dayOfWeek - 1;

        fromDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate() -
          daysFromMonday,
          0,
          0,
          0,
          0
        );

        toDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
          999
        );
      }

      // --------------------------------------------------
      // MONTH
      // First day of month -> Today
      // --------------------------------------------------

      else if (period === "month") {
        fromDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          1,
          0,
          0,
          0,
          0
        );

        toDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
          999
        );
      }

      // --------------------------------------------------
      // YEAR
      // 1 January -> Today
      // --------------------------------------------------

      else {
        fromDate = new Date(
          now.getFullYear(),
          0,
          1,
          0,
          0,
          0,
          0
        );

        toDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
          999
        );
      }

      // ==================================================
      // LOAD POSTED SALES OF LOGGED-IN SALESMAN
      // ==================================================

      const sales =
        await Sale.find({
          farmId,

          salesmanId:
            salesman.salesmanId,

          createdRole:
            "salesman",

          status:
            "POSTED",

          saleDate: {
            $gte: fromDate,
            $lte: toDate,
          },
        })
          .select(
            [
              "saleId",
              "saleNo",
              "saleDate",
              "customerId",
              "customerName",
              "route",
              "products",
              "totalQuantity",
              "grandTotal",
            ].join(" ")
          )
          .sort({
            saleDate: -1,
            createdAt: -1,
          })
          .lean();

      // ==================================================
      // OVERALL SUMMARY
      // ==================================================

      let salesAmount = 0;
      let totalQuantity = 0;

      const uniqueCustomers =
        new Set();

      for (const sale of sales) {
        salesAmount +=
          Number(
            sale.grandTotal
          ) || 0;

        totalQuantity +=
          Number(
            sale.totalQuantity
          ) || 0;

        const customerId =
          String(
            sale.customerId || ""
          )
            .trim()
            .toUpperCase();

        if (customerId) {
          uniqueCustomers.add(
            customerId
          );
        }
      }

      
      // ==================================================
      // CUSTOMER-WISE PERFORMANCE
      // ==================================================

      const customerMap =
        new Map();

      for (const sale of sales) {
        const customerId =
          String(
            sale.customerId || ""
          )
            .trim()
            .toUpperCase();

        if (!customerId) {
          continue;
        }

        if (
          !customerMap.has(
            customerId
          )
        ) {
          customerMap.set(
            customerId,
            {
              customerId:
                sale.customerId || "",

              customerName:
                sale.customerName || "",

              route:
                sale.route || "",

              billCount:
                0,

              totalQuantity:
                0,

              salesAmount:
                0,

              productsMap:
                new Map(),
            }
          );
        }

        const customer =
          customerMap.get(
            customerId
          );

        customer.billCount += 1;

        customer.totalQuantity +=
          Number(
            sale.totalQuantity
          ) || 0;

        customer.salesAmount +=
          Number(
            sale.grandTotal
          ) || 0;

        // ================================================
        // PRODUCT-WISE SALES FOR CUSTOMER
        // ================================================

        for (
          const product of
          sale.products || []
        ) {
          const productId =
            String(
              product.productId || ""
            )
              .trim()
              .toUpperCase();

          if (!productId) {
            continue;
          }

          if (
            !customer.productsMap.has(
              productId
            )
          ) {
            customer.productsMap.set(
              productId,
              {
                productId:
                  product.productId || "",

                productName:
                  product.productName || "",

                variant:
                  product.variant || "",

                unit:
                  product.unit || "",

                quantity:
                  0,

                salesAmount:
                  0,
              }
            );
          }

          const productSummary =
            customer.productsMap.get(
              productId
            );

          productSummary.quantity +=
            Number(
              product.quantity
            ) || 0;

          productSummary.salesAmount +=
            Number(
              product.amount
            ) || 0;
        }
      }

      // ==================================================
      // CONVERT MAP TO API RESPONSE
      // ==================================================

      const customers =
        Array.from(
          customerMap.values()
        )
          .map(
            (customer) => ({
              customerId:
                customer.customerId,

              customerName:
                customer.customerName,

              route:
                customer.route,

              billCount:
                customer.billCount,

              totalQuantity:
                Number(
                  customer.totalQuantity
                    .toFixed(2)
                ),

              salesAmount:
                Number(
                  customer.salesAmount
                    .toFixed(2)
                ),

              products:
                Array.from(
                  customer.productsMap
                    .values()
                )
                  .map(
                    (product) => ({
                      ...product,

                      quantity:
                        Number(
                          product.quantity
                            .toFixed(2)
                        ),

                      salesAmount:
                        Number(
                          product.salesAmount
                            .toFixed(2)
                        ),
                    })
                  )
                  .sort(
                    (a, b) =>
                      b.quantity -
                      a.quantity
                  ),
            })
          )
          .sort(
            (a, b) =>
              b.salesAmount -
              a.salesAmount
          );

      // ==================================================
      // RESPONSE
      // ==================================================

      return res.status(200).json({
        success: true,

        data: {
          period,

          from:
            fromDate
              .toISOString(),

          to:
            toDate
              .toISOString(),

          salesman: {
            salesmanId:
              salesman.salesmanId,

            salesmanName:
              salesman.name,
          },

          summary: {
            salesAmount:
              Number(
                salesAmount
                  .toFixed(2)
              ),

            quantity:
              Number(
                totalQuantity
                  .toFixed(2)
              ),

            bills:
              sales.length,

            customers:
              uniqueCustomers.size,
          },

          customers,
        },
      });

    } catch (error) {
      console.error(
        "GET SALESMAN PERFORMANCE ERROR:",
        error
      );

      return res.status(500).json({
        success: false,

        message:
          "Unable to load salesman sales performance.",

        error:
          error.message,
      });
    }
  }
);

// ======================================================
// ADMIN DASHBOARD
// TODAY SALESMAN SUMMARY
//
// IMPORTANT:
// Separate read-only endpoint for React Admin Dashboard.
// Does NOT modify existing mobile dashboard APIs.
// ======================================================

// ======================================================
// ADMIN DASHBOARD
// TODAY SALESMAN / ROUTE CONTROL
//
// Shows:
// 1. Today's allocation
// 2. Today's sales
// 3. Today's collection
//    - Cash
//    - Online
// 4. Previous pending allocation
//
// IMPORTANT:
// Allocation consumption follows FIFO.
// Older allocations consume salesman sales first.
// ======================================================

app.get(
  "/api/admin/dashboard/today-salesman-summary",
  authenticateToken,
  loadAccessContext,
  async (req, res) => {
    try {
      // ==================================================
      // ADMIN ONLY
      // ==================================================

      if (req.user.role !== "admin") {
        return res.status(403).json({
          success: false,
          message: "Administrator access only.",
        });
      }

      const farmId =
        req.user.farmId;

      // ==================================================
      // TODAY RANGE
      //
      // IMPORTANT:
      // Use the same IST business-day helper already used
      // by Allocation module.
      //
      // This avoids Render / UTC timezone mismatch.
      // ==================================================

      const {
        start: todayStart,
        end: todayEnd,
        date: businessDate,
      } =
        getAllocationBusinessDayRange();

      // ==================================================
      // LOAD DATA
      //
      // IMPORTANT:
      //
      // Allocations:
      // load ALL active allocations up to today so FIFO
      // can correctly identify previous pending stock.
      //
      // Sales:
      // load all salesman allocation sales up to todayEnd
      // so FIFO can be calculated.
      //
      // Collections:
      // today only.
      // ==================================================

      const [
        salesmen,
        routes,
        allocations,
        allocationSales,
        collections,
      ] =
        await Promise.all([
          Salesman.find({
            farmId,
            isActive: true,
          })
            .select(
              "salesmanId name"
            )
            .sort({
              name: 1,
            })
            .lean(),

          RouteMaster.find({
            farmId,
            isActive: true,
          })
            .select(
              "routeId routeName salesmanId salesmanName"
            )
            .lean(),

          Allocation.find({
            farmId,

            allocationDate: {
              $lt: todayEnd,
            },

            status: {
              $in: [
                "POSTED",
                "RETURNED",
              ],
            },
          })
          .select(
  [
    "saleId",
    "saleNo",
    "saleDate",

    "salesmanId",
    "salesmanName",

    "products",
    "totalQuantity",
    "grandTotal",

    "paymentMode",
    "payments",
    "paidAmount",
  ].join(" ")
)
            .sort({
              allocationDate: 1,
              createdAt: 1,
            })
            .lean(),

          Sale.find({
            farmId,

            status: "POSTED",

            salesmanId: {
              $ne: "",
            },

            saleDate: {
              $lt: todayEnd,
            },

            $or: [
              {
                stockSource:
                  "SALESMAN_ALLOCATION",
              },

              // Legacy salesman sales
              {
                stockSource: {
                  $exists: false,
                },
                createdRole:
                  "salesman",
              },

              {
                stockSource: null,
                createdRole:
                  "salesman",
              },

              {
                stockSource: "",
                createdRole:
                  "salesman",
              },
            ],
          })
            .select(
              [
                "saleId",
                "saleNo",
                "saleDate",
                "salesmanId",
                "salesmanName",
                "products",
                "totalQuantity",
                "grandTotal",
              ].join(" ")
            )
            .lean(),

          Collection.find({
            farmId,

            status: "POSTED",

            collectionDate: {
              $gte: todayStart,
              $lt: todayEnd,
            },

            salesmanId: {
              $ne: "",
            },
          })
            .select(
              [
                "collectionId",
                "receiptNo",
                "salesmanId",
                "salesmanName",
                "amount",
                "paymentMode",
              ].join(" ")
            )
            .lean(),
        ]);

      // ==================================================
      // NORMALIZE ID
      // ==================================================

      const normalizeId = (
        value
      ) =>
        String(value || "")
          .trim()
          .toUpperCase();

      // ==================================================
      // ROUND QUANTITY / MONEY
      // ==================================================

      const round2 = (
        value
      ) =>
        Number(
          (
            Number(value) || 0
          ).toFixed(2)
        );

      // ==================================================
      // ROUTE MAP
      // salesmanId -> route names
      // ==================================================

      const routeMap =
        new Map();

      for (
        const route of routes
      ) {
        const salesmanId =
          normalizeId(
            route.salesmanId
          );

        if (!salesmanId) {
          continue;
        }

        if (
          !routeMap.has(
            salesmanId
          )
        ) {
          routeMap.set(
            salesmanId,
            new Set()
          );
        }

        const routeName =
          String(
            route.routeName || ""
          ).trim();

        if (routeName) {
          routeMap
            .get(salesmanId)
            .add(routeName);
        }
      }

      // ==================================================
      // TOTAL SOLD MAP FOR FIFO
      //
      // Map<
      //   salesmanId,
      //   Map<productId, totalSoldQty>
      // >
      // ==================================================

      const totalSoldBySalesman =
        new Map();

      // ==================================================
      // TODAY SALES MAP
      //
      // This represents actual sales made today.
      // It is separate from FIFO allocation consumption.
      // ==================================================

      const todaySalesMap =
        new Map();

      for (
        const sale of
        allocationSales
      ) {
        const salesmanId =
          normalizeId(
            sale.salesmanId
          );

        if (!salesmanId) {
          continue;
        }

        // ----------------------------------------------
        // ALL-TIME SOLD PRODUCT-WISE
        // Used only for FIFO.
        // ----------------------------------------------

        if (
          !totalSoldBySalesman.has(
            salesmanId
          )
        ) {
          totalSoldBySalesman.set(
            salesmanId,
            new Map()
          );
        }

        const salesmanProductMap =
          totalSoldBySalesman.get(
            salesmanId
          );

        let saleQuantity =
          0;

        for (
          const product of
          Array.isArray(
            sale.products
          )
            ? sale.products
            : []
        ) {
          const productId =
            normalizeId(
              product.productId
            );

          if (!productId) {
            continue;
          }

          const quantity =
            Number(
              product.quantity
            ) || 0;

          saleQuantity +=
            quantity;

          salesmanProductMap.set(
            productId,
            (
              salesmanProductMap.get(
                productId
              ) || 0
            ) + quantity
          );
        }

        // ----------------------------------------------
        // TODAY SALES ONLY
        // ----------------------------------------------

        const saleDate =
          new Date(
            sale.saleDate
          );

        const isToday =
          saleDate >=
            todayStart &&
          saleDate <
            todayEnd;

        if (!isToday) {
          continue;
        }

        if (
          !todaySalesMap.has(
            salesmanId
          )
        ) {
       todaySalesMap.set(
  salesmanId,
  {
    soldQuantity:
      0,

    salesAmount:
      0,

    billCount:
      0,

    billingReceiptCount:
      0,

    billingCollectionAmount:
      0,

    billingCashCollectionAmount:
      0,

    billingOnlineCollectionAmount:
      0,

    billingUpiCollectionAmount:
      0,

    billingBankCollectionAmount:
      0,
  }
);
        }

        const todaySale =
          todaySalesMap.get(
            salesmanId
          );

        todaySale.billCount +=
          1;

        todaySale.soldQuantity +=
          saleQuantity;

        todaySale.salesAmount +=
          Number(
            sale.grandTotal
          ) || 0;
          // ==============================================
// PAYMENT RECEIVED DURING THIS SALE
// ==============================================

const billing =
  getSaleBillingPaymentBreakup(
    sale
  );


if (
  billing.total > 0.001
) {
  todaySale.billingReceiptCount +=
    1;

  todaySale.billingCollectionAmount +=
    billing.total;

  todaySale.billingCashCollectionAmount +=
    billing.cash;

  todaySale.billingUpiCollectionAmount +=
    billing.upi;

  todaySale.billingBankCollectionAmount +=
    billing.bankTransfer;

  todaySale.billingOnlineCollectionAmount +=
    (
      billing.total -
      billing.cash
    );
}
      }

      // ==================================================
      // COPY SOLD MAP
      //
      // This map is progressively reduced as allocations
      // are processed oldest-first.
      // ==================================================

      const remainingSoldBySalesman =
        new Map();

      for (
        const [
          salesmanId,
          productMap,
        ] of
        totalSoldBySalesman.entries()
      ) {
        remainingSoldBySalesman.set(
          salesmanId,
          new Map(productMap)
        );
      }

      // ==================================================
      // ALLOCATION POSITION MAP
      //
      // Tracks:
      //
      // TODAY:
      // allocated / fifo sold / returned / remaining
      //
      // PREVIOUS:
      // remaining allocation still with salesman
      // ==================================================

      const allocationMap =
        new Map();

      function ensureAllocationSummary(
        salesmanId
      ) {
        if (
          !allocationMap.has(
            salesmanId
          )
        ) {
          allocationMap.set(
            salesmanId,
            {
              // Today's allocation
              todayAllocationCount:
                0,

              todayAllocatedQuantity:
                0,

              todayAllocationSoldQuantity:
                0,

              todayReturnedQuantity:
                0,

              todayRemainingQuantity:
                0,

              todayRouteNames:
                new Set(),

              // Previous pending
              previousPendingAllocationCount:
                0,

              previousPendingQuantity:
                0,

              previousPendingAllocations:
                [],
            }
          );
        }

        return allocationMap.get(
          salesmanId
        );
      }

      // ==================================================
      // FIFO ALLOCATION CONSUMPTION
      //
      // allocations already sorted oldest first.
      // ==================================================

      for (
        const allocation of
        allocations
      ) {
        const salesmanId =
          normalizeId(
            allocation.salesmanId
          );

        if (!salesmanId) {
          continue;
        }

        const allocationSummary =
          ensureAllocationSummary(
            salesmanId
          );

        if (
          !remainingSoldBySalesman.has(
            salesmanId
          )
        ) {
          remainingSoldBySalesman.set(
            salesmanId,
            new Map()
          );
        }

        const remainingSoldMap =
          remainingSoldBySalesman.get(
            salesmanId
          );

        const allocationDate =
          new Date(
            allocation.allocationDate ||
              allocation.createdAt
          );

        const isToday =
          allocationDate >=
            todayStart &&
          allocationDate <
            todayEnd;

        let allocatedQuantity =
          0;

        let fifoSoldQuantity =
          0;

        let returnedQuantity =
          0;

        let remainingQuantity =
          0;

        for (
          const product of
          Array.isArray(
            allocation.products
          )
            ? allocation.products
            : []
        ) {
          const productId =
            normalizeId(
              product.productId
            );

          if (!productId) {
            continue;
          }

          const allocated =
            Number(
              product.quantity
            ) || 0;

          const returned =
            Number(
              product.returnedQuantity
            ) || 0;

          // Saleable quantity still belonging
          // to this allocation before FIFO sales.
          const usableAllocated =
            Math.max(
              0,
              allocated -
                returned
            );

          const soldAvailable =
            Number(
              remainingSoldMap.get(
                productId
              )
            ) || 0;

          const consumed =
            Math.min(
              usableAllocated,
              soldAvailable
            );

          const remaining =
            Math.max(
              0,
              usableAllocated -
                consumed
            );

          allocatedQuantity +=
            allocated;

          returnedQuantity +=
            returned;

          fifoSoldQuantity +=
            consumed;

          remainingQuantity +=
            remaining;

          remainingSoldMap.set(
            productId,
            Math.max(
              0,
              soldAvailable -
                consumed
            )
          );
        }

        // =================================================
        // TODAY ALLOCATION
        // =================================================

        if (isToday) {
          allocationSummary
            .todayAllocationCount +=
            1;

          allocationSummary
            .todayAllocatedQuantity +=
            allocatedQuantity;

          allocationSummary
            .todayAllocationSoldQuantity +=
            fifoSoldQuantity;

          allocationSummary
            .todayReturnedQuantity +=
            returnedQuantity;

          allocationSummary
            .todayRemainingQuantity +=
            remainingQuantity;

          const routeName =
            String(
              allocation.routeName ||
                ""
            ).trim();

          if (routeName) {
            allocationSummary
              .todayRouteNames
              .add(routeName);
          }

          continue;
        }

        // =================================================
        // PREVIOUS PENDING ALLOCATION
        //
        // Only old allocations which STILL have remaining
        // quantity after FIFO sales + returns.
        // =================================================

        if (
          allocationDate <
            todayStart &&
          remainingQuantity >
            0.000001
        ) {
          allocationSummary
            .previousPendingAllocationCount +=
            1;

          allocationSummary
            .previousPendingQuantity +=
            remainingQuantity;

          allocationSummary
            .previousPendingAllocations
            .push({
              allocationId:
                allocation.allocationId,

              allocationNo:
                allocation.allocationNo,

              allocationDate:
                allocation.allocationDate,

              routeName:
                allocation.routeName ||
                "",

              allocatedQuantity:
                round2(
                  allocatedQuantity
                ),

              soldQuantity:
                round2(
                  fifoSoldQuantity
                ),

              returnedQuantity:
                round2(
                  returnedQuantity
                ),

              remainingQuantity:
                round2(
                  remainingQuantity
                ),
            });
        }
      }

      // ==================================================
      // COLLECTION MAP
      //
      // CASH
      // -> Cash
      //
      // ONLINE
      // -> UPI
      // -> PhonePe
      // -> Google Pay
      // -> Paytm
      // -> Bank Transfer
      // ==================================================

      const collectionMap =
        new Map();

      for (
        const collection of
        collections
      ) {
        const salesmanId =
          normalizeId(
            collection.salesmanId
          );

        if (!salesmanId) {
          continue;
        }

        if (
          !collectionMap.has(
            salesmanId
          )
        ) {
          collectionMap.set(
            salesmanId,
            {
              collectionAmount:
                0,

              cashCollectionAmount:
                0,

              onlineCollectionAmount:
                0,

              upiCollectionAmount:
                0,

              bankCollectionAmount:
                0,

              receiptCount:
                0,
            }
          );
        }

        const item =
          collectionMap.get(
            salesmanId
          );

        const amount =
          Number(
            collection.amount
          ) || 0;

        const paymentMode =
          String(
            collection.paymentMode ||
              ""
          )
            .trim()
            .toUpperCase();

        item.receiptCount +=
          1;

        item.collectionAmount +=
          amount;

        if (
          paymentMode ===
          "CASH"
        ) {
          item.cashCollectionAmount +=
            amount;
        } else {
          // All non-cash collection modes
          // are treated as Online/Digital.
          item.onlineCollectionAmount +=
            amount;

          if (
            paymentMode ===
            "BANK TRANSFER"
          ) {
            item.bankCollectionAmount +=
              amount;
          } else {
            // UPI / PHONEPE /
            // GOOGLE PAY / PAYTM
            item.upiCollectionAmount +=
              amount;
          }
        }
      }

      // ==================================================
      // BUILD SALESMAN ROWS
      // ==================================================

      const rows =
        salesmen.map(
          (salesman) => {
            const salesmanId =
              normalizeId(
                salesman.salesmanId
              );

            const allocation =
              allocationMap.get(
                salesmanId
              ) || {
                todayAllocationCount:
                  0,

                todayAllocatedQuantity:
                  0,

                todayAllocationSoldQuantity:
                  0,

                todayReturnedQuantity:
                  0,

                todayRemainingQuantity:
                  0,

                todayRouteNames:
                  new Set(),

                previousPendingAllocationCount:
                  0,

                previousPendingQuantity:
                  0,

                previousPendingAllocations:
                  [],
              };

const sale =
  todaySalesMap.get(
    salesmanId
  ) || {
    soldQuantity:
      0,

    salesAmount:
      0,

    billCount:
      0,

    billingReceiptCount:
      0,

    billingCollectionAmount:
      0,

    billingCashCollectionAmount:
      0,

    billingOnlineCollectionAmount:
      0,

    billingUpiCollectionAmount:
      0,

    billingBankCollectionAmount:
      0,
  };

            const collection =
              collectionMap.get(
                salesmanId
              ) || {
                collectionAmount:
                  0,

                cashCollectionAmount:
                  0,

                onlineCollectionAmount:
                  0,

                upiCollectionAmount:
                  0,

                bankCollectionAmount:
                  0,

                receiptCount:
                  0,
              };

            // =============================================
            // ROUTE
            // =============================================

            let routeNames =
              Array.from(
                allocation
                  .todayRouteNames
              );

            if (
              routeNames.length ===
              0
            ) {
              routeNames =
                Array.from(
                  routeMap.get(
                    salesmanId
                  ) || []
                );
            }

            // =============================================
            // TODAY ALLOCATION POSITION
            // =============================================

            const todayAllocatedQuantity =
              Number(
                allocation
                  .todayAllocatedQuantity
              ) || 0;

            const todayAllocationSoldQuantity =
              Number(
                allocation
                  .todayAllocationSoldQuantity
              ) || 0;

            const todayReturnedQuantity =
              Number(
                allocation
                  .todayReturnedQuantity
              ) || 0;

            const todayRemainingQuantity =
              Number(
                allocation
                  .todayRemainingQuantity
              ) || 0;

            // =============================================
            // ACTUAL SALES DONE TODAY
            //
            // This can consume previous allocations first
            // because allocation FIFO is handled separately.
            // =============================================

            const todaySoldQuantity =
              Number(
                sale.soldQuantity
              ) || 0;

            const todaySalesAmount =
              Number(
                sale.salesAmount
              ) || 0;

            // =============================================
            // PREVIOUS PENDING
            // =============================================

            const previousPendingQuantity =
              Number(
                allocation
                  .previousPendingQuantity
              ) || 0;

            const totalPendingQuantity =
              previousPendingQuantity +
              todayRemainingQuantity;

            // =============================================
            // STATUS
            // =============================================

            let status =
              "NO_ACTIVITY";

            if (
              previousPendingQuantity >
              0.000001
            ) {
              status =
                "PREVIOUS_PENDING";
            } else if (
              todayRemainingQuantity >
              0.000001
            ) {
              status =
                "RETURN_PENDING";
            } else if (
              todayAllocatedQuantity >
              0
            ) {
              status =
                "COMPLETED";
            } else if (
              todaySoldQuantity >
              0
            ) {
              status =
                "SALES_ONLY";
            } else if (
              collection.collectionAmount >
              0
            ) {
              status =
                "COLLECTION_ONLY";
            }

            return {
              salesmanId:
                salesman.salesmanId,

              salesmanName:
                salesman.name ||
                "",

              routeName:
                routeNames.join(
                  ", "
                ),

              // =========================================
              // TODAY ALLOCATION
              // =========================================

              allocationCount:
                allocation
                  .todayAllocationCount,

              allocatedQuantity:
                round2(
                  todayAllocatedQuantity
                ),

              // Keep legacy soldQuantity as actual
              // quantity SOLD TODAY so old frontend
              // continues working.
              soldQuantity:
                round2(
                  todaySoldQuantity
                ),

              returnedQuantity:
                round2(
                  todayReturnedQuantity
                ),

              remainingQuantity:
                round2(
                  todayRemainingQuantity
                ),

              pendingReturnQuantity:
                round2(
                  todayRemainingQuantity
                ),

              // New explicit FIFO field.
              todayAllocationSoldQuantity:
                round2(
                  todayAllocationSoldQuantity
                ),

              // =========================================
              // PREVIOUS PENDING ALLOCATION
              // =========================================

              previousPendingAllocationCount:
                allocation
                  .previousPendingAllocationCount,

              previousPendingQuantity:
                round2(
                  previousPendingQuantity
                ),

              previousPendingAllocations:
                allocation
                  .previousPendingAllocations,

              totalPendingQuantity:
                round2(
                  totalPendingQuantity
                ),

              // =========================================
              // TODAY SALES
              // =========================================

              billCount:
                sale.billCount,

              salesAmount:
                round2(
                  todaySalesAmount
                ),

              // =========================================
              // TODAY COLLECTION
              // =========================================

           receiptCount:
  Number(
    collection.receiptCount ||
      0
  ) +
  Number(
    sale.billingReceiptCount ||
      0
  ),

collectionAmount:
  round2(
    Number(
      collection.collectionAmount ||
        0
    ) +
    Number(
      sale.billingCollectionAmount ||
        0
    )
  ),

cashCollectionAmount:
  round2(
    Number(
      collection.cashCollectionAmount ||
        0
    ) +
    Number(
      sale.billingCashCollectionAmount ||
        0
    )
  ),

onlineCollectionAmount:
  round2(
    Number(
      collection.onlineCollectionAmount ||
        0
    ) +
    Number(
      sale.billingOnlineCollectionAmount ||
        0
    )
  ),

upiCollectionAmount:
  round2(
    Number(
      collection.upiCollectionAmount ||
        0
    ) +
    Number(
      sale.billingUpiCollectionAmount ||
        0
    )
  ),

bankCollectionAmount:
  round2(
    Number(
      collection.bankCollectionAmount ||
        0
    ) +
    Number(
      sale.billingBankCollectionAmount ||
        0
    )
  ),

              status,
            };
          }
        );

      // ==================================================
      // SORT
      //
      // 1. Previous pending
      // 2. Today's pending
      // 3. Remaining salesman alphabetically
      // ==================================================

      rows.sort(
        (a, b) => {
          const aPrevious =
            Number(
              a.previousPendingQuantity
            ) || 0;

          const bPrevious =
            Number(
              b.previousPendingQuantity
            ) || 0;

          if (
            aPrevious > 0 &&
            bPrevious <= 0
          ) {
            return -1;
          }

          if (
            bPrevious > 0 &&
            aPrevious <= 0
          ) {
            return 1;
          }

          const aPending =
            Number(
              a.remainingQuantity
            ) || 0;

          const bPending =
            Number(
              b.remainingQuantity
            ) || 0;

          if (
            aPending > 0 &&
            bPending <= 0
          ) {
            return -1;
          }

          if (
            bPending > 0 &&
            aPending <= 0
          ) {
            return 1;
          }

          return String(
            a.salesmanName ||
              ""
          ).localeCompare(
            String(
              b.salesmanName ||
                ""
            )
          );
        }
      );

      // ==================================================
      // SUMMARY
      // ==================================================

      const summary =
        rows.reduce(
          (
            total,
            row
          ) => {
            const hasActivity =
              row.allocatedQuantity >
                0 ||
              row.soldQuantity >
                0 ||
              row.collectionAmount >
                0 ||
              row.previousPendingQuantity >
                0;

            if (hasActivity) {
              total.salesmen +=
                1;
            }

            total.allocatedQuantity +=
              row.allocatedQuantity;

            total.soldQuantity +=
              row.soldQuantity;

            total.todayAllocationSoldQuantity +=
              row.todayAllocationSoldQuantity;

            total.returnedQuantity +=
              row.returnedQuantity;

            total.remainingQuantity +=
              row.remainingQuantity;

            total.pendingReturnQuantity +=
              row.pendingReturnQuantity;

            total.previousPendingQuantity +=
              row.previousPendingQuantity;

            total.totalPendingQuantity +=
              row.totalPendingQuantity;

            total.salesAmount +=
              row.salesAmount;

            total.collectionAmount +=
              row.collectionAmount;

            total.cashCollectionAmount +=
              row.cashCollectionAmount;

            total.onlineCollectionAmount +=
              row.onlineCollectionAmount;

            total.upiCollectionAmount +=
              row.upiCollectionAmount;

            total.bankCollectionAmount +=
              row.bankCollectionAmount;

            if (
              row.pendingReturnQuantity >
              0.000001
            ) {
              total.pendingReturnSalesmen +=
                1;
            }

            if (
              row.previousPendingQuantity >
              0.000001
            ) {
              total.previousPendingSalesmen +=
                1;
            }

            return total;
          },
          {
            salesmen:
              0,

            allocatedQuantity:
              0,

            soldQuantity:
              0,

            todayAllocationSoldQuantity:
              0,

            returnedQuantity:
              0,

            remainingQuantity:
              0,

            pendingReturnQuantity:
              0,

            pendingReturnSalesmen:
              0,

            previousPendingQuantity:
              0,

            previousPendingSalesmen:
              0,

            totalPendingQuantity:
              0,

            salesAmount:
              0,

            collectionAmount:
              0,

            cashCollectionAmount:
              0,

            onlineCollectionAmount:
              0,

            upiCollectionAmount:
              0,

            bankCollectionAmount:
              0,
          }
        );

      // ==================================================
      // ROUND SUMMARY
      // ==================================================

      const roundedSummary = {
        ...summary,

        allocatedQuantity:
          round2(
            summary
              .allocatedQuantity
          ),

        soldQuantity:
          round2(
            summary
              .soldQuantity
          ),

        todayAllocationSoldQuantity:
          round2(
            summary
              .todayAllocationSoldQuantity
          ),

        returnedQuantity:
          round2(
            summary
              .returnedQuantity
          ),

        remainingQuantity:
          round2(
            summary
              .remainingQuantity
          ),

        pendingReturnQuantity:
          round2(
            summary
              .pendingReturnQuantity
          ),

        previousPendingQuantity:
          round2(
            summary
              .previousPendingQuantity
          ),

        totalPendingQuantity:
          round2(
            summary
              .totalPendingQuantity
          ),

        salesAmount:
          round2(
            summary
              .salesAmount
          ),

        collectionAmount:
          round2(
            summary
              .collectionAmount
          ),

        cashCollectionAmount:
          round2(
            summary
              .cashCollectionAmount
          ),

        onlineCollectionAmount:
          round2(
            summary
              .onlineCollectionAmount
          ),

        upiCollectionAmount:
          round2(
            summary
              .upiCollectionAmount
          ),

        bankCollectionAmount:
          round2(
            summary
              .bankCollectionAmount
          ),
      };

      // ==================================================
      // RESPONSE
      // ==================================================

      return res
        .status(200)
        .json({
          success: true,

          data: {
            businessDate,

            date:
              new Date()
                .toISOString(),

            summary:
              roundedSummary,

            rows,
          },
        });
    } catch (error) {
      console.error(
        "GET ADMIN TODAY SALESMAN SUMMARY ERROR:",
        error
      );

      return res
        .status(
          error.statusCode ||
            500
        )
        .json({
          success: false,

          message:
            error.message ||
            "Unable to load today's salesman summary.",
        });
    }
  }
);

// ======================================================
// SALES & COLLECTION HISTORY MODULE
// ======================================================

const HISTORY_IST_OFFSET_MS = 330 * 60 * 1000;

function parseHistoryIstDateRange(startDateStr, endDateStr) {
  const now = new Date();
  const istNow = new Date(now.getTime() + HISTORY_IST_OFFSET_MS);

  let rangeStart = null;
  let rangeEnd = null;

  if (startDateStr) {
    const s = String(startDateStr).trim().substring(0, 10);
    const parts = s.split("-").map(Number);
    if (parts.length === 3 && !parts.some(isNaN)) {
      rangeStart = new Date(
        Date.UTC(parts[0], parts[1] - 1, parts[2], 0, 0, 0, 0) -
          HISTORY_IST_OFFSET_MS
      );
    }
  }

  if (endDateStr) {
    const e = String(endDateStr).trim().substring(0, 10);
    const parts = e.split("-").map(Number);
    if (parts.length === 3 && !parts.some(isNaN)) {
      rangeEnd = new Date(
        Date.UTC(parts[0], parts[1] - 1, parts[2], 23, 59, 59, 999) -
          HISTORY_IST_OFFSET_MS
      );
    }
  }

  // Default: Current Month in IST
  if (!rangeStart) {
    rangeStart = new Date(
      Date.UTC(istNow.getUTCFullYear(), istNow.getUTCMonth(), 1, 0, 0, 0, 0) -
        HISTORY_IST_OFFSET_MS
    );
  }

  if (!rangeEnd) {
    rangeEnd = new Date(
      Date.UTC(
        istNow.getUTCFullYear(),
        istNow.getUTCMonth(),
        istNow.getUTCDate(),
        23,
        59,
        59,
        999
      ) - HISTORY_IST_OFFSET_MS
    );
  }

  return { rangeStart, rangeEnd };
}

function classifyHistoryPaymentMode(
  rawMode
) {
  const mode =
    String(
      rawMode || ""
    )
      .trim()
      .toLowerCase();

  if (
    mode === "cash"
  ) {
    return "cash";
  }

  if (
    mode === "upi" ||
    mode === "phonepe" ||
    mode === "google pay" ||
    mode === "gpay" ||
    mode === "paytm"
  ) {
    return "upi";
  }

  if (
    mode === "bank transfer" ||
    mode === "bank" ||
    mode === "neft" ||
    mode === "rtgs" ||
    mode === "imps"
  ) {
    return "bankTransfer";
  }

  if (
    mode === "cheque"
  ) {
    return "cheque";
  }

  return "other";
}


// ======================================================
// SALE PAYMENT RECEIVED AT BILLING
//
// IMPORTANT:
// This DOES NOT create TRN_COLLECTION.
//
// It only reads money already stored in TRN_SALE:
//   paidAmount
//   payments[]
//   paymentMode
//
// Therefore outstanding is NOT reduced twice.
// ======================================================

function getSaleBillingPaymentBreakup(
  sale
) {
  const paidAmount =
    Math.max(
      0,
      Number(
        sale?.paidAmount || 0
      )
    );

  const result = {
    total:
      Number(
        paidAmount.toFixed(2)
      ),

    cash: 0,
    upi: 0,
    bankTransfer: 0,
    cheque: 0,
    other: 0,
  };


  if (
    paidAmount <= 0.001
  ) {
    return result;
  }


  const addAmountByMode = (
    rawMode,
    amount
  ) => {
    const safeAmount =
      Math.max(
        0,
        Number(
          amount || 0
        )
      );

    if (
      safeAmount <= 0.001
    ) {
      return;
    }

    const group =
      classifyHistoryPaymentMode(
        rawMode
      );

    if (
      group === "cash"
    ) {
      result.cash +=
        safeAmount;
    }

    else if (
      group === "upi"
    ) {
      result.upi +=
        safeAmount;
    }

    else if (
      group ===
      "bankTransfer"
    ) {
      result.bankTransfer +=
        safeAmount;
    }

    else if (
      group === "cheque"
    ) {
      result.cheque +=
        safeAmount;
    }

    else {
      result.other +=
        safeAmount;
    }
  };


  const payments =
    Array.isArray(
      sale?.payments
    )
      ? sale.payments
      : [];


  let remaining =
    paidAmount;


  // ==================================================
  // SPLIT / MULTIPLE PAYMENT
  // ==================================================

  for (
    const payment of payments
  ) {
    if (
      remaining <= 0.001
    ) {
      break;
    }

    const requestedAmount =
      Math.max(
        0,
        Number(
          payment?.amount || 0
        )
      );

    const amount =
      Math.min(
        requestedAmount,
        remaining
      );

    addAmountByMode(
      payment?.mode ||
        payment?.paymentMode ||
        "",
      amount
    );

    remaining -=
      amount;
  }


  // ==================================================
  // LEGACY SINGLE PAYMENT / FALLBACK
  // ==================================================

  if (
    remaining > 0.001
  ) {
    addAmountByMode(
      sale?.paymentMode ||
        "",
      remaining
    );
  }


  result.cash =
    Number(
      result.cash.toFixed(2)
    );

  result.upi =
    Number(
      result.upi.toFixed(2)
    );

  result.bankTransfer =
    Number(
      result.bankTransfer
        .toFixed(2)
    );

  result.cheque =
    Number(
      result.cheque.toFixed(2)
    );

  result.other =
    Number(
      result.other.toFixed(2)
    );


  return result;
}


// ======================================================
// PAYMENT MODE FILTER
// Works for bill-time payment AND collection receipt.
// ======================================================

function getHistoryPaymentFilterAmount(
  breakup,
  requestedPaymentMode
) {
  const mode =
    String(
      requestedPaymentMode ||
        "ALL"
    )
      .trim()
      .toUpperCase();


  if (
    mode === "ALL"
  ) {
    return Number(
      breakup?.total || 0
    );
  }


  if (
    mode === "CASH"
  ) {
    return Number(
      breakup?.cash || 0
    );
  }


  if (
    mode === "UPI"
  ) {
    return Number(
      breakup?.upi || 0
    );
  }


  if (
    mode ===
      "BANK TRANSFER" ||
    mode ===
      "BANK_TRANSFER"
  ) {
    return Number(
      breakup?.bankTransfer ||
        0
    );
  }


  if (
    mode === "CHEQUE"
  ) {
    return Number(
      breakup?.cheque || 0
    );
  }


  return Number(
    breakup?.other || 0
  );
}

async function calculateHistoryAccountPosition(
  farmId,
  { salesmanId = null, customerId = null, rangeStart = null, rangeEnd = null } = {}
) {
  let totalOutstanding = 0;
  let totalAdvance = 0;
  const customerPositionMap = new Map();

  if (salesmanId && salesmanId !== "UNASSIGNED") {
    const saleQuery = {
      farmId,
      salesmanId,
      createdRole: "salesman",
      status: "POSTED",
    };
    if (customerId) saleQuery.customerId = customerId;
    if (rangeStart && rangeEnd) {
      saleQuery.saleDate = { $gte: rangeStart, $lte: rangeEnd };
    }

    const salesmanSales = await Sale.find(saleQuery)
      .select(
        "saleId saleDate createdAt customerId grandTotal paymentMode paidAmount paymentApplied outstandingAmount advanceCreated advanceUsed"
      )
      .sort({ saleDate: 1, createdAt: 1 })
      .lean();

    const saleIds = salesmanSales
      .map((s) => String(s.saleId || "").trim().toUpperCase())
      .filter(Boolean);
    const saleIdSet = new Set(saleIds);

    let allocatedCollections = [];
    if (saleIds.length > 0) {
      allocatedCollections = await Collection.find({
        farmId,
        status: "POSTED",
        $or: [
          { "allocations.referenceId": { $in: saleIds } },
          { "allocations.saleId": { $in: saleIds } },
        ],
      })
        .select("allocations")
        .lean();
    }

    const collectionAppliedBySale = new Map();
    for (const col of allocatedCollections) {
      for (const alloc of col.allocations || []) {
        const srcType = String(alloc.sourceType || "SALE").trim().toUpperCase();
        if (srcType !== "SALE") continue;
        const sId = String(alloc.referenceId || alloc.saleId || "").trim().toUpperCase();
        if (!sId || !saleIdSet.has(sId)) continue;
        const applied = Math.max(0, Number(alloc.amountApplied || 0));
        collectionAppliedBySale.set(
          sId,
          (collectionAppliedBySale.get(sId) || 0) + applied
        );
      }
    }

    const billsByCust = new Map();
    const advanceByCust = new Map();

    for (const sale of salesmanSales) {
      const cId = String(sale.customerId || "").trim().toUpperCase();
      if (!cId) continue;

      let billOutstanding = Number(sale.outstandingAmount);
      if (!Number.isFinite(billOutstanding)) {
        const billAmt = Math.max(0, Number(sale.grandTotal || 0));
        const paid = Math.max(0, Number(sale.paymentApplied ?? sale.paidAmount ?? 0));
        const advUsed = Math.max(0, Number(sale.advanceUsed || 0));
        billOutstanding = Math.max(0, billAmt - paid - advUsed);
      }

      const sId = String(sale.saleId || "").trim().toUpperCase();
      const allocated = Math.max(0, Number(collectionAppliedBySale.get(sId) || 0));
      const remOutstanding = Math.max(0, billOutstanding - allocated);

      if (!billsByCust.has(cId)) billsByCust.set(cId, []);
      billsByCust.get(cId).push({
        saleId: sId,
        saleDate: sale.saleDate || sale.createdAt,
        remainingOutstanding: remOutstanding,
      });

      if (!advanceByCust.has(cId)) advanceByCust.set(cId, { created: 0, used: 0 });
      const advRow = advanceByCust.get(cId);
      advRow.created += Math.max(0, Number(sale.advanceCreated || 0));
      advRow.used += Math.max(0, Number(sale.advanceUsed || 0));
    }

    const directColQuery = {
      farmId,
      salesmanId,
      status: "POSTED",
      $or: [{ allocations: { $size: 0 } }, { allocations: { $exists: false } }],
    };
    if (customerId) directColQuery.customerId = customerId;
    if (rangeStart && rangeEnd) {
      directColQuery.collectionDate = { $gte: rangeStart, $lte: rangeEnd };
    }

    const unallocatedCollections = await Collection.find(directColQuery)
      .select("customerId amount collectionDate")
      .sort({ collectionDate: 1, createdAt: 1 })
      .lean();

    for (const col of unallocatedCollections) {
      const cId = String(col.customerId || "").trim().toUpperCase();
      if (!cId || !billsByCust.has(cId)) continue;
      const cBills = billsByCust.get(cId);
      let remReceipt = Math.max(0, Number(col.amount || 0));
      const colDate = col.collectionDate ? new Date(col.collectionDate) : null;

      for (const bill of cBills) {
        if (remReceipt <= 0.001) break;
        if (colDate && bill.saleDate && new Date(bill.saleDate) > colDate) continue;
        if (bill.remainingOutstanding <= 0.001) continue;
        const applied = Math.min(remReceipt, bill.remainingOutstanding);
        bill.remainingOutstanding -= applied;
        remReceipt -= applied;
      }
    }

    const allCustIds = new Set([...billsByCust.keys(), ...advanceByCust.keys()]);
    for (const cId of allCustIds) {
      const gross = (billsByCust.get(cId) || []).reduce(
        (sum, b) => sum + Math.max(0, Number(b.remainingOutstanding || 0)),
        0
      );
      const advRow = advanceByCust.get(cId) || { created: 0, used: 0 };
      const netAdv = Math.max(0, Number(advRow.created || 0) - Number(advRow.used || 0));
      const netPosition = Number((gross - netAdv).toFixed(2));

      customerPositionMap.set(cId, {
        grossOutstanding: Number(gross.toFixed(2)),
        advance: Number(netAdv.toFixed(2)),
        netPosition,
        outstanding: netPosition > 0.001 ? netPosition : 0,
        advanceAmount: netPosition < -0.001 ? Math.abs(netPosition) : 0,
      });

      if (netPosition > 0.001) totalOutstanding += netPosition;
      else if (netPosition < -0.001) totalAdvance += Math.abs(netPosition);
    }
  } else {
    const custFilter = { farmId, isActive: true };
    if (customerId) custFilter.customerId = customerId;

    const saleFilter = { farmId, status: "POSTED" };
    if (customerId) saleFilter.customerId = customerId;
    if (rangeStart && rangeEnd) {
      saleFilter.saleDate = { $gte: rangeStart, $lte: rangeEnd };
    }
    if (salesmanId === "UNASSIGNED") {
      saleFilter.$or = [
        { salesmanId: "" },
        { salesmanId: { $exists: false } },
        { salesmanId: null },
      ];
    }

    const outFilter = { farmId, status: "POSTED" };
    if (customerId) outFilter.customerId = customerId;
    if (rangeStart && rangeEnd) {
      outFilter.adjustmentDate = { $gte: rangeStart, $lte: rangeEnd };
    }

    const colFilter = { farmId, status: "POSTED" };
    if (customerId) colFilter.customerId = customerId;
    if (rangeStart && rangeEnd) {
      colFilter.collectionDate = { $gte: rangeStart, $lte: rangeEnd };
    }
    if (salesmanId === "UNASSIGNED") {
      colFilter.$or = [
        { salesmanId: "" },
        { salesmanId: { $exists: false } },
        { salesmanId: null },
      ];
    }

    const [activeCustomers, postedSales, manualOutstandings, postedCollections] =
      await Promise.all([
        Customer.find(custFilter).select("customerId balance").lean(),
        Sale.find(saleFilter)
          .select("saleId saleDate createdAt customerId grandTotal paymentMode paidAmount paymentApplied outstandingAmount advanceUsed")
          .sort({ saleDate: 1, createdAt: 1 })
          .lean(),
        CustomerOutstanding.find(outFilter)
          .select("adjustmentId adjustmentDate createdAt customerId amount")
          .sort({ adjustmentDate: 1, createdAt: 1 })
          .lean(),
        Collection.find(colFilter)
          .select("customerId amount collectionDate createdAt allocations")
          .sort({ collectionDate: 1, createdAt: 1 })
          .lean(),
      ]);

    const sourceMap = new Map();
    const sourcesByCustomer = new Map();

    const addSource = (source) => {
      sourceMap.set(source.key, source);
      if (!sourcesByCustomer.has(source.customerId)) {
        sourcesByCustomer.set(source.customerId, []);
      }
      sourcesByCustomer.get(source.customerId).push(source);
    };

    for (const sale of postedSales) {
      const cId = String(sale.customerId || "").trim().toUpperCase();
      const sId = String(sale.saleId || "").trim().toUpperCase();
      if (!cId || !sId) continue;

      let billOutstanding = Number(sale.outstandingAmount);
      if (!Number.isFinite(billOutstanding)) {
        const grandTotal = Math.max(0, Number(sale.grandTotal || 0));
        const paid = Math.max(0, Number(sale.paymentApplied ?? sale.paidAmount ?? 0));
        const advUsed = Math.max(0, Number(sale.advanceUsed || 0));
        billOutstanding = Math.max(0, grandTotal - paid - advUsed);
      }

      addSource({
        key: `SALE|${sId}`,
        sourceType: "SALE",
        referenceId: sId,
        customerId: cId,
        referenceDate: sale.saleDate || sale.createdAt,
        originalAmount: Math.max(0, Number(sale.grandTotal || 0)),
        remainingOutstanding: billOutstanding,
      });
    }

    for (const item of manualOutstandings) {
      const cId = String(item.customerId || "").trim().toUpperCase();
      const adjId = String(item.adjustmentId || "").trim().toUpperCase();
      if (!cId || !adjId) continue;

      addSource({
        key: `MANUAL_OUTSTANDING|${adjId}`,
        sourceType: "MANUAL_OUTSTANDING",
        referenceId: adjId,
        customerId: cId,
        referenceDate: item.adjustmentDate || item.createdAt,
        originalAmount: Math.max(0, Number(item.amount || 0)),
        remainingOutstanding: Math.max(0, Number(item.amount || 0)),
      });
    }

    for (const sourceList of sourcesByCustomer.values()) {
      sourceList.sort(
        (a, b) => new Date(a.referenceDate || 0) - new Date(b.referenceDate || 0)
      );
    }

    for (const col of postedCollections) {
      const allocs = Array.isArray(col.allocations) ? col.allocations : [];
      if (allocs.length > 0) {
        for (const alloc of allocs) {
          const srcType = String(alloc.sourceType || "SALE").trim().toUpperCase();
          const refId = String(alloc.referenceId || alloc.saleId || "").trim().toUpperCase();
          const src = sourceMap.get(`${srcType}|${refId}`);
          if (!src) continue;
          const applied = Math.max(0, Number(alloc.amountApplied || 0));
          src.remainingOutstanding = Math.max(0, src.remainingOutstanding - applied);
        }
        continue;
      }

      const cId = String(col.customerId || "").trim().toUpperCase();
      if (!cId || !sourcesByCustomer.has(cId)) continue;
      const cSources = sourcesByCustomer.get(cId);
      let remReceipt = Math.max(0, Number(col.amount || 0));
      const colDate = col.collectionDate ? new Date(col.collectionDate) : null;

      for (const src of cSources) {
        if (remReceipt <= 0.001) break;
        if (colDate && src.referenceDate && new Date(src.referenceDate) > colDate) continue;
        if (src.remainingOutstanding <= 0.001) continue;
        const applied = Math.min(remReceipt, src.remainingOutstanding);
        src.remainingOutstanding -= applied;
        remReceipt -= applied;
      }
    }

    if (rangeStart && rangeEnd) {
      for (const source of sourceMap.values()) {
        totalOutstanding += Math.max(0, Number(source.remainingOutstanding || 0));
      }
    } else {
      const customerAdvanceMap = new Map();
      for (const cust of activeCustomers) {
        const cId = String(cust.customerId || "").trim().toUpperCase();
        if (cId) customerAdvanceMap.set(cId, Math.max(0, Number(cust.balance || 0)));
      }

      const allCustIds = new Set([
        ...sourcesByCustomer.keys(),
        ...customerAdvanceMap.keys(),
      ]);

      for (const cId of allCustIds) {
        const gross = (sourcesByCustomer.get(cId) || []).reduce(
          (sum, s) => sum + Math.max(0, Number(s.remainingOutstanding || 0)),
          0
        );
        const adv = customerAdvanceMap.get(cId) || 0;
        const netPosition = Number((gross - adv).toFixed(2));

        customerPositionMap.set(cId, {
          grossOutstanding: Number(gross.toFixed(2)),
          advance: Number(adv.toFixed(2)),
          netPosition,
          outstanding: netPosition > 0.001 ? netPosition : 0,
          advanceAmount: netPosition < -0.001 ? Math.abs(netPosition) : 0,
        });

        if (netPosition > 0.001) totalOutstanding += netPosition;
        else if (netPosition < -0.001) totalAdvance += Math.abs(netPosition);
      }
    }
  }

  return {
    currentOutstanding: Number(totalOutstanding.toFixed(2)),
    currentAdvance: Number(totalAdvance.toFixed(2)),
    customerPositionMap,
  };
}

// ------------------------------------------------------
// 1. GET /api/history/sales-collection-summary
// ------------------------------------------------------
app.get(
  "/api/history/sales-collection-summary",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission("salesView", "collectionView", "reportsView"),
  async (req, res) => {
    try {
      const farmId = req.access.farmId;
      const isAdmin = req.access.isAdmin;
      const isSalesman = req.access.isSalesman;

      // STRICT AUTHORIZATION: never trust salesmanId query param if role is salesman
      let effectiveSalesmanId = null;
      if (isSalesman) {
        effectiveSalesmanId = req.access.salesmanId;
      } else if (
        req.query.salesmanId &&
        String(req.query.salesmanId).trim() !== "ALL" &&
        String(req.query.salesmanId).trim() !== ""
      ) {
        effectiveSalesmanId = String(req.query.salesmanId).trim().toUpperCase();
      }

      const customerId = req.query.customerId
        ? String(req.query.customerId).trim().toUpperCase()
        : null;

      const requestedPaymentMode = req.query.paymentMode
        ? String(req.query.paymentMode).trim().toUpperCase()
        : "ALL";

      // Date Range parsing in IST
      const { rangeStart, rangeEnd } = parseHistoryIstDateRange(
        req.query.startDate,
        req.query.endDate
      );

      if (rangeEnd < rangeStart) {
        return res.status(400).json({
          success: false,
          message: "Start date cannot be after end date.",
        });
      }

      // ----------------------------------------------------
      // SALES QUERY (Only POSTED sales)
      // Note: Payment mode filter applies to Collections only
      // ----------------------------------------------------
      const saleFilter = {
        farmId,
        status: "POSTED",
        saleDate: { $gte: rangeStart, $lte: rangeEnd },
      };

      if (isSalesman) {
        saleFilter.salesmanId = effectiveSalesmanId;
        saleFilter.createdRole = "salesman";
      } else if (effectiveSalesmanId) {
        if (effectiveSalesmanId === "UNASSIGNED") {
          saleFilter.$or = [
            { salesmanId: "" },
            { salesmanId: { $exists: false } },
            { salesmanId: null },
          ];
        } else {
          saleFilter.salesmanId = effectiveSalesmanId;
        }
      }

      if (customerId) {
        saleFilter.customerId = customerId;
      }

      // ----------------------------------------------------
      // COLLECTION QUERY (Only POSTED collections)
      // ----------------------------------------------------
      const collectionFilter = {
        farmId,
        status: "POSTED",
        collectionDate: { $gte: rangeStart, $lte: rangeEnd },
      };

      if (isSalesman) {
        collectionFilter.salesmanId = effectiveSalesmanId;
      } else if (effectiveSalesmanId) {
        if (effectiveSalesmanId === "UNASSIGNED") {
          collectionFilter.$or = [
            { salesmanId: "" },
            { salesmanId: { $exists: false } },
            { salesmanId: null },
          ];
        } else {
          collectionFilter.salesmanId = effectiveSalesmanId;
        }
      }

      if (customerId) {
        collectionFilter.customerId = customerId;
      }

      // Parallel Data Fetching
      const [
        periodSales,
        periodCollections,
        allSalesmen,
        allRoutes,
        allCustomers,
        accountPosition,
        allTimePosition,
      ] = await Promise.all([
      Sale.find(
  saleFilter
)
  .select(
    [
      "saleId",
      "saleNo",
      "saleDate",

      "customerId",
      "customerName",
      "customerMobile",
      "route",

      "grandTotal",

      "paymentMode",
      "payments",
      "paidAmount",
      "paymentApplied",
      "advanceCreated",
      "advanceUsed",
      "outstandingAmount",
      "paymentStatus",

      "salesmanId",
      "salesmanName",
      "createdRole",
    ].join(" ")
  )
  .lean(),
        Collection.find(collectionFilter)
          .select("collectionId receiptNo collectionDate customerId customerName route amount paymentMode salesmanId salesmanName")
          .lean(),
        Salesman.find({ farmId, isActive: true })
          .select("salesmanId name mobile email")
          .sort({ name: 1 })
          .lean(),
        RouteMaster.find({ farmId, isActive: true })
          .select("routeId routeName salesmanId salesmanName")
          .lean(),
        Customer.find({ farmId, isActive: true })
          .select("customerId name route")
          .sort({ name: 1 })
          .lean(),
        calculateHistoryAccountPosition(farmId, {
          salesmanId: effectiveSalesmanId,
          customerId,
          rangeStart,
          rangeEnd,
        }),
        calculateHistoryAccountPosition(farmId, {
          salesmanId: effectiveSalesmanId,
          customerId,
        }),
      ]);

      // Route mapping: Map<salesmanId, Array<{ routeId, routeName }>>
      const routesBySalesman = new Map();
      for (const route of allRoutes) {
        const sId = String(route.salesmanId || "").trim().toUpperCase();
        if (!sId) continue;
        if (!routesBySalesman.has(sId)) routesBySalesman.set(sId, []);
        routesBySalesman.get(sId).push({
          routeId: route.routeId || "",
          routeName: route.routeName || "",
        });
      }

      // ----------------------------------------------------
      // AGGREGATE TOTALS
      // ----------------------------------------------------
      let totalSales = 0;
      for (const sale of periodSales) {
        totalSales += Math.max(0, Number(sale.grandTotal || 0));
      }
      totalSales = Number(totalSales.toFixed(2));
      const salesBillsCount = periodSales.length;

   // ======================================================
// RECEIVED PAYMENT TOTALS
//
// Includes:
//
// 1. Payment received directly while making sale
// 2. Later TRN_COLLECTION receipts
//
// Does NOT alter outstanding.
// ======================================================

let cashCollected = 0;
let upiCollected = 0;
let bankTransferCollected = 0;
let chequeCollected = 0;
let otherCollected = 0;

let filteredCollectionsCount =
  0;

let filteredCollectionAmount =
  0;


// ======================================================
// BILL-TIME PAYMENTS
// ======================================================

for (
  const sale of periodSales
) {
  const billing =
    getSaleBillingPaymentBreakup(
      sale
    );

  cashCollected +=
    billing.cash;

  upiCollected +=
    billing.upi;

  bankTransferCollected +=
    billing.bankTransfer;

  chequeCollected +=
    billing.cheque;

  otherCollected +=
    billing.other;


  const matchingAmount =
    getHistoryPaymentFilterAmount(
      billing,
      requestedPaymentMode
    );


  if (
    matchingAmount > 0.001
  ) {
    filteredCollectionAmount +=
      matchingAmount;

    filteredCollectionsCount +=
      1;
  }
}


// ======================================================
// LATER COLLECTION RECEIPTS
// ======================================================

for (
  const col of
  periodCollections
) {
  const amt =
    Math.max(
      0,
      Number(
        col.amount || 0
      )
    );

  const modeGroup =
    classifyHistoryPaymentMode(
      col.paymentMode
    );


  if (
    modeGroup === "cash"
  ) {
    cashCollected +=
      amt;
  }

  else if (
    modeGroup === "upi"
  ) {
    upiCollected +=
      amt;
  }

  else if (
    modeGroup ===
    "bankTransfer"
  ) {
    bankTransferCollected +=
      amt;
  }

  else if (
    modeGroup === "cheque"
  ) {
    chequeCollected +=
      amt;
  }

  else {
    otherCollected +=
      amt;
  }


  let matchesPaymentModeFilter =
    true;


  if (
    requestedPaymentMode !==
    "ALL"
  ) {
    if (
      requestedPaymentMode ===
        "CASH" &&
      modeGroup !== "cash"
    ) {
      matchesPaymentModeFilter =
        false;
    }

    else if (
      requestedPaymentMode ===
        "UPI" &&
      modeGroup !== "upi"
    ) {
      matchesPaymentModeFilter =
        false;
    }

    else if (
      (
        requestedPaymentMode ===
          "BANK TRANSFER" ||
        requestedPaymentMode ===
          "BANK_TRANSFER"
      ) &&
      modeGroup !==
        "bankTransfer"
    ) {
      matchesPaymentModeFilter =
        false;
    }

    else if (
      requestedPaymentMode ===
        "CHEQUE" &&
      modeGroup !== "cheque"
    ) {
      matchesPaymentModeFilter =
        false;
    }
  }


  if (
    matchesPaymentModeFilter
  ) {
    filteredCollectionAmount +=
      amt;

    filteredCollectionsCount +=
      1;
  }
}


cashCollected =
  Number(
    cashCollected.toFixed(2)
  );

upiCollected =
  Number(
    upiCollected.toFixed(2)
  );

bankTransferCollected =
  Number(
    bankTransferCollected
      .toFixed(2)
  );

chequeCollected =
  Number(
    chequeCollected.toFixed(2)
  );

otherCollected =
  Number(
    otherCollected.toFixed(2)
  );


const totalCollected =
  Number(
    filteredCollectionAmount
      .toFixed(2)
  );


const collectionTransactions =
  filteredCollectionsCount;

      // ----------------------------------------------------
      // SALESMEN SUMMARY (For Admin view or Single Salesman)
      // ----------------------------------------------------
      const salesmanDataMap = new Map();

      // Initialize map for all active salesmen
      for (const sm of allSalesmen) {
        const sId = String(sm.salesmanId || "").trim().toUpperCase();
        salesmanDataMap.set(sId, {
          salesmanId: sId,
          salesmanName: sm.name || "",
          mobile: sm.mobile || "",
          routes: routesBySalesman.get(sId) || [],
          totalSales: 0,
          salesBillsCount: 0,
          totalCollected: 0,
          collectionTransactions: 0,
          cash: 0,
          cheque: 0,
          upi: 0,
          bankTransfer: 0,
          other: 0,
          customerSet: new Set(),
          lastSaleDate: null,
          lastCollectionDate: null,
          currentOutstanding: 0,
          currentAdvance: 0,
        });
      }

      // Unassigned summary (Admin created sales/collections without salesman)
      const unassignedSummary = {
        salesmanId: "UNASSIGNED",
        salesmanName: "Admin / Unassigned",
        routes: [],
        totalSales: 0,
        salesBillsCount: 0,
        totalCollected: 0,
        collectionTransactions: 0,
        cash: 0,
        cheque: 0,
        upi: 0,
        bankTransfer: 0,
        other: 0,
        customerCount: 0,
        lastSaleDate: null,
        lastCollectionDate: null,
      };

      // Populate sales into salesman maps
 // ======================================================
// POPULATE SALES + BILL-TIME COLLECTION
// INTO SALESMAN SUMMARY
// ======================================================

for (
  const sale of periodSales
) {
  const sId =
    String(
      sale.salesmanId || ""
    )
      .trim()
      .toUpperCase();

  const amt =
    Math.max(
      0,
      Number(
        sale.grandTotal || 0
      )
    );

  const cId =
    String(
      sale.customerId || ""
    )
      .trim()
      .toUpperCase();

  const sDate =
    sale.saleDate ||
    null;


  const billing =
    getSaleBillingPaymentBreakup(
      sale
    );

  const matchingBillingAmount =
    getHistoryPaymentFilterAmount(
      billing,
      requestedPaymentMode
    );


  if (
    sId &&
    salesmanDataMap.has(
      sId
    )
  ) {
    const entry =
      salesmanDataMap.get(
        sId
      );

    entry.totalSales +=
      amt;

    entry.salesBillsCount +=
      1;


    entry.cash +=
      billing.cash;

    entry.upi +=
      billing.upi;

    entry.bankTransfer +=
      billing.bankTransfer;

    entry.cheque +=
      billing.cheque;

    entry.other +=
      billing.other;


    if (
      matchingBillingAmount >
      0.001
    ) {
      entry.totalCollected +=
        matchingBillingAmount;

      entry.collectionTransactions +=
        1;

      if (
        sDate &&
        (
          !entry.lastCollectionDate ||
          new Date(
            sDate
          ) >
            new Date(
              entry.lastCollectionDate
            )
        )
      ) {
        entry.lastCollectionDate =
          sDate;
      }
    }


    if (cId) {
      entry.customerSet.add(
        cId
      );
    }


    if (
      sDate &&
      (
        !entry.lastSaleDate ||
        new Date(
          sDate
        ) >
          new Date(
            entry.lastSaleDate
          )
      )
    ) {
      entry.lastSaleDate =
        sDate;
    }
  }

  else {
    unassignedSummary.totalSales +=
      amt;

    unassignedSummary.salesBillsCount +=
      1;


    unassignedSummary.cash +=
      billing.cash;

    unassignedSummary.upi +=
      billing.upi;

    unassignedSummary.bankTransfer +=
      billing.bankTransfer;

    unassignedSummary.cheque +=
      billing.cheque;

    unassignedSummary.other +=
      billing.other;


    if (
      matchingBillingAmount >
      0.001
    ) {
      unassignedSummary.totalCollected +=
        matchingBillingAmount;

      unassignedSummary.collectionTransactions +=
        1;

      if (
        sDate &&
        (
          !unassignedSummary.lastCollectionDate ||
          new Date(
            sDate
          ) >
            new Date(
              unassignedSummary.lastCollectionDate
            )
        )
      ) {
        unassignedSummary.lastCollectionDate =
          sDate;
      }
    }


    if (
      sDate &&
      (
        !unassignedSummary.lastSaleDate ||
        new Date(
          sDate
        ) >
          new Date(
            unassignedSummary.lastSaleDate
          )
      )
    ) {
      unassignedSummary.lastSaleDate =
        sDate;
    }
  }
}
      // Populate collections into salesman maps
      for (const col of periodCollections) {
        const sId = String(col.salesmanId || "").trim().toUpperCase();
        const amt = Math.max(0, Number(col.amount || 0));
        const cId = String(col.customerId || "").trim().toUpperCase();
        const cDate = col.collectionDate || null;
        const modeGroup = classifyHistoryPaymentMode(col.paymentMode);

        let matchesFilter = true;
        if (requestedPaymentMode !== "ALL") {
          if (requestedPaymentMode === "CASH" && modeGroup !== "cash") matchesFilter = false;
          else if (requestedPaymentMode === "UPI" && modeGroup !== "upi") matchesFilter = false;
          else if ((requestedPaymentMode === "BANK TRANSFER" || requestedPaymentMode === "BANK_TRANSFER") && modeGroup !== "bankTransfer") matchesFilter = false;
          else if (requestedPaymentMode === "CHEQUE" && modeGroup !== "cheque") matchesFilter = false;
        }

        if (sId && salesmanDataMap.has(sId)) {
          const entry = salesmanDataMap.get(sId);
          if (modeGroup === "cash") entry.cash += amt;
          else if (modeGroup === "upi") entry.upi += amt;
          else if (modeGroup === "bankTransfer") entry.bankTransfer += amt;
          else if (modeGroup === "cheque") entry.cheque += amt;
          else entry.other += amt;

          if (matchesFilter) {
            entry.totalCollected += amt;
            entry.collectionTransactions += 1;
          }
          if (cId) entry.customerSet.add(cId);
          if (cDate && (!entry.lastCollectionDate || new Date(cDate) > new Date(entry.lastCollectionDate))) {
            entry.lastCollectionDate = cDate;
          }
        } else {
          if (modeGroup === "cash") unassignedSummary.cash += amt;
          else if (modeGroup === "upi") unassignedSummary.upi += amt;
          else if (modeGroup === "bankTransfer") unassignedSummary.bankTransfer += amt;
          else if (modeGroup === "cheque") unassignedSummary.cheque += amt;
          else unassignedSummary.other += amt;

          if (matchesFilter) {
            unassignedSummary.totalCollected += amt;
            unassignedSummary.collectionTransactions += 1;
          }
          if (cDate && (!unassignedSummary.lastCollectionDate || new Date(cDate) > new Date(unassignedSummary.lastCollectionDate))) {
            unassignedSummary.lastCollectionDate = cDate;
          }
        }
      }

      // Calculate individual salesman live account position if admin
      let salesmenSummaryList = [];
      if (isAdmin && !effectiveSalesmanId) {
        const [salesmanPositions, unassignedPos] = await Promise.all([
          Promise.all(
            allSalesmen.map((sm) =>
              calculateHistoryAccountPosition(farmId, {
                salesmanId: String(sm.salesmanId).toUpperCase(),
                rangeStart,
                rangeEnd,
              })
            )
          ),
          calculateHistoryAccountPosition(farmId, {
            salesmanId: "UNASSIGNED",
            rangeStart,
            rangeEnd,
          }),
        ]);

        unassignedSummary.currentOutstanding = unassignedPos.currentOutstanding;
        unassignedSummary.currentAdvance = unassignedPos.currentAdvance;

        allSalesmen.forEach((sm, index) => {
          const sId = String(sm.salesmanId || "").trim().toUpperCase();
          const entry = salesmanDataMap.get(sId);
          const pos = salesmanPositions[index];
          entry.currentOutstanding = pos.currentOutstanding;
          entry.currentAdvance = pos.currentAdvance;
          entry.customerCount = entry.customerSet.size;
          delete entry.customerSet;

          entry.totalSales = Number(entry.totalSales.toFixed(2));
          entry.totalCollected = Number(entry.totalCollected.toFixed(2));
          entry.cash = Number(entry.cash.toFixed(2));
          entry.cheque = Number(entry.cheque.toFixed(2));
          entry.upi = Number(entry.upi.toFixed(2));
          entry.bankTransfer = Number(entry.bankTransfer.toFixed(2));
          entry.other = Number(entry.other.toFixed(2));

          salesmenSummaryList.push(entry);
        });
      } else if (effectiveSalesmanId) {
        const entry = salesmanDataMap.get(effectiveSalesmanId) || {
          salesmanId: effectiveSalesmanId,
          salesmanName: "",
          routes: routesBySalesman.get(effectiveSalesmanId) || [],
          totalSales: 0,
          salesBillsCount: 0,
          totalCollected: 0,
          collectionTransactions: 0,
          cash: 0,
          cheque: 0,
          upi: 0,
          bankTransfer: 0,
          other: 0,
          customerSet: new Set(),
          lastSaleDate: null,
          lastCollectionDate: null,
        };
        entry.currentOutstanding = accountPosition.currentOutstanding;
        entry.currentAdvance = accountPosition.currentAdvance;
        entry.customerCount = entry.customerSet ? entry.customerSet.size : 0;
        delete entry.customerSet;

        entry.totalSales = Number(entry.totalSales.toFixed(2));
        entry.totalCollected = Number(entry.totalCollected.toFixed(2));
        entry.cash = Number(entry.cash.toFixed(2));
        entry.cheque = Number(entry.cheque.toFixed(2));
        entry.upi = Number(entry.upi.toFixed(2));
        entry.bankTransfer = Number(entry.bankTransfer.toFixed(2));
        entry.other = Number(entry.other.toFixed(2));

        salesmenSummaryList.push(entry);
      }

      unassignedSummary.totalSales = Number(unassignedSummary.totalSales.toFixed(2));
      unassignedSummary.totalCollected = Number(unassignedSummary.totalCollected.toFixed(2));
      unassignedSummary.cash = Number(unassignedSummary.cash.toFixed(2));
      unassignedSummary.cheque = Number(unassignedSummary.cheque.toFixed(2));
      unassignedSummary.upi = Number(unassignedSummary.upi.toFixed(2));
      unassignedSummary.bankTransfer = Number(unassignedSummary.bankTransfer.toFixed(2));
      unassignedSummary.other = Number(unassignedSummary.other.toFixed(2));

      return res.status(200).json({
        success: true,
        filters: {
          startDate: rangeStart.toISOString().substring(0, 10),
          endDate: rangeEnd.toISOString().substring(0, 10),
          salesmanId: effectiveSalesmanId || "ALL",
          customerId: customerId || "ALL",
          paymentMode: requestedPaymentMode,
        },
        kpi: {
          totalSales,
          salesBillsCount,
          totalCollected,
          collectionTransactions,
          currentOutstanding: accountPosition.currentOutstanding,
          periodOutstanding: accountPosition.currentOutstanding,
          allTimeOutstanding: allTimePosition.currentOutstanding,
          currentAdvance: accountPosition.currentAdvance,
        },
        paymentModes: {
          cash: cashCollected,
          cheque: chequeCollected,
          upi: upiCollected,
          bankTransfer: bankTransferCollected,
          other: otherCollected,
        },
        salesmenSummary: salesmenSummaryList,
        unassignedSummary:
          unassignedSummary.totalSales > 0 ||
          unassignedSummary.totalCollected > 0 ||
          (unassignedSummary.currentOutstanding && unassignedSummary.currentOutstanding > 0)
            ? unassignedSummary
            : null,
        salesmen: isAdmin
          ? allSalesmen.map((s) => ({
              salesmanId: s.salesmanId,
              name: s.name,
              mobile: s.mobile,
            }))
          : [],
        customers: allCustomers.map((c) => ({
          customerId: c.customerId,
          name: c.name,
          route: c.route,
        })),
      });
    } catch (error) {
      console.error("HISTORY SUMMARY ERROR:", error);
      return res.status(500).json({
        success: false,
        message: "Unable to load sales & collection history summary.",
        error: error.message,
      });
    }
  }
);

// ------------------------------------------------------
// 2. GET /api/history/salesman-details
// ------------------------------------------------------
app.get(
  "/api/history/salesman-details",
  authenticateToken,
  loadAccessContext,
  requireAnyPermission("salesView", "collectionView", "reportsView"),
  async (req, res) => {
    try {
      const farmId = req.access.farmId;
      const isAdmin = req.access.isAdmin;
      const isSalesman = req.access.isSalesman;

      // STRICT AUTHORIZATION:
      let targetSalesmanId = null;
      if (isSalesman) {
        targetSalesmanId = req.access.salesmanId;
      } else {
        targetSalesmanId = req.query.salesmanId
          ? String(req.query.salesmanId).trim().toUpperCase()
          : null;
      }

      if (!targetSalesmanId && !isAdmin) {
        return res.status(400).json({
          success: false,
          message: "Salesman ID is required.",
        });
      }

      const customerId = req.query.customerId
        ? String(req.query.customerId).trim().toUpperCase()
        : null;

      const requestedPaymentMode = req.query.paymentMode
        ? String(req.query.paymentMode).trim().toUpperCase()
        : "ALL";

      const search = req.query.search
        ? String(req.query.search).trim().toLowerCase()
        : "";

      const salesPage = Math.max(1, parseInt(req.query.salesPage, 10) || 1);
      const salesLimit = Math.min(100, Math.max(1, parseInt(req.query.salesLimit, 10) || 20));

      const collectionPage = Math.max(1, parseInt(req.query.collectionPage, 10) || 1);
      const collectionLimit = Math.min(100, Math.max(1, parseInt(req.query.collectionLimit, 10) || 20));

      // Date Range parsing in IST
      const { rangeStart, rangeEnd } = parseHistoryIstDateRange(
        req.query.startDate,
        req.query.endDate
      );

      // Base query for Sales
      const saleFilter = {
        farmId,
        status: "POSTED",
        saleDate: { $gte: rangeStart, $lte: rangeEnd },
      };

      if (targetSalesmanId === "UNASSIGNED") {
        saleFilter.$or = [
          { salesmanId: "" },
          { salesmanId: { $exists: false } },
          { salesmanId: null },
        ];
      } else if (targetSalesmanId) {
        saleFilter.salesmanId = targetSalesmanId;
        if (isSalesman) {
          saleFilter.createdRole = "salesman";
        }
      }

      if (customerId) {
        saleFilter.customerId = customerId;
      }

      // Base query for Collections
      const collectionFilter = {
        farmId,
        status: "POSTED",
        collectionDate: { $gte: rangeStart, $lte: rangeEnd },
      };

      if (targetSalesmanId === "UNASSIGNED") {
        collectionFilter.$or = [
          { salesmanId: "" },
          { salesmanId: { $exists: false } },
          { salesmanId: null },
        ];
      } else if (targetSalesmanId) {
        collectionFilter.salesmanId = targetSalesmanId;
      }

      if (customerId) {
        collectionFilter.customerId = customerId;
      }

      // Fetch Salesman Profile & Routes
      let salesmanProfile = null;
      let assignedRoutes = [];
      if (targetSalesmanId && targetSalesmanId !== "UNASSIGNED") {
        const [smDoc, routeDocs] = await Promise.all([
          Salesman.findOne({ farmId, salesmanId: targetSalesmanId })
            .select("salesmanId name mobile email")
            .lean(),
          RouteMaster.find({ farmId, salesmanId: targetSalesmanId, isActive: true })
            .select("routeId routeName")
            .lean(),
        ]);
        salesmanProfile = smDoc;
        assignedRoutes = routeDocs.map((r) => ({
          routeId: r.routeId || "",
          routeName: r.routeName || "",
        }));
      } else if (targetSalesmanId === "UNASSIGNED") {
        salesmanProfile = {
          salesmanId: "UNASSIGNED",
          name: "Admin / Unassigned",
          mobile: "",
          email: "",
        };
      }

      // Fetch All Matching Sales & Collections for this target within period
      const [allSales, allCollections, accountPos, allTimePos] = await Promise.all([
        Sale.find(
  saleFilter
)
  .select(
    [
      "saleId",
      "saleNo",
      "saleDate",

      "customerId",
      "customerName",
      "customerMobile",
      "route",

      "grandTotal",

      "paymentMode",
      "payments",
      "paidAmount",
      "paymentApplied",
      "advanceCreated",
      "advanceUsed",
      "outstandingAmount",
      "paymentStatus",

      "status",

      "salesmanId",
      "salesmanName",
    ].join(" ")
  )
          .sort({ saleDate: -1, createdAt: -1 })
          .lean(),
        Collection.find(collectionFilter)
          .select("collectionId receiptNo collectionDate customerId customerName customerMobile route amount appliedAmount advanceAmount previousOutstanding remainingOutstanding paymentMode referenceNo remarks status cancelReason salesmanId salesmanName allocations")
          .sort({ collectionDate: -1, createdAt: -1 })
          .lean(),
        calculateHistoryAccountPosition(farmId, {
          salesmanId: targetSalesmanId,
          customerId,
          rangeStart,
          rangeEnd,
        }),
        calculateHistoryAccountPosition(farmId, {
          salesmanId: targetSalesmanId,
          customerId,
        }),
      ]);

      // Calculate Overview KPI
      let totalSales = 0;
      for (const sale of allSales) {
        totalSales += Math.max(0, Number(sale.grandTotal || 0));
      }
      totalSales = Number(totalSales.toFixed(2));
      const salesBillsCount = allSales.length;

 let cash = 0;
let upi = 0;
let bankTransfer = 0;
let cheque = 0;
let other = 0;

let totalCollected = 0;
let collectionTransactions =
  0;


// ======================================================
// PAYMENT RECEIVED AT BILLING
// ======================================================

for (
  const sale of allSales
) {
  const billing =
    getSaleBillingPaymentBreakup(
      sale
    );

  cash +=
    billing.cash;

  upi +=
    billing.upi;

  bankTransfer +=
    billing.bankTransfer;

  cheque +=
    billing.cheque;

  other +=
    billing.other;


  const matchingAmount =
    getHistoryPaymentFilterAmount(
      billing,
      requestedPaymentMode
    );


  if (
    matchingAmount > 0.001
  ) {
    totalCollected +=
      matchingAmount;

    collectionTransactions +=
      1;
  }
}


// ======================================================
// LATER COLLECTION RECEIPTS
// ======================================================

for (
  const col of
  allCollections
) {
  const amt =
    Math.max(
      0,
      Number(
        col.amount || 0
      )
    );

  const modeGroup =
    classifyHistoryPaymentMode(
      col.paymentMode
    );


  if (
    modeGroup === "cash"
  ) {
    cash += amt;
  }

  else if (
    modeGroup === "upi"
  ) {
    upi += amt;
  }

  else if (
    modeGroup ===
    "bankTransfer"
  ) {
    bankTransfer +=
      amt;
  }

  else if (
    modeGroup === "cheque"
  ) {
    cheque += amt;
  }

  else {
    other += amt;
  }


  let matchesFilter =
    true;


  if (
    requestedPaymentMode !==
    "ALL"
  ) {
    if (
      requestedPaymentMode ===
        "CASH" &&
      modeGroup !== "cash"
    ) {
      matchesFilter =
        false;
    }

    else if (
      requestedPaymentMode ===
        "UPI" &&
      modeGroup !== "upi"
    ) {
      matchesFilter =
        false;
    }

    else if (
      (
        requestedPaymentMode ===
          "BANK TRANSFER" ||
        requestedPaymentMode ===
          "BANK_TRANSFER"
      ) &&
      modeGroup !==
        "bankTransfer"
    ) {
      matchesFilter =
        false;
    }

    else if (
      requestedPaymentMode ===
        "CHEQUE" &&
      modeGroup !== "cheque"
    ) {
      matchesFilter =
        false;
    }
  }


  if (
    matchesFilter
  ) {
    totalCollected +=
      amt;

    collectionTransactions +=
      1;
  }
}


totalCollected =
  Number(
    totalCollected.toFixed(2)
  );

cash =
  Number(
    cash.toFixed(2)
  );

upi =
  Number(
    upi.toFixed(2)
  );

bankTransfer =
  Number(
    bankTransfer.toFixed(2)
  );

cheque =
  Number(
    cheque.toFixed(2)
  );

other =
  Number(
    other.toFixed(2)
  );

      // ----------------------------------------------------
      // SALES TAB (with search and pagination)
      // ----------------------------------------------------
      let filteredSales = allSales;
      if (search) {
        filteredSales = filteredSales.filter((s) => {
          const sNo = String(s.saleNo || "").toLowerCase();
          const cName = String(s.customerName || "").toLowerCase();
          const cId = String(s.customerId || "").toLowerCase();
          const rName = String(s.route || "").toLowerCase();
          return (
            sNo.includes(search) ||
            cName.includes(search) ||
            cId.includes(search) ||
            rName.includes(search)
          );
        });
      }

      const totalSalesCount = filteredSales.length;
      const paginatedSales = filteredSales.slice(
        (salesPage - 1) * salesLimit,
        salesPage * salesLimit
      );

      // ----------------------------------------------------
// COLLECTIONS TAB
//
// Unified list:
//
// BILL_PAYMENT
//   Money received while making sale
//
// COLLECTION
//   Money received later through TRN_COLLECTION
// ----------------------------------------------------

const billingReceiptRows =
  allSales
    .filter(
      (sale) =>
        Math.max(
          0,
          Number(
            sale.paidAmount || 0
          )
        ) > 0.001
    )
    .map(
      (sale) => {
        const billing =
          getSaleBillingPaymentBreakup(
            sale
          );

        return {
          sourceType:
            "BILL_PAYMENT",

          collectionId:
            `BILL-${sale.saleId}`,

          receiptNo:
            sale.saleNo ||
            sale.saleId,

          collectionDate:
            sale.saleDate,

          customerId:
            sale.customerId ||
            "",

          customerName:
            sale.customerName ||
            "",

          customerMobile:
            String(
              sale.customerMobile ||
              ""
            ),

          route:
            sale.route ||
            "",

          amount:
            billing.total,

          paymentMode:
            sale.paymentMode ||
            "",

          payments:
            Array.isArray(
              sale.payments
            )
              ? sale.payments
              : [],

          paymentBreakup:
            billing,

          referenceNo:
            sale.saleNo ||
            "",

          remarks:
            "Payment received at billing.",

          status:
            "POSTED",

          salesmanId:
            sale.salesmanId ||
            "",

          salesmanName:
            sale.salesmanName ||
            "",

          saleId:
            sale.saleId ||
            "",

          saleNo:
            sale.saleNo ||
            "",

          billAmount:
            Number(
              sale.grandTotal ||
              0
            ),

          paidAmount:
            billing.total,

          paymentApplied:
            Number(
              (
                sale.paymentApplied !== undefined && sale.paymentApplied !== null
                  ? Number(sale.paymentApplied)
                  : Math.min(billing.total, Number(sale.grandTotal || 0))
              ).toFixed(2)
            ),

          paymentAppliedAtBilling:
            Number(
              (
                sale.paymentApplied !== undefined && sale.paymentApplied !== null
                  ? Number(sale.paymentApplied)
                  : Math.min(billing.total, Number(sale.grandTotal || 0))
              ).toFixed(2)
            ),

          outstandingAmount:
            Number(
              sale.outstandingAmount ||
              0
            ),

          paymentStatus:
            sale.paymentStatus ||
            "",

          advanceCreated:
            Number(
              sale.advanceCreated ||
              0
            ),

          advanceUsed:
            Number(
              sale.advanceUsed ||
              0
            ),

          canDownloadReceipt:
            true,

          canCollectPayment:
            Number(
              sale.outstandingAmount ||
              0
            ) > 0.001,
        };
      }
    );


const laterCollectionRows =
  allCollections.map(
    (collection) => ({
      ...collection,

      sourceType:
        "COLLECTION",

      customerMobile:
        String(
          collection.customerMobile ||
          ""
        ),

      canDownloadReceipt:
        true,
    })
  );


let filteredCollections = [
  ...billingReceiptRows,
  ...laterCollectionRows,
];


// NEWEST FIRST

filteredCollections.sort(
  (a, b) =>
    new Date(
      b.collectionDate || 0
    ) -
    new Date(
      a.collectionDate || 0
    )
);


// PAYMENT MODE FILTER

if (
  requestedPaymentMode !==
  "ALL"
) {
  filteredCollections =
    filteredCollections.filter(
      (item) => {
        if (
          item.sourceType ===
          "BILL_PAYMENT"
        ) {
          return (
            getHistoryPaymentFilterAmount(
              item.paymentBreakup,
              requestedPaymentMode
            ) > 0.001
          );
        }


        const modeGroup =
          classifyHistoryPaymentMode(
            item.paymentMode
          );


        if (
          requestedPaymentMode ===
          "CASH"
        ) {
          return (
            modeGroup ===
            "cash"
          );
        }


        if (
          requestedPaymentMode ===
          "UPI"
        ) {
          return (
            modeGroup ===
            "upi"
          );
        }


        if (
          requestedPaymentMode ===
            "BANK TRANSFER" ||
          requestedPaymentMode ===
            "BANK_TRANSFER"
        ) {
          return (
            modeGroup ===
            "bankTransfer"
          );
        }


        if (
          requestedPaymentMode ===
          "CHEQUE"
        ) {
          return (
            modeGroup ===
            "cheque"
          );
        }


        return true;
      }
    );
}


// SEARCH

if (search) {
  filteredCollections =
    filteredCollections.filter(
      (item) => {
        const rNo =
          String(
            item.receiptNo || ""
          ).toLowerCase();

        const saleNo =
          String(
            item.saleNo || ""
          ).toLowerCase();

        const cName =
          String(
            item.customerName ||
              ""
          ).toLowerCase();

        const cId =
          String(
            item.customerId || ""
          ).toLowerCase();

        const mobile =
          String(
            item.customerMobile ||
              ""
          ).toLowerCase();

        const mode =
          String(
            item.paymentMode || ""
          ).toLowerCase();

        const refNo =
          String(
            item.referenceNo ||
              ""
          ).toLowerCase();


        return (
          rNo.includes(
            search
          ) ||
          saleNo.includes(
            search
          ) ||
          cName.includes(
            search
          ) ||
          cId.includes(
            search
          ) ||
          mobile.includes(
            search
          ) ||
          mode.includes(
            search
          ) ||
          refNo.includes(
            search
          )
        );
      }
    );
}


const totalCollectionsCount =
  filteredCollections.length;


const paginatedCollections =
  filteredCollections.slice(
    (
      collectionPage - 1
    ) *
      collectionLimit,

    collectionPage *
      collectionLimit
  );
      // ----------------------------------------------------
      // CUSTOMER SUMMARY TAB
      // ----------------------------------------------------
      const custSummaryMap = new Map();

      for (const s of allSales) {
        const cId = String(s.customerId || "").trim().toUpperCase();
        if (!cId) continue;
        if (!custSummaryMap.has(cId)) {
          custSummaryMap.set(cId, {
            customerId: cId,
            customerName: s.customerName || "",
            customerMobile: s.customerMobile || "",
            route: s.route || "",
            periodSales: 0,
            salesCount: 0,
            periodCollections: 0,
            collectionCount: 0,
            lastSaleDate: null,
            lastCollectionDate: null,
          });
        }
        const item = custSummaryMap.get(cId);
        item.periodSales += Math.max(0, Number(s.grandTotal || 0));
        item.salesCount += 1;
        const billing =
  getSaleBillingPaymentBreakup(
    s
  );


if (
  billing.total > 0.001
) {
  item.periodCollections +=
    billing.total;

  item.collectionCount +=
    1;


  if (
    s.saleDate &&
    (
      !item.lastCollectionDate ||
      new Date(
        s.saleDate
      ) >
        new Date(
          item.lastCollectionDate
        )
    )
  ) {
    item.lastCollectionDate =
      s.saleDate;
  }
}
        if (s.saleDate && (!item.lastSaleDate || new Date(s.saleDate) > new Date(item.lastSaleDate))) {
          item.lastSaleDate = s.saleDate;
        }
      }

      for (const c of allCollections) {
        const cId = String(c.customerId || "").trim().toUpperCase();
        if (!cId) continue;
        if (!custSummaryMap.has(cId)) {
          custSummaryMap.set(cId, {
            customerId: cId,
            customerName: c.customerName || "",
            customerMobile: c.customerMobile || "",
            route: c.route || "",
            periodSales: 0,
            salesCount: 0,
            periodCollections: 0,
            collectionCount: 0,
            lastSaleDate: null,
            lastCollectionDate: null,
          });
        }
        const item = custSummaryMap.get(cId);
        item.periodCollections += Math.max(0, Number(c.amount || 0));
        item.collectionCount += 1;
        if (c.collectionDate && (!item.lastCollectionDate || new Date(c.collectionDate) > new Date(item.lastCollectionDate))) {
          item.lastCollectionDate = c.collectionDate;
        }
      }

      const customerSummaryList = Array.from(custSummaryMap.values()).map((cust) => {
        const pos = accountPos.customerPositionMap.get(cust.customerId) || {
          outstanding: 0,
          advanceAmount: 0,
        };
        return {
          ...cust,
          periodSales: Number(cust.periodSales.toFixed(2)),
          periodCollections: Number(cust.periodCollections.toFixed(2)),
          currentOutstanding: pos.outstanding || 0,
          currentAdvance: pos.advanceAmount || 0,
        };
      });

      customerSummaryList.sort((a, b) => b.periodSales - a.periodSales);

      // Date-wise sales vs collection trend (if practical)
      const trendMap = new Map();
      for (const s of allSales) {
        const dStr = (s.saleDate || s.createdAt || "").toISOString().substring(0, 10);
        if (!trendMap.has(dStr)) trendMap.set(dStr, { date: dStr, sales: 0, collections: 0 });
        trendMap.get(dStr).sales += Math.max(0, Number(s.grandTotal || 0));
        const billing =
  getSaleBillingPaymentBreakup(
    s
  );

trendMap
  .get(dStr)
  .collections +=
  billing.total;
      }
      for (const c of allCollections) {
        const dStr = (c.collectionDate || c.createdAt || "").toISOString().substring(0, 10);
        if (!trendMap.has(dStr)) trendMap.set(dStr, { date: dStr, sales: 0, collections: 0 });
        trendMap.get(dStr).collections += Math.max(0, Number(c.amount || 0));
      }
      const trendList = Array.from(trendMap.values())
        .sort((a, b) => a.date.localeCompare(b.date))
        .map((t) => ({
          date: t.date,
          sales: Number(t.sales.toFixed(2)),
          collections: Number(t.collections.toFixed(2)),
        }));

      return res.status(200).json({
        success: true,
        salesman: salesmanProfile
          ? {
              salesmanId: salesmanProfile.salesmanId,
              name: salesmanProfile.name,
              mobile: salesmanProfile.mobile,
              routes: assignedRoutes,
            }
          : null,
        overview: {
          totalSales,
          salesBillsCount,
          totalCollected,
          collectionTransactions,
          currentOutstanding: accountPos.currentOutstanding,
          periodOutstanding: accountPos.currentOutstanding,
          allTimeOutstanding: allTimePos.currentOutstanding,
          currentAdvance: accountPos.currentAdvance,
          cash,
          cheque,
          upi,
          bankTransfer,
          other,
          trend: trendList,
        },
        sales: {
          list: paginatedSales,
          totalCount: totalSalesCount,
          page: salesPage,
          limit: salesLimit,
        },
        collections: {
          list: paginatedCollections,
          totalCount: totalCollectionsCount,
          page: collectionPage,
          limit: collectionLimit,
        },
        customerSummary: customerSummaryList,
      });
    } catch (error) {
      console.error("HISTORY SALESMAN DETAILS ERROR:", error);
      return res.status(500).json({
        success: false,
        message: "Unable to load salesman history details.",
        error: error.message,
      });
    }
  }
);


// ======================================================
// SERVER
// ======================================================

const PORT =
  process.env.PORT || 5000;


app.listen(
  PORT,
  () => {

    console.log(
      "-----------------------------------"
    );

    console.log(
      "MilkPro Backend Server"
    );

    console.log(
      `Server running on http://localhost:${PORT}`
    );

    console.log(
      "Collections:"
    );

    console.log(
      "MAS_REGISTER"
    );

    console.log(
      "MAS_SALESMAN"
    );

    console.log(
      "-----------------------------------"
    );
  }
);
