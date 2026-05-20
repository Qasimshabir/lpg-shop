# Cylinder Tracking System Documentation

## Overview

The LPG Shop application implements a comprehensive cylinder tracking system that manages cylinder inventory across three states: **Empty**, **Filled**, and **Sold**. The system uses a dual-table approach with both a dedicated `cylinders` table for individual cylinder tracking and a `cylinder_states` JSONB field in the `lpg_products` table for aggregate inventory management.

---

## 1. Database Schema

### 1.1 Primary Tables

#### **cylinders** Table
Tracks individual cylinders with detailed information:

```sql
CREATE TABLE cylinders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  serial_number VARCHAR(100) UNIQUE NOT NULL,
  product_id UUID REFERENCES lpg_products(id) ON DELETE SET NULL,
  customer_id UUID REFERENCES lpg_customers(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'available',
  last_refill_date DATE,
  next_inspection_date DATE,
  manufacturing_date DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_cylinders_serial ON cylinders(serial_number);
CREATE INDEX idx_cylinders_customer ON cylinders(customer_id);
```

**Key Fields:**
- `serial_number`: Unique identifier for each physical cylinder
- `product_id`: Links to the product type (11.8kg, 15kg, 45.4kg)
- `customer_id`: Tracks which customer currently has the cylinder
- `status`: Current state ('available', 'in_use', 'maintenance', 'retired')
- `next_inspection_date`: Safety compliance tracking

#### **lpg_products** Table (Cylinder-Related Fields)
Manages product-level cylinder inventory with aggregate states:

```sql
ALTER TABLE lpg_products
  ADD COLUMN product_type VARCHAR(50) DEFAULT 'cylinder',
  ADD COLUMN cylinder_type VARCHAR(50),
  ADD COLUMN capacity DECIMAL(10, 2),
  ADD COLUMN cylinder_states JSONB DEFAULT '{"empty": 0, "filled": 0, "sold": 0}'::jsonb,
  ADD COLUMN stock_quantity INTEGER DEFAULT 0,
  ADD COLUMN cost_price DECIMAL(10, 2) DEFAULT 0,
  ADD COLUMN deposit_amount DECIMAL(10, 2) DEFAULT 0,
  ADD COLUMN refill_price DECIMAL(10, 2) DEFAULT 0;
```

**Cylinder States JSONB Structure:**
```json
{
  "empty": 10,    // Cylinders returned by customers, awaiting refill
  "filled": 25,   // Cylinders ready for sale/delivery
  "sold": 5       // Cylinders currently with customers
}
```

**Key Relationships:**
- `stock_quantity` = `empty` + `filled` (total cylinders in inventory)
- `sold` tracks cylinders currently with customers (not in stock)

#### **cylinder_refill_history** Table
Tracks refill transactions:

```sql
CREATE TABLE cylinder_refill_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES lpg_customers(id) ON DELETE CASCADE,
  cylinder_id UUID REFERENCES cylinders(id) ON DELETE SET NULL,
  refill_date DATE NOT NULL,
  quantity DECIMAL(10, 2),
  amount DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 1.2 Related Tables

#### **lpg_sales** Table
Records sales transactions:
- Links to customers via `customer_id`
- Contains `invoice_number`, `total_amount`, `payment_method`
- Tracks `delivery_status` and `payment_status`

#### **sale_items** Table
Individual line items in sales:
- Links to `lpg_sales` via `sale_id`
- Links to `lpg_products` via `product_id`
- Contains `quantity`, `unit_price`, `subtotal`

---

## 2. Backend Implementation

### 2.1 Cylinder Controller (`server/controllers/cylinderController.js`)

#### **Register Cylinder**
```javascript
POST /api/cylinders
```
Registers a new physical cylinder in the system.

**Request Body:**
```json
{
  "serial_number": "CYL-2024-001234",
  "product_id": "uuid",
  "customer_id": "uuid",
  "status": "available",
  "manufacturing_date": "2024-01-15"
}
```

#### **Get All Cylinders**
```javascript
GET /api/cylinders?status=available&customer_id=uuid
```
Retrieves cylinders with optional filtering by status or customer.

**Response:**
```json
{
  "success": true,
  "count": 10,
  "data": [
    {
      "id": "uuid",
      "serial_number": "CYL-2024-001234",
      "status": "available",
      "lpg_products": { "name": "HP Gas 11.8kg", "weight": 11.8 },
      "lpg_customers": { "name": "John Doe" }
    }
  ]
}
```

#### **Update Cylinder Status**
```javascript
PUT /api/cylinders/:id/status
```
Updates the status of a specific cylinder.

#### **Get Cylinders Due for Inspection**
```javascript
GET /api/cylinders/due-inspection
```
Returns cylinders that need safety inspection based on `next_inspection_date`.

### 2.2 Product Controller (`server/controllers/lpgProductController.js`)

#### **Get Cylinder Summary**
```javascript
GET /api/products/cylinder-summary
```
Aggregates cylinder inventory by type.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "11.8kg",
      "type": "11.8kg",
      "totalEmpty": 10,
      "totalFilled": 25,
      "totalSold": 5,
      "totalStock": 35,
      "products": 2
    }
  ]
}
```

