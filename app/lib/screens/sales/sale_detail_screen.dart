import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../lpg_theme.dart';

class SaleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> sale;

  const SaleDetailScreen({Key? key, required this.sale}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(sale['createdAt'] ?? DateTime.now().toIso8601String());
    final items = sale['items'] as List? ?? [];
    final customer = sale['customer'] as Map<String, dynamic>?;
    final total = (sale['total'] ?? 0).toDouble();
    final subtotal = (sale['subtotal'] ?? 0).toDouble();
    final tax = (sale['tax'] ?? 0).toDouble();
    final discount = (sale['discountAmount'] ?? 0).toDouble();
    final paidAmount = (sale['paidAmount'] ?? 0).toDouble();
    final remainingAmount = (sale['remainingAmount'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text('Sale Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _showComingSoon(context, 'Share Invoice'),
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () => _showComingSoon(context, 'Print Invoice'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildInvoiceHeader(date),
          SizedBox(height: 16),
          _buildCustomerInfo(customer),
          SizedBox(height: 16),
          _buildItemsList(items),
          SizedBox(height: 16),
          _buildPricingDetails(subtotal, tax, discount, total),
          SizedBox(height: 16),
          _buildPaymentInfo(paidAmount, remainingAmount, sale),
          SizedBox(height: 16),
          _buildDeliveryInfo(sale),
          if (sale['notes'] != null && sale['notes'].toString().isNotEmpty) ...[
            SizedBox(height: 16),
            _buildNotes(sale['notes']),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader(DateTime date) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice', style: LPGTextStyles.heading2),
                    SizedBox(height: 4),
                    Text(
                      sale['invoiceNumber'] ?? 'N/A',
                      style: LPGTextStyles.body1.copyWith(color: LPGColors.textSecondary),
                    ),
                  ],
                ),
                _buildStatusBadge(sale['status'] ?? 'Completed'),
              ],
            ),
            SizedBox(height: 12),
            Divider(height: 1),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: LPGColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                  style: LPGTextStyles.body2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = LPGColors.success;
        break;
      case 'pending':
        color = LPGColors.warning;
        break;
      case 'cancelled':
        color = LPGColors.error;
        break;
      default:
        color = LPGColors.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: LPGTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(Map<String, dynamic>? customer) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Information', style: LPGTextStyles.subtitle1),
            SizedBox(height: 12),
            if (customer != null) ...[
              _buildInfoRow(Icons.person, customer['name'] ?? 'N/A'),
              SizedBox(height: 8),
              _buildInfoRow(Icons.phone, customer['phone'] ?? 'N/A'),
              if (customer['email'] != null && customer['email'].toString().isNotEmpty) ...[
                SizedBox(height: 8),
                _buildInfoRow(Icons.email, customer['email']),
              ],
            ] else
              Text('Walk-in Customer', style: LPGTextStyles.body2.copyWith(color: LPGColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: LPGColors.textSecondary),
        SizedBox(width: 12),
        Expanded(
          child: Text(text, style: LPGTextStyles.body2),
        ),
      ],
    );
  }

  Widget _buildItemsList(List items) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items (${items.length})', style: LPGTextStyles.subtitle1),
            SizedBox(height: 12),
            ...items.map((item) => _buildItemRow(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final product = item['product'] as Map<String, dynamic>?;
    final productName = product?['name'] ?? 'Unknown Product';
    final quantity = item['quantity'] ?? 0;
    final unitPrice = (item['unitPrice'] ?? 0).toDouble();
    final subtotal = (item['subtotal'] ?? 0).toDouble();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LPGColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: LPGTextStyles.body1),
                SizedBox(height: 4),
                Text(
                  '$quantity × ₹${unitPrice.toStringAsFixed(2)}',
                  style: LPGTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            '₹${subtotal.toStringAsFixed(2)}',
            style: LPGTextStyles.subtitle2.copyWith(color: LPGColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingDetails(double subtotal, double tax, double discount, double total) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', subtotal, false),
            if (tax > 0) ...[
              SizedBox(height: 8),
              _buildPriceRow('Tax', tax, false),
            ],
            if (discount > 0) ...[
              SizedBox(height: 8),
              _buildPriceRow('Discount', -discount, false, color: LPGColors.error),
            ],
            SizedBox(height: 12),
            Divider(height: 1),
            SizedBox(height: 12),
            _buildPriceRow('Total', total, true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, bool isBold, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold ? LPGTextStyles.subtitle1 : LPGTextStyles.body2,
        ),
        Text(
          '₹${amount.abs().toStringAsFixed(2)}',
          style: (isBold ? LPGTextStyles.heading3 : LPGTextStyles.body1).copyWith(
            color: color ?? (isBold ? LPGColors.success : null),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(double paidAmount, double remainingAmount, Map<String, dynamic> sale) {
    final paymentStatus = sale['paymentStatus'] ?? 'Pending';
    final paymentMethod = sale['paymentMethod'] ?? 'Cash';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Information', style: LPGTextStyles.subtitle1),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment Method', style: LPGTextStyles.body2),
                Text(paymentMethod, style: LPGTextStyles.body1),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment Status', style: LPGTextStyles.body2),
                _buildPaymentStatusBadge(paymentStatus),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Paid Amount', style: LPGTextStyles.body2),
                Text(
                  '₹${paidAmount.toStringAsFixed(2)}',
                  style: LPGTextStyles.body1.copyWith(color: LPGColors.success),
                ),
              ],
            ),
            if (remainingAmount > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Remaining', style: LPGTextStyles.body2),
                  Text(
                    '₹${remainingAmount.toStringAsFixed(2)}',
                    style: LPGTextStyles.body1.copyWith(color: LPGColors.error),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = LPGColors.success;
        break;
      case 'partial':
        color = LPGColors.warning;
        break;
      case 'pending':
        color = LPGColors.error;
        break;
      default:
        color = LPGColors.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: LPGTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDeliveryInfo(Map<String, dynamic> sale) {
    final deliveryRequired = sale['deliveryRequired'] ?? false;
    final deliveryStatus = sale['deliveryStatus'] ?? 'Not Required';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Information', style: LPGTextStyles.subtitle1),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery Required', style: LPGTextStyles.body2),
                Text(
                  deliveryRequired ? 'Yes' : 'No',
                  style: LPGTextStyles.body1,
                ),
              ],
            ),
            if (deliveryRequired) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Status', style: LPGTextStyles.body2),
                  _buildDeliveryStatusBadge(deliveryStatus),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered':
        color = LPGColors.success;
        break;
      case 'in transit':
        color = LPGColors.info;
        break;
      case 'pending':
      case 'scheduled':
        color = LPGColors.warning;
        break;
      default:
        color = LPGColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: LPGTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNotes(String notes) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: LPGTextStyles.subtitle1),
            SizedBox(height: 8),
            Text(notes, style: LPGTextStyles.body2),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: LPGColors.info,
      ),
    );
  }
}
