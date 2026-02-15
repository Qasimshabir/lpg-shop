import 'package:flutter/material.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../services/lpg_api_service.dart';
import 'package:intl/intl.dart';

class CylinderTrackingScreen extends StatefulWidget {
  const CylinderTrackingScreen({Key? key}) : super(key: key);

  @override
  State<CylinderTrackingScreen> createState() => _CylinderTrackingScreenState();
}

class _CylinderTrackingScreenState extends State<CylinderTrackingScreen> {
  bool _isLoading = true;
  List<dynamic> _cylinderSummary = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadCylinders();
  }

  Future<void> _loadCylinders() async {
    try {
      setState(() => _isLoading = true);
      final summary = await LPGApiService.getCylinderSummary();
      setState(() {
        _cylinderSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load cylinders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cylinder Tracking'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCylinders,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All Cylinders')),
              PopupMenuItem(value: 'filled', child: Text('Filled Only')),
              PopupMenuItem(value: 'empty', child: Text('Empty Only')),
              PopupMenuItem(value: 'sold', child: Text('Sold Only')),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/cylinders'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCylinders,
              child: _cylinderSummary.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        _buildOverviewCard(),
                        SizedBox(height: 16),
                        ..._cylinderSummary.map((data) => _buildCylinderTypeCard(data)),
                      ],
                    ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    int totalEmpty = 0;
    int totalFilled = 0;
    int totalSold = 0;

    for (var data in _cylinderSummary) {
      totalEmpty += (data['totalEmpty'] ?? 0) as int;
      totalFilled += (data['totalFilled'] ?? 0) as int;
      totalSold += (data['totalSold'] ?? 0) as int;
    }

    int total = totalEmpty + totalFilled + totalSold;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Inventory', style: LPGTextStyles.heading3),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox('Empty', totalEmpty, LPGColors.cylinderEmpty),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox('Filled', totalFilled, LPGColors.cylinderFilled),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox('Sold', totalSold, LPGColors.cylinderSold),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: total > 0 ? totalFilled / total : 0,
              backgroundColor: LPGColors.cylinderEmpty,
              valueColor: AlwaysStoppedAnimation<Color>(LPGColors.cylinderFilled),
              minHeight: 10,
            ),
            SizedBox(height: 8),
            Text(
              'Available: $totalFilled / $total cylinders',
              style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: LPGTextStyles.heading2.copyWith(
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

  Widget _buildCylinderTypeCard(Map<String, dynamic> data) {
    final cylinderType = data['_id'] ?? 'Unknown';
    final totalEmpty = data['totalEmpty'] ?? 0;
    final totalFilled = data['totalFilled'] ?? 0;
    final totalSold = data['totalSold'] ?? 0;
    final total = totalEmpty + totalFilled + totalSold;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LPGColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.propane_tank, color: LPGColors.primary, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$cylinderType Cylinders',
                        style: LPGTextStyles.subtitle1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Total: $total units',
                        style: LPGTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$totalFilled',
                  style: LPGTextStyles.heading2.copyWith(
                    color: LPGColors.cylinderFilled,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat('Empty', totalEmpty, LPGColors.cylinderEmpty),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat('Filled', totalFilled, LPGColors.cylinderFilled),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat('Sold', totalSold, LPGColors.cylinderSold),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: total > 0 ? totalFilled / total : 0,
              backgroundColor: LPGColors.cylinderEmpty,
              valueColor: AlwaysStoppedAnimation<Color>(LPGColors.cylinderFilled),
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: LPGTextStyles.subtitle1.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: LPGTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.propane_tank, size: 80, color: LPGColors.textTertiary),
          SizedBox(height: 16),
          Text('No cylinders found', style: LPGTextStyles.heading3),
          SizedBox(height: 8),
          Text('Add products to start tracking', style: LPGTextStyles.body2),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.error),
    );
  }
}
