const DeliveryPersonnel = require('../models/DeliveryPersonnel');
const DeliveryRoute = require('../models/DeliveryRoute');
const LPGSale = require('../models/LPGSale');

// @desc    Add delivery personnel
// @route   POST /api/delivery/personnel
// @access  Private
exports.addDeliveryPersonnel = async (req, res, next) => {
  try {
    const personnelData = {
      ...req.body,
      userId: req.user.id
    };
    
    const personnel = await DeliveryPersonnel.create(personnelData);
    
    res.status(201).json({
      success: true,
      message: 'Delivery personnel added successfully',
      data: personnel
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all delivery personnel
// @route   GET /api/delivery/personnel
// @access  Private
exports.getDeliveryPersonnel = async (req, res, next) => {
  try {
    const { isActive, availability } = req.query;
    
    const query = { userId: req.user.id };
    
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }
    if (availability) {
      query.availability = availability;
    }
    
    const personnel = await DeliveryPersonnel.find(query)
      .sort({ name: 1 });
    
    res.json({
      success: true,
      count: personnel.length,
      data: personnel
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update delivery personnel
// @route   PUT /api/delivery/personnel/:id
// @access  Private
exports.updateDeliveryPersonnel = async (req, res, next) => {
  try {
    const personnel = await DeliveryPersonnel.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      req.body,
      { new: true, runValidators: true }
    );
    
    if (!personnel) {
      return res.status(404).json({
        success: false,
        message: 'Delivery personnel not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Delivery personnel updated successfully',
      data: personnel
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Assign deliveries to personnel
// @route   POST /api/delivery/assign
// @access  Private
exports.assignDeliveries = async (req, res, next) => {
  try {
    const { personnelId, saleIds, date } = req.body;
    
    const personnel = await DeliveryPersonnel.findOne({
      _id: personnelId,
      userId: req.user.id
    });
    
    if (!personnel) {
      return res.status(404).json({
        success: false,
        message: 'Delivery personnel not found'
      });
    }
    
    if (personnel.availability !== 'available') {
      return res.status(400).json({
        success: false,
        message: 'Personnel is not available'
      });
    }
    
    const route = await DeliveryRoute.create({
      date: date || new Date(),
      deliveryPersonnel: personnelId,
      sales: saleIds,
      optimizedOrder: saleIds,
      status: 'planned'
    });
    
    personnel.assignedDeliveries = saleIds;
    personnel.availability = 'on-delivery';
    await personnel.save();
    
    await LPGSale.updateMany(
      { _id: { $in: saleIds } },
      { deliveryStatus: 'Scheduled' }
    );
    
    res.status(201).json({
      success: true,
      message: 'Deliveries assigned successfully',
      data: route
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get delivery routes
// @route   GET /api/delivery/routes
// @access  Private
exports.getDeliveryRoutes = async (req, res, next) => {
  try {
    const { date, status, personnelId } = req.query;
    
    const query = {};
    
    if (date) {
      const startOfDay = new Date(date);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(date);
      endOfDay.setHours(23, 59, 59, 999);
      query.date = { $gte: startOfDay, $lte: endOfDay };
    }
    
    if (status) query.status = status;
    if (personnelId) query.deliveryPersonnel = personnelId;
    
    const routes = await DeliveryRoute.find(query)
      .populate('deliveryPersonnel', 'name phone vehicleNumber')
      .populate('sales', 'invoiceNumber deliveryAddress total')
      .sort({ date: -1 });
    
    res.json({
      success: true,
      count: routes.length,
      data: routes
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Start delivery route
// @route   PUT /api/delivery/routes/:id/start
// @access  Private
exports.startDeliveryRoute = async (req, res, next) => {
  try {
    const route = await DeliveryRoute.findById(req.params.id);
    
    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found'
      });
    }
    
    route.status = 'in-progress';
    route.startTime = new Date();
    await route.save();
    
    await LPGSale.updateMany(
      { _id: { $in: route.sales } },
      { deliveryStatus: 'In Transit' }
    );
    
    res.json({
      success: true,
      message: 'Route started successfully',
      data: route
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Complete delivery route
// @route   PUT /api/delivery/routes/:id/complete
// @access  Private
exports.completeDeliveryRoute = async (req, res, next) => {
  try {
    const route = await DeliveryRoute.findById(req.params.id);
    
    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found'
      });
    }
    
    route.status = 'completed';
    route.endTime = new Date();
    await route.save();
    
    const personnel = await DeliveryPersonnel.findById(route.deliveryPersonnel);
    if (personnel) {
      personnel.availability = 'available';
      personnel.completedDeliveries += route.sales.length;
      personnel.assignedDeliveries = [];
      await personnel.save();
    }
    
    res.json({
      success: true,
      message: 'Route completed successfully',
      data: route
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update delivery proof
// @route   PUT /api/delivery/:saleId/proof
// @access  Private
exports.updateDeliveryProof = async (req, res, next) => {
  try {
    const { signature, photo, notes } = req.body;
    
    const sale = await LPGSale.findById(req.params.saleId);
    
    if (!sale) {
      return res.status(404).json({
        success: false,
        message: 'Sale not found'
      });
    }
    
    sale.deliveryStatus = 'Delivered';
    sale.deliveryNotes = notes || sale.deliveryNotes;
    
    if (!sale.deliveryProof) {
      sale.deliveryProof = {};
    }
    sale.deliveryProof.signature = signature;
    sale.deliveryProof.photo = photo;
    sale.deliveryProof.deliveredAt = new Date();
    
    await sale.save();
    
    res.json({
      success: true,
      message: 'Delivery proof updated successfully',
      data: sale
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get pending deliveries
// @route   GET /api/delivery/pending
// @access  Private
exports.getPendingDeliveries = async (req, res, next) => {
  try {
    const sales = await LPGSale.find({
      soldBy: req.user.id,
      deliveryRequired: true,
      deliveryStatus: { $in: ['Pending', 'Scheduled'] }
    })
      .populate('customer', 'name phone')
      .sort({ deliveryDate: 1 });
    
    res.json({
      success: true,
      count: sales.length,
      data: sales
    });
  } catch (error) {
    next(error);
  }
};

// Functions are already exported via exports.functionName above