**Implementation Logic:**
```javascript
const summary = products.reduce((acc, product) => {
  let key = product.cylinder_type || `${product.capacity || product.weight}kg`;
  
  if (!acc[key]) {
    acc[key] = {
      _id: key,
      type: key,
      totalEmpty: 0,
      totalFilled: 0,
      totalSold: 0,
      totalStock: 0,
      products: 0
    };
  }
  
  const states = product.cylinder_states;
  acc[key].totalEmpty += states.empty || 0;
  acc[key].totalFilled += states.filled || 0;
  acc[key].totalSold += states.sold || 0;
  acc[key].totalStock = acc[key].totalEmpty + acc[key].totalFilled + acc[key].totalSold;
  acc[key].products += 1;
  
  return acc;
}, {});
```

#### **Update Cylinder State**
```javascript
PUT /api/products/:id/cylinder-state
```
Updates specific cylinder state counts.

**Request Body:**
```json
{
  "state": "filled",
  "quantity": 5,
  "operation": "add"  // "add", "subtract", or "set"
}
```

**Implementation:**
```javascript
const cylinderStates = product.cylinder_states || { empty: 0, filled: 0, sold: 0 };

if (operation === 'add') {
  cylinderStates[state] = (cylinderStates[state] || 0) + quantity;
} else if (operation === 'subtract') {
  cylinderStates[state] = Math.max(0, (cylinderStates[state] || 0) - quantity);
} else if (operation === 'set') {
  cylinderStates[state] = quantity;
}

// Update stock_quantity (empty + filled)
const newStockQuantity = (cylinderStates.empty || 0) + (cylinderStates.filled || 0);
```

#### **Exchange Cylinder**
```javascript
PUT /api/products/:id/exchange
```
Handles cylinder exchange: converts empty cylinders to filled.

**Request Body:**
```json
{
  "quantity": 10
}
```

**Implementation:**
```javascript
// Check if enough empty cylinders available
if ((cylinderStates.empty || 0) < quantity) {
  return error('Insufficient empty cylinders');
}

// Exchange: decrease empty, increase filled
cylinderStates.empty -= quantity;
cylinderStates.filled += quantity;

// Stock quantity remains the same (empty + filled)
const newStockQuantity = cylinderStates.empty + cylinderStates.filled;
```

### 2.3 Sales Controller (`server/controllers/lpgSalesController.js`)

#### **Create Sale**
```javascript
POST /api/sales
```
Creates a new sale and updates product stock.

**Current Implementation:**
```javascript
// Update product stock (SIMPLE DECREMENT)
for (let item of items) {
  const { data: product } = await supabase
    .from('lpg_products')
    .select('stock_quantity')
    .eq('id', item.product_id)
    .single();
  
  if (product) {
    await supabase
      .from('lpg_products')
      .update({ stock_quantity: product.stock_quantity - item.quantity })
      .eq('id', item.product_id);
  }
}
```

**⚠️ ISSUE IDENTIFIED:** The sales controller does NOT update `cylinder_states`. It only decrements `stock_quantity`, which can cause inconsistencies.

---

## 3. Frontend Implementation

### 3.1 Cylinder Tracking Screen (`app/lib/screens/cylinders/cylinder_tracking_screen.dart`)

#### **Purpose**
Displays aggregate cylinder inventory grouped by type with visual indicators.

#### **Key Features**
1. **Overview Card**: Shows total empty, filled, and sold cylinders across all types
2. **Type-Specific Cards**: Breaks down inventory by cylinder type (11.8kg, 15kg, 45.4kg)
3. **Progress Indicators**: Visual representation of filled vs total cylinders
4. **Filtering**: Filter by all, filled only, empty only, or sold only
5. **Add Cylinder**: Register new cylinders for tracking

