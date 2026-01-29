# 🔥 LPG Dealer Management System

## 🎯 Overview

The LPG Dealer Management System is a comprehensive full-stack application designed for LPG cylinder and accessories management, sales tracking, customer management, and delivery operations. Built using modern technologies:

- **Frontend**: Flutter (Mobile App)
- **Backend**: Node.js + Express
- **Database**: MongoDB

---

## 👥 Actors in the System

| Actor     | Description |
|-----------|-------------|
| **User**  | Shop employee or dealer using the app. |
| **Admin** | System administrator managing users, pricing, and inventory. |
| **System**| Backend platform that handles operations and logic. |

---

## ✅ Use Case Descriptions

### 1. 📝 Register

**Actor**: User  
**Description**: Create an account with name, email, phone, and shop details.

---

### 2. 🔐 Login

**Actor**: User  
**Description**: Login with credentials, receive JWT token.

---

### 3. 🚪 Logout

**Actor**: User  
**Description**: Logout by clearing token/session on client side.

---

### 4. 📦 Manage Inventory

**Actor**: Admin  
**Description**: Add/update/delete LPG cylinders and accessories, track empty/filled/sold states.

---

### 5. 💰 Process Sales

**Actor**: User  
**Description**: Create sales transactions with cylinder exchange, refills, and accessory sales. Auto-update inventory.

---

### 6. 🚚 Delivery Management

**Actor**: User  
**Description**: Schedule deliveries, track delivery status, manage delivery addresses.

---

### 7. 📊 Generate Reports

**Actor**: Admin/User  
**Description**: View sales reports, cylinder inventory summaries, customer analytics.

---

### 8. 👤 Manage Customers

**Actor**: User/Admin  
**Description**: Store customer info with multiple premises, track refill history, consumption patterns.

---

### 9. 💵 Set Pricing

**Actor**: Admin  
**Description**: Update cylinder and accessory prices, manage deposits and refunds.

---

### 10. ⚙️ Manage Profile

**Actor**: User  
**Description**: Update personal profile, contact info, password.

---

## 🌐 API Endpoints

### 🧾 Auth Routes

| Method | Endpoint         | Description               |
|--------|------------------|---------------------------|
| POST   | `/api/register`  | Register a new user       |
| POST   | `/api/login`     | Login and receive token   |
| POST   | `/api/logout`    | Logout (Client-side only) |

---

### 📦 Product Routes (LPG Cylinders & Accessories)

| Method | Endpoint                           | Description                        |
|--------|------------------------------------|------------------------------------|
| GET    | `/api/products`                    | Get all products                   |
| GET    | `/api/products/:id`                | Get single product by ID           |
| POST   | `/api/products`                    | Add a new product                  |
| PUT    | `/api/products/:id`                | Update product by ID               |
| DELETE | `/api/products/:id`                | Delete product by ID               |
| PUT    | `/api/products/:id/cylinder-state` | Update cylinder inventory state    |
| PUT    | `/api/products/:id/exchange`       | Process cylinder exchange          |
| GET    | `/api/products/low-stock`          | Get low stock alerts               |
| GET    | `/api/products/cylinder-summary`   | Get cylinder inventory summary     |
| GET    | `/api/products/inspection-due`     | Get cylinders due for inspection   |

---

### 💰 Sales Routes

| Method | Endpoint           | Description                    |
|--------|--------------------|--------------------------------|
| POST   | `/api/sales`       | Create a new sales record      |
| GET    | `/api/sales`       | Get all sales records          |
| GET    | `/api/sales/report`| Generate sales report          |

---

### 👥 Customer Routes

