import 'package:flutter/material.dart';
import '../../services/lpg_api_service.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
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
      
      double total = 0;
      for (var sale in sales) {
        // Try both 'total' and 'totalAmount' fields
        total += (sale['total'] ?? sale['totalAmount'] ?? 0).toDouble();
      }
      
      setState(() {
        _sales = sales;
        _totalRevenue = total;
        _isLoading = false;
      });
    } catch (e) {
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
            '₹${_totalRevenue.toStringAsFixed(2)}',
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
    final date = DateTime.parse(sale['createdAt'] ?? DateTime.now().toIso8601String());
    final amount = (sale['total'] ?? sale['totalAmount'] ?? 0).toDouble();
    final items = sale['items'] as List? ?? [];
    final customerName = sale['customer']?['name'] ?? 'Walk-in Customer';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SaleDetailScreen(sale: sale),
            ),
          );
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
                    '₹${amount.toStringAsFixed(2)}',
                    style: LPGTextStyles.heading3.copyWith(
                      color: LPGColors.success,
                    ),
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
}
