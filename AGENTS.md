# LPG Shop Management System - Agent Context

## Project Overview

A comprehensive LPG (Liquefied Petroleum Gas) shop management system built with Flutter (frontend) and Node.js/Express (backend) with Supabase PostgreSQL database. The system manages cylinder inventory, customer relationships, sales, deliveries, safety compliance, and business analytics.

## Technology Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: StatefulWidget with setState
- **HTTP Client**: http package
- **Storage**: SharedPreferences for local settings
- **Image Handling**: image_picker package
- **Platforms**: Web, iOS, Android, Windows, Linux, macOS

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: Supabase (PostgreSQL)
- **Authentication**: JWT tokens
- **File Storage**: Supabase Storage
- **Logging**: Winston
- **Deployment**: Vercel

### Database
- **Provider**: Supabase
- **Type**: PostgreSQL
- **Features**: Row Level Security (RLS), JSONB columns, triggers, real-time subscriptions

## Architecture

### Frontend Structure
```
app/lib/
├── config/          # API configuration
├── models/          # Data models (LPGProduct, LPGCustomer, User, etc.)
├── screens/         # UI screens organized by feature
│   ├── auth/        # Login, Register
│   ├── customers/   # Customer management
│   ├── products/    # Product management
│   ├── sales/       # Sales transactions
│   ├── cylinders/   # Cylinder tracking
│   ├── delivery/    # Delivery management
│   ├── safety/      # Safety compliance
│   ├── feedback/    # Customer feedback
│   ├── reports/     # Business reports
│   └── settings/    # App settings
├── services/        # API services
├── widgets/         # Reusable widgets
└── utils/           # Utilities (logger, etc.)
```

### Backend Structure
```
server/
├── api/             # Vercel serverless entry point
├── config/          # Database and logger config
├── controllers/     # Business logic
├── middleware/      # Auth, error handling, logging
├── models/          # Data models (not used with Supabase)
├── routes/          # API routes
├── utils/           # Utilities (file storage, errors)
└── supabase/        # Database migrations
```

## Key Features Implemented

### 1. Product Management
- **Product Types**: Cylinders and Accessories
- **Cylinder-Specific Fields**: 
  - Cylinder type (11.8kg, 15kg, 45.4kg)
  - Capacity, pressure rating
  - Cost price, deposit amount, refill price
  - Cylinder states (empty, filled, sold)
- **Inventory Tracking**: Stock levels, min/max thresholds
- **Image Management**: Upload to Supabase Storage
- **Quick Actions**: Exchange, Return, Refill cylinders

### 2. Customer Management
- **Customer Types**: Domestic, Commercial, Industrial
- **Customer Data**: Contact info, address, loyalty tier
- **Purchase History**: Track all customer transactions
- **Analytics**: Total refills, total spent, loyalty points
- **Refill Tracking**: Last refill date, average consumption

### 3. Sales Management
- **Sale Creation**: Multi-item sales with customer selection
- **Payment Methods**: Cash, Card, UPI, Credit
- **Cylinder State Updates**: Automatically updates filled→sold
- **Sale History**: View and filter sales by date, status
- **Sale Details**: Complete transaction information

### 4. Cylinder Tracking
- **State Management**: Empty, Filled, Sold
- **Automatic Updates**: 
  - Sales decrease filled, increase sold
  - Returns decrease sold, increase empty
  - Exchange decreases empty, increases filled
- **Stock Calculation**: Trigger automatically calculates stock_quantity = empty + filled
- **Summary Dashboard**: View cylinder counts by type
- **Consistency**: Database trigger ensures data integrity

### 5. Safety Compliance
- **Incident Reporting**: Log safety incidents with severity levels
- **Safety Checklists**: Regular safety inspections
- **Compliance Reports**: Track compliance metrics
- **Status Updates**: Mark incidents as resolved
- **User-Specific Data**: Each user sees only their own records

### 6. Delivery Management
- **Route Planning**: Create delivery routes
- **Personnel Assignment**: Assign delivery staff
- **Status Tracking**: Pending, In Progress, Completed
- **Customer Notifications**: Track delivery status

### 7. Business Analytics
- **Dashboard Metrics**: 
  - Total sales, revenue, profit
  - Customer count, active customers
  - Low stock alerts
  - Cylinder inventory summary
- **Reports**: 
  - Sales reports by date range
  - Customer analytics
  - Product performance
  - Inventory reports

### 8. Settings & Configuration
- **Theme Support**: Light and Dark themes
- **Notifications**: Toggle notifications on/off
- **Base URL Configuration**: Custom API endpoint
- **Persistent Settings**: Saved to SharedPreferences