| Method | Endpoint                              | Description                  |
|--------|---------------------------------------|------------------------------|
| POST   | `/api/customers`                      | Add new customer             |
| GET    | `/api/customers`                      | Get all customers            |
| GET    | `/api/customers/:id`                  | Get customer by ID           |
| PUT    | `/api/customers/:id`                  | Update customer info         |
| POST   | `/api/customers/:id/premises`         | Add delivery premises        |
| POST   | `/api/customers/:id/refill`           | Record cylinder refill       |
| GET    | `/api/customers/:id/refill-history`   | Get refill history           |
| PUT    | `/api/customers/:id/credit`           | Update customer credit       |
| GET    | `/api/customers/due-refill`           | Get customers due for refill |
| GET    | `/api/customers/top-customers`        | Get top customers            |
| GET    | `/api/customers/analytics`            | Get customer analytics       |

---

### ⚙️ User/Profile Routes

| Method | Endpoint          | Description                    |
|--------|-------------------|--------------------------------|
| GET    | `/api/users/me`   | Get current user profile       |
| PUT    | `/api/users/me`   | Update profile info            |
| PUT    | `/api/users/password` | Change password             |

---

## 🖥️ Node.js Backend Structure

### 1. Folder Structure

```
server/
├── controllers/
│   ├── authController.js
│   ├── lpgProductController.js
│   ├── lpgSalesController.js
│   ├── lpgCustomerController.js
│   ├── userController.js
│   ├── brandController.js
│   ├── categoryController.js
│   └── feedbackController.js
├── models/
│   ├── User.js
│   ├── LPGProduct.js
│   ├── LPGSale.js
│   ├── LPGCustomer.js
│   ├── Brand.js
│   └── Feedback.js
├── routes/
│   ├── authRoutes.js
│   ├── lpgProductRoutes.js
│   ├── lpgSalesRoutes.js
│   ├── lpgCustomerRoutes.js
│   ├── userRoutes.js
│   ├── brandRoutes.js
│   ├── categoryRoutes.js
│   └── feedbackRoutes.js
├── middleware/
│   ├── authMiddleware.js
│   └── errorHandler.js
├── config/
│   └── db.js
├── utils/
│   └── fileStorage.js
├── server.js
├── .env
└── package.json
```

---

## 🎨 Color Theme & Styling Guide

| Element              | Hex Code  | Usage                           |
| -------------------- | --------- | ------------------------------- |
| **Primary Color**    | `#1565C0` | AppBar, Buttons, Titles         |
| **Secondary Color**  | `#FF6F00` | Highlights, CTAs, Badges        |
| **Success Color**    | `#2E7D32` | Safety, Confirmation            |
| **Warning Color**    | `#F57C00` | Alerts, Low Stock               |
| **Error Color**      | `#D32F2F` | Validation, Error Messages      |
| **Info Color**       | `#0288D1` | Information, Links              |
| **Light Background** | `#F8F9FA` | Main screens, forms             |
| **Card Surface**     | `#FFFFFF` | Cards, Panels                   |
| **Primary Text**     | `#1A1A1A` | Headings, Labels                |
| **Secondary Text**   | `#424242` | Descriptions, Body Text         |

### Cylinder Status Colors
| Status    | Color     | Usage                    |
|-----------|-----------|--------------------------|
| Empty     | `#E0E0E0` | Empty cylinders          |
| Filled    | `#4CAF50` | Filled cylinders         |
| Sold      | `#2196F3` | Sold cylinders           |
| Exchange  | `#FF9800` | Exchange transactions    |

---

## 🖋️ Typography

* Font: `Roboto` (Google Fonts)
* Headline1: 28px Bold
* Headline2: 24px Bold
* BodyText: 16px Regular
* Caption: 12px Light Gray

---

## 📱 Flutter App Structure

### Key Features

1. **LPG Dashboard**
   - Real-time cylinder inventory summary
   - Sales metrics and analytics
   - Low stock alerts
   - Customers due for refill
   - Quick action buttons

2. **Inventory Management**
   - Cylinder tracking (11.8kg, 15kg, 45.4kg)
   - Empty/Filled/Sold states
   - Accessory management
   - Inspection due dates
   - Stock alerts

