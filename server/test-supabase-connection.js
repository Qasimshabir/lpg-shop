#!/usr/bin/env node

/**
 * Test Supabase Connection
 * 
 * This script tests if your Supabase connection is valid
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

async function testConnection() {
  console.log('🧪 Testing Supabase Connection\n');
  
  if (!process.env.SUPABASE_URL) {
    console.error('❌ SUPABASE_URL not found in .env file');
    process.exit(1);
  }
  
  if (!process.env.SUPABASE_ANON_KEY && !process.env.SUPABASE_SERVICE_KEY) {
    console.error('❌ SUPABASE_ANON_KEY or SUPABASE_SERVICE_KEY not found in .env file');
    process.exit(1);
  }
  
  console.log('Supabase URL:', process.env.SUPABASE_URL);
  console.log('API Key:', process.env.SUPABASE_SERVICE_KEY ? 'Service Key (****...)' : 'Anon Key (****...)');
  console.log('\n' + '='.repeat(60));
  
  try {
    console.log('\n⏳ Attempting to connect...\n');
    
    const { createClient } = require('@supabase/supabase-js');
    
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY
    );
    
    // Test connection by querying roles table
    const { data, error, count } = await supabase
      .from('roles')
      .select('*', { count: 'exact' });
    
    if (error) {
      if (error.code === 'PGRST116') {
        console.log('⚠️  Connected but tables not found!');
        console.log('   Please run the schema SQL file in Supabase SQL Editor:');
        console.log('   File: server/config/supabase-schema.sql\n');
        console.log('✅ Connection test successful (but schema needs to be created)\n');
        process.exit(0);
      }
      throw error;
    }
    
    console.log('✅ Successfully connected to Supabase!');
    console.log('   Project URL:', process.env.SUPABASE_URL);
    console.log('   Database: PostgreSQL');
    
    // List tables by checking roles
    console.log('\n📦 Sample data from roles table:');
    if (!data || data.length === 0) {
      console.log('   (No roles yet - run seed data)');
    } else {
      console.log(`   Found ${count} role(s):`);
      data.forEach(role => {
        console.log(`   - ${role.name}: ${role.description}`);
      });
    }
    
    // Test other tables
    const tables = ['users', 'lpg_products', 'lpg_customers', 'lpg_sales'];
    console.log('\n📊 Checking other tables:');
    
    for (const table of tables) {
      const { count: tableCount, error: tableError } = await supabase
        .from(table)
        .select('*', { count: 'exact', head: true });
      
      if (tableError) {
        console.log(`   ❌ ${table}: Error - ${tableError.message}`);
      } else {
        console.log(`   ✅ ${table}: ${tableCount || 0} records`);
      }
    }
    
    console.log('\n✅ Connection test successful!\n');
    
  } catch (error) {
    console.error('\n❌ Connection failed!');
    console.error('Error:', error.message);
    console.error('\nCommon issues:');
    console.error('1. Incorrect Supabase URL');
    console.error('2. Wrong API key');
    console.error('3. Tables not created yet (run schema SQL)');
    console.error('4. Network/firewall blocking connection');
    console.error('\nPlease check:');
    console.error('- Supabase Dashboard → Project Settings → API');
    console.error('- Copy the correct URL and keys');
    console.error('- Update your .env file\n');
    console.error('\nFull error:', error);
    process.exit(1);
  }
}

testConnection();
