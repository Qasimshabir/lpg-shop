const SafetyChecklist = require('../models/SafetyChecklist');
const SafetyIncident = require('../models/SafetyIncident');

// @desc    Get checklist for sale
// @route   GET /api/safety/checklists/sale/:saleId
// @access  Private
exports.getChecklistForSale = async (req, res, next) => {
  try {
    const checklist = await SafetyChecklist.findOne({
      saleId: req.params.saleId
    })
      .populate('customerId', 'name phone')
      .populate('completedBy', 'name')
      .populate('items.checkedBy', 'name');
    
    if (!checklist) {
      return res.status(404).json({
        success: false,
        message: 'Checklist not found'
      });
    }
    
    res.json({
      success: true,
      data: checklist
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create safety checklist
// @route   POST /api/safety/checklists
// @access  Private
exports.createChecklist = async (req, res, next) => {
  try {
    const { saleId, customerId, checklistType } = req.body;
    
    const template = SafetyChecklist.getTemplate(checklistType);
    
    const checklistItems = template.flatMap(category =>
      category.items.map(item => ({
        category: category.category,
        item,
        checked: false
      }))
    );
    
    const checklist = await SafetyChecklist.create({
      saleId,
      customerId,
      checklistType,
      items: checklistItems,
      completedBy: req.user.id,
      status: 'pending'
    });
    
    res.status(201).json({
      success: true,
      message: 'Checklist created successfully',
      data: checklist
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Check checklist item
// @route   PUT /api/safety/checklists/:id/items/:itemId
// @access  Private
exports.checkItem = async (req, res, next) => {
  try {
    const { notes } = req.body;
    
    const checklist = await SafetyChecklist.findById(req.params.id);
    
    if (!checklist) {
      return res.status(404).json({
        success: false,
        message: 'Checklist not found'
      });
    }
    
    await checklist.checkItem(req.params.itemId, req.user.id, notes);
    
    res.json({
      success: true,
      message: 'Item checked successfully',
      data: checklist
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add customer acknowledgment
// @route   POST /api/safety/checklists/:id/acknowledge
// @access  Private
exports.addAcknowledgment = async (req, res, next) => {
  try {
    const { signature, customerName } = req.body;
    
    if (!signature || !customerName) {
      return res.status(400).json({
        success: false,
        message: 'Signature and customer name required'
      });
    }
    
    const checklist = await SafetyChecklist.findById(req.params.id);
    
    if (!checklist) {
      return res.status(404).json({
        success: false,
        message: 'Checklist not found'
      });
    }
    
    await checklist.addAcknowledgment(signature, customerName);
    
    res.json({
      success: true,
      message: 'Acknowledgment recorded successfully',
      data: checklist
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Report safety incident
// @route   POST /api/safety/incidents
// @access  Private
exports.reportIncident = async (req, res, next) => {
  try {
    const incidentData = {
      ...req.body,
      reportedBy: req.user.id,
      reportedDate: new Date()
    };
    
    const incident = await SafetyIncident.create(incidentData);
    
    res.status(201).json({
      success: true,
      message: 'Incident reported successfully',
      data: incident
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all incidents
// @route   GET /api/safety/incidents
// @access  Private
exports.getIncidents = async (req, res, next) => {
  try {
    const { status, severity, startDate, endDate } = req.query;
    
    const query = { reportedBy: req.user.id };
    
    if (status) query.status = status;
    if (severity) query.severity = severity;
    if (startDate && endDate) {
      query.incidentDate = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }
    
    const incidents = await SafetyIncident.find(query)
      .populate('customerId', 'name phone')
      .populate('cylinderId', 'serialNumber')
      .populate('reportedBy', 'name')
      .sort({ incidentDate: -1 });
    
    res.json({
      success: true,
      count: incidents.length,
      data: incidents
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update incident status
// @route   PUT /api/safety/incidents/:id/status
// @access  Private
exports.updateIncidentStatus = async (req, res, next) => {
  try {
    const { status, notes } = req.body;
    
    const incident = await SafetyIncident.findById(req.params.id);
    
    if (!incident) {
      return res.status(404).json({
        success: false,
        message: 'Incident not found'
      });
    }
    
    await incident.updateStatus(status, req.user.id, notes);
    
    res.json({
      success: true,
      message: 'Incident status updated',
      data: incident
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get safety compliance report
// @route   GET /api/safety/compliance-report
// @access  Private
exports.getComplianceReport = async (req, res, next) => {
  try {
    const { startDate, endDate } = req.query;
    
    const dateFilter = {};
    if (startDate && endDate) {
      dateFilter.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }
    
    const checklistStats = await SafetyChecklist.aggregate([
      { $match: dateFilter },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);
    
    const incidentStats = await SafetyIncident.aggregate([
      { $match: dateFilter },
      {
        $group: {
          _id: {
            type: '$incidentType',
            severity: '$severity'
          },
          count: { $sum: 1 }
        }
      }
    ]);
    
    const pendingChecklists = await SafetyChecklist.countDocuments({
      status: { $in: ['pending', 'in-progress'] }
    });
    
    const openIncidents = await SafetyIncident.countDocuments({
      status: { $ne: 'closed' }
    });
    
    const total = checklistStats.reduce((sum, s) => sum + s.count, 0);
    const completed = checklistStats.find(s => s._id === 'completed')?.count || 0;
    const complianceRate = total > 0 ? Math.round((completed / total) * 100) : 0;
    
    res.json({
      success: true,
      data: {
        checklistStats,
        incidentStats,
        pendingChecklists,
        openIncidents,
        complianceRate
      }
    });
  } catch (error) {
    next(error);
  }
};

// Functions are already exported via exports.functionName above
