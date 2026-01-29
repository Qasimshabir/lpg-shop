const mongoose = require('mongoose');
require('dotenv').config();

// Role Model
const roleSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true,
    enum: ['super-admin', 'admin', 'manager', 'sales-person', 'delivery-person', 'inventory-manager']
  },
  displayName: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  permissions: [{
    resource: {
      type: String,
      required: true
    },
    actions: [{
      type: String,
      enum: ['create', 'read', 'update', 'delete', 'export', 'approve']
    }]
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const Role = mongoose.model('Role', roleSchema);

// Predefined roles with permissions
const predefinedRoles = [
  {
    name: 'super-admin',
    displayName: 'Super Administrator',
    description: 'Full system access with all permissions',
    permissions: [
      {
        resource: 'users',
        actions: ['create', 'read', 'update', 'delete']
      },
      {
        resource: 'roles',
        actions: ['create', 'read', 'update', 'delete']
      },
      {
        resource: 'products',
        actions: ['create', 'read', 'update', 'delete', 'export']
      },
      {
        resource: 'cylinders',
        actions: ['create', 'read', 'update', 'delete', 'export']
      },
      {
        resource: 'customers',
        actions: ['create', 'read', 'update', 'delete', 'export']
      },
      {
        resource: 'sales',
        actions: ['create', 'read', 'update', 'delete', 'export', 'approve']
      },
      {
        resource: 'delivery',
        actions: ['create', 'read', 'update', 'delete']
      },
      {
        resource: 'safety',
        actions: ['create', 'read', 'update', 'delete', 'export']
      },
      {
        resource: 'reports',
        actions: ['read', 'export']
      },
      {
        resource: 'audit-logs',
        actions: ['read', 'export']
      }
    ],
    isActive: true
  },
  {
    name: 'admin',
    displayName: 'Administrator',
    description: 'Shop owner or main administrator with most permissions',
    permissions: [
      {
        resource: 'users',
        actions: ['create', 'read', 'update']
      },
      {
        resource: 'products',
        actions: ['create', 'read', 'update', 'delete', 'export']
      },
      {
        resource: 'cylinders',
        actions: ['create', 'read', 'update', 'export']
      },
      {
        resource: 'customers',
        actions: ['create', 'read', 'update', 'delete', 'export']
      },
      {
        resource: 'sales',
        actions: ['create', 'read', 'update', 'delete', 'export', 'approve']
      },
      {
        resource: 'delivery',
        actions: ['create', 'read', 'update', 'delete']
      },
      {
        resource: 'safety',
        actions: ['create', 'read', 'update', 'export']
      },
      {
        resource: 'reports',
        actions: ['read', 'export']
      },
      {
        resource: 'audit-logs',
        actions: ['read']
      }
    ],
    isActive: true
  },
  {
    name: 'manager',
    displayName: 'Manager',
    description: 'Shop manager with operational permissions',
    permissions: [
      {
        resource: 'products',
        actions: ['create', 'read', 'update']
      },
      {
        resource: 'cylinders',
        actions: ['read', 'update']
      },
      {
        resource: 'customers',
        actions: ['create', 'read', 'update']
      },
      {
        resource: 'sales',
        actions: ['create', 'read', 'update', 'approve']
      },
      {
        resource: 'delivery',
        actions: ['create', 'read', 'update']
      },
      {
        resource: 'safety',
        actions: ['create', 'read', 'update']
      },
      {
        resource: 'reports',
        actions: ['read', 'export']
      }
    ],
    isActive: true
  },
  {
    name: 'sales-person',
    displayName: 'Sales Person',
    description: 'Sales staff with customer and sales permissions',
    permissions: [
      {
        resource: 'products',
        actions: ['read']
      },
      {
        resource: 'cylinders',
        actions: ['read']
      },
      {
        resource: 'customers',
        actions: ['create', 'read', 'update']
      },
      {
        resource: 'sales',
        actions: ['create', 'read']
      },
      {
        resource: 'safety',
        actions: ['create', 'read', 'update']
      }
    ],
    isActive: true
  },
  {
    name: 'delivery-person',
    displayName: 'Delivery Person',
    description: 'Delivery staff with delivery and route permissions',
    permissions: [
      {
        resource: 'customers',
        actions: ['read']
      },
      {
        resource: 'sales',
        actions: ['read', 'update']
      },
      {
        resource: 'delivery',
        actions: ['read', 'update']
      },
      {
        resource: 'safety',
        actions: ['read']
      }
    ],
    isActive: true
  },
  {
    name: 'inventory-manager',
    displayName: 'Inventory Manager',
    description: 'Inventory staff with product and cylinder management permissions',
    permissions: [
      {
        resource: 'products',
        actions: ['create', 'read', 'update']
      },
      {
        resource: 'cylinders',
        actions: ['create', 'read', 'update', 'export']
      },
      {
        resource: 'safety',
        actions: ['read', 'update']
      },
      {
        resource: 'reports',
        actions: ['read']
      }
    ],
    isActive: true
  }
];

async function seedRoles() {
  try {
    console.log('🌱 Starting Role Seeder...\n');
    
    // Connect to MongoDB
    console.log('📡 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');
    
    // Clear existing roles
    console.log('🗑️  Clearing existing roles...');
    await Role.deleteMany({});
    console.log('✅ Existing roles cleared\n');
    
    // Insert predefined roles
    console.log('📝 Inserting predefined roles...\n');
    
    for (const roleData of predefinedRoles) {
      const role = await Role.create(roleData);
      console.log(`   ✅ Created role: ${role.displayName} (${role.name})`);
      console.log(`      Permissions: ${role.permissions.length} resources`);
    }
    
    console.log('\n🎉 Role seeding completed successfully!\n');
    
    // Display summary
    console.log('📊 Summary:');
    console.log(`   Total roles created: ${predefinedRoles.length}`);
    console.log('\n📋 Available Roles:');
    
    const roles = await Role.find().sort({ name: 1 });
    roles.forEach(role => {
      console.log(`\n   🔐 ${role.displayName} (${role.name})`);
      console.log(`      ${role.description}`);
      console.log(`      Resources: ${role.permissions.map(p => p.resource).join(', ')}`);
    });
    
    console.log('\n✨ Roles are ready to be assigned to users!\n');
    
  } catch (error) {
    console.error('❌ Error seeding roles:', error.message);
    console.error(error);
  } finally {
    await mongoose.connection.close();
    console.log('👋 Disconnected from MongoDB');
  }
}

// Run the seeder
seedRoles();
