CREATE TABLE IF NOT EXISTS cylinder_refill_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES lpg_customers(id) ON DELETE CASCADE,
  cylinder_id UUID REFERENCES cylinders(id) ON DELETE SET NULL,
  refill_date DATE NOT NULL,
  quantity DECIMAL(10, 2),
  amount DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refill_history_customer ON cylinder_refill_history(customer_id);
CREATE INDEX IF NOT EXISTS idx_refill_history_cylinder ON cylinder_refill_history(cylinder_id);
CREATE INDEX IF NOT EXISTS idx_refill_history_date ON cylinder_refill_history(refill_date);;