#### **Data Loading**
```dart
Future<void> _loadCylinders() async {
  final summary = await LPGApiService.getCylinderSummary();
  setState(() {
    _cylinderSummary = summary;
  });
}
```

#### **UI Components**

**Overview Card:**
```dart
Widget _buildOverviewCard() {
  int totalEmpty = 0;
  int totalFilled = 0;
  int totalSold = 0;

  for (var data in _cylinderSummary) {
    totalEmpty += (data['totalEmpty'] ?? 0) as int;
    totalFilled += (data['totalFilled'] ?? 0) as int;
    totalSold += (data['totalSold'] ?? 0) as int;
  }

  int total = totalEmpty + totalFilled + totalSold;
  
  // Displays stat boxes with color coding:
  // - Empty: Gray (LPGColors.cylinderEmpty)
  // - Filled: Green (LPGColors.cylinderFilled)
  // - Sold: Blue (LPGColors.cylinderSold)
}
```

**Cylinder Type Card:**
```dart
Widget _buildCylinderTypeCard(Map<String, dynamic> data) {
  final cylinderType = data['_id'] ?? 'Unknown';
  final totalEmpty = data['totalEmpty'] ?? 0;
  final totalFilled = data['totalFilled'] ?? 0;
  final totalSold = data['totalSold'] ?? 0;
  final total = totalEmpty + totalFilled + totalSold;
  
  // Shows:
  // - Cylinder type icon
  // - Total units
  // - Breakdown by state
  // - Progress bar (filled/total)
}
```

### 3.2 Add Product Screen (`app/lib/screens/products/add_product_screen.dart`)

#### **Cylinder States Section**
When adding a cylinder product, users specify initial inventory:

```dart
Widget _buildCylinderStatesSection() {
  return Card(
    child: Column(
      children: [
        TextFormField(
          controller: _emptyController,
          decoration: InputDecoration(
            labelText: 'Empty Cylinders',
            prefixIcon: Icon(Icons.propane_tank, color: LPGColors.cylinderEmpty),
          ),
        ),
        TextFormField(
          controller: _filledController,
          decoration: InputDecoration(
            labelText: 'Filled Cylinders',
            prefixIcon: Icon(Icons.propane_tank, color: LPGColors.cylinderFilled),
          ),
        ),
      ],
    ),
  );
}
```

#### **Product Creation**
```dart
if (_productType == 'cylinder') {
  productData['cylinderStates'] = {
    'empty': int.parse(_emptyController.text),
    'filled': int.parse(_filledController.text),
    'sold': 0,
  };
}
```

### 3.3 Create Sale Screen (`app/lib/screens/sales/create_sale_screen.dart`)

#### **Current Implementation**
The sale screen allows selecting products and quantities but does NOT explicitly update cylinder states.

**Sale Creation:**
```dart
final saleData = {
  'customer_id': _selectedCustomer?.id,
  'items': _cartItems.map((item) => {
    'product_id': item['product'],
    'quantity': item['quantity'],
    'unit_price': item['unitPrice'],
  }).toList(),
  'payment_method': _paymentMethod,
  'payment_status': _paymentMethod == 'Credit' ? 'pending' : 'paid',
};

await LPGApiService.createLPGSale(saleData);
```

**⚠️ ISSUE:** The frontend relies on the backend to update inventory, but the backend only updates `stock_quantity`, not `cylinder_states`.

### 3.4 Product Model (`app/lib/models/lpg_product.dart`)

#### **CylinderStates Class**
```dart
class CylinderStates {
  final int empty;
  final int filled;
  final int sold;

  CylinderStates({
    required this.empty,
    required this.filled,
    required this.sold,
  });

  factory CylinderStates.fromJson(Map<String, dynamic> json) {
    return CylinderStates(
      empty: json['empty'] ?? 0,
      filled: json['filled'] ?? 0,
      sold: json['sold'] ?? 0,
    );
  }

  int get total => empty + filled;
}
```

