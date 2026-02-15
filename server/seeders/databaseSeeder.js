const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const User = require('../models/User');
const LPGProduct = require('../models/LPGProduct');
const LPGCustomer = require('../models/LPGCustomer');
const Cylinder = require('../models/Cylinder');
const DeliveryPersonnel = require('../models/DeliveryPersonnel');

async function seedDatabase() {
  try {
    console.log('🌱 Starting Complete Database Seeder...\n');
    
    // Check if MONGO_URI is loaded
    if (!process.env.MONGO_URI) {
      console.error('❌ MONGO_URI not found in environment variables');
      console.log('💡 Make sure .env file exists in the server directory');
      console.log('📁 Current directory:', __dirname);
      console.log('📁 Looking for .env at:', path.join(__dirname, '../.env'));
      process.exit(1);
    }
    
    // Connect to MongoDB
    console.log('📡 Connecting to MongoDB...');
    console.log('🔗 URI:', process.env.MONGO_URI.replace(/\/\/([^:]+):([^@]+)@/, '//$1:****@')); // Hide password
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');
    
    // 1. Create Admin User
    console.log('1️⃣  Creating Admin User...');
    await User.deleteMany({ email: 'admin@lpgdealer.com' });
    
    const adminUser = await User.create({
      name: 'Admin User',
      shopName: 'LPG Dealer Shop',
      ownerName: 'Qasim ',
      email: 'admin@lpgdealer.com',
      password: 'admin123',
      phone: '+929876543210',
      address: '123 Main Street, Business District',
      city: 'Islamabad',
      role: 'owner',
      isActive: true
    });
    console.log(`   ✅ Admin user created: ${adminUser.email}`);
    console.log(`   📧 Email: admin@lpgdealer.com`);
    console.log(`   🔑 Password: admin123\n`);
    
    // 2. Create Sample Products
    console.log('2️⃣  Creating Sample Products...');
    await LPGProduct.deleteMany({ userId: adminUser._id });
    
    const products = [
      {
        userId: adminUser._id,
        name: 'HP Gas 11.8kg Cylinder',
        brand: 'HP Gas',
        category: 'LPG Cylinder',
        productType: 'cylinder',
        cylinderType: '11.8kg',
        capacity: 11.8,
        pressureRating: '15 bar',
        cylinderStates: { empty: 10, filled: 20, sold: 5 },
        price: 950,
        costPrice: 800,
        depositAmount: 1500,
        refillPrice: 850,
        minStock: 5,
        maxStock: 50,
        sku: 'HPGLPG0001',
        description: 'Standard 11.8kg LPG cylinder for domestic use'
      },
      {
        userId: adminUser._id,
        name: 'HP Gas 15kg Cylinder',
        brand: 'HP Gas',
        category: 'LPG Cylinder',
        productType: 'cylinder',
        cylinderType: '15kg',
        capacity: 15,
        pressureRating: '15 bar',
        cylinderStates: { empty: 5, filled: 10, sold: 2 },
        price: 1200,
        costPrice: 1000,
        depositAmount: 2000,
        refillPrice: 1100,
        minStock: 3,
        maxStock: 30,
        sku: 'HPGLPG0002',
        description: 'Medium 15kg LPG cylinder for commercial use'
      },
      {
        userId: adminUser._id,
        name: 'HP Gas 45.4kg Cylinder',
        brand: 'HP Gas',
        category: 'LPG Cylinder',
        productType: 'cylinder',
        cylinderType: '45.4kg',
        capacity: 45.4,
        pressureRating: '15 bar',
        cylinderStates: { empty: 2, filled: 5, sold: 1 },
        price: 3500,
        costPrice: 3000,
        depositAmount: 5000,
        refillPrice: 3300,
        minStock: 2,
        maxStock: 15,
        sku: 'HPGLPG0003',
        description: 'Large 45.4kg LPG cylinder for industrial use'
      },
      {
        userId: adminUser._id,
        name: 'Gas Regulator',
        brand: 'Universal',
        category: 'Regulator',
        productType: 'accessory',
        unit: 'Piece',
        stock: 50,
        minStock: 10,
        maxStock: 100,
        price: 350,
        costPrice: 250,
        sku: 'UNIREGACC01',
        description: 'Standard LPG gas regulator'
      },
      {
        userId: adminUser._id,
        name: 'Gas Pipe (2 meters)',
        brand: 'Universal',
        category: 'Gas Pipe',
        productType: 'accessory',
        unit: 'Piece',
        stock: 30,
        minStock: 10,
        maxStock: 100,
        price: 200,
        costPrice: 150,
        sku: 'UNIGASACC02',
        description: '2 meter flexible gas pipe'
      }
    ];
    
    const createdProducts = await LPGProduct.insertMany(products);
    console.log(`   ✅ Created ${createdProducts.length} products\n`);
    
    // 3. Create Sample Cylinders
    console.log('3️⃣  Creating Sample Cylinders...');
    await Cylinder.deleteMany({ userId: adminUser._id });
    
    const cylinders = [];
    const cylinderTypes = ['11.8kg', '15kg', '45.4kg'];
    const manufacturers = ['HP Gas', 'Bharat Gas', 'Indane'];
    
    for (let i = 1; i <= 15; i++) {
      const type = cylinderTypes[i % 3];
      const manufacturer = manufacturers[i % 3];
      const year = 2024 + (i % 2);
      
      cylinders.push({
        userId: adminUser._id,
        serialNumber: `CYL-${year}-${String(i).padStart(6, '0')}`,
        capacity: type,
        manufacturer: manufacturer,
        manufacturingDate: new Date(`${year}-01-15`),
        tareWeight: type === '11.8kg' ? 15.5 : type === '15kg' ? 18.0 : 35.0,
        certificationNumber: `CERT-${year}-${String(i).padStart(4, '0')}`,
        certificationAuthority: 'National Safety Board',
        nextTestDue: new Date(`${year + 5}-01-15`),
        status: i % 3 === 0 ? 'in-stock' : i % 3 === 1 ? 'with-customer' : 'in-stock',
        depositAmount: type === '11.8kg' ? 1500 : type === '15kg' ? 2000 : 5000,
        isActive: true
      });
    }
    
    const createdCylinders = await Cylinder.insertMany(cylinders);
    console.log(`   ✅ Created ${createdCylinders.length} cylinders\n`);
    
    // 4. Create Sample Customers
    console.log('4️⃣  Creating Sample Customers...');
    await LPGCustomer.deleteMany({ userId: adminUser._id });
    
    const customers = [
      {
        userId: adminUser._id,
        name: 'Rajesh Kumar',
        email: 'rajesh@example.com',
        phone: '+919876543211',
        customerType: 'Individual',
        premises: [{
          name: 'Home',
          type: 'Residential',
          address: {
            street: '45 Park Avenue',
            city: 'Mumbai',
            state: 'Maharashtra',
            pincode: '400001',
            landmark: 'Near City Park'
          },
          cylinderCapacity: '11.8kg',
          isPrimary: true
        }],
        loyaltyPoints: 150,
        loyaltyTier: 'Silver',
        totalSpent: 5000,
        totalRefills: 5,
        creditLimit: 2000,
        currentCredit: 0
      },
      {
        userId: adminUser._id,
        name: 'Priya Restaurant',
        businessName: 'Priya Restaurant',
        email: 'priya@restaurant.com',
        phone: '+919876543212',
        customerType: 'Business',
        gstNumber: '27AABCU9603R1ZM',
        premises: [{
          name: 'Main Kitchen',
          type: 'Restaurant',
          address: {
            street: '78 Food Street',
            city: 'Mumbai',
            state: 'Maharashtra',
            pincode: '400002',
            landmark: 'Near Market'
          },
          cylinderCapacity: '15kg',
          estimatedMonthlyConsumption: 60,
          isPrimary: true
        }],
        loyaltyPoints: 500,
        loyaltyTier: 'Gold',
        totalSpent: 25000,
        totalRefills: 20,
        creditLimit: 10000,
        currentCredit: 0
      },
      {
        userId: adminUser._id,
        name: 'ABC Industries',
        businessName: 'ABC Industries Pvt Ltd',
        email: 'contact@abcindustries.com',
        phone: '+919876543213',
        customerType: 'Business',
        gstNumber: '27AABCU9603R1ZN',
        premises: [{
          name: 'Factory Unit 1',
          type: 'Industrial',
          address: {
            street: 'Plot 123, Industrial Area',
            city: 'Mumbai',
            state: 'Maharashtra',
            pincode: '400003',
            landmark: 'Near Highway'
          },
          cylinderCapacity: '45.4kg',
          estimatedMonthlyConsumption: 200,
          isPrimary: true
        }],
        loyaltyPoints: 2000,
        loyaltyTier: 'Platinum',
        totalSpent: 100000,
        totalRefills: 30,
        creditLimit: 50000,
        currentCredit: 0
      }
    ];
    
    const createdCustomers = await LPGCustomer.insertMany(customers);
    console.log(`   ✅ Created ${createdCustomers.length} customers\n`);
    
    // 5. Create Delivery Personnel
    console.log('5️⃣  Creating Delivery Personnel...');
    await DeliveryPersonnel.deleteMany({ userId: adminUser._id });
    
    const personnel = [
      {
        userId: adminUser._id,
        name: 'Ramesh Sharma',
        phone: '+919876543214',
        email: 'ramesh@delivery.com',
        vehicleNumber: 'MH01AB1234',
        vehicleType: 'van',
        licenseNumber: 'DL1234567890',
        licenseExpiry: new Date('2027-12-31'),
        isActive: true,
        availability: 'available',
        completedDeliveries: 150,
        rating: 4.5
      },
      {
        userId: adminUser._id,
        name: 'Suresh Patel',
        phone: '+919876543215',
        email: 'suresh@delivery.com',
        vehicleNumber: 'MH01CD5678',
        vehicleType: 'bike',
        licenseNumber: 'DL0987654321',
        licenseExpiry: new Date('2026-06-30'),
        isActive: true,
        availability: 'available',
        completedDeliveries: 200,
        rating: 4.8
      }
    ];
    
    const createdPersonnel = await DeliveryPersonnel.insertMany(personnel);
    console.log(`   ✅ Created ${createdPersonnel.length} delivery personnel\n`);
    
    // Summary
    console.log('🎉 Database seeding completed successfully!\n');
    console.log('📊 Summary:');
    console.log(`   👤 Users: 1 admin user`);
    console.log(`   📦 Products: ${createdProducts.length} products`);
    console.log(`   🛢️  Cylinders: ${createdCylinders.length} cylinders`);
    console.log(`   👥 Customers: ${createdCustomers.length} customers`);
    console.log(`   🚚 Delivery Personnel: ${createdPersonnel.length} personnel`);
    
    console.log('\n🔐 Login Credentials:');
    console.log('   Email: admin@lpgdealer.com');
    console.log('   Password: admin123');
    
    console.log('\n✨ Database is ready for use!\n');
    
  } catch (error) {
    console.error('❌ Error seeding database:', error.message);
    console.error(error);
  } finally {
    await mongoose.connection.close();
    console.log('👋 Disconnected from MongoDB');
  }
}

// Run the seeder
seedDatabase();
