const { getSupabaseClient } = require('../config/supabase');

const auditLog = (action, resource) => {
  return async (req, res, next) => {
    // Capture original data for updates/deletes
    if (['PUT', 'DELETE', 'PATCH'].includes(req.method) && req.params.id) {
      try {
        const supabase = getSupabaseClient();
        const tableName = getTableName(resource);
        
        if (tableName) {
          const { data } = await supabase
            .from(tableName)
            .select('*')
            .eq('id', req.params.id)
            .single();
          
          req.originalData = data;
        }
      } catch (error) {
        console.error('Failed to fetch original data for audit:', error);
      }
    }
    
    // Override res.json to capture response
    const originalJson = res.json.bind(res);
    res.json = function(data) {
      // Log after successful operation
      if (res.statusCode >= 200 && res.statusCode < 300 && req.user) {
        const supabase = getSupabaseClient();
        
        const logData = {
          user_id: req.user.id,
          action,
          resource,
          resource_id: req.params.id || data.data?.id,
          details: {
            method: req.method,
            path: req.path,
            result: 'success',
            changes: (req.method === 'PUT' || req.method === 'PATCH') ? {
              before: req.originalData,
              after: data.data
            } : null
          },
          ip_address: req.ip,
          user_agent: req.get('user-agent')
        };
        
        // Create audit log (don't wait for it)
        supabase
          .from('audit_logs')
          .insert([logData])
          .then(() => {})
          .catch(err => console.error('Audit log creation failed:', err));
      }
      
      return originalJson(data);
    };
    
    next();
  };
};

// Helper to get table name by resource name
function getTableName(resource) {
  const tables = {
    'product': 'lpg_products',
    'customer': 'lpg_customers',
    'sale': 'lpg_sales',
    'cylinder': 'cylinders',
    'user': 'users'
  };
  
  return tables[resource];
}

module.exports = { auditLog };
