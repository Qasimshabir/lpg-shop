-- Add name field to delivery_personnel table
ALTER TABLE delivery_personnel 
ADD COLUMN name VARCHAR(255);

-- Update existing records to use the user's name
UPDATE delivery_personnel dp
SET name = u.name
FROM users u
WHERE dp.user_id = u.id AND dp.name IS NULL;
