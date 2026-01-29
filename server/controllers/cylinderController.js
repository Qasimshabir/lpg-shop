const Cylinder = require('../models/Cylinder');

// @desc    Register new cylinder
// @route   POST /api/cylinders
// @access  Private
exports.registerCylinder = async (req, res, next) => {
  try {
    const cylinderData = {
      ...req.body,
      userId: req.user.id
    };
    
    if (!cylinderData.nextTestDue && cylinderData.manufacturingDate) {
      const nextTest = new Date(cylinderData.manufacturingDate);
      nextTest.setFullYear(nextTest.getFullYear() + 5);
      cylinderData.nextTestDue = nextTest;
    }
    
    const cylinder = await Cylinder.create(cylinderData);
    
    await cylinder.addHistory('purchased', req.user.id, {
      notes: 'Initial registration'
    });
    
    res.status(201).json({
      success: true,
      message: 'Cylinder registered successfully',
      data: cylinder
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all cylinders
// @route   GET /api/cylinders
// @access  Private
exports.getCylinders = async (req, res, next) => {
  try {
    const { status, capacity, search, page = 1, limit = 20 } = req.query;
    
    const query = { userId: req.user.id };
    
    if (status) query.status = status;
    if (capacity) query.capacity = capacity;
    if (search) {
      query.$or = [
        { serialNumber: new RegExp(search, 'i') },
        { manufacturer: new RegExp(search, 'i') }
      ];
    }
    
    const cylinders = await Cylinder.find(query)
      .populate('currentLocation.customerId', 'name phone')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit));
    
    const total = await Cylinder.countDocuments(query);
    
    res.json({
      success: true,
      count: cylinders.length,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / limit),
      data: cylinders
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get cylinder by serial number
// @route   GET /api/cylinders/:serialNumber
// @access  Private
exports.getCylinderBySerial = async (req, res, next) => {
  try {
    const cylinder = await Cylinder.findOne({
      serialNumber: req.params.serialNumber.toUpperCase(),
      userId: req.user.id
    })
      .populate('currentLocation.customerId', 'name phone email')
      .populate('history.performedBy', 'name')
      .populate('history.customerId', 'name phone');
    
    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }
    
    res.json({
      success: true,
      data: cylinder
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update cylinder status
// @route   PUT /api/cylinders/:id/status
// @access  Private
exports.updateCylinderStatus = async (req, res, next) => {
  try {
    const { status, notes } = req.body;
    
    const cylinder = await Cylinder.findOne({
      _id: req.params.id,
      userId: req.user.id
    });
    
    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }
    
    const oldStatus = cylinder.status;
    cylinder.status = status;
    
    await cylinder.addHistory('status_change', req.user.id, {
      notes: `Status changed from ${oldStatus} to ${status}. ${notes || ''}`
    });
    
    await cylinder.save();
    
    res.json({
      success: true,
      message: 'Cylinder status updated',
      data: cylinder
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Record cylinder inspection
// @route   POST /api/cylinders/:id/inspection
// @access  Private
exports.recordInspection = async (req, res, next) => {
  try {
    const cylinder = await Cylinder.findOne({
      _id: req.params.id,
      userId: req.user.id
    });
    
    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }
    
    const inspectionData = {
      date: req.body.date || new Date(),
      type: req.body.type,
      result: req.body.result,
      inspector: req.body.inspector,
      certificationNumber: req.body.certificationNumber,
      notes: req.body.notes
    };
    
    if (inspectionData.result === 'passed') {
      const nextDue = new Date(inspectionData.date);
      if (inspectionData.type === 'hydrostatic') {
        nextDue.setFullYear(nextDue.getFullYear() + 5);
      } else {
        nextDue.setFullYear(nextDue.getFullYear() + 1);
      }
      inspectionData.nextDueDate = nextDue;
    }
    
    await cylinder.recordInspection(inspectionData);
    
    await cylinder.addHistory('inspected', req.user.id, {
      notes: `${inspectionData.type} inspection: ${inspectionData.result}`
    });
    
    res.json({
      success: true,
      message: 'Inspection recorded successfully',
      data: cylinder
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get cylinders due for inspection
// @route   GET /api/cylinders/due-inspection
// @access  Private
exports.getCylindersDueInspection = async (req, res, next) => {
  try {
    const { days = 30 } = req.query;
    
    const cylinders = await Cylinder.getDueForInspection(
      req.user.id,
      parseInt(days)
    );
    
    res.json({
      success: true,
      count: cylinders.length,
      data: cylinders
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get cylinders with customer
// @route   GET /api/cylinders/with-customer/:customerId
// @access  Private
exports.getCylindersWithCustomer = async (req, res, next) => {
  try {
    const cylinders = await Cylinder.find({
      userId: req.user.id,
      'currentLocation.customerId': req.params.customerId,
      status: 'with-customer'
    }).populate('currentLocation.customerId', 'name phone');
    
    res.json({
      success: true,
      count: cylinders.length,
      data: cylinders
    });
  } catch (error) {
    next(error);
  }
};