#### **Computed Properties**
```dart
int get totalCylinders {
  if (productType == 'cylinder' && cylinderStates != null) {
    return cylinderStates!.empty + cylinderStates!.filled;
  }
  return 0;
}

int get availableCylinders {
  if (productType == 'cylinder' && cylinderStates != null) {
    return cylinderStates!.filled;
  }
  return stock;
}

String get stockStatus {
  final available = productType == 'cylinder' ? availableCylinders : stock;
  
  if (available == 0) return 'Out of Stock';
  if (available <= minStock) return 'Low Stock';
  if (available >= maxStock) return 'Overstock';
  return 'In Stock';
}
```

---

## 4. Data Flow

### 4.1 Product Creation Flow

```
User Input (Add Product Screen)
  ↓
  Empty: 10, Filled: 25
  ↓
API Request: POST /api/products
  ↓
Backend (lpgProductController.createLPGProduct)
  ↓
Database Insert:
  - cylinder_states: {"empty": 10, "filled": 25, "sold": 0}
  - stock_quantity: 35 (empty + filled)
  ↓
Response: Product created
  ↓
Frontend: Navigate back to products list
```

### 4.2 Cylinder Exchange Flow

```
User Action: Exchange 5 empty cylinders
  ↓
API Request: PUT /api/products/:id/exchange
  Body: { "quantity": 5 }
  ↓
Backend (lpgProductController.exchangeCylinder)
  ↓
Validation: Check if empty >= 5
  ↓
Update cylinder_states:
  - empty: 10 → 5
  - filled: 25 → 30
  - sold: 0 (unchanged)
  ↓
Update stock_quantity: 35 (unchanged, still empty + filled)
  ↓
Response: Updated product
  ↓
Frontend: Refresh cylinder tracking screen
```

### 4.3 Sale Creation Flow (CURRENT - WITH ISSUE)

```
User Action: Create sale with 3 cylinders
  ↓
API Request: POST /api/sales
  Body: {
    items: [{ product_id, quantity: 3, unit_price }]
  }
  ↓
Backend (lpgSalesController.createLPGSale)
  ↓
Create sale record
  ↓
Create sale_items records
  ↓
Update stock_quantity: 35 → 32
  ⚠️ ISSUE: cylinder_states NOT updated
  ↓
Response: Sale created
  ↓
Frontend: Navigate to sales list
```

**Expected Behavior:**
```
Update should be:
  - filled: 25 → 22 (decrease by quantity sold)
  - sold: 0 → 3 (increase by quantity sold)
  - empty: 10 (unchanged)
  - stock_quantity: 35 → 32 (empty + filled)
```

### 4.4 Cylinder Return Flow (NOT IMPLEMENTED)

**Expected Flow:**
```
Customer returns empty cylinder
  ↓
API Request: PUT /api/products/:id/cylinder-state
  Body: {
    "state": "empty",
    "quantity": 1,
    "operation": "add"
  }
  ↓
AND
  Body: {
    "state": "sold",
    "quantity": 1,
    "operation": "subtract"
  }
  ↓
Update cylinder_states:
  - empty: 10 → 11
  - sold: 3 → 2
  - filled: 22 (unchanged)
  - stock_quantity: 32 → 33
```

---

## 5. Issues and Improvements Needed

### 5.1 Critical Issues

#### **Issue 1: Sales Don't Update Cylinder States**
**Problem:** When a sale is created, only `stock_quantity` is decremented. The `cylinder_states` JSONB field is not updated.

**Impact:**
- Cylinder tracking screen shows incorrect data
- `filled` count doesn't decrease when cylinders are sold
- `sold` count doesn't increase
- Inventory reports are inaccurate

**Solution:**
Modify `lpgSalesController.createLPGSale()`:

```javascript
// After creating sale items
for (let item of items) {
  const { data: product } = await supabase
    .from('lpg_products')
    .select('stock_quantity, cylinder_states, product_type')
    .eq('id', item.product_id)
    .single();
  
  if (product) {
    if (product.product_type === 'cylinder' && product.cylinder_states) {
      // Update cylinder states
      const states = product.cylinder_states;
      const newStates = {
        empty: states.empty || 0,
        filled: Math.max(0, (states.filled || 0) - item.quantity),
        sold: (states.sold || 0) + item.quantity
      };
      
      await supabase
        .from('lpg_products')
        .update({ 
          stock_quantity: newStates.empty + newStates.filled,
          cylinder_states: newStates
        })
        .eq('id', item.product_id);
    } else {
      // For non-cylinder products, just update stock
      await supabase
        .from('lpg_products')
        .update({ stock_quantity: product.stock_quantity - item.quantity })
        .eq('id', item.product_id);
    }
  }
}
```

