-- LPG Dealer Management System - PostgreSQL Schema for Supabase
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable timestamp functions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================
-- ROLES TABLE
-- ============================================
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  permissions JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  role_id UUID REFERENCES roles(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role_id);

-- ============================================
-- BRANDS TABLE
-- ============================================
CREATE TABLE brands (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  logo_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- LPG PRODUCTS TABLE
-- ============================================
CREATE TABLE lpg_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  brand_id UUID REFERENCES brands(id) ON DELETE SET NULL,
  category VARCHAR(100),
  weight DECIMAL(10, 2),
  weight_unit VARCHAR(20) DEFAULT 'kg',
  price DECIMAL(10, 2) NOT NULL,
  stock_quantity INTEGER DEFAULT 0,
  reorder_level INTEGER DEFAULT 10,
  description TEXT,
  image_url TEXT,
  sku VARCHAR(100) UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_products_user ON lpg_products(user_id);
CREATE INDEX idx_products_brand ON lpg_products(brand_id);
CREATE INDEX idx_products_sku ON lpg_products(sku);

-- ============================================
-- LPG CUSTOMERS TABLE
-- ============================================
CREATE TABLE lpg_customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  customer_id VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(20) NOT NULL,
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  customer_type VARCHAR(50) DEFAULT 'residential',
  registration_date DATE DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_customers_user ON lpg_customers(user_id);
CREATE INDEX idx_customers_customer_id ON lpg_customers(customer_id);
CREATE INDEX idx_customers_phone ON lpg_customers(phone);

-- ============================================
-- CUSTOMER PREMISES TABLE
-- ============================================
CREATE TABLE customer_premises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES lpg_customers(id) ON DELETE CASCADE,
  premises_type VARCHAR(50),
  address TEXT NOT NULL,
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- CYLINDERS TABLE
-- ============================================
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

-- ============================================
-- CYLINDER REFILL HISTORY TABLE
-- ============================================
CREATE TABLE cylinder_refill_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES lpg_customers(id) ON DELETE CASCADE,
  cylinder_id UUID REFERENCES cylinders(id) ON DELETE SET NULL,
  refill_date DATE NOT NULL,
  quantity DECIMAL(10, 2),
  amount DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- LPG SALES TABLE
-- ============================================
CREATE TABLE lpg_sales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  invoice_number VARCHAR(100) UNIQUE NOT NULL,
  customer_id UUID REFERENCES lpg_customers(id) ON DELETE SET NULL,
  sale_date TIMESTAMP DEFAULT NOW(),
  total_amount DECIMAL(10, 2) NOT NULL,
  payment_method VARCHAR(50),
  payment_status VARCHAR(50) DEFAULT 'pending',
  delivery_status VARCHAR(50) DEFAULT 'pending',
  delivery_address TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sales_user ON lpg_sales(user_id);
CREATE INDEX idx_sales_customer ON lpg_sales(customer_id);
CREATE INDEX idx_sales_invoice ON lpg_sales(invoice_number);
CREATE INDEX idx_sales_date ON lpg_sales(sale_date);

-- ============================================
-- SALE ITEMS TABLE
-- ============================================
CREATE TABLE sale_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_id UUID REFERENCES lpg_sales(id) ON DELETE CASCADE,
  product_id UUID REFERENCES lpg_products(id) ON DELETE SET NULL,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);

-- ============================================
-- FEEDBACK TABLE
-- ============================================
CREATE TABLE feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(100),
  subject VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  status VARCHAR(50) DEFAULT 'pending',
  response TEXT,
  responded_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_feedback_user ON feedback(user_id);
CREATE INDEX idx_feedback_status ON feedback(status);

-- ============================================
-- IMAGES TABLE
-- ============================================
CREATE TABLE images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  filename VARCHAR(255) NOT NULL,
  original_name VARCHAR(255),
  mime_type VARCHAR(100),
  size INTEGER,
  path TEXT NOT NULL,
  url TEXT,
  uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- DELIVERY PERSONNEL TABLE
-- ============================================
CREATE TABLE delivery_personnel (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  vehicle_number VARCHAR(50),
  license_number VARCHAR(100),
  phone VARCHAR(20),
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- DELIVERY ROUTES TABLE
-- ============================================
CREATE TABLE delivery_routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL,
  personnel_id UUID REFERENCES delivery_personnel(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'planned',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- SAFETY CHECKLISTS TABLE
-- ============================================
CREATE TABLE safety_checklists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_id UUID REFERENCES lpg_sales(id) ON DELETE CASCADE,
  cylinder_id UUID REFERENCES cylinders(id) ON DELETE SET NULL,
  checked_by UUID REFERENCES users(id) ON DELETE SET NULL,
  check_date TIMESTAMP DEFAULT NOW(),
  items JSONB DEFAULT '[]'::jsonb,
  passed BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- SAFETY INCIDENTS TABLE
-- ============================================
CREATE TABLE safety_incidents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  incident_date TIMESTAMP NOT NULL,
  location TEXT,
  description TEXT NOT NULL,
  severity VARCHAR(50),
  reported_by UUID REFERENCES users(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'reported',
  resolution TEXT,
  resolved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- AUDIT LOGS TABLE
-- ============================================
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL,
  resource VARCHAR(100),
  resource_id UUID,
  details JSONB,
  ip_address VARCHAR(50),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_created ON audit_logs(created_at);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to tables with updated_at
CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_brands_updated_at BEFORE UPDATE ON brands FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_lpg_products_updated_at BEFORE UPDATE ON lpg_products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_lpg_customers_updated_at BEFORE UPDATE ON lpg_customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cylinders_updated_at BEFORE UPDATE ON cylinders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_lpg_sales_updated_at BEFORE UPDATE ON lpg_sales FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_feedback_updated_at BEFORE UPDATE ON feedback FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_delivery_personnel_updated_at BEFORE UPDATE ON delivery_personnel FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_delivery_routes_updated_at BEFORE UPDATE ON delivery_routes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_safety_incidents_updated_at BEFORE UPDATE ON safety_incidents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY (RLS) - Optional
-- ============================================
-- Enable RLS on tables if needed
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY users_policy ON users FOR ALL USING (auth.uid() = id);

-- ============================================
-- SEED DATA
-- ============================================
-- Insert default roles
INSERT INTO roles (name, description, permissions) VALUES
  ('admin', 'Administrator with full access', '["all"]'::jsonb),
  ('manager', 'Manager with limited admin access', '["read", "write", "update"]'::jsonb),
  ('staff', 'Staff member with basic access', '["read", "write"]'::jsonb),
  ('customer', 'Customer with view-only access', '["read"]'::jsonb);

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Schema created successfully! ✅';
  RAISE NOTICE 'Tables created: %, rows inserted: %', 
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'),
    (SELECT COUNT(*) FROM roles);
END $$;
