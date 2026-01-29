# Database Seeders

This directory contains scripts to populate the database with initial data for development and testing.

## Available Seeders

### 1. Role Seeder (`roleSeeder.js`)
Seeds the database with predefined user roles and permissions.

**Roles Created:**
- **Super Admin** - Full system access
- **Admin** - Shop owner/administrator
- **Manager** - Shop manager with operational permissions
- **Sales Person** - Sales staff with customer and sales permissions
- **Delivery Person** - Delivery staff with delivery permissions
- **Inventory Manager** - Inventory staff with product management permissions

**Usage:**
```bash
npm run seed:roles
```

**What it does:**
- Clears existing roles
- Creates 6 predefined roles with specific permissions
- Sets up permission structure for each role

---

### 2. Database Seeder (`databaseSeeder.js`)
Seeds the database with sample data for testing.

**Data Created:**
- 1 Admin user (login credentials)
- 5 Sample products (3 cylinders + 2 accessories)
- 15 Sample cylinders with serial numbers
- 3 Sample customers (individual, restaurant, industrial)
- 2 Delivery personnel

**Usage:**
```bash
npm run seed:database
```

**Login Credentials:**
- Email: `admin@lpgdealer.com`
- Password: `admin123`

---

### 3. Seed All
Run both seeders in sequence.

**Usage:**
```bash
npm run seed:all
```

This will:
1. First seed roles
2. Then seed sample data

---

## Role Permissions Structure

Each role has permissions defined for different resources:

### Resources:
- `users` - User management
- `roles` - Role management
- `products` - Product management
- `cylinders` - Cylinder tracking
- `customers` - Customer management
- `sales` - Sales operations
- `delivery` - Delivery management
- `safety` - Safety compliance
- `reports` - Report generation
- `audit-logs` - Audit trail viewing

### Actions:
- `create` - Create new records
- `read` - View records
- `update` - Modify records
- `delete` - Remove records
- `export` - Export data
- `approve` - Approve operations

---

## Permission Examples

### Super Admin
```javascript
{
  resource: 'users',
  actions: ['create', 'read', 'update', 'delete']
}
```

### Sales Person
```javascript
{
  resource: 'sales',
  actions: ['create', 'read']
}
```

### Delivery Person
```javascript
{
  resource: 'delivery',
  actions: ['read', 'update']
}
```

---

## Using Roles in Your Application

### 1. Assign Role to User

**API Endpoint:**
```
PUT /api/roles/assign/:userId
```

**Request Body:**
```json
{
  "roleId": "role_id_here"
}
```

### 2. Check Permissions in Routes

**Using Permission Middleware:**
```javascript
const { checkPermission } = require('../middleware/permissionMiddleware');

router.post('/products', 
  protect, 
  checkPermission('products', 'create'),
  createProduct
);
```

**Using Role Middleware:**
```javascript
const { hasRole } = require('../middleware/permissionMiddleware');

router.get('/admin/dashboard',
  protect,
  hasRole('super-admin', 'admin'),
  getAdminDashboard
);
```

### 3. Check Multiple Permissions

```javascript
const { checkMultiplePermissions } = require('../middleware/permissionMiddleware');

router.post('/sales/approve',
  protect,
  checkMultiplePermissions([
    { resource: 'sales', action: 'read' },
    { resource: 'sales', action: 'approve' }
  ]),
  approveSale
);
```

---

## Sample Data Details

### Products
1. **HP Gas 11.8kg Cylinder** - ₹950 (20 filled, 10 empty)
2. **HP Gas 15kg Cylinder** - ₹1,200 (10 filled, 5 empty)
3. **HP Gas 45.4kg Cylinder** - ₹3,500 (5 filled, 2 empty)
4. **Gas Regulator** - ₹350 (50 in stock)
5. **Gas Pipe (2m)** - ₹200 (30 in stock)

### Cylinders
- 15 cylinders with unique serial numbers
- Format: `CYL-YYYY-NNNNNN`
- Mix of 11.8kg, 15kg, and 45.4kg
- Various manufacturers: HP Gas, Bharat Gas, Indane
- Some in-stock, some with customers

### Customers
1. **Rajesh Kumar** - Individual customer (Silver tier)
2. **Priya Restaurant** - Business customer (Gold tier)
3. **ABC Industries** - Industrial customer (Platinum tier)

### Delivery Personnel
1. **Ramesh Sharma** - Van driver (150 deliveries, 4.5★)
2. **Suresh Patel** - Bike rider (200 deliveries, 4.8★)

---

## Resetting Database

To reset and reseed the database:

```bash
# Drop all collections (be careful!)
mongo lpg_dealer_shop --eval "db.dropDatabase()"

# Reseed
npm run seed:all
```

---

## Environment Variables Required

Make sure your `.env` file has:

```env
MONGO_URI=mongodb://localhost:27017/lpg_dealer_shop
JWT_SECRET=your_secret_key
JWT_EXPIRE=7d
```

---

## Troubleshooting

### Error: "Cannot connect to MongoDB"
- Check if MongoDB is running
- Verify MONGO_URI in .env file
- Ensure database name is correct

### Error: "Duplicate key error"
- Database already has data
- Drop the database or use different data
- Check for unique constraints

### Error: "Validation failed"
- Check model schemas
- Ensure all required fields are provided
- Verify enum values are correct

---

## Adding Custom Roles

To add your own custom roles, edit `roleSeeder.js`:

```javascript
const customRole = {
  name: 'custom-role',
  displayName: 'Custom Role',
  description: 'Your custom role description',
  permissions: [
    {
      resource: 'products',
      actions: ['read', 'update']
    }
  ],
  isActive: true
};

predefinedRoles.push(customRole);
```

---

## Production Considerations

⚠️ **WARNING:** These seeders are for development only!

**For Production:**
1. Don't use default passwords
2. Don't seed sample data
3. Only seed essential roles
4. Use environment-specific configurations
5. Implement proper user registration flow
6. Use strong password policies

---

## Next Steps

After seeding:
1. Start the server: `npm run dev`
2. Login with admin credentials
3. Test API endpoints
4. Assign roles to users
5. Test permission-based access

---

**Last Updated:** January 29, 2026  
**Version:** 1.0.0