#### **Issue 2: No Cylinder Return Mechanism**
**Problem:** There's no API endpoint or UI to handle customers returning empty cylinders.

**Impact:**
- `sold` count keeps increasing
- `empty` count doesn't increase when cylinders are returned
- No way to track cylinder lifecycle

**Solution:**
Add new endpoint:

```javascript
// POST /api/products/:id/return-cylinder
const returnCylinder = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { quantity } = req.body;

    const { data: product } = await supabase
      .from('lpg_products')
      .select('cylinder_states')
      .eq('id', req.params.id)
      .single();

    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    const states = product.cylinder_states || { empty: 0, filled: 0, sold: 0 };
    
    // Check if enough sold cylinders to return
    if (states.sold < quantity) {
      return res.status(400).json({
        success: false,
        message: `Cannot return ${quantity} cylinders. Only ${states.sold} are sold.`
      });
    }

    // Return: decrease sold, increase empty
    const newStates = {
      empty: states.empty + quantity,
      filled: states.filled,
      sold: states.sold - quantity
    };

    const { data: updated } = await supabase
      .from('lpg_products')
      .update({ 
        stock_quantity: newStates.empty + newStates.filled,
        cylinder_states: newStates
      })
      .eq('id', req.params.id)
      .select()
      .single();

    res.json({
      success: true,
      message: 'Cylinders returned successfully',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};
```

#### **Issue 3: Inconsistent Stock Calculation**
**Problem:** `stock_quantity` can become out of sync with `cylinder_states.empty + cylinder_states.filled`.

**Solution:**
Add database constraint or trigger:

```sql
-- Add a check constraint
ALTER TABLE lpg_products
ADD CONSTRAINT check_cylinder_stock 
CHECK (
  product_type != 'cylinder' OR 
  stock_quantity = (cylinder_states->>'empty')::int + (cylinder_states->>'filled')::int
);

-- Or create a trigger to auto-calculate
CREATE OR REPLACE FUNCTION update_cylinder_stock()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.product_type = 'cylinder' AND NEW.cylinder_states IS NOT NULL THEN
    NEW.stock_quantity := (NEW.cylinder_states->>'empty')::int + (NEW.cylinder_states->>'filled')::int;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_cylinder_stock
BEFORE INSERT OR UPDATE ON lpg_products
FOR EACH ROW
EXECUTE FUNCTION update_cylinder_stock();
```

### 5.2 Enhancement Opportunities

#### **Enhancement 1: Link Individual Cylinders to Sales**
**Current:** Sales only track product_id and quantity
**Proposed:** Track which specific cylinders (by serial_number) were sold

**Implementation:**
```sql
-- Add sale_cylinders junction table
CREATE TABLE sale_cylinders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_item_id UUID REFERENCES sale_items(id) ON DELETE CASCADE,
  cylinder_id UUID REFERENCES cylinders(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### **Enhancement 2: Cylinder Lifecycle Tracking**
**Proposed:** Add status history to cylinders table

```sql
-- Add history column
ALTER TABLE cylinders
ADD COLUMN status_history JSONB DEFAULT '[]'::jsonb;

-- Update trigger to track status changes
CREATE OR REPLACE FUNCTION track_cylinder_status()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    NEW.status_history := COALESCE(OLD.status_history, '[]'::jsonb) || 
      jsonb_build_object(
        'from', OLD.status,
        'to', NEW.status,
        'changed_at', NOW()
      );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

#### **Enhancement 3: Automated Inspection Alerts**
**Proposed:** Add notification system for cylinders due for inspection

```javascript
// GET /api/cylinders/inspection-alerts
const getInspectionAlerts = async (req, res) => {
  const daysAhead = req.query.days || 30;
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() + daysAhead);
  
  const { data: cylinders } = await supabase
    .from('cylinders')
    .select('*, lpg_products(name)')
    .lte('next_inspection_date', cutoffDate.toISOString().split('T')[0])
    .order('next_inspection_date', { ascending: true });
  
  res.json({
    success: true,
    count: cylinders.length,
    data: cylinders
  });
};
```

#### **Enhancement 4: Cylinder Exchange History**
**Proposed:** Track all cylinder exchanges for audit purposes

