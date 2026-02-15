import 'package:flutter/material.dart';
import '../../services/lpg_api_service.dart';
import '../../models/lpg_product.dart';
import '../../models/lpg_customer.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/logger.dart';
import '../products/products_screen.dart';
import '../customers/customers_screen.dart';
import '../sales/sales_screen.dart';
import '../reports/reports_screen.dart';

class LPGDashboardScreen extends StatefulWidget {
  const LPGDashboardScreen({Key? key}) : super(key: key);

  @override
  State<LPGDashboardScreen> createState() => _LPGDashboardScreenState();
}

class _LPGDashboardScreenState extends State<LPGDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<LPGProduct> _lowStockProducts = [];
  List<LPGCustomer> _customersDueForRefill = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Load dashboard data in parallel
      final futures = await Future.wait([
        LPGApiService.getCylinderSummary(),
        LPGApiService.getLowStockProducts(),
        LPGApiService.getCustomersDueForRefill(),
        LPGApiService.getCustomerAnalytics(),
        LPGApiService.getSalesReport(),
      ]);

      AppLogger.debug('Cylinder Summary Type: ${futures[0].runtimeType}');
      AppLogger.debug('Customer Analytics Type: ${futures[3].runtimeType}');
      AppLogger.debug('Sales Report Type: ${futures[4].runtimeType}');
      AppLogger.debug('Sales Report Data: ${futures[4]}');

      setState(() {
        _dashboardData = {
          'cylinderSummary': futures[0], // This is a List from aggregation
          'customerAnalytics': futures[3], // This is a Map
          'salesReport': futures[4], // This is a Map
        };
        _lowStockProducts = futures[1] as List<LPGProduct>;
        _customersDueForRefill = futures[2] as List<LPGCustomer>;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load dashboard data', e, stackTrace);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: $e'),
            backgroundColor: LPGColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LPG Dealer Dashboard'),
        backgroundColor: LPGColors.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/dashboard'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    SizedBox(height: 24),
                    _buildCylinderSummary(),
                    SizedBox(height: 24),
                    _buildLowStockAlert(),
                    SizedBox(height: 24),
                    _buildCustomersDueForRefill(),
                    SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final salesReport = _dashboardData['salesReport'] as Map<String, dynamic>? ?? {};
    final salesSummary = salesReport['summary'] as Map<String, dynamic>? ?? {};
    final customerAnalytics = _dashboardData['customerAnalytics'] as Map<String, dynamic>? ?? {};
    final customerOverview = customerAnalytics['overview'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: LPGTextStyles.heading3,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Sales',
                '${salesSummary['totalSales'] ?? 0}',
                Icons.shopping_cart,
                LPGColors.primary,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Revenue',
                'Rs. ${((salesSummary['totalRevenue'] ?? 0) as num).toStringAsFixed(0)}',
                Icons.attach_money,
                LPGColors.success,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Customers',
                '${customerOverview['totalCustomers'] ?? 0}',
                Icons.people,
                LPGColors.info,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Avg Sale',
                'Rs. ${((salesSummary['avgSaleValue'] ?? 0) as num).toStringAsFixed(0)}',
                Icons.trending_up,
                LPGColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: LPGTextStyles.body2.copyWith(
                      color: LPGColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
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
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCylinderSummary() {
    final cylinderData = _dashboardData['cylinderSummary'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cylinder Inventory',
          style: LPGTextStyles.heading3,
        ),
        SizedBox(height: 16),
        if (cylinderData.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No cylinder data available'),
            ),
          )
        else
          ...cylinderData.map((data) => _buildCylinderCard(data)),
      ],
    );
  }

  Widget _buildCylinderCard(Map<String, dynamic> data) {
    final cylinderType = data['_id'] ?? 'Unknown';
    final totalEmpty = data['totalEmpty'] ?? 0;
    final totalFilled = data['totalFilled'] ?? 0;
    final totalSold = data['totalSold'] ?? 0;
    final total = totalEmpty + totalFilled;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.propane_tank, color: LPGColors.primary),
                SizedBox(width: 8),
                Text(
                  '$cylinderType Cylinders',
                  style: LPGTextStyles.subtitle1,
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCylinderStat('Empty', totalEmpty, LPGColors.cylinderEmpty),
                ),
                Expanded(
                  child: _buildCylinderStat('Filled', totalFilled, LPGColors.cylinderFilled),
                ),
                Expanded(
                  child: _buildCylinderStat('Sold', totalSold, LPGColors.cylinderSold),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: total > 0 ? totalFilled / total : 0,
              backgroundColor: LPGColors.cylinderEmpty,
              valueColor: AlwaysStoppedAnimation<Color>(LPGColors.cylinderFilled),
            ),
            SizedBox(height: 4),
            Text(
              'Available: $totalFilled / $total',
              style: LPGTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCylinderStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: LPGTextStyles.subtitle1.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: LPGTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildLowStockAlert() {
    if (_lowStockProducts.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: LPGColors.warning),
            SizedBox(width: 8),
            Text(
              'Low Stock Alert',
              style: LPGTextStyles.heading3.copyWith(color: LPGColors.warning),
            ),
          ],
        ),
        SizedBox(height: 16),
        Card(
          color: LPGColors.warning.withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${_lowStockProducts.length} products are running low on stock',
                  style: LPGTextStyles.body1,
                ),
                SizedBox(height: 12),
                ..._lowStockProducts.take(3).map((product) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        product.productType == 'cylinder' 
                            ? Icons.propane_tank 
                            : Icons.build,
                        size: 16,
                        color: LPGColors.warning,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product.displayName,
                          style: LPGTextStyles.body2,
                        ),
                      ),
                      Text(
                        '${product.availableCylinders} left',
                        style: LPGTextStyles.body2.copyWith(
                          color: LPGColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
                if (_lowStockProducts.length > 3)
                  Text(
                    'and ${_lowStockProducts.length - 3} more...',
                    style: LPGTextStyles.caption,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomersDueForRefill() {
    if (_customersDueForRefill.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, color: LPGColors.info),
            SizedBox(width: 8),
            Text(
              'Customers Due for Refill',
              style: LPGTextStyles.heading3.copyWith(color: LPGColors.info),
            ),
          ],
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${_customersDueForRefill.length} customers are due for refill',
                  style: LPGTextStyles.body1,
                ),
                SizedBox(height: 12),
                ..._customersDueForRefill.take(3).map((customer) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16, color: LPGColors.info),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customer.displayName,
                          style: LPGTextStyles.body2,
                        ),
                      ),
                      Text(
                        customer.phone,
                        style: LPGTextStyles.caption,
                      ),
                    ],
                  ),
                )),
                if (_customersDueForRefill.length > 3)
                  Text(
                    'and ${_customersDueForRefill.length - 3} more...',
                    style: LPGTextStyles.caption,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: LPGTextStyles.heading3,
        ),
        SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'New Sale',
                    Icons.add_shopping_cart,
                    LPGColors.primary,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalesScreen()),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    'Add Product',
                    Icons.add_box,
                    LPGColors.secondary,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Manage Customers',
                    Icons.people_alt,
                    LPGColors.success,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomersScreen()),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    'View Reports',
                    Icons.analytics,
                    LPGColors.info,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReportsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(minHeight: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: LPGTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}