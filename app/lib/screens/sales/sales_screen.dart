import 'package:flutter/material.dart';
import '../../services/lpg_api_service.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/logger.dart';
import 'package:intl/intl.dart';
import 'create_sale_screen.dart';
import 'sale_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      setState(() => _isLoading = true);
      
      final sales = await LPGApiService.getLPGSales(
        limit: 100,
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
      );
      
      AppLogger.debug('Loaded ${sales.length} sales');
      
      double total = 0;
      for (var sale in sales) {
        final saleTotal = (sale['total'] ?? sale['totalAmount'] ?? sale['total_amount'] ?? 0);
        AppLogger.debug('Sale ${sale['id']}: total=$saleTotal, keys=${sale.keys.toList()}');
        total += (saleTotal as num).toDouble();
      }
      
      AppLogger.info('Total revenue calculated: $total');
      
      setState(() {
        _sales = sales;
        _totalRevenue = total;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load sales', e, stackTrace);
      setState(() => _isLoading = false);
      _showError('Failed to load sales: $e');
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/sales'),
      body: Column(
        children: [
          _buildRevenueCard(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                    ? _buildEmptyState()
                    : _buildSalesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateSaleScreen()),
          );
          if (result == true) _loadSales();
        },
        icon: Icon(Icons.add_shopping_cart),
        label: Text('New Sale'),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [LPGColors.primary, LPGColors.primary.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Total Revenue',
            style: LPGTextStyles.body1.copyWith(color: Colors.white70),
          ),
          SizedBox(height: 8),
          Text(
            'Rs${_totalRevenue.toStringAsFixed(2)}',
            style: LPGTextStyles.heading1.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${_sales.length} transactions',
            style: LPGTextStyles.body2.copyWith(color: Colors.white70),
          ),
          if (_startDate != null && _endDate != null) ...[
            SizedBox(height: 8),
            Text(
              '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
              style: LPGTextStyles.caption.copyWith(color: Colors.white60),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesList() {
    return RefreshIndicator(
      onRefresh: _loadSales,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _sales.length,
        itemBuilder: (context, index) {
          final sale = _sales[index];
          return _buildSaleCard(sale);
        },
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final date = DateTime.parse(sale['createdAt'] ?? sale['created_at'] ?? sale['sale_date'] ?? DateTime.now().toIso8601String());
    final amount = (sale['total'] ?? sale['totalAmount'] ?? sale['total_amount'] ?? 0).toDouble();
    final items = (sale['items'] ?? sale['sale_items']) as List? ?? [];
    final customer = sale['customer'] ?? sale['lpg_customers'];
    final customerName = customer != null ? (customer['name'] ?? 'Walk-in Customer') : 'Walk-in Customer';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SaleDetailScreen(sale: sale),
            ),
          );
          if (result == true) _loadSales();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: LPGTextStyles.subtitle1,
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                          style: LPGTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs${amount.toStringAsFixed(2)}',
                    style: LPGTextStyles.heading3.copyWith(
                      color: LPGColors.success,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') _confirmDelete(sale);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: LPGColors.error),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: LPGColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              Text(
                '${items.length} item${items.length != 1 ? 's' : ''}',
                style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 80, color: LPGColors.textTertiary),
          SizedBox(height: 16),
          Text('No sales found', style: LPGTextStyles.heading3),
          SizedBox(height: 8),
          Text('Create your first sale to get started', style: LPGTextStyles.body2),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature - Coming Soon!'), backgroundColor: LPGColors.info),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.error),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> sale) async {
    final invoiceNumber = sale['invoiceNumber'] ?? sale['invoice_number'] ?? 'N/A';
    final total = (sale['total'] ?? sale['totalAmount'] ?? sale['total_amount'] ?? 0).toDouble();
    final items = (sale['items'] ?? sale['sale_items']) as List? ?? [];

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
      await _deleteSale(sale);
    }
  }

  Future<void> _deleteSale(Map<String, dynamic> sale) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting sale...'),
                ],
              ),
            ),
          ),
        ),
      );

      final saleId = sale['id'];
      await LPGApiService.deleteLPGSale(saleId);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
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
        _loadSales();
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      _showError('Failed to delete sale: $e');
    }
  }
}
