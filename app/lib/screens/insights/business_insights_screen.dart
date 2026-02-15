import 'package:flutter/material.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class BusinessInsightsScreen extends StatefulWidget {
  const BusinessInsightsScreen({Key? key}) : super(key: key);

  @override
  State<BusinessInsightsScreen> createState() => _BusinessInsightsScreenState();
}

class _BusinessInsightsScreenState extends State<BusinessInsightsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _insights = {};
  List<dynamic> _topProducts = [];
  List<dynamic> _salesTrends = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await ApiService.get('/analytics/insights');
      final data = response['data'] ?? {};
      
      setState(() {
        _insights = data;
        _summary = data['summary'] ?? {};
        _topProducts = data['topProducts'] ?? [];
        _salesTrends = data['salesTrends'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load insights: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Insights'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInsights,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/insights'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInsights,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  SizedBox(height: 16),
                  _buildGrowthCard(),
                  SizedBox(height: 16),
                  _buildTopProductsCard(),
                  SizedBox(height: 16),
                  _buildSalesTrendCard(),
                  SizedBox(height: 16),
                  _buildCustomerInsightsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final totalRevenue = (_summary['totalRevenue'] ?? 0).toDouble();
    final totalSales = _summary['totalSales'] ?? 0;
    final avgSaleValue = (_summary['averageSaleValue'] ?? 0).toDouble();
    final totalCustomers = _summary['totalCustomers'] ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Overview', style: LPGTextStyles.heading3),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    'Total Revenue',
                    'Rs. ${totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    LPGColors.success,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    'Total Sales',
                    totalSales.toString(),
                    Icons.shopping_cart,
                    LPGColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    'Avg Sale Value',
                    'Rs. ${avgSaleValue.toStringAsFixed(0)}',
                    Icons.trending_up,
                    LPGColors.info,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    'Customers',
                    totalCustomers.toString(),
                    Icons.people,
                    LPGColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: LPGTextStyles.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(label, style: LPGTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildGrowthCard() {
    final growthRate = double.tryParse(_summary['growthRate']?.toString() ?? '0') ?? 0;
    final isPositive = growthRate >= 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isPositive ? LPGColors.success : LPGColors.error).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? LPGColors.success : LPGColors.error,
                size: 32,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Growth Rate', style: LPGTextStyles.body2),
                  SizedBox(height: 4),
                  Text(
                    '${isPositive ? '+' : ''}${growthRate.toStringAsFixed(1)}%',
                    style: LPGTextStyles.heading2.copyWith(
                      color: isPositive ? LPGColors.success : LPGColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Compared to previous period',
                    style: LPGTextStyles.caption.copyWith(color: LPGColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsCard() {
    if (_topProducts.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Selling Products', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            ..._topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final name = product['name'] ?? 'Unknown';
              final quantity = product['quantity'] ?? 0;
              final revenue = (product['revenue'] ?? 0).toDouble();

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LPGColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRankColor(index).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: _getRankColor(index),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: LPGTextStyles.body1),
                          Text('$quantity units sold', style: LPGTextStyles.caption),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${revenue.toStringAsFixed(0)}',
                      style: LPGTextStyles.subtitle2.copyWith(color: LPGColors.success),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Color(0xFFFFD700); // Gold
      case 1:
        return Color(0xFFC0C0C0); // Silver
      case 2:
        return Color(0xFFCD7F32); // Bronze
      default:
        return LPGColors.primary;
    }
  }

  Widget _buildSalesTrendCard() {
    if (_salesTrends.isEmpty) {
      return SizedBox.shrink();
    }

    // Get last 7 days
    final recentTrends = _salesTrends.length > 7 
        ? _salesTrends.sublist(_salesTrends.length - 7)
        : _salesTrends;

    final maxRevenue = recentTrends.fold<double>(
      0,
      (max, day) => (day['revenue'] as num).toDouble() > max ? (day['revenue'] as num).toDouble() : max,
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sales Trend (Last 7 Days)', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: recentTrends.map((day) {
                  final revenue = (day['revenue'] as num).toDouble();
                  final date = DateTime.parse(day['date']);
                  final height = maxRevenue > 0 ? (revenue / maxRevenue * 150).toDouble() : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: LPGColors.primary,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            DateFormat('E').format(date),
                            style: LPGTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInsightsCard() {
    final customersByType = _insights['customersByType'] as Map<String, dynamic>? ?? {};
    
    if (customersByType.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Distribution', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            ...customersByType.entries.map((entry) {
              final type = entry.key;
              final count = entry.value;
              final total = customersByType.values.fold<int>(0, (sum, val) => sum + (val as int));
              final percentage = total > 0 ? (count / total * 100) : 0;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          type.toUpperCase(),
                          style: LPGTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$count (${percentage.toStringAsFixed(0)}%)',
                          style: LPGTextStyles.body2,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: LPGColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(LPGColors.primary),
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.error),
    );
  }
}
