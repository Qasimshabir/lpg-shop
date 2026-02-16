# Purchase History Feature - LPG Shop Management System

## Overview

The Purchase History feature provides a comprehensive system for tracking, analyzing, and displaying complete customer purchase records. Every transaction is recorded with full details including products, quantities, prices, dates, and transaction IDs.

## Database Schema Design

### Core Tables

#### 1. **lpg_customers**
Stores registered customer information.

```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key → users)
- customer_id (VARCHAR, Unique)
- name, email, phone
- address, city, state, postal_code
- customer_type (residential/commercial)
- registration_date
- is_active
- timestamps
```

#### 2. **lpg_sales**
Main transaction table storing each sale.

```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key → users)
- customer_id (UUID, Foreign Key → lpg_customers)
- invoice_number (VARCHAR, Unique)
- sale_date (TIMESTAMP)
- total_amount (DECIMAL)
- payment_method (VARCHAR)
- payment_status (VARCHAR)
- delivery_status (VARCHAR)
- delivery_address (TEXT)
- notes (TEXT)
- timestamps
```

**Indexes:**
- `idx_sales_customer_date` on (customer_id, sale_date DESC)
- `idx_sales_customer_status` on (customer_id, payment_status)
- `idx_sales_invoice` on (invoice_number)
- `idx_sales_date` on (sale_date)

#### 3. **sale_items**
Line items for each sale with product details.

```sql
- id (UUID, Primary Key)
- sale_id (UUID, Foreign Key → lpg_sales)
- product_id (UUID, Foreign Key → lpg_products)
- quantity (INTEGER)
- unit_price (DECIMAL)
- subtotal (DECIMAL)
- created_at (TIMESTAMP)
```

**Indexes:**
- `idx_sale_items_sale` on (sale_id)
- `idx_sale_items_product` on (product_id, created_at DESC)

#### 4. **lpg_products**
Product catalog with pricing information.

```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key → users)
- name, brand_id, category
- price, stock_quantity
- sku (VARCHAR, Unique)
- timestamps
```

### Relationships

```
lpg_customers (1) ──→ (N) lpg_sales
lpg_sales (1) ──→ (N) sale_items
sale_items (N) ──→ (1) lpg_products
lpg_products (N) ──→ (1) brands
```

## Database Views

### 1. customer_purchase_summary
Aggregated customer purchase statistics.

**Columns:**
- customer_id, customer_code, customer_name
- total_orders, total_spent, average_order_value
- last_purchase_date, first_purchase_date
- orders_last_30_days, orders_last_90_days
- spent_last_30_days, pending_amount

**Use Case:** Quick overview of customer spending patterns.

### 2. product_purchase_history
Product sales analytics.

**Columns:**
- product_id, product_name, brand_name
- times_sold, total_quantity_sold, total_revenue
- last_sold_date, average_selling_price

**Use Case:** Identify best-selling products and pricing trends.

### 3. monthly_sales_summary
Monthly aggregated sales data.

**Columns:**
- month, user_id
- total_orders, unique_customers
- total_revenue, average_order_value
- paid_orders, pending_orders

**Use Case:** Monthly performance tracking.

### 4. customer_loyalty_metrics
Customer engagement and loyalty indicators.

**Columns:**
- customer_id, customer_name
- purchase_frequency, lifetime_value
- customer_lifetime_days, customer_status
- loyalty_tier (Bronze/Silver/Gold/Platinum)

**Use Case:** Customer segmentation and retention strategies.

## Database Functions

### 1. get_customer_purchase_history(customer_id, limit, offset)
Retrieves paginated purchase history with product summaries.

**Returns:**
- sale_id, invoice_number, sale_date
- total_amount, payment details
- items_count, products_summary (aggregated)

### 2. get_sale_details(sale_id)
Fetches complete details for a specific sale.

**Returns:**
- Sale information
- Customer details
- All line items with product information

### 3. get_customer_product_preferences(customer_id, limit)
Identifies customer's most purchased products.

**Returns:**
- product_id, product_name, brand_name
- purchase_count, total_quantity, total_spent
- last_purchased, average_price

### 4. get_purchase_history_by_date(customer_id, start_date, end_date)
Filters purchase history by date range.

### 5. calculate_customer_ltv(customer_id)
Calculates customer lifetime value metrics.

**Returns:**
- total_orders, total_spent, average_order_value
- first_purchase, last_purchase, customer_lifetime_days
- predicted_next_purchase, loyalty_tier

## API Endpoints

### Base URL: `/api/purchase-history`

#### 1. GET `/:customerId`
Get complete purchase history for a customer.

**Query Parameters:**
- `limit` (default: 50) - Number of records per page
- `offset` (default: 0) - Pagination offset
- `startDate` (optional) - Filter from date
- `endDate` (optional) - Filter to date

**Response:**
```json
{
  "success": true,
  "data": {
    "purchases": [...],
    "pagination": {
      "total": 150,
      "limit": 50,
      "offset": 0,
      "hasMore": true
    }
  }
}
```

#### 2. GET `/:customerId/summary`
Get purchase summary statistics.

**Response:**
```json
{
  "success": true,
  "data": {
    "customer_id": "uuid",
    "total_orders": 45,
    "total_spent": 125000.00,
    "average_order_value": 2777.78,
    "last_purchase_date": "2024-02-15",
    ...
  }
}
```

#### 3. GET `/sale/:saleId`
Get detailed information for a specific sale.

#### 4. GET `/:customerId/preferences`
Get customer's product preferences.

**Query Parameters:**
- `limit` (default: 10)

#### 5. GET `/:customerId/lifetime-value`
Calculate customer lifetime value.

