import 'package:flutter/material.dart';
import '../../services/lpg_api_service.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _salesReport = {};
  Map<String, dynamic> _customerAnalytics = {};
  Map<String, dynamic> _cylinderSummary = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() => _isLoading = true);
      
      final results = await Future.wait([
        LPGApiService.getSalesReport(),
        LPGApiService.getCustomerAnalytics(),
        LPGApiService.getCylinderSummary(),
      ]);
      
      setState(() {
        _salesReport = results[0];
        _customerAnalytics = results[1];
        _cylinderSummary = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/reports'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildSalesOverview(),
                  SizedBox(height: 16),
                  _buildCustomerStats(),
                  SizedBox(height: 16),
                  _buildCylinderDistribution(),
                  SizedBox(height: 16),
                  _buildQuickReports(),
                ],
              ),
            ),
    );
  }

  Widget _buildSalesOverview() {
    final overview = _salesReport['overview'] ?? {};
    final totalSales = overview['totalSales'] ?? 0;
    final totalRevenue = (overview['totalRevenue'] ?? 0).toDouble();
    final avgSale = (overview['avgSaleAmount'] ?? 0).toDouble();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sales Overview', style: LPGTextStyles.heading3),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    'Total Sales',
                    totalSales.toString(),
                    Icons.shopping_cart,
                    LPGColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Revenue',
                    '₹${totalRevenue.toStringAsFixed(0)}',
                    Icons.currency_rupee,
                    LPGColors.success,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildStatBox(
              'Average Sale',
              '₹${avgSale.toStringAsFixed(0)}',
              Icons.trending_up,
              LPGColors.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: LPGTextStyles.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStats() {
    final overview = _customerAnalytics['overview'] ?? {};
    final totalCustomers = overview['totalCustomers'] ?? 0;
    final activeCustomers = overview['activeCustomers'] ?? 0;
    final dueForRefill = overview['dueForRefill'] ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Analytics', style: LPGTextStyles.heading3),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    'Total',
                    totalCustomers.toString(),
                    Icons.people,
                    LPGColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Active',
                    activeCustomers.toString(),
                    Icons.person_add_alt,
                    LPGColors.success,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildStatBox(
              'Due for Refill',
              dueForRefill.toString(),
              Icons.schedule,
              LPGColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCylinderDistribution() {
    if (_cylinderSummary is! List || (_cylinderSummary as List).isEmpty) {
      return SizedBox.shrink();
    }

    final summary = _cylinderSummary as List;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cylinder Distribution', style: LPGTextStyles.heading3),
            SizedBox(height: 16),
            ...summary.map((item) {
              final type = item['_id'] ?? 'Unknown';
              final empty = item['totalEmpty'] ?? 0;
              final filled = item['totalFilled'] ?? 0;
              final total = empty + filled;

              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$type Cylinders',
                          style: LPGTextStyles.subtitle1,
                        ),
                        Text(
                          '$filled / $total',
                          style: LPGTextStyles.body1.copyWith(
                            color: LPGColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: total > 0 ? filled / total : 0,
                      backgroundColor: LPGColors.cylinderEmpty,
                      valueColor: AlwaysStoppedAnimation<Color>(LPGColors.cylinderFilled),
                      minHeight: 8,
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Empty: $empty',
                          style: LPGTextStyles.caption,
                        ),
                        Text(
                          'Filled: $filled',
                          style: LPGTextStyles.caption,
                        ),
                      ],
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

  Widget _buildQuickReports() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Reports', style: LPGTextStyles.heading3),
            SizedBox(height: 16),
            _buildReportButton(
              'Daily Report',
              'View today\'s performance',
              Icons.today,
              () => _showComingSoon('Daily Report'),
            ),
            SizedBox(height: 12),
            _buildReportButton(
              'Weekly Report',
              'Last 7 days analysis',
              Icons.date_range,
              () => _showComingSoon('Weekly Report'),
            ),
            SizedBox(height: 12),
            _buildReportButton(
              'Monthly Report',
              'Current month summary',
              Icons.calendar_month,
              () => _showComingSoon('Monthly Report'),
            ),
            SizedBox(height: 12),
            _buildReportButton(
              'Custom Report',
              'Generate custom date range',
              Icons.analytics,
              () => _showComingSoon('Custom Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: LPGColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LPGColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: LPGColors.primary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: LPGTextStyles.subtitle2),
                  Text(
                    subtitle,
                    style: LPGTextStyles.caption.copyWith(color: LPGColors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: LPGColors.textTertiary),
          ],
        ),
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
