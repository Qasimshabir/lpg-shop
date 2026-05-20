-- Add trigger to ensure stock_quantity consistency with cylinder_states
-- This automatically calculates stock_quantity as empty + filled

CREATE OR REPLACE FUNCTION update_cylinder_stock()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update for cylinder products with cylinder_states
  IF NEW.product_type = 'cylinder' AND NEW.cylinder_states IS NOT NULL THEN
    -- Calculate stock_quantity as empty + filled
    NEW.stock_quantity := 
      COALESCE((NEW.cylinder_states->>'empty')::int, 0) + 
      COALESCE((NEW.cylinder_states->>'filled')::int, 0);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for INSERT and UPDATE
CREATE TRIGGER trigger_update_cylinder_stock
BEFORE INSERT OR UPDATE ON lpg_products
FOR EACH ROW
EXECUTE FUNCTION update_cylinder_stock();

-- Add comment explaining the trigger
COMMENT ON FUNCTION update_cylinder_stock() IS 
'Automatically calculates stock_quantity as the sum of empty and filled cylinders for cylinder products';