#### 6. GET `/:customerId/loyalty`
Get customer loyalty metrics.

#### 7. GET `/:customerId/trends`
Get monthly purchase trends.

**Query Parameters:**
- `months` (default: 12)

#### 8. GET `/:customerId/date-range`
Get purchase history by date range.

**Query Parameters:**
- `startDate` (required)
- `endDate` (required)

#### 9. GET `/:customerId/search`
Search purchase history.

**Query Parameters:**
- `query` (required) - Search term
- `limit` (default: 20)

#### 10. GET `/:customerId/export`
Export purchase history to CSV.

**Query Parameters:**
- `startDate` (optional)
- `endDate` (optional)

## Performance Optimizations

### 1. Indexing Strategy
- Composite indexes on frequently queried columns
- Covering indexes for common queries
- GIN indexes for full-text search

### 2. Query Optimization
- Materialized views for heavy aggregations
- Efficient pagination using offset/limit
- Selective column retrieval

### 3. Caching Strategy
- Cache customer summaries (TTL: 5 minutes)
- Cache product preferences (TTL: 15 minutes)
- Invalidate cache on new purchases

### 4. Database Connection Pooling
- Use connection pooling for concurrent requests
- Optimize pool size based on load

## Data Retrieval Efficiency

### Pagination
```javascript
// Efficient pagination with cursor-based approach
const { data, count } = await supabase
  .from('lpg_sales')
  .select('*', { count: 'exact' })
  .eq('customer_id', customerId)
  .order('sale_date', { ascending: false })
  .range(offset, offset + limit - 1);
```

### Eager Loading
```javascript
// Load related data in single query
const { data } = await supabase
  .from('lpg_sales')
  .select(`
    *,
    sale_items (
      *,
      lpg_products (
        *,
        brands (title)
      )
    )
  `)
  .eq('customer_id', customerId);
```

### Aggregation Functions
```sql
-- Use database functions for complex calculations
SELECT * FROM get_customer_purchase_history(
  'customer-uuid',
  50,  -- limit
  0    -- offset
);
```

## Frontend Implementation

### Flutter Models
- `PurchaseHistory` - Main purchase record
- `PurchaseItem` - Individual line items
- `PurchaseSummary` - Aggregated statistics
- `CustomerLifetimeValue` - LTV metrics
- `ProductPreference` - Product preferences
- `MonthlyTrend` - Trend data

### Service Layer
`PurchaseHistoryService` provides methods for:
- Fetching purchase history with pagination
- Getting summaries and analytics
- Searching and filtering
- Exporting data

### UI Components
`CustomerPurchaseHistoryScreen` features:
- Tabbed interface (Purchases, Summary, Preferences, Trends)
- Pull-to-refresh functionality
- Infinite scroll with load more
- Detailed purchase view in bottom sheet
- Status indicators and visual feedback

## Security Considerations

### 1. Authentication
- All endpoints require valid JWT token
- Token validation via `protect` middleware

### 2. Authorization
- Users can only access their own customer data
- Role-based access control for admin features

### 3. Data Privacy
- Sensitive data encrypted at rest
- PII handling compliance
- Audit logging for data access

### 4. Input Validation
- Sanitize all user inputs
- Validate date ranges
- Prevent SQL injection via parameterized queries

## Usage Examples

### Backend (Node.js)
```javascript
// Get purchase history
const history = await supabase
  .from('lpg_sales')
  .select('*, sale_items(*)')
  .eq('customer_id', customerId)
  .order('sale_date', { ascending: false });

// Calculate LTV
const { data } = await supabase
  .rpc('calculate_customer_ltv', { 
    p_customer_id: customerId 
  });
```

### Frontend (Flutter)
```dart
// Load purchase history
final service = PurchaseHistoryService();
final result = await service.getCustomerPurchaseHistory(
  customerId,
  limit: 20,
  offset: 0,
);

// Navigate to history screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CustomerPurchaseHistoryScreen(
      customerId: customer.id,
      customerName: customer.name,
    ),
  ),
);
```

## Maintenance and Monitoring

### 1. Regular Tasks
- Archive old transactions (> 2 years)
- Rebuild indexes monthly
- Update statistics for query planner

### 2. Monitoring
- Track slow queries (> 1 second)
- Monitor cache hit rates
- Alert on failed transactions

### 3. Backup Strategy
- Daily incremental backups
- Weekly full backups
- Point-in-time recovery enabled

## Future Enhancements

1. **Real-time Updates**: WebSocket integration for live updates
2. **Advanced Analytics**: ML-based purchase predictions
3. **Recommendation Engine**: Product recommendations based on history
4. **Mobile Offline Support**: Local caching with sync
5. **Export Formats**: PDF invoices, Excel reports
6. **Bulk Operations**: Batch invoice generation
7. **Customer Portal**: Self-service purchase history access

## Installation

### 1. Run Database Migrations
```bash
# Run main schema
psql -U postgres -d lpg_db -f server/config/supabase-schema.sql

# Run purchase history enhancements
psql -U postgres -d lpg_db -f server/config/purchase-history-schema.sql
```

### 2. Update Server Routes
Add to `server/server.js` or `server/api/index.js`:
```javascript
const purchaseHistoryRoutes = require('./routes/purchaseHistory');
app.use('/api/purchase-history', purchaseHistoryRoutes);
```

### 3. Test Endpoints
```bash
# Test purchase history endpoint
curl -X GET http://localhost:5000/api/purchase-history/{customerId} \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Conclusion

The Purchase History feature provides a robust, scalable solution for tracking customer purchases in the LPG shop management system. With optimized database design, efficient queries, and comprehensive API endpoints, it enables detailed customer insights and business analytics.
