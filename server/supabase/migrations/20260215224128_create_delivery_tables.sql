-- Create delivery_personnel table
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

-- Create indexes
CREATE INDEX idx_delivery_personnel_user ON delivery_personnel(user_id);

-- Create delivery_routes table
CREATE TABLE delivery_routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL,
  personnel_id UUID REFERENCES delivery_personnel(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'planned',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_delivery_routes_personnel ON delivery_routes(personnel_id);
CREATE INDEX idx_delivery_routes_date ON delivery_routes(date);

-- Add triggers for updated_at
CREATE TRIGGER update_delivery_personnel_updated_at 
  BEFORE UPDATE ON delivery_personnel 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_delivery_routes_updated_at 
  BEFORE UPDATE ON delivery_routes 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();;
