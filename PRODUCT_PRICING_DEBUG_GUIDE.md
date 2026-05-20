# Product Pricing Fields Debug Guide

## Issue
Product pricing fields (Deposit Amount, Refill Price, Cost Price) are showing as Rs0 in the product detail page even after entering values during product creation.

## Debug Steps Added

### 1. Frontend Logging (Flutter App)
Added comprehensive logging in `app/lib/screens/products/add_product_screen.dart`:

**When you create a product, check the browser console (F12) for:**
```
=== FORM CONTROLLER VALUES ===
Name: [product name]
Price: [price value]
Cost Price: [cost price value]
Product Type: cylinder
Deposit Amount Controller: "[value you entered]"
Refill Price Controller: "[value you entered]"

=== FRONTEND DEBUG ===
depositAmountController.text: "[value]"
refillPriceController.text: "[value]"
Parsed depositAmount: [number]
Parsed refillPrice: [number]
Final productData: {name: ..., depositAmount: [number], refillPrice: [number], ...}

=== SENDING TO API ===
Product Data: {"name":"...","depositAmount":1500,"refillPrice":800,...}
```

### 2. Backend Logging (Node.js Server)
Added logging in `server/controllers/lpgProductController.js`:

**Check your server logs for:**
```
=== CREATE PRODUCT DEBUG ===
Request body: {...}
costPrice: [value]
depositAmount: [value]
refillPrice: [value]
cylinderType: [value]
capacity: [value]
Product data to insert: {...}

=== PRODUCT CREATED ===
Database response: {...}
cost_price: [value]
deposit_amount: [value]
refill_price: [value]
```

## How to Test

1. **Open Browser Console** (Press F12, go to Console tab)
2. **Navigate to Add Product** screen in your app
3. **Fill in the form:**
   - Select "Cylinder" as product type
   - Fill in basic info (name, brand, SKU)
   - Fill in pricing:
     - Selling Price: e.g., 3000
     - Cost Price: e.g., 2500
     - **Deposit Amount: e.g., 1500** ← Important!
     - **Refill Price: e.g., 800** ← Important!
   - Fill in cylinder inventory (empty, filled)
4. **Click "Add Product"**
5. **Check Console Logs** - You should see all the debug output
6. **Check Server Logs** - Look at your terminal/server logs
7. **Navigate to Product Detail** page
8. **Verify** if the values are displayed correctly

## What to Look For

### If Frontend Shows Correct Values But Backend Shows 0:
- **Problem:** Data is not being sent correctly to the API
- **Check:** Network tab in browser (F12 → Network) to see the actual request payload

### If Frontend Shows 0 Values:
- **Problem:** Form controllers are not capturing user input
- **Possible causes:**
  - Text fields not properly bound to controllers
  - Form state not updating
  - Product type not set to 'cylinder' (fields only show for cylinders)

### If Backend Receives Correct Values But Database Shows 0:
- **Problem:** Database insertion issue
- **Check:** Database migration to ensure columns exist
- **Verify:** Column data types are correct (numeric, not text)

### If Everything Shows Correct Values in Logs But UI Shows 0:
- **Problem:** Frontend model parsing issue
- **Check:** `LPGProduct.fromJson()` method in `app/lib/models/lpg_product.dart`

## Expected Data Flow

1. **User Input** → Text Controllers (`_depositAmountController`, `_refillPriceController`)
2. **Form Submit** → Parse to double → Add to `productData` map with camelCase keys
3. **API Call** → Send JSON with camelCase keys (`depositAmount`, `refillPrice`)
4. **Backend** → Map camelCase to snake_case (`deposit_amount`, `refill_price`)
5. **Database** → Store in snake_case columns
6. **Response** → Return snake_case from database
7. **Frontend Model** → Parse both camelCase and snake_case
8. **UI Display** → Show values from model

## Quick Fix Checklist

- [ ] Verify text fields are visible when product type is "Cylinder"
- [ ] Verify you're actually entering values (not leaving them as 0)
- [ ] Check browser console for frontend logs
- [ ] Check server terminal for backend logs
- [ ] Verify database columns exist: `cost_price`, `deposit_amount`, `refill_price`
- [ ] Verify database columns are numeric type (not text)
- [ ] Check if values are in the database using Supabase dashboard
- [ ] Verify frontend model is parsing both camelCase and snake_case

## Database Verification

Run this query in Supabase SQL Editor to check your product:

```sql
SELECT 
  id,
  name,
  price,
  cost_price,
  deposit_amount,
  refill_price,
  product_type,
  cylinder_type
FROM lpg_products
WHERE product_type = 'cylinder'
ORDER BY created_at DESC
LIMIT 5;
```

## Common Issues

### Issue 1: Fields Not Visible
**Symptom:** Deposit Amount and Refill Price fields don't appear
**Cause:** Product type is not set to 'cylinder'
**Fix:** Ensure the "Cylinder" radio button is selected

### Issue 2: Values Reset to 0
**Symptom:** After entering values, they reset to 0
**Cause:** Form validation failing or state not updating
**Fix:** Check for validation errors, ensure no form reset

### Issue 3: Backend Receives 0
**Symptom:** Frontend logs show correct values, backend receives 0
**Cause:** API request not sending data correctly
**Fix:** Check network request payload in browser DevTools

### Issue 4: Database Has 0
**Symptom:** Backend logs show correct values, database has 0
**Cause:** Column type mismatch or constraint issue
**Fix:** Verify column types in database schema

## Next Steps

After running the test:
1. Share the console logs (both frontend and backend)
2. Share a screenshot of the Add Product form with values filled in
3. Share the database query result
4. This will help identify exactly where the data is being lost
