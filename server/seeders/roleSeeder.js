const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { createClient } = require('@supabase/supabase-js');

// Predefined roles with permissions
const predefinedRoles = [
  {
    name: 'admin',
    description: 'Administrator with full access',
    permissions: JSON.stringify(['all'])
  },
  {
    name: 'manager',
    description: 'Manager with limited admin access',
    permissions: JSON.stringify(['read', 'write', 'update'])
  },
  {
    name: 'staff',
    description: 'Staff member with basic access',
    permissions: JSON.stringify(['read', 'write'])
  },
  {
    name: 'customer',
    description: 'Customer with view-only access',
    permissions: JSON.stringify(['read'])
  }
];

async function seedRoles() {
  try {
    console.log('🌱 Starting Role Seeder...\n');
    
    // Initialize Supabase client
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Missing Supabase credentials. Please set SUPABASE_URL and SUPABASE_SERVICE_KEY in .env');
    }

    console.log('📡 Connecting to Supabase...');
    const supabase = createClient(supabaseUrl, supabaseKey);
    console.log('✅ Connected to Supabase\n');
    
    // Clear existing roles
    console.log('🗑️  Clearing existing roles...');
    const { error: deleteError } = await supabase
      .from('roles')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all
    
    if (deleteError && deleteError.code !== 'PGRST116') {
      console.log('⚠️  Warning clearing roles:', deleteError.message);
    } else {
      console.log('✅ Existing roles cleared\n');
    }
    
    // Insert predefined roles
    console.log('📝 Inserting predefined roles...\n');
    
    const { data: roles, error: insertError } = await supabase
      .from('roles')
      .insert(predefinedRoles)
      .select();
    
    if (insertError) {
      throw insertError;
    }
    
    roles.forEach(role => {
      console.log(`   ✅ Created role: ${role.name}`);
      console.log(`      Description: ${role.description}`);
    });
    
    console.log('\n🎉 Role seeding completed successfully!\n');
    
    // Display summary
    console.log('📊 Summary:');
    console.log(`   Total roles created: ${roles.length}`);
    console.log('\n📋 Available Roles:');
    
    roles.forEach(role => {
      console.log(`\n   🔐 ${role.name}`);
      console.log(`      ${role.description}`);
    });
    
    console.log('\n✨ Roles are ready to be assigned to users!\n');
    
  } catch (error) {
    console.error('❌ Error seeding roles:', error.message);
    console.error(error);
  }
}

// Run the seeder
seedRoles();
