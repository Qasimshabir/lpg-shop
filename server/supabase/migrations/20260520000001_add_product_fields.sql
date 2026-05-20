-- Add missing product fields to lpg_products table
ALTER TABLE lpg_products
  ADD COLUMN IF NOT EXISTS product_type VARCHAR(50) DEFAULT 'cylinder',
  ADD COLUMN IF NOT EXISTS cylinder_type VARCHAR(50),
  ADD COLUMN IF NOT EXISTS capacity DECIMAL(10, 2),
  ADD COLUMN IF NOT EXISTS pressure_rating VARCHAR(50),
  ADD COLUMN IF NOT EXISTS cost_price DECIMAL(10, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS deposit_amount DECIMAL(10, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS refill_price DECIMAL(10, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS min_stock INTEGER DEFAULT 5,
  ADD COLUMN IF NOT EXISTS max_stock INTEGER DEFAULT 100,
  ADD COLUMN IF NOT EXISTS unit VARCHAR(20) DEFAULT 'Piece',
  ADD COLUMN IF NOT EXISTS barcode VARCHAR(100),
  ADD COLUMN IF NOT EXISTS discount DECIMAL(5, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS tags TEXT[],
  ADD COLUMN IF NOT EXISTS cylinder_states JSONB DEFAULT '{"empty": 0, "filled": 0, "sold": 0}'::jsonb,
  ADD COLUMN IF NOT EXISTS inspection_required BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS inspection_interval INTEGER DEFAULT 60,
  ADD COLUMN IF NOT EXISTS last_inspection_date DATE,
  ADD COLUMN IF NOT EXISTS next_inspection_due DATE,
  ADD COLUMN IF NOT EXISTS certification_number VARCHAR(100);

-- Create indexes for new fields
CREATE INDEX IF NOT EXISTS idx_products_product_type ON lpg_products(product_type);
CREATE INDEX IF NOT EXISTS idx_products_cylinder_type ON lpg_products(cylinder_type);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON lpg_products(barcode);

-- Update existing products to have default cylinder_states
UPDATE lpg_products 
SET cylinder_states = jsonb_build_object(
  'empty', 0,
  'filled', COALESCE(stock_quantity, 0),
  'sold', 0
)
WHERE cylinder_states IS NULL;
