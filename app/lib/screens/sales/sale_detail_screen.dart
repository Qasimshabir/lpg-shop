import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../lpg_theme.dart';
import '../../services/lpg_api_service.dart';

class SaleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sale;

  const SaleDetailScreen({Key? key, required this.sale}) : super(key: key);

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(
      widget.sale['createdAt'] ?? widget.sale['created_at'] ?? widget.sale['sale_date'] ?? DateTime.now().toIso8601String()
    );
    final items = (widget.sale['items'] ?? widget.sale['sale_items']) as List? ?? [];
    final customer = (widget.sale['customer'] ?? widget.sale['lpg_customers']) as Map<String, dynamic>?;
    final total = (widget.sale['total'] ?? widget.sale['totalAmount'] ?? widget.sale['total_amount'] ?? 0).toDouble();
    final subtotal = (widget.sale['subtotal'] ?? widget.sale['subTotal'] ?? widget.sale['sub_total'] ?? total).toDouble();
    final tax = (widget.sale['tax'] ?? widget.sale['taxAmount'] ?? widget.sale['tax_amount'] ?? 0).toDouble();
    final discount = (widget.sale['discountAmount'] ?? widget.sale['discount_amount'] ?? widget.sale['discount'] ?? 0).toDouble();
    final paidAmount = (widget.sale['paidAmount'] ?? widget.sale['paid_amount'] ?? total).toDouble();
    final remainingAmount = (widget.sale['remainingAmount'] ?? widget.sale['remaining_amount'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text('Sale Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _showComingSoon('Share Invoice'),
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () => _showComingSoon('Print Invoice'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: LPGColors.error),
                    SizedBox(width: 8),
                    Text('Delete Sale', style: TextStyle(color: LPGColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
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
                _buildPaymentInfo(paidAmount, remainingAmount, widget.sale),
                SizedBox(height: 16),
                _buildDeliveryInfo(widget.sale),
                if (widget.sale['notes'] != null && widget.sale['notes'].toString().isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildNotes(widget.sale['notes']),
                ],
              ],
            ),
    );
  }

  Future<void> _confirmDelete() async {
    final invoiceNumber = widget.sale['invoiceNumber'] ?? widget.sale['invoice_number'] ?? 'N/A';
    final total = (widget.sale['total'] ?? widget.sale['totalAmount'] ?? widget.sale['total_amount'] ?? 0).toDouble();
    final items = (widget.sale['items'] ?? widget.sale['sale_items']) as List? ?? [];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: LPGColors.error),
            SizedBox(width: 8),
            Text('Delete Sale'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this sale?',
              style: LPGTextStyles.body1,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LPGColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LPGColors.error.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt, size: 16, color: LPGColors.error),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Invoice: $invoiceNumber',
                          style: LPGTextStyles.subtitle2.copyWith(
                            color: LPGColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Amount: Rs${total.toStringAsFixed(2)}',
                    style: LPGTextStyles.caption.copyWith(color: LPGColors.error),
                  ),
                  Text(
                    '${items.length} item${items.length != 1 ? 's' : ''}',
                    style: LPGTextStyles.caption.copyWith(color: LPGColors.error),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LPGColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LPGColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: LPGColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The sale record will be permanently deleted. Note: This will NOT restore cylinder inventory.',
                      style: LPGTextStyles.caption.copyWith(color: LPGColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: LPGColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSale();
    }
  }

  Future<void> _deleteSale() async {
    try {
      setState(() => _isLoading = true);
      
      final saleId = widget.sale['id'];
      await LPGApiService.deleteLPGSale(saleId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Sale deleted successfully'),
                ),
              ],
            ),
            backgroundColor: LPGColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to delete sale: $e');
    }
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
                      widget.sale['invoiceNumber'] ?? widget.sale['invoice_number'] ?? 'N/A',
                      style: LPGTextStyles.body1.copyWith(color: LPGColors.textSecondary),
                    ),
                  ],
                ),
                _buildStatusBadge(widget.sale['status'] ?? 'Completed'),
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
    final product = (item['product'] ?? item['lpg_products']) as Map<String, dynamic>?;
    final productName = product?['name'] ?? item['product_name'] ?? 'Unknown Product';
    final quantity = item['quantity'] ?? 0;
    final unitPrice = (item['unitPrice'] ?? item['unit_price'] ?? 0).toDouble();
    final subtotal = (item['subtotal'] ?? item['sub_total'] ?? (quantity * unitPrice)).toDouble();

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
                  '$quantity × Rs${unitPrice.toStringAsFixed(2)}',
                  style: LPGTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            'Rs${subtotal.toStringAsFixed(2)}',
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
          'Rs${amount.abs().toStringAsFixed(2)}',
          style: (isBold ? LPGTextStyles.heading3 : LPGTextStyles.body1).copyWith(
            color: color ?? (isBold ? LPGColors.success : null),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(double paidAmount, double remainingAmount, Map<String, dynamic> sale) {
    final paymentStatus = sale['paymentStatus'] ?? sale['payment_status'] ?? 'Pending';
    final paymentMethod = sale['paymentMethod'] ?? sale['payment_method'] ?? 'Cash';

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
                  'Rs${paidAmount.toStringAsFixed(2)}',
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
                    'Rs${remainingAmount.toStringAsFixed(2)}',
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
    final deliveryRequired = sale['deliveryRequired'] ?? sale['delivery_required'] ?? false;
    final deliveryStatus = sale['deliveryStatus'] ?? sale['delivery_status'] ?? 'Not Required';

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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: LPGColors.info,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LPGColors.error,
      ),
    );
  }
}
