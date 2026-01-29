const AuditLog = require('../models/AuditLog');

const auditLog = (action, resource) => {
  return async (req, res, next) => {
    // Capture original data for updates/deletes
    if (['PUT', 'DELETE', 'PATCH'].includes(req.method) && req.params.id) {
      try {
        const Model = getModel(resource);
        if (Model) {
          req.originalData = await Model.findById(req.params.id).lean();
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
        const logData = {
          userId: req.user.id,
          userName: req.user.name,
          action,
          resource,
          resourceId: req.params.id || data.data?._id,
          method: req.method,
          path: req.path,
          ipAddress: req.ip,
          userAgent: req.get('user-agent'),
          timestamp: new Date(),
          result: 'success'
        };
        
        // Add changes for updates
        if (req.method === 'PUT' || req.method === 'PATCH') {
          logData.changes = {
            before: req.originalData,
            after: data.data
          };
        }
        
        // Create audit log (don't wait for it)
        AuditLog.create(logData).catch(err => 
          console.error('Audit log creation failed:', err)
        );
      }
      
      return originalJson(data);
    };
    
    next();
  };
};

// Helper to get model by resource name
function getModel(resource) {
  const models = {
    'product': require('../models/LPGProduct'),
    'customer': require('../models/LPGCustomer'),
    'sale': require('../models/LPGSale'),
    'cylinder': require('../models/Cylinder'),
    'user': require('../models/User')
  };
  
  return models[resource];
}

module.exports = { auditLog };
