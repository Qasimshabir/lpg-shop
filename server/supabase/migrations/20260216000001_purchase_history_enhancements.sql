-- ============================================
-- PURCHASE HISTORY ENHANCEMENTS
-- Migration to add purchase history views and functions
-- ============================================

-- Add purchase history specific indexes for faster retrieval
CREATE INDEX IF NOT EXISTS idx_sales_customer_date ON lpg_sales(customer_id, sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_sales_customer_status ON lpg_sales(customer_id, payment_status);
CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id, created_at DESC);

-- Add GIN index for full-text search on invoice numbers and notes
CREATE INDEX IF NOT EXISTS idx_sales_invoice_trgm ON lpg_sales USING gin(invoice_number gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_sales_notes_trgm ON lpg_sales USING gin(notes gin_trgm_ops);

-- ============================================
-- CUSTOMER PURCHASE SUMMARY VIEW
-- ============================================
CREATE OR REPLACE VIEW customer_purchase_summary AS
SELECT 
  c.id AS customer_id,
  c.customer_id AS customer_code,
  c.name AS customer_name,
  c.phone,
  c.email,
  COUNT(DISTINCT s.id) AS total_orders,
  COALESCE(SUM(s.total_amount), 0) AS total_spent,
  COALESCE(AVG(s.total_amount), 0) AS average_order_value,
  MAX(s.sale_date) AS last_purchase_date,
  MIN(s.sale_date) AS first_purchase_date,
  COUNT(DISTINCT CASE WHEN s.sale_date >= CURRENT_DATE - INTERVAL '30 days' THEN s.id END) AS orders_last_30_days,
  COUNT(DISTINCT CASE WHEN s.sale_date >= CURRENT_DATE - INTERVAL '90 days' THEN s.id END) AS orders_last_90_days,
  COALESCE(SUM(CASE WHEN s.sale_date >= CURRENT_DATE - INTERVAL '30 days' THEN s.total_amount ELSE 0 END), 0) AS spent_last_30_days,
  COALESCE(SUM(CASE WHEN s.payment_status = 'pending' THEN s.total_amount ELSE 0 END), 0) AS pending_amount
FROM lpg_customers c
LEFT JOIN lpg_sales s ON c.id = s.customer_id
GROUP BY c.id, c.customer_id, c.name, c.phone, c.email;

-- ============================================
-- PRODUCT PURCHASE HISTORY VIEW
-- ============================================
CREATE OR REPLACE VIEW product_purchase_history AS
SELECT 
  p.id AS product_id,
  p.name AS product_name,
  p.image_url,
  p.brand_id,
  b.title AS brand_name,
  COUNT(DISTINCT si.sale_id) AS times_sold,
  COALESCE(SUM(si.quantity), 0) AS total_quantity_sold,
  COALESCE(SUM(si.subtotal), 0) AS total_revenue,
  MAX(s.sale_date) AS last_sold_date,
  COALESCE(AVG(si.unit_price), 0) AS average_selling_price
FROM lpg_products p
LEFT JOIN brands b ON p.brand_id = b.id
LEFT JOIN sale_items si ON p.id = si.product_id
LEFT JOIN lpg_sales s ON si.sale_id = s.id
GROUP BY p.id, p.name, p.image_url, p.brand_id, b.title;

-- ============================================
-- MONTHLY SALES SUMMARY VIEW
-- ============================================
CREATE OR REPLACE VIEW monthly_sales_summary AS
SELECT 
  DATE_TRUNC('month', sale_date) AS month,
  user_id,
  COUNT(DISTINCT id) AS total_orders,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COALESCE(SUM(total_amount), 0) AS total_revenue,
  COALESCE(AVG(total_amount), 0) AS average_order_value,
  COUNT(DISTINCT CASE WHEN payment_status = 'paid' THEN id END) AS paid_orders,
  COUNT(DISTINCT CASE WHEN payment_status = 'pending' THEN id END) AS pending_orders
FROM lpg_sales
GROUP BY DATE_TRUNC('month', sale_date), user_id
ORDER BY month DESC;

-- ============================================
-- CUSTOMER LOYALTY METRICS VIEW
-- ============================================
CREATE OR REPLACE VIEW customer_loyalty_metrics AS
SELECT 
  c.id AS customer_id,
  c.name AS customer_name,
  COUNT(DISTINCT s.id) AS purchase_frequency,
  COALESCE(SUM(s.total_amount), 0) AS lifetime_value,
  EXTRACT(DAYS FROM (MAX(s.sale_date) - MIN(s.sale_date))) AS customer_lifetime_days,
  CASE 
    WHEN MAX(s.sale_date) >= CURRENT_DATE - INTERVAL '30 days' THEN 'Active'
    WHEN MAX(s.sale_date) >= CURRENT_DATE - INTERVAL '90 days' THEN 'At Risk'
    ELSE 'Inactive'
  END AS customer_status,
  CASE 
    WHEN COUNT(DISTINCT s.id) >= 20 THEN 'Platinum'
    WHEN COUNT(DISTINCT s.id) >= 10 THEN 'Gold'
    WHEN COUNT(DISTINCT s.id) >= 5 THEN 'Silver'
    ELSE 'Bronze'
  END AS loyalty_tier
FROM lpg_customers c
LEFT JOIN lpg_sales s ON c.id = s.customer_id
GROUP BY c.id, c.name;

-- ============================================
-- FUNCTION: Get Customer Purchase History
-- ============================================
CREATE OR REPLACE FUNCTION get_customer_purchase_history(
  p_customer_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  sale_id UUID,
  invoice_number VARCHAR,
  sale_date TIMESTAMP,
  total_amount DECIMAL,
  payment_method VARCHAR,
  payment_status VARCHAR,
  delivery_status VARCHAR,
  items_count BIGINT,
  products_summary TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id AS sale_id,
    s.invoice_number,
    s.sale_date,
    s.total_amount,
    s.payment_method,
    s.payment_status,
    s.delivery_status,
    COUNT(si.id) AS items_count,
    STRING_AGG(
      p.name || ' (x' || si.quantity || ')', 
      ', ' 
      ORDER BY si.created_at
    ) AS products_summary
  FROM lpg_sales s
  LEFT JOIN sale_items si ON s.id = si.sale_id
  LEFT JOIN lpg_products p ON si.product_id = p.id
  WHERE s.customer_id = p_customer_id
  GROUP BY s.id, s.invoice_number, s.sale_date, s.total_amount, 
           s.payment_method, s.payment_status, s.delivery_status
  ORDER BY s.sale_date DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Get Detailed Sale Information
-- ============================================
CREATE OR REPLACE FUNCTION get_sale_details(p_sale_id UUID)
RETURNS TABLE (
  sale_id UUID,
  invoice_number VARCHAR,
  sale_date TIMESTAMP,
  customer_name VARCHAR,
  customer_phone VARCHAR,
  total_amount DECIMAL,
  payment_method VARCHAR,
  payment_status VARCHAR,
  delivery_status VARCHAR,
  delivery_address TEXT,
  product_id UUID,
  product_name VARCHAR,
  brand_name VARCHAR,
  quantity INTEGER,
  unit_price DECIMAL,
  subtotal DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id AS sale_id,
    s.invoice_number,
    s.sale_date,
    c.name AS customer_name,
    c.phone AS customer_phone,
    s.total_amount,
    s.payment_method,
    s.payment_status,
    s.delivery_status,
    s.delivery_address,
    p.id AS product_id,
    p.name AS product_name,
    b.title AS brand_name,
    si.quantity,
    si.unit_price,
    si.subtotal
  FROM lpg_sales s
  LEFT JOIN lpg_customers c ON s.customer_id = c.id
  LEFT JOIN sale_items si ON s.id = si.sale_id
  LEFT JOIN lpg_products p ON si.product_id = p.id
  LEFT JOIN brands b ON p.brand_id = b.id
  WHERE s.id = p_sale_id
  ORDER BY si.created_at;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Get Customer Product Preferences
-- ============================================
CREATE OR REPLACE FUNCTION get_customer_product_preferences(
  p_customer_id UUID,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  product_id UUID,
  product_name VARCHAR,
  brand_name VARCHAR,
  image_url TEXT,
  purchase_count BIGINT,
  total_quantity BIGINT,
  total_spent DECIMAL,
  last_purchased TIMESTAMP,
  average_price DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id AS product_id,
    p.name AS product_name,
    b.title AS brand_name,
    p.image_url,
    COUNT(DISTINCT s.id) AS purchase_count,
    SUM(si.quantity)::BIGINT AS total_quantity,
    SUM(si.subtotal) AS total_spent,
    MAX(s.sale_date) AS last_purchased,
    AVG(si.unit_price) AS average_price
  FROM lpg_sales s
  JOIN sale_items si ON s.id = si.sale_id
  JOIN lpg_products p ON si.product_id = p.id
  LEFT JOIN brands b ON p.brand_id = b.id
  WHERE s.customer_id = p_customer_id
  GROUP BY p.id, p.name, p.image_url, b.title
  ORDER BY purchase_count DESC, total_spent DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Get Purchase History by Date Range
-- ============================================
CREATE OR REPLACE FUNCTION get_purchase_history_by_date(
  p_customer_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  sale_id UUID,
  invoice_number VARCHAR,
  sale_date TIMESTAMP,
  total_amount DECIMAL,
  payment_status VARCHAR,
  items_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id AS sale_id,
    s.invoice_number,
    s.sale_date,
    s.total_amount,
    s.payment_status,
    COUNT(si.id) AS items_count
  FROM lpg_sales s
  LEFT JOIN sale_items si ON s.id = si.sale_id
  WHERE s.customer_id = p_customer_id
    AND s.sale_date::DATE BETWEEN p_start_date AND p_end_date
  GROUP BY s.id, s.invoice_number, s.sale_date, s.total_amount, s.payment_status
  ORDER BY s.sale_date DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Calculate Customer Lifetime Value
-- ============================================
CREATE OR REPLACE FUNCTION calculate_customer_ltv(p_customer_id UUID)
RETURNS TABLE (
  total_orders BIGINT,
  total_spent DECIMAL,
  average_order_value DECIMAL,
  first_purchase DATE,
  last_purchase DATE,
  customer_lifetime_days INTEGER,
  predicted_next_purchase DATE,
  loyalty_tier VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT s.id)::BIGINT AS total_orders,
    COALESCE(SUM(s.total_amount), 0) AS total_spent,
    COALESCE(AVG(s.total_amount), 0) AS average_order_value,
    MIN(s.sale_date)::DATE AS first_purchase,
    MAX(s.sale_date)::DATE AS last_purchase,
    EXTRACT(DAYS FROM (MAX(s.sale_date) - MIN(s.sale_date)))::INTEGER AS customer_lifetime_days,
    (MAX(s.sale_date) + 
      INTERVAL '1 day' * 
      (EXTRACT(DAYS FROM (MAX(s.sale_date) - MIN(s.sale_date))) / 
       NULLIF(COUNT(DISTINCT s.id), 0))
    )::DATE AS predicted_next_purchase,
    CASE 
      WHEN COUNT(DISTINCT s.id) >= 20 THEN 'Platinum'
      WHEN COUNT(DISTINCT s.id) >= 10 THEN 'Gold'
      WHEN COUNT(DISTINCT s.id) >= 5 THEN 'Silver'
      ELSE 'Bronze'
    END AS loyalty_tier
  FROM lpg_sales s
  WHERE s.customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STORAGE BUCKET FOR PRODUCT IMAGES
-- ============================================
-- Create storage bucket for product images if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for product images
CREATE POLICY "Public Access for Product Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can upload product images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'product-images' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can update their product images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'product-images' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can delete their product images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'product-images' 
  AND auth.role() = 'authenticated'
);