## Data Flow & Conventions

### Naming Conventions
- **Frontend (Flutter)**: camelCase (e.g., `depositAmount`, `costPrice`)
- **Backend (Node.js)**: camelCase in request/response
- **Database (PostgreSQL)**: snake_case (e.g., `deposit_amount`, `cost_price`)

### Data Mapping
Backend controllers map between camelCase and snake_case:
```javascript
// Request (camelCase) → Database (snake_case)
cost_price: req.body.costPrice
deposit_amount: req.body.depositAmount
refill_price: req.body.refillPrice

// Database (snake_case) → Response (both for compatibility)
// Frontend model handles both formats
```

### Frontend Models
Models like `LPGProduct` parse both naming conventions:
```dart
costPrice: (json['costPrice'] ?? json['cost_price'] ?? 0).toDouble()
depositAmount: (json['depositAmount'] ?? json['deposit_amount'] ?? 0).toDouble()
```

## Database Schema

### Key Tables

#### lpg_products
- Product information (cylinders and accessories)
- Pricing fields: price, cost_price, deposit_amount, refill_price
- Cylinder-specific: cylinder_type, capacity, cylinder_states (JSONB)
- Inventory: stock_quantity (auto-calculated by trigger)
- Metadata: sku, barcode, tags, images

#### lpg_customers
- Customer information and contact details
- Customer type: domestic, commercial, industrial
- Loyalty: loyalty_tier, loyalty_points
- Analytics: total_refills, total_spent (calculated)
- Timestamps: last_refill_date, created_at

#### lpg_sales
- Sales transactions
- Items: sale_items (JSONB array)
- Payment: payment_method, payment_status
- Customer: customer_id (foreign key)
- Totals: subtotal, tax, discount, total

#### cylinders
- Individual cylinder tracking
- Serial numbers and certifications
- Inspection dates and status
- Current location and condition

#### safety_incidents
- Safety incident reports
- Severity levels: low, medium, high, critical
- Status: open, investigating, resolved
- User-specific (reported_by)

#### safety_checklists
- Regular safety inspections
- Checklist items and completion status
- User-specific (checked_by)

### Database Triggers

#### update_cylinder_stock()
Automatically calculates stock_quantity when cylinder_states changes:
```sql
stock_quantity = (cylinder_states->>'empty')::int + (cylinder_states->>'filled')::int
```

## API Endpoints

### Products
- `GET /api/products` - List products with filters
- `GET /api/products/:id` - Get single product
- `POST /api/products` - Create product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product
- `PUT /api/products/:id/cylinder-state` - Update cylinder state
- `PUT /api/products/:id/exchange` - Exchange cylinders
- `POST /api/products/:id/return-cylinder` - Return cylinders
- `GET /api/products/cylinder-summary` - Cylinder inventory summary

### Customers
- `GET /api/customers` - List customers
- `GET /api/customers/:id` - Get customer with analytics
- `POST /api/customers` - Create customer
- `PUT /api/customers/:id` - Update customer
- `DELETE /api/customers/:id` - Delete customer
- `GET /api/customers/analytics` - Customer analytics

### Sales
- `GET /api/sales` - List sales
- `POST /api/sales` - Create sale (updates cylinder states)
- `GET /api/sales/report` - Sales report

### Safety
- `GET /api/safety/incidents` - List incidents
- `POST /api/safety/incidents` - Create incident
- `PUT /api/safety/incidents/:id` - Update incident
- `GET /api/safety/checklists` - List checklists
- `POST /api/safety/checklists` - Create checklist
- `GET /api/safety/compliance-report` - Compliance metrics

## Known Issues & Solutions

### Issue 1: Product Pricing Fields Showing Rs0
**Status**: Debugging in progress
**Symptoms**: Cost price, deposit amount, and refill price show as 0 in product details
**Investigation**:
- Database schema is correct (numeric columns exist)
- Database can store values (verified with manual inserts)
- Frontend form has proper controllers and validation
- Backend has correct field mapping
- Debug logging added to both frontend and backend

**Possible Causes**:
1. Form controllers not capturing user input
2. Product type not set to 'cylinder' (fields only show for cylinders)
3. Data not being sent in API request
4. Backend not receiving or parsing data correctly

**Debug Steps**:
1. Check browser console for frontend logs
2. Check server logs for backend logs
3. Verify network request payload in DevTools
4. Confirm product type is 'cylinder' when creating

### Issue 2: Tab Colors Not Visible
**Status**: Fixed
**Solution**: Added explicit TabBar styling with white colors on blue AppBar

