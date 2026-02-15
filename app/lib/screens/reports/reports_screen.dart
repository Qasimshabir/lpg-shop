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
  List<dynamic> _cylinderSummary = [];

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
        _salesReport = results[0] as Map<String, dynamic>;
        _customerAnalytics = results[1] as Map<String, dynamic>;
        _cylinderSummary = results[2] as List<dynamic>;
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
    final summary = _salesReport['summary'] as Map<String, dynamic>? ?? {};
    final totalSales = summary['totalSales'] ?? 0;
    final totalRevenue = ((summary['totalRevenue'] ?? 0) as num).toDouble();
    final avgSale = ((summary['avgSaleValue'] ?? 0) as num).toDouble();

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
                    Icons.attach_money,
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
    if (_cylinderSummary.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cylinder Distribution', style: LPGTextStyles.heading3),
            SizedBox(height: 16),
            ..._cylinderSummary.map((item) {
              final data = item as Map<String, dynamic>;
              final type = data['_id'] ?? 'Unknown';
              final empty = data['totalEmpty'] ?? 0;
              final filled = data['totalFilled'] ?? 0;
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
              () => _generateDailyReport(),
            ),
            SizedBox(height: 12),
            _buildReportButton(
              'Weekly Report',
              'Last 7 days analysis',
              Icons.date_range,
              () => _generateWeeklyReport(),
            ),
            SizedBox(height: 12),
            _buildReportButton(
              'Monthly Report',
              'Current month summary',
              Icons.calendar_month,
              () => _generateMonthlyReport(),
            ),
            SizedBox(height: 12),
            _buildReportButton(
              'Custom Report',
              'Generate custom date range',
              Icons.analytics,
              () => _showCustomReportDialog(),
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

  Future<void> _generateDailyReport() async {
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day).toIso8601String();
    final endDate = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    
    await _showReportDetails('Daily Report', startDate, endDate);
  }

  Future<void> _generateWeeklyReport() async {
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: 7)).toIso8601String();
    final endDate = today.toIso8601String();
    
    await _showReportDetails('Weekly Report', startDate, endDate);
  }

  Future<void> _generateMonthlyReport() async {
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, 1).toIso8601String();
    final endDate = today.toIso8601String();
    
    await _showReportDetails('Monthly Report', startDate, endDate);
  }

  Future<void> _showCustomReportDialog() async {
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Custom Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Start Date'),
                subtitle: Text(
                  startDate != null
                      ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                      : 'Select start date',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => startDate = picked);
                  }
                },
              ),
              ListTile(
                title: Text('End Date'),
                subtitle: Text(
                  endDate != null
                      ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                      : 'Select end date',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => endDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: startDate != null && endDate != null
                  ? () {
                      Navigator.pop(context);
                      _showReportDetails(
                        'Custom Report',
                        startDate!.toIso8601String(),
                        endDate!.toIso8601String(),
                      );
                    }
                  : null,
              child: Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDetails(String title, String startDate, String endDate) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final report = await LPGApiService.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show report details
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportRow('Period', '${_formatDate(startDate)} - ${_formatDate(endDate)}'),
                  Divider(),
                  Text('Sales Summary', style: LPGTextStyles.subtitle1),
                  SizedBox(height: 8),
                  _buildReportRow('Total Sales', '${report['summary']?['totalSales'] ?? 0}'),
                  _buildReportRow('Total Revenue', '₹${((report['summary']?['totalRevenue'] ?? 0) as num).toStringAsFixed(2)}'),
                  _buildReportRow('Average Sale', '₹${((report['summary']?['avgSaleValue'] ?? 0) as num).toStringAsFixed(2)}'),
                  Divider(),
                  Text('Payment Status', style: LPGTextStyles.subtitle1),
                  SizedBox(height: 8),
                  _buildReportRow('Paid', '${report['paymentStatus']?['paid'] ?? 0}'),
                  _buildReportRow('Pending', '${report['paymentStatus']?['pending'] ?? 0}'),
                  _buildReportRow('Failed', '${report['paymentStatus']?['failed'] ?? 0}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export feature coming soon!')),
                  );
                },
                icon: Icon(Icons.download),
                label: Text('Export'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _showError('Failed to generate report: $e');
    }
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: LPGTextStyles.body2),
          Text(value, style: LPGTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.error),
    );
  }
}