```sql
CREATE TABLE cylinder_exchanges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES lpg_products(id),
  quantity INTEGER NOT NULL,
  performed_by UUID REFERENCES users(id),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### **Enhancement 5: Dashboard Widgets**
**Proposed:** Add cylinder tracking widgets to main dashboard

```dart
// Dashboard widgets to add:
// 1. Cylinders needing refill (empty count)
// 2. Cylinders ready for sale (filled count)
// 3. Cylinders with customers (sold count)
// 4. Cylinders due for inspection
// 5. Exchange rate (filled/empty ratio)
```

---

## 6. API Endpoints Summary

### Cylinder Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/cylinders` | Register new cylinder |
| GET | `/api/cylinders` | Get all cylinders (with filters) |
| GET | `/api/cylinders/:serialNumber` | Get cylinder by serial number |
| PUT | `/api/cylinders/:id/status` | Update cylinder status |
| POST | `/api/cylinders/:id/inspection` | Record inspection |
| GET | `/api/cylinders/due-inspection` | Get cylinders due for inspection |
| GET | `/api/cylinders/with-customer/:customerId` | Get customer's cylinders |

### Product/Inventory Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/products` | Get all products |
| POST | `/api/products` | Create new product |
| GET | `/api/products/:id` | Get single product |
| PUT | `/api/products/:id` | Update product |
| DELETE | `/api/products/:id` | Delete product |
| GET | `/api/products/cylinder-summary` | Get cylinder inventory summary |
| PUT | `/api/products/:id/cylinder-state` | Update cylinder state |
| PUT | `/api/products/:id/exchange` | Exchange empty for filled |
| GET | `/api/products/low-stock` | Get low stock products |
| GET | `/api/products/inspection-due` | Get products due for inspection |

### Sales
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/sales` | Create new sale |
| GET | `/api/sales` | Get all sales |
| GET | `/api/sales/report` | Get sales report |

---

## 7. Color Coding

The application uses consistent color coding for cylinder states:

```dart
// From LPGColors theme
cylinderEmpty: Colors.grey[400]      // Empty cylinders
cylinderFilled: Colors.green[600]    // Filled cylinders (ready for sale)
cylinderSold: Colors.blue[600]       // Sold cylinders (with customers)
```

---

## 8. Recommendations

### Immediate Actions (High Priority)
1. **Fix sales controller** to update `cylinder_states` when creating sales
2. **Add cylinder return endpoint** to handle empty cylinder returns
3. **Add database trigger** to ensure `stock_quantity` consistency
4. **Add validation** to prevent selling more cylinders than available

### Short-term Improvements (Medium Priority)
1. Implement cylinder return UI in the app
2. Add cylinder exchange tracking/history
3. Create dashboard widgets for cylinder metrics
4. Add inspection alert notifications
5. Implement bulk cylinder operations (exchange multiple types at once)

### Long-term Enhancements (Low Priority)
1. Link individual cylinders to sales for complete traceability
2. Add cylinder lifecycle analytics
3. Implement predictive refill scheduling
4. Add customer cylinder deposit tracking
5. Create cylinder maintenance scheduling system
6. Add barcode/QR code scanning for cylinder tracking

---

## 9. Testing Checklist

### Backend Tests Needed
- [ ] Create product with cylinder states
- [ ] Update cylinder states (add, subtract, set)
- [ ] Exchange cylinders (empty → filled)
- [ ] Create sale and verify cylinder states update
- [ ] Return cylinders and verify state changes
- [ ] Verify stock_quantity consistency
- [ ] Test low stock alerts
- [ ] Test inspection due queries

### Frontend Tests Needed
- [ ] Display cylinder tracking screen
- [ ] Show correct totals by type
- [ ] Filter cylinders by state
- [ ] Add new cylinder
- [ ] Create sale with cylinders
- [ ] Verify inventory updates after sale
- [ ] Test product creation with cylinder states
- [ ] Test cylinder exchange UI

### Integration Tests Needed
- [ ] End-to-end sale flow with cylinder state updates
- [ ] Cylinder lifecycle: add → fill → sell → return → refill
- [ ] Multi-user concurrent cylinder operations
- [ ] Data consistency across tables

---

## Conclusion

The cylinder tracking system provides a solid foundation for managing LPG cylinder inventory with separate tracking of empty, filled, and sold states. However, the critical issue of sales not updating cylinder states needs immediate attention to ensure data accuracy. The recommended enhancements will provide better traceability, compliance tracking, and operational insights.
