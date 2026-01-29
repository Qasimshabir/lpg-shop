const LPGCustomer = require('../models/LPGCustomer');

// @desc    Get all LPG customers
// @route   GET /api/lpg/customers
// @access  Private
const getLPGCustomers = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    let query = { userId: req.user.id };

    if (req.query.search) {
      query.$or = [
        { name: new RegExp(req.query.search, 'i') },
        { email: new RegExp(req.query.search, 'i') },
        { phone: new RegExp(req.query.search, 'i') },
        { businessName: new RegExp(req.query.search, 'i') },
        { 'premises.name': new RegExp(req.query.search, 'i') }
      ];
    }

    if (req.query.customerType) {
      query.customerType = req.query.customerType;
    }

    if (req.query.loyaltyTier) {
      query.loyaltyTier = req.query.loyaltyTier;
    }

    if (req.query.isActive !== undefined) {
      query.isActive = req.query.isActive === 'true';
    }

    const customers = await LPGCustomer.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await LPGCustomer.countDocuments(query);

    res.json({
      success: true,
      count: customers.length,
      total,
      page,
      pages: Math.ceil(total / limit),
      data: customers
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single LPG customer
// @route   GET /api/lpg/customers/:id
// @access  Private
const getLPGCustomer = async (req, res, next) => {
  try {
    const customer = await LPGCustomer.findOne({ _id: req.params.id, userId: req.user.id });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    res.json({
      success: true,
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new LPG customer
// @route   POST /api/lpg/customers
// @access  Private
const createLPGCustomer = async (req, res, next) => {
  try {
    const customer = await LPGCustomer.create({
      ...req.body,
      userId: req.user.id
    });

    res.status(201).json({
      success: true,
      message: 'Customer created successfully',
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update LPG customer
// @route   PUT /api/lpg/customers/:id
// @access  Private
const updateLPGCustomer = async (req, res, next) => {
  try {
    const customer = await LPGCustomer.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      req.body,
      {
        new: true,
        runValidators: true
      }
    );

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    res.json({
      success: true,
      message: 'Customer updated successfully',
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete LPG customer
// @route   DELETE /api/lpg/customers/:id
// @access  Private
const deleteLPGCustomer = async (req, res, next) => {
  try {
    const customer = await LPGCustomer.findOne({ _id: req.params.id, userId: req.user.id });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    await customer.deleteOne();

    res.json({
      success: true,
      message: 'Customer deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add premises to customer
// @route   POST /api/lpg/customers/:id/premises
// @access  Private
const addPremises = async (req, res, next) => {
  try {
    const customer = await LPGCustomer.findOne({ _id: req.params.id, userId: req.user.id });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    await customer.addPremises(req.body);

    res.status(201).json({
      success: true,
      message: 'Premises added successfully',
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update premises
// @route   PUT /api/lpg/customers/:id/premises/:premisesId
// @access  Private
const updatePremises = async (req, res, next) => {
  try {
    const customer = await LPGCustomer.findOne({ _id: req.params.id, userId: req.user.id });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    await customer.updatePremises(req.params.premisesId, req.body);

    res.json({
      success: true,
      message: 'Premises updated successfully',
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Remove premises
// @route   DELETE /api/lpg/customers/:id/premises/:premisesId
// @access  Private
const removePremises = async (req, res, next) => {
  try {
    const customer = await LPGCustomer.findOne({ _id: req.params.id, userId: req.user.id });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    await customer.removePremises(req.params.premisesId);

    res.json({
      success: true,
      message: 'Premises removed successfully',
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add refill record
// @route   POST /api/lpg/customers/:id/refill
// @access  Private
const addRefillRecord = async (req, res, next) => {
  try {
    const customer = await LPGCustomer.findOne({ _id: req.params.id, userId: req.user.id });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    const refillData = {
      ...req.body,
      soldBy: req.user.id
    };

    await customer.addRefillRecord(refillData);

    res.status(201).json({
      success: true,
      message: 'Refill record added successfully',
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customer refill history
// @route   GET /api/lpg/customers/:id/refill-history
// @access  Private
const getRefillHistory = async (req, res, next) => {
  try {
    const customer = await LPGCustomer.findOne({ _id: req.params.id, userId: req.user.id })
      .populate('refillHistory.soldBy', 'name');

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const refillHistory = customer.refillHistory
      .sort((a, b) => b.refillDate - a.refillDate)
      .slice(skip, skip + limit);

    const total = customer.refillHistory.length;

    res.json({
      success: true,
      count: refillHistory.length,
      total,
      page,
      pages: Math.ceil(total / limit),
      data: refillHistory
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update customer credit
// @route   PUT /api/lpg/customers/:id/credit
// @access  Private
const updateCredit = async (req, res, next) => {
  try {
    const { amount, operation = 'add' } = req.body;

    const customer = await LPGCustomer.findOne({ _id: req.params.id, userId: req.user.id });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    await customer.updateCredit(amount, operation);

    res.json({
      success: true,
      message: 'Credit updated successfully',
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customers due for refill
// @route   GET /api/lpg/customers/due-refill
// @access  Private
const getCustomersDueForRefill = async (req, res, next) => {
  try {
    const daysAhead = parseInt(req.query.days) || 7;
    const customers = await LPGCustomer.getCustomersDueForRefill(req.user.id, daysAhead);

    res.json({
      success: true,
      count: customers.length,
      data: customers
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get top customers by spending
// @route   GET /api/lpg/customers/top-customers
// @access  Private
const getTopCustomers = async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const customers = await LPGCustomer.getTopCustomers(req.user.id, limit);

    res.json({
      success: true,
      count: customers.length,
      data: customers
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customer analytics
// @route   GET /api/lpg/customers/analytics
// @access  Private
const getCustomerAnalytics = async (req, res, next) => {
  try {
    const analytics = await LPGCustomer.aggregate([
      { $match: { userId: req.user._id, isActive: true } },
      {
        $group: {
          _id: null,
          totalCustomers: { $sum: 1 },
          totalSpent: { $sum: '$totalSpent' },
          totalRefills: { $sum: '$totalRefills' },
          avgSpentPerCustomer: { $avg: '$totalSpent' },
          avgRefillsPerCustomer: { $avg: '$totalRefills' }
        }
      },
      {
        $project: {
          _id: 0,
          totalCustomers: 1,
          totalSpent: { $round: ['$totalSpent', 2] },
          totalRefills: 1,
          avgSpentPerCustomer: { $round: ['$avgSpentPerCustomer', 2] },
          avgRefillsPerCustomer: { $round: ['$avgRefillsPerCustomer', 1] }
        }
      }
    ]);

    // Get loyalty tier distribution
    const loyaltyDistribution = await LPGCustomer.aggregate([
      { $match: { userId: req.user._id, isActive: true } },
      {
        $group: {
          _id: '$loyaltyTier',
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // Get customer type distribution
    const customerTypeDistribution = await LPGCustomer.aggregate([
      { $match: { userId: req.user._id, isActive: true } },
      {
        $group: {
          _id: '$customerType',
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    res.json({
      success: true,
      data: {
        overview: analytics[0] || {
          totalCustomers: 0,
          totalSpent: 0,
          totalRefills: 0,
          avgSpentPerCustomer: 0,
          avgRefillsPerCustomer: 0
        },
        loyaltyDistribution,
        customerTypeDistribution
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customer consumption pattern
// @route   GET /api/lpg/customers/:id/consumption-pattern
// @access  Private
const getConsumptionPattern = async (req, res, next) => {
  try {
    const customer = await LPGCustomer.findOne({ _id: req.params.id, userId: req.user.id });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    // Get monthly consumption for the last 12 months
    const monthlyConsumption = await LPGCustomer.aggregate([
      { $match: { _id: customer._id } },
      { $unwind: '$refillHistory' },
      {
        $addFields: {
          month: { $dateToString: { format: '%Y-%m', date: '$refillHistory.refillDate' } },
          cylinderWeight: {
            $toDouble: { $substr: ['$refillHistory.cylinderType', 0, -2] }
          },
          totalWeight: {
            $multiply: [
              { $toDouble: { $substr: ['$refillHistory.cylinderType', 0, -2] } },
              '$refillHistory.quantity'
            ]
          }
        }
      },
      {
        $group: {
          _id: '$month',
          totalConsumption: { $sum: '$totalWeight' },
          totalRefills: { $sum: '$refillHistory.quantity' },
          totalAmount: { $sum: '$refillHistory.totalAmount' }
        }
      },
      { $sort: { _id: -1 } },
      { $limit: 12 }
    ]);

    res.json({
      success: true,
      data: {
        customer: {
          id: customer._id,
          name: customer.name,
          averageMonthlyConsumption: customer.averageMonthlyConsumption,
          lastRefillDate: customer.lastRefillDate,
          nextExpectedRefill: customer.nextExpectedRefill
        },
        monthlyConsumption: monthlyConsumption.reverse()
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getLPGCustomers,
  getLPGCustomer,
  createLPGCustomer,
  updateLPGCustomer,
  deleteLPGCustomer,
  addPremises,
  updatePremises,
  removePremises,
  addRefillRecord,
  getRefillHistory,
  updateCredit,
  getCustomersDueForRefill,
  getTopCustomers,
  getCustomerAnalytics,
  getConsumptionPattern
};