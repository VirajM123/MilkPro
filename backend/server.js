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
        "PURCHASE_CANCEL",
        "PURCHASE_RETURN",
        "SALE",
        "SALE_CANCEL",
        "SALES_RETURN",
        "ALLOCATION_OUT",
        "ALLOCATION_RETURN",
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

    paymentMode: {
      type: String,
      required: true,
      enum: [
        "Cash",
        "UPI",
        "Credit",
        "Bank Transfer",
      ],
      default: "Cash",
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
      ],
      default: "POSTED",
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
    collection: "TRN_ALLOCATION",
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


const Collection = mongoose.model(
  "Collection",
  collectionSchema,
  "TRN_COLLECTION"
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
  role === "salesman" &&
  Array.isArray(user.permissions)
    ? user.permissions
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

app.get(
  "/api/customers",
  authenticateToken,
  async (req, res) => {

    try {

      const farmId =
        req.user.farmId;

      const customers =
        await Customer.find({
          farmId: farmId,
        })
        .sort({
          createdAt: -1,
        });


      return res.status(200).json({
        success: true,

        count:
          customers.length,

        data:
          customers,
      });

    } catch (error) {

      console.error(
        "GET CUSTOMERS ERROR:",
        error
      );

      return res.status(500).json({
        success: false,

        message:
          "Unable to load customers.",
      });
    }
  }
);


// ======================================================
// ADD CUSTOMER
// ======================================================

app.post(
  "/api/customers",
  authenticateToken,
  async (req, res) => {

    try {

      const {
        name,
        mobile,
        route,
        balance,
      } = req.body;


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
        mobile.toString().length !== 10
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Enter a valid 10-digit mobile number.",
        });
      }


      const farmId =
        req.user.farmId;


      // Duplicate mobile only inside same farm
      const existingCustomer =
        await Customer.findOne({
          farmId: farmId,
          mobile:
            mobile.toString().trim(),
        });


      if (existingCustomer) {
        return res.status(409).json({
          success: false,
          message:
            "Customer with this mobile number already exists.",
        });
      }


      const customerId =
        await generateCustomerId();


      const customer =
        await Customer.create({

          farmId:
            farmId,

          customerId:
            customerId,

          name:
            name.trim(),

          mobile:
            mobile.toString().trim(),

          route:
            route?.trim() || "",

          balance:
            Number(balance) || 0,

          isActive:
            true,

          createdBy:
            req.user.userId,
        });


      return res.status(201).json({

        success:
          true,

        message:
          "Customer added successfully.",

        data:
          customer,
      });

    } catch (error) {

      console.error(
        "ADD CUSTOMER ERROR:",
        error
      );


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
  async (req, res) => {

    try {

      const {
        name,
        mobile,
        route,
        balance,
        isActive,
      } = req.body;


      const customer =
        await Customer.findOne({
          _id:
            req.params.id,

          farmId:
            req.user.farmId,
        });


      if (!customer) {
        return res.status(404).json({
          success: false,
          message:
            "Customer not found.",
        });
      }


      if (name !== undefined)
        customer.name = name.trim();

      if (mobile !== undefined)
        customer.mobile =
          mobile.toString().trim();

      if (route !== undefined)
        customer.route =
          route.trim();

      if (balance !== undefined)
        customer.balance =
          Number(balance) || 0;

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

app.delete(
  "/api/customers/:id",
  authenticateToken,
  async (req, res) => {

    try {

      const customer =
        await Customer.findOneAndDelete({
          _id:
            req.params.id,

          farmId:
            req.user.farmId,
        });


      if (!customer) {

        return res.status(404).json({
          success:
            false,

          message:
            "Customer not found.",
        });
      }


      return res.status(200).json({
        success:
          true,

        message:
          "Customer deleted successfully.",
      });

    } catch (error) {

      console.error(
        "DELETE CUSTOMER ERROR:",
        error
      );


      return res.status(500).json({
        success:
          false,

        message:
          "Unable to delete customer.",
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
  async (req, res) => {

    try {

      const farmId =
        req.user.farmId;


      const salesmen =
        await Salesman.find({
          farmId:
            farmId,
        })
          .select(
            "_id role farmId salesmanId name mobile email username businessName permissions isActive createdAt"
          )
          .sort({
            name: 1,
          });


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

                permissions:
                  Array.isArray(
                    salesman.permissions
                  )
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
  async (req, res) => {

    try {

      const farmId =
        req.user.farmId;

      const salesmanId =
        req.params.salesmanId
          .toString()
          .trim()
          .toUpperCase();


      const salesman =
        await Salesman.findOne({
          farmId:
            farmId,

          salesmanId:
            salesmanId,
        })
          .select(
            "_id role farmId salesmanId name mobile email username businessName permissions isActive createdAt"
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

          permissions:
            Array.isArray(
              salesman.permissions
            )
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
  async (req, res) => {

    try {

      // ================================================
      // ADMIN ONLY
      // ================================================

      if (
        req.user.role !== "admin"
      ) {

        return res.status(403).json({
          success:
            false,

          message:
            "Only administrator can change salesman access.",
        });
      }


      const farmId =
        req.user.farmId;


      const salesmanId =
        req.params.salesmanId
          .toString()
          .trim()
          .toUpperCase();


      const {
        permissions,
      } = req.body;


      // ================================================
      // VALIDATE ARRAY
      // ================================================

      if (
        !Array.isArray(
          permissions
        )
      ) {

        return res.status(400).json({
          success:
            false,

          message:
            "Permissions must be an array.",
        });
      }


      // ================================================
      // NORMALIZE / REMOVE DUPLICATES
      // ================================================

      const normalizedPermissions =
        [
          ...new Set(
            permissions
              .map(
                (permission) =>
                  permission
                    ?.toString()
                    .trim()
              )
              .filter(
                (permission) =>
                  permission
              )
          ),
        ];


      // ================================================
      // BLOCK UNKNOWN PERMISSIONS
      // ================================================

      const invalidPermissions =
        normalizedPermissions.filter(
          (permission) =>
            !VALID_SALESMAN_PERMISSIONS.includes(
              permission
            )
        );


      if (
        invalidPermissions.length >
        0
      ) {

        return res.status(400).json({
          success:
            false,

          message:
            `Invalid permission: ${invalidPermissions.join(", ")}`,
        });
      }


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


      salesman.permissions =
        normalizedPermissions;


      await salesman.save();


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

          permissions:
            salesman.permissions,

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
// GET ROUTES
// ======================================================

app.get(
  "/api/routes",
  authenticateToken,
  async (req, res) => {
    try {
      const routes =
        await RouteMaster.find({
          farmId: req.user.farmId,
        })
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
// GET PRODUCTS
// ======================================================

app.get(
  "/api/products",
  authenticateToken,
  async (req, res) => {
    try {
      const products = await Product.find({
        farmId: req.user.farmId,
      }).sort({
        createdAt: -1,
      });

      return res.status(200).json({
        success: true,
        count: products.length,
        data: products,
      });

    } catch (error) {
      console.error(
        "GET PRODUCTS ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message: "Unable to load products.",
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
// GET SUPPLIERS
// ======================================================

app.get(
  "/api/suppliers",
  authenticateToken,
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
// GET PURCHASES
// ======================================================

app.get(
  "/api/purchases",
  authenticateToken,
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
          // PAYMENT MODE
          // ==================================================

          const allowedPaymentModes = [
            "Cash",
            "UPI",
            "Credit",
            "Bank Transfer",
          ];


          const finalPaymentMode =
            allowedPaymentModes.includes(
              paymentMode
            )
              ? paymentMode
              : "Cash";


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
          // ADMIN ONLY
          // DEDUCT MAIN GODOWN STOCK
          // ==================================================

          if (role === "admin") {

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
  async (req, res) => {

    const session =
      await mongoose.startSession();

    try {

      let cancelledSale =
        null;


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
          // IDENTIFY STOCK SOURCE OF ORIGINAL SALE
          // ==================================================

          const isSalesmanSale =
            sale.createdRole ===
            "salesman";


          // ==================================================
          // ADMIN / MAIN STOCK SALE
          // RESTORE MAIN PRODUCT STOCK
          // ==================================================

          if (!isSalesmanSale) {

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


              const product =
                await Product.findOne({
                  farmId:
                    farmId,

                  productId:
                    line.productId,
                }).session(session);


              if (!product) {

                const error =
                  new Error(
                    `Product ${line.productName} not found.`
                  );

                error.statusCode = 404;

                throw error;
              }


              // ============================================
              // ADD MAIN STOCK BACK
              // ============================================

              const updateResult =
                await Product.updateOne(
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
                    `Unable to restore stock for ${line.productName}.`
                  );

                error.statusCode = 409;

                throw error;
              }


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
          // MARK SALE CANCELLED
          // ==================================================

          sale.status =
            "CANCELLED";

          sale.cancelledBy =
            userId || "";

          sale.cancelledAt =
            new Date();

          sale.updatedAt =
            new Date();


          await sale.save({
            session:
              session,
          });


          cancelledSale =
            sale;
        }
      );


      return res.status(200).json({

        success:
          true,

        message:
          cancelledSale?.createdRole ===
          "salesman"
            ? "Salesman sale cancelled successfully."
            : "Sale cancelled and stock restored successfully.",

        data:
          cancelledSale,
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

  createdRole:
    "salesman",
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


      return res.status(200).json({

        success:
          true,

        count:
          enrichedByIndex.length,

        data:
          enrichedByIndex,
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
            customerId,
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


          const normalizedCustomerId =
            customerId
              ?.toString()
              .trim()
              .toUpperCase() ||
            "";


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
          // OPTIONAL CUSTOMER
          // ============================================

          let customer =
            null;


          if (
            normalizedCustomerId
          ) {

            customer =
              await Customer.findOne({
                farmId:
                  farmId,

                customerId:
                  normalizedCustomerId,

                isActive:
                  true,
              }).session(
                session
              );


            if (!customer) {

              const error =
                new Error(
                  "Selected customer not found."
                );

              error.statusCode =
                404;

              throw error;
            }
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

                  customerId:
                    customer
                      ? customer.customerId
                      : "",

                  customerName:
                    customer
                      ? customer.name
                      : "",

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
                    req.user.userId ||
                    "",
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
      // SALESMAN SALES
      //
      // IMPORTANT:
      // Current admin sales are NOT deducted here.
      //
      // Later when Salesman Sale is connected,
      // only sales created by this salesman will be
      // deducted from his allocated stock.
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


        products.push(row);
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

        paymentMode:
          "Credit",
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
            "saleId saleNo saleDate customerId customerName customerMobile route grandTotal salesmanId salesmanName"
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
            "customerId amount paymentMode collectionDate salesmanId salesmanName"
          )
          .sort({
            collectionDate: 1,
            createdAt: 1,
          })
          .lean();


      // ==================================================
      // CUSTOMER MAP
      // ==================================================

      const customerMap =
        new Map();


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

              totalCollected:
                0,

              outstanding:
                0,

              lastPaymentMode:
                "",

              lastCollectionDate:
                null,

              billCount:
                0,
            }
          );
        }


        const row =
          customerMap.get(
            customerId
          );


        row.totalCreditSales +=
          Number(
            sale.grandTotal
          ) || 0;


        row.billCount +=
          1;


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
      // SUBTRACT COLLECTIONS
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


        row.totalCollected +=
          Number(
            collection.amount
          ) || 0;


        row.lastPaymentMode =
          collection.paymentMode || "";


        row.lastCollectionDate =
          collection.collectionDate ||
          null;
      }


      // ==================================================
      // FINAL RESULT
      // ==================================================

      const data = [];


      for (
        const row of
        customerMap.values()
      ) {

        row.totalCreditSales =
          Number(
            row.totalCreditSales
              .toFixed(2)
          );


        row.totalCollected =
          Number(
            row.totalCollected
              .toFixed(2)
          );


        row.outstanding =
          Number(
            Math.max(
              0,
              row.totalCreditSales -
              row.totalCollected
            ).toFixed(2)
          );


        // ================================================
        // PAYMENT STATUS
        // ================================================

        if (
          row.outstanding <= 0
        ) {

          row.status =
            "PAID";
        }

        else if (
          row.totalCollected > 0
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

app.post(
  "/api/collections",
  authenticateToken,
  async (req, res) => {

    try {

      const farmId =
        req.user.farmId;

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


      const normalizedCustomerId =
        (
          customerId || ""
        )
          .toString()
          .trim()
          .toUpperCase();


      const collectionAmount =
        Number(
          amount
        ) || 0;


      // ==================================================
      // VALIDATION
      // ==================================================

      if (
        !normalizedCustomerId
      ) {

        return res.status(400).json({
          success: false,
          message:
            "Customer is required.",
        });
      }


      if (
        collectionAmount <= 0
      ) {

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

          farmId:
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


      // ==================================================
      // SALESMAN DETAILS
      // ==================================================

      let salesmanId = "";
      let salesmanName = "";


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


        salesmanId =
          salesman.salesmanId;

        salesmanName =
          salesman.name;
      }


      else if (
        role !== "admin"
      ) {

        return res.status(403).json({
          success: false,
          message:
            "You are not allowed to save collections.",
        });
      }


      // ==================================================
      // CALCULATE CUSTOMER CREDIT SALES
      // ==================================================

      const saleFilter = {

        farmId:
          farmId,

        customerId:
          normalizedCustomerId,

        status:
          "POSTED",

        paymentMode:
          "Credit",
      };


      if (
        role === "salesman"
      ) {

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
            "grandTotal"
          )
          .lean();


      let totalCreditSales =
        0;


      for (
        const sale of sales
      ) {

        totalCreditSales +=
          Number(
            sale.grandTotal
          ) || 0;
      }


      // ==================================================
      // PREVIOUS POSTED COLLECTIONS
      // ==================================================

      const previousCollectionFilter = {

        farmId:
          farmId,

        customerId:
          normalizedCustomerId,

        status:
          "POSTED",
      };


      if (
        role === "salesman"
      ) {

        previousCollectionFilter.salesmanId =
          salesmanId;
      }


      const previousCollections =
        await Collection.find(
          previousCollectionFilter
        )
          .select(
            "amount"
          )
          .lean();


      let alreadyCollected =
        0;


      for (
        const item of
        previousCollections
      ) {

        alreadyCollected +=
          Number(
            item.amount
          ) || 0;
      }


      // ==================================================
      // OUTSTANDING
      // ==================================================

      const outstanding =
        Math.max(
          0,
          totalCreditSales -
          alreadyCollected
        );


      if (
        outstanding <= 0
      ) {

        return res.status(409).json({

          success:
            false,

          message:
            "This customer has no pending outstanding.",
        });
      }


      if (
        collectionAmount >
        outstanding + 0.001
      ) {

        return res.status(400).json({

          success:
            false,

          message:
            `Collection amount cannot exceed outstanding ₹${outstanding.toFixed(2)}.`,
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
      // SAVE
      // ==================================================

      const savedCollection =
        await Collection.create({

          farmId:
            farmId,

          collectionId:
            collectionId,

          receiptNo:
            receiptNo,

          collectionDate:
            collectionDate
              ? new Date(
                  collectionDate
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

          salesmanId:
            salesmanId,

          salesmanName:
            salesmanName,

          amount:
            Number(
              collectionAmount
                .toFixed(2)
            ),

          paymentMode:
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
            req.user.userId ||
            "",

          createdRole:
            role,

          createdAt:
            new Date(),

          updatedAt:
            new Date(),
        });


      const newOutstanding =
        Math.max(
          0,
          outstanding -
          collectionAmount
        );


      return res.status(201).json({

        success:
          true,

        message:
          "Collection saved successfully.",

        data: {
          ...savedCollection.toObject(),

          previousOutstanding:
            Number(
              outstanding.toFixed(2)
            ),

          remainingOutstanding:
            Number(
              newOutstanding.toFixed(2)
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

        return res.status(409).json({
          success: false,
          message:
            "Duplicate collection or receipt number detected.",
        });
      }


      return res.status(500).json({

        success:
          false,

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

app.put(
  "/api/collections/:collectionId/cancel",
  authenticateToken,
  async (req, res) => {

    try {

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

        return res.status(400).json({
          success: false,
          message:
            "Collection ID is required.",
        });
      }


      const filter = {

        farmId:
          farmId,

        collectionId:
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
            "You are not allowed to cancel collections.",
        });
      }


      const collection =
        await Collection.findOne(
          filter
        );


      if (!collection) {

        return res.status(404).json({
          success: false,
          message:
            "Collection not found.",
        });
      }


      if (
        collection.status ===
        "CANCELLED"
      ) {

        return res.status(409).json({
          success: false,
          message:
            "Collection is already cancelled.",
        });
      }


      collection.status =
        "CANCELLED";

      collection.cancelledBy =
        req.user.userId ||
        "";

      collection.cancelledAt =
        new Date();

      collection.updatedAt =
        new Date();


      await collection.save();


      return res.status(200).json({

        success:
          true,

        message:
          "Collection cancelled successfully.",

        data:
          collection,
      });


    } catch (error) {

      console.error(
        "CANCEL COLLECTION ERROR:",
        error
      );


      return res.status(500).json({

        success:
          false,

        message:
          "Unable to cancel collection.",

        error:
          error.message,
      });
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
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      // ================================================
      // PAYMENT IS CURRENTLY ADMIN SIDE
      // ================================================

      if (
        req.user.role !== "admin"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Only admin can view supplier payments.",
        });
      }

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
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      if (
        req.user.role !== "admin"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Only admin can record supplier payments.",
        });
      }

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
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      if (
        req.user.role !== "admin"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Only admin can view supplier payments.",
        });
      }

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
  async (req, res) => {
    try {
      const farmId =
        req.user.farmId;

      if (
        req.user.role !== "admin"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Only admin can cancel supplier payments.",
        });
      }

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
              "customerId name mobile route"
            )
            .lean();

        if (!customer) {
          return res.status(404).json({
            success: false,
            message:
              "Customer not found.",
          });
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
      "saleId saleNo saleDate grandTotal paymentMode"
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
              "collectionId receiptNo collectionDate amount paymentMode referenceNo"
            )
            .lean();


        const entries = [];

        let totalDebit = 0;
        let totalCredit = 0;


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
  const amount =
    Number(
      sale.grandTotal
    ) || 0;

  const paymentMode =
    (
      sale.paymentMode ||
      "Credit"
    )
      .toString()
      .trim();

  const isCredit =
    paymentMode
      .toLowerCase() ===
    "credit";


  // Only credit sale increases
  // customer outstanding
  if (isCredit) {
    totalDebit +=
      amount;
  }


  entries.push({
    id:
      sale.saleId,

    referenceNo:
      sale.saleNo,

    date:
      sale.saleDate,

    type:
      "SALE",

    title:
      isCredit
        ? "Credit Sale"
        : `${paymentMode} Sale`,

    // Actual transaction amount
    amount:
      amount,

    // Only credit affects balance
    debit:
      isCredit
        ? amount
        : 0,

    credit:
      0,

    paymentMode:
      paymentMode,

    reference:
      "",

    affectsBalance:
      isCredit,
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
    collection.paymentMode ||
    "",

  reference:
    collection.referenceNo ||
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

            balance:
              Number(
                (
                  totalDebit -
                  totalCredit
                ).toFixed(2)
              ),

            transactions:
              entries.reverse(),
          },
        });
      }


      // ==================================================
      // SUPPLIER LEDGER
      // CREDIT PURCHASES + PAYMENTS
      // ==================================================

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
        saleFilter.salesmanId =
          userId;
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
                    .where(
                      product =>
                        (
                          Number(
                            product.stock
                          ) || 0
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