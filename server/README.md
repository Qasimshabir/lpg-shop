# LPG Dealer Management System - Backend API

Backend API for LPG Dealer Management System built with Express.js and Supabase (PostgreSQL).

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: Supabase (PostgreSQL)
- **Authentication**: JWT
- **Deployment**: Vercel (Serverless)

## Features

- User authentication and authorization
- Role-based access control
- LPG product management
- Customer management
- Sales tracking
- Cylinder inventory management
- Feedback system
- Audit logging
- Image upload support

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env` and fill in your values:
```bash
cp .env.example .env
```

Required variables:
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anon/public key
- `SUPABASE_SERVICE_KEY`: Your Supabase service key (for admin operations)
- `JWT_SECRET`: Secret key for JWT tokens (min 32 characters)
- `JWT_EXPIRE`: Token expiration time (e.g., "7d")

### 3. Test Supabase Connection
```bash
npm run test:supabase
```

### 4. Run Development Server
```bash
npm run dev
```

Server will start on http://localhost:5000

## API Endpoints

### Authentication
- `POST /api/register` - Register new user
- `POST /api/login` - Login user
- `POST /api/forgot-password` - Request password reset

### Users
- `GET /api/users/me` - Get current user profile
- `PUT /api/users/me` - Update profile
- `PUT /api/users/password` - Change password

### Products
- `GET /api/products` - List all products
- `POST /api/products` - Create product
- `GET /api/products/:id` - Get product details
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

### Customers
- `GET /api/customers` - List all customers
- `POST /api/customers` - Create customer
- `GET /api/customers/:id` - Get customer details
- `PUT /api/customers/:id` - Update customer
- `DELETE /api/customers/:id` - Delete customer

### Sales
- `GET /api/sales` - List all sales
- `POST /api/sales` - Create sale
- `GET /api/sales/:id` - Get sale details
- `GET /api/sales/report` - Get sales report

### Health & Debug
- `GET /api/health` - Health check
- `GET /api/debug/env` - Environment variables check

## Database Schema

The database includes the following tables:
- `roles` - User roles and permissions
- `users` - User accounts
- `brands` - LPG brands
- `lpg_products` - Product catalog
- `lpg_customers` - Customer records
- `lpg_sales` - Sales transactions
- `sale_items` - Sale line items
- `cylinders` - Cylinder inventory
- `feedback` - Customer feedback
- `images` - Uploaded images
- `audit_logs` - System audit trail

## Deployment

### Deploy to Vercel

See [VERCEL_DEPLOYMENT.md](./VERCEL_DEPLOYMENT.md) for detailed deployment instructions.

Quick deploy:
```bash
vercel
```

### Environment Variables on Vercel

Add these in Vercel Dashboard → Settings → Environment Variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_KEY`
- `JWT_SECRET`
- `JWT_EXPIRE`
- `NODE_ENV=production`

## Project Structure

```
server/
├── api/
│   └── index.js          # Vercel serverless entry point
├── config/
│   ├── supabase.js       # Supabase client configuration
│   └── logger.js         # Winston logger setup
├── controllers/          # Route controllers
├── middleware/           # Express middleware
├── routes/              # API routes
├── types/
│   └── supabase.ts      # TypeScript types for Supabase
├── utils/               # Utility functions
├── server.js            # Express app setup
├── vercel.json          # Vercel configuration
└── package.json         # Dependencies
```

## Security

- Helmet.js for security headers
- Rate limiting (100 requests per 15 minutes)
- CORS configured
- JWT authentication
- Input validation with express-validator
- Audit logging for all operations

## Development

### Run Tests
```bash
npm test
```

### Test Supabase Connection
```bash
npm run test:supabase
```

### Watch Mode
```bash
npm run dev
```

## Troubleshooting

### Connection Issues
1. Verify Supabase credentials in `.env`
2. Check Supabase project is active
3. Test with `npm run test:supabase`

### Deployment Issues
1. Ensure all environment variables are set in Vercel
2. Check logs in Vercel Dashboard
3. Verify `vercel.json` configuration

## Support

For issues and questions:
1. Check the logs in `logs/` directory
2. Review Vercel deployment logs
3. Check Supabase Dashboard for database issues

## License

MIT