3. **Customer Management**
   - Multiple delivery premises per customer
   - Refill history tracking
   - Consumption pattern analysis
   - Credit management
   - Loyalty tiers

4. **Sales Operations**
   - New sales with cylinder exchange
   - Refill transactions
   - Accessory sales
   - Delivery scheduling
   - Payment tracking

5. **Reports & Analytics**
   - Sales reports
   - Cylinder utilization
   - Customer analytics
   - Top products
   - Revenue tracking

---

## 🔒 Security Features

* **JWT Authentication** for secure API access
* **Password Hashing** using bcrypt
* **Input Validation** using express-validator
* **Rate Limiting** to prevent abuse
* **CORS Protection** for API security
* **Helmet** for HTTP header security

---

## 🚀 Getting Started

### Prerequisites
- Node.js (v14 or higher)
- MongoDB
- Flutter SDK
- VS Code or Android Studio

### Backend Setup
```bash
cd server
npm install
# Copy example.env to .env and configure
cp example.env .env
# Update MONGO_URI in .env
npm run dev
```

### Frontend Setup
```bash
cd app
flutter pub get
# Update API base URL in lib/services/lpg_api_service.dart
flutter run
```

---

## 📁 Project Structure

```
lpg-dealer-management/
├── server/          # Node.js Backend
│   ├── controllers/ # Business logic
│   ├── models/      # Database schemas
│   ├── routes/      # API endpoints
│   ├── middleware/  # Auth & error handling
│   └── utils/       # Helper functions
└── app/             # Flutter Frontend
    ├── lib/
    │   ├── models/      # Data models
    │   ├── screens/     # UI screens
    │   ├── services/    # API services
    │   └── lpg_theme.dart
    └── pubspec.yaml
```

---

## 🎯 Key Business Features

### Cylinder Management
- Track cylinder states (empty, filled, sold)
- Manage cylinder exchanges
- Monitor inspection due dates
- Handle deposits and refunds

### Customer Operations
- Multiple delivery addresses (premises)
- Refill history and consumption tracking
- Loyalty points and tiers
- Credit management
- Safety training records

### Sales & Delivery
- Cylinder refills and exchanges
- Accessory sales
- Delivery scheduling and tracking
- Multiple payment methods
- Invoice generation

### Analytics & Reporting
- Cylinder inventory summaries
- Sales trends and patterns
- Customer consumption analytics
- Top-selling products
- Revenue reports

---

## 📊 Database Models

### LPGProduct
- Cylinder types (11.8kg, 15kg, 45.4kg)
- Accessory categories
- Inventory states (empty/filled/sold)
- Pricing and deposits
- Inspection tracking

### LPGCustomer
- Customer information
- Multiple premises (delivery locations)
- Refill history
- Loyalty points and tiers
- Credit management
- Emergency contacts

### LPGSale
- Sale items (cylinders and accessories)
- Delivery information
- Payment tracking
- Cylinder exchanges
- Deposits and refunds

---

## 🔧 Configuration

### Environment Variables
```env
MONGO_URI=mongodb://localhost:27017/lpg_dealer_shop
JWT_SECRET=your_secret_key
JWT_EXPIRE=7d
PORT=5000
NODE_ENV=development
```

### API Base URL
Update in `app/lib/services/lpg_api_service.dart`:
```dart
static const String _baseUrl = 'http://YOUR_IP:5000/api';
```

---

## 📈 Future Enhancements

- [ ] Mobile delivery app for drivers
- [ ] IoT cylinder monitoring
- [ ] Route optimization for deliveries
- [ ] Customer self-service portal
- [ ] Automated compliance reporting
- [ ] SMS/Email notifications
- [ ] Barcode scanning for cylinders
- [ ] Multi-language support

---

## 📝 License

MIT License - Feel free to use this project for your business needs.

---

## 👨‍💻 Support

For issues and questions, please create an issue in the repository or contact the development team.

---

## 🙏 Acknowledgments

Built with modern technologies and best practices for LPG dealer operations management.
