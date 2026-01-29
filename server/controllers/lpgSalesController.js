const mongoose = require('mongoose');
const LPGSale = require('../models/LPGSale');
const LPGProduct = require('../models/LPGProduct');
const LPGCustomer = require('../models/LPGCustomer');
const Cylinder = require('../models/Cylinder');
const SafetyChecklist = require('../models/SafetyChecklist');

const createLPGSale = async (req, res, next) => {
  const session = await mongoose.startSession();
  session.startTransaction();
  
  try {
    const { items, customer, deliveryRequired, deliveryAddress, paymentMethod, taxRate, discount, discountType, notes, saleType } = req.body;
    
    const reservedCylinders = [];
    
    for (let item of items) {
      const product = await LPGProduct.findOne({ 
        _id: item.product, 
        userId: req.user.id 
      }).session(session);
      
      if (!product) {
        throw new Error(`Product not found: ${item.product}`);
      }
      
      if (product.productType === 'cylinder') {
        const availableCylinders = await Cylinder.find({
          userId: req.user.id,
          capacity: product.cylinderType,
          status: 'in-stock',
          isActive: true
        })
          .limit(item.quantity)
          .session(session);
        
        if (availableCylinders.length < item.quantity) {
          throw new Error(
            `Insufficient cylinders for ${product.name}. ` +
            `Available: ${availableCylinders.length}, Requested: ${item.quantity}`
          );
        }
        
        reservedCylinders.push({
          productId: item.product,
          cylinders: availableCylinders.map(c => c.serialNumber)
        });
        
        await Cylinder.updateMany(
          { _id: { $in: availableCylinders.map(c => c._id) } },
          { 
            status: 'with-customer',
            currentLocation: {
              type: 'customer',
              customerId: customer
            }
          },
          { session }
        );
        
        product.cylinderStates.filled -= item.quantity;
        product.cylinderStates.sold += item.quantity;
        await product.save({ session });
      } else {
        if (product.stock < item.quantity) {
          throw new Error(
            `Insufficient stock for ${product.name}. ` +
            `Available: ${product.stock}, Requested: ${item.quantity}`
          );
        }
        
        product.stock -= item.quantity;
        await product.save({ session });
      }
    }
    
    let subtotal = 0;
    const processedItems = items.map(item => {
      const itemTotal = item.quantity * item.unitPrice;
      subtotal += itemTotal;
      return {
        ...item,
        total: itemTotal
      };
    });
    
    const taxAmount = (subtotal * (taxRate || 0)) / 100;
    let discountAmount = 0;
    
    if (discountType === 'percentage') {
      discountAmount = (subtotal * (discount || 0)) / 100;
    } else {
      discountAmount = discount || 0;
    }
    
    const totalAmount = subtotal + taxAmount - discountAmount;
    
    const sale = await LPGSale.create([{
      userId: req.user.id,
      customer,
      items: processedItems,
      subtotal,
      taxRate: taxRate || 0,
      taxAmount,
      discount: discount || 0,
      discountType: discountType || 'fixed',
      discountAmount,
      totalAmount,
      paymentMethod,
      paidAmount: req.body.paidAmount || totalAmount,
      balanceAmount: totalAmount - (req.body.paidAmount || totalAmount),
      paymentStatus: (req.body.paidAmount || totalAmount) >= totalAmount ? 'Paid' : 'Partial',
      deliveryRequired: deliveryRequired || false,
      deliveryAddress: deliveryAddress || null,
      deliveryStatus: deliveryRequired ? 'Pending' : 'Not Required',
      saleType: saleType || 'New Sale',
      notes: notes || '',
      cylinderSerialNumbers: reservedCylinders.flatMap(r => r.cylinders)
    }], { session });
    
    if (customer) {
      await LPGCustomer.findByIdAndUpdate(
        customer,
        {
          $inc: {
            totalRefills: 1,
            totalSpent: totalAmount,
            loyaltyPoints: Math.floor(totalAmount / 100)
          },
          lastRefillDate: new Date()
        },
        { session }
      );
      
      if (saleType === 'New Connection') {
        await SafetyChecklist.create([{
          userId: req.user.id,
          saleId: sale[0]._id,
          customerId: customer,
          checklistType: 'new-connection',
          items: SafetyChecklist.getTemplate('new-connection')
        }], { session });
      }
    }
    
    await session.commitTransaction();
    
    res.status(201).json({
      success: true,
      message: 'Sale created successfully',
      data: sale[0]
    });
    
  } catch (error) {
    await session.abortTransaction();
    console.error('Sale creation error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to create sale'
    });
  } finally {
    session.endSession();
  }
};

const getLPGSales = async (req, res, next) => {
  try {
    const { startDate, endDate, customer, paymentStatus, deliveryStatus } = req.query;
    
    const query = { userId: req.user.id };
    
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }
    
    if (customer) query.customer = customer;
    if (paymentStatus) query.paymentStatus = paymentStatus;
    if (deliveryStatus) query.deliveryStatus = deliveryStatus;
    
    const sales = await LPGSale.find(query)
      .populate('customer', 'name phone email')
      .populate('items.product', 'name brand category')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      count: sales.length,
      data: sales
    });
  } catch (error) {
    next(error);
  }
};

const getSalesReport = async (req, res, next) => {
  try {
    const { startDate, endDate } = req.query;
    
    const matchStage = { userId: new mongoose.Types.ObjectId(req.user.id) };
    
    if (startDate || endDate) {
      matchStage.createdAt = {};
      if (startDate) matchStage.createdAt.$gte = new Date(startDate);
      if (endDate) matchStage.createdAt.$lte = new Date(endDate);
    }
    
    const report = await LPGSale.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: null,
          totalSales: { $sum: 1 },
          totalRevenue: { $sum: '$totalAmount' },
          totalPaid: { $sum: '$paidAmount' },
          totalBalance: { $sum: '$balanceAmount' },
          avgSaleValue: { $avg: '$totalAmount' }
        }
      }
    ]);
    
    const salesByPaymentMethod = await LPGSale.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: '$paymentMethod',
          count: { $sum: 1 },
          total: { $sum: '$totalAmount' }
        }
      }
    ]);
    
    const salesByStatus = await LPGSale.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: '$paymentStatus',
          count: { $sum: 1 },
          total: { $sum: '$totalAmount' }
        }
      }
    ]);
    
    res.json({
      success: true,
      data: {
        summary: report[0] || {
          totalSales: 0,
          totalRevenue: 0,
          totalPaid: 0,
          totalBalance: 0,
          avgSaleValue: 0
        },
        byPaymentMethod: salesByPaymentMethod,
        byStatus: salesByStatus
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createLPGSale,
  getLPGSales,
  getSalesReport
};