### Issue 3: Cylinder Quick Actions Showing for All Products
**Status**: Fixed
**Solution**: Updated non-cylinder products to have `product_type = 'accessory'`

### Issue 4: Dashboard Showing 0 Customers
**Status**: Fixed
**Solution**: Fixed data access path (removed incorrect 'overview' wrapper)

### Issue 5: Safety Screen Not Refreshing
**Status**: Fixed
**Solution**: Added proper async/await and mounted checks, filtered by user ID

## Development Guidelines

### Adding New Features
1. **Database First**: Create migration in `server/supabase/migrations/`
2. **Backend**: Add controller, routes, and models
3. **Frontend**: Create models, services, and UI screens
4. **Testing**: Test data flow end-to-end

### Naming Conventions
- Use camelCase in Dart/JavaScript code
- Use snake_case in SQL/database
- Map between conventions in backend controllers
- Frontend models should handle both formats

### Error Handling
- Backend: Use AppError class with proper status codes
- Frontend: Use try-catch with user-friendly messages
- Log errors with context for debugging

### Authentication
- JWT tokens stored in SharedPreferences
- Include in Authorization header for all API calls
- Backend middleware validates tokens

### File Uploads
- Images uploaded to Supabase Storage
- Base64 encoding for web compatibility
- Validate file size and type
- Clean up old files when updating

### State Management
- Use setState for simple state
- Refresh data after mutations
- Check mounted before setState
- Show loading indicators during async operations

## Testing Checklist

### Product Management
- [ ] Create cylinder product with all fields
- [ ] Create accessory product
- [ ] Update product details
- [ ] Upload product image
- [ ] View product details (verify all fields display)
- [ ] Delete product

### Cylinder Operations
- [ ] Exchange cylinders (empty → filled)
- [ ] Return cylinders (sold → empty)
- [ ] Create sale (filled → sold)
- [ ] Verify stock_quantity updates automatically
- [ ] Check cylinder summary dashboard

### Customer Management
- [ ] Create customer
- [ ] View customer details with analytics
- [ ] Update customer information
- [ ] View purchase history
- [ ] Delete customer

### Sales
- [ ] Create sale with multiple items
- [ ] Verify cylinder states update
- [ ] View sale details
- [ ] Generate sales report

### Safety
- [ ] Create incident report
- [ ] Create safety checklist
- [ ] Update incident status
- [ ] View compliance report
- [ ] Verify user-specific filtering

## Deployment

### Frontend (Flutter Web)
- Build: `flutter build web`
- Deploy to hosting service (Firebase, Netlify, etc.)
- Configure base URL in settings

### Backend (Vercel)
- Deploy: `vercel --prod`
- Environment variables in Vercel dashboard
- Serverless functions in `api/` directory

### Database (Supabase)
- Migrations: Apply via Supabase CLI or MCP tools
- RLS Policies: Ensure proper security
- Backups: Configure automatic backups

## Environment Variables

### Backend (.env)
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_key
JWT_SECRET=your_jwt_secret
PORT=3000
NODE_ENV=production
```

### Frontend (Configured in app)
- Base URL: Configurable via settings screen
- Default: https://server-lpg-shop.vercel.app/api

## Future Enhancements

### Planned Features
- [ ] Real-time notifications using Supabase subscriptions
- [ ] Advanced analytics with charts and graphs
- [ ] Barcode scanning for products
- [ ] SMS notifications for customers
- [ ] Multi-language support
- [ ] Offline mode with sync
- [ ] Role-based access control
- [ ] Automated backup and restore
- [ ] Integration with payment gateways
- [ ] Mobile app optimization

### Performance Optimizations
- [ ] Implement pagination for large lists
- [ ] Add caching for frequently accessed data
- [ ] Optimize image loading and compression
- [ ] Lazy loading for screens
- [ ] Database query optimization with indexes

## Support & Maintenance

### Logging
- Frontend: AppLogger utility with debug/info/error levels
- Backend: Winston logger with file rotation
- Check logs in `server/logs/` directory

### Monitoring
- Track API response times
- Monitor database query performance
- Set up alerts for errors and downtime

### Backup Strategy
- Database: Daily automated backups via Supabase
- Code: Version control with Git
- Images: Backed up in Supabase Storage

## Contact & Resources

### Documentation
- Flutter: https://flutter.dev/docs
- Supabase: https://supabase.com/docs
- Express: https://expressjs.com/

### Project Repository
- Frontend: `app/` directory
- Backend: `server/` directory
- Migrations: `server/supabase/migrations/`

---

**Last Updated**: May 20, 2026
**Version**: 1.0.0
**Maintained By**: Development Team
