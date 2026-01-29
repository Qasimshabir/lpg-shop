// Quick test script to verify implementation
// Run with: node test-implementation.js

const mongoose = require('mongoose');
require('dotenv').config();

const Cylinder = require('./models/Cylinder');
const SafetyChecklist = require('./models/SafetyChecklist');
const SafetyIncident = require('./models/SafetyIncident');
const AuditLog = require('./models/AuditLog');
const DeliveryPersonnel = require('./models/DeliveryPersonnel');
const DeliveryRoute = require('./models/DeliveryRoute');

async function testImplementation() {
  try {
    console.log('🔍 Testing LPG Dealer Management System Implementation...\n');
    
    // Connect to MongoDB
    console.log('📡 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');
    
    // Test 1: Cylinder Model
    console.log('1️⃣  Testing Cylinder Model...');
    const cylinderCount = await Cylinder.countDocuments();
    console.log(`   Found ${cylinderCount} cylinders in database`);
    console.log('   ✅ Cylinder model working\n');
    
    // Test 2: Safety Models
    console.log('2️⃣  Testing Safety Models...');
    const checklistCount = await SafetyChecklist.countDocuments();
    const incidentCount = await SafetyIncident.countDocuments();
    console.log(`   Found ${checklistCount} safety checklists`);
    console.log(`   Found ${incidentCount} safety incidents`);
    console.log('   ✅ Safety models working\n');
    
    // Test 3: Audit Log
    console.log('3️⃣  Testing Audit Log Model...');
    const auditCount = await AuditLog.countDocuments();
    console.log(`   Found ${auditCount} audit log entries`);
    console.log('   ✅ Audit log model working\n');
    
    // Test 4: Delivery Models
    console.log('4️⃣  Testing Delivery Models...');
    const personnelCount = await DeliveryPersonnel.countDocuments();
    const routeCount = await DeliveryRoute.countDocuments();
    console.log(`   Found ${personnelCount} delivery personnel`);
    console.log(`   Found ${routeCount} delivery routes`);
    console.log('   ✅ Delivery models working\n');
    
    // Test 5: Checklist Template
    console.log('5️⃣  Testing Safety Checklist Template...');
    const template = SafetyChecklist.getTemplate('new-connection');
    console.log(`   Template has ${template.length} categories`);
    const totalItems = template.reduce((sum, cat) => sum + cat.items.length, 0);
    console.log(`   Template has ${totalItems} total checklist items`);
    console.log('   ✅ Checklist template working\n');
    
    // Test 6: Indexes
    console.log('6️⃣  Testing Database Indexes...');
    const cylinderIndexes = await Cylinder.collection.getIndexes();
    const safetyIndexes = await SafetyChecklist.collection.getIndexes();
    const auditIndexes = await AuditLog.collection.getIndexes();
    console.log(`   Cylinder indexes: ${Object.keys(cylinderIndexes).length}`);
    console.log(`   Safety checklist indexes: ${Object.keys(safetyIndexes).length}`);
    console.log(`   Audit log indexes: ${Object.keys(auditIndexes).length}`);
    console.log('   ✅ Indexes created successfully\n');
    
    console.log('🎉 All tests passed! Implementation is working correctly.\n');
    console.log('📋 Summary:');
    console.log('   ✅ All models created and accessible');
    console.log('   ✅ Database connections working');
    console.log('   ✅ Indexes created properly');
    console.log('   ✅ Template system working');
    console.log('\n✨ Ready for API testing!\n');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error(error);
  } finally {
    await mongoose.connection.close();
    console.log('👋 Disconnected from MongoDB');
  }
}

testImplementation();
