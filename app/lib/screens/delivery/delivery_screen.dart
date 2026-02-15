import 'package:flutter/material.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _pendingDeliveries = [];
  List<dynamic> _deliveryRoutes = [];
  List<dynamic> _personnel = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load data with individual error handling
      List<dynamic> pendingDeliveries = [];
      List<dynamic> deliveryRoutes = [];
      List<dynamic> personnel = [];
      
      try {
        final pendingResult = await ApiService.get('/delivery/pending');
        pendingDeliveries = pendingResult['data'] ?? [];
      } catch (e) {
        print('Failed to load pending deliveries: $e');
      }
      
      try {
        final routesResult = await ApiService.get('/delivery/routes');
        deliveryRoutes = routesResult['data'] ?? [];
      } catch (e) {
        print('Failed to load delivery routes: $e');
      }
      
      try {
        final personnelResult = await ApiService.get('/delivery/personnel');
        personnel = personnelResult['data'] ?? [];
      } catch (e) {
        print('Failed to load delivery personnel: $e');
      }
      
      setState(() {
        _pendingDeliveries = pendingDeliveries;
        _deliveryRoutes = deliveryRoutes;
        _personnel = personnel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load delivery data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Routes', icon: Icon(Icons.route)),
            Tab(text: 'Personnel', icon: Icon(Icons.people)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/delivery'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildRoutesTab(),
                _buildPersonnelTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPersonnelDialog,
        icon: Icon(Icons.add),
        label: Text('Add Personnel'),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingDeliveries.isEmpty) {
      return _buildEmptyState('No pending deliveries', Icons.local_shipping);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _pendingDeliveries.length,
        itemBuilder: (context, index) {
          final delivery = _pendingDeliveries[index];
          return _buildDeliveryCard(delivery);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    // Handle both snake_case and camelCase
    final customer = delivery['customer'] ?? delivery['lpg_customers'] ?? {};
    final deliveryAddress = delivery['delivery_address'] ?? delivery['deliveryAddress'];
    final address = deliveryAddress ?? customer['address'] ?? 'No address';
    final totalAmount = delivery['total_amount'] ?? delivery['totalAmount'] ?? 0;
    final amount = (totalAmount is num) ? totalAmount.toDouble() : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LPGColors.warning.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.local_shipping, color: LPGColors.warning),
        ),
        title: Text(customer['name'] ?? 'Unknown Customer'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(address, maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4),
            Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(color: LPGColors.success)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _assignDelivery(delivery['id']),
          child: Text('Assign'),
          style: ElevatedButton.styleFrom(
            backgroundColor: LPGColors.primary,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildRoutesTab() {
    if (_deliveryRoutes.isEmpty) {
      return _buildEmptyState('No delivery routes', Icons.route);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _deliveryRoutes.length,
        itemBuilder: (context, index) {
          final route = _deliveryRoutes[index];
          return _buildRouteCard(route);
        },
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final dateStr = route['date'];
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final status = route['status'] ?? 'planned';
    final personnel = route['personnel'] ?? route['delivery_personnel'] ?? {};

    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = LPGColors.success;
        break;
      case 'in_progress':
        statusColor = LPGColors.info;
        break;
      default:
        statusColor = LPGColors.warning;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: LPGTextStyles.subtitle1,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: LPGTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: LPGColors.textSecondary),
                SizedBox(width: 8),
                Text(personnel['name'] ?? 'Unassigned'),
              ],
            ),
            if (status == 'planned') ...[
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _startRoute(route['id']),
                icon: Icon(Icons.play_arrow),
                label: Text('Start Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LPGColors.success,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelTab() {
    if (_personnel.isEmpty) {
      return _buildEmptyState('No delivery personnel', Icons.people);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _personnel.length,
        itemBuilder: (context, index) {
          final person = _personnel[index];
          return _buildPersonnelCard(person);
        },
      ),
    );
  }

  Widget _buildPersonnelCard(Map<String, dynamic> person) {
    final user = person['user'] ?? {};
    final isAvailable = person['is_available'] ?? person['isAvailable'] ?? false;
    final vehicleNumber = person['vehicle_number'] ?? person['vehicleNumber'];
    final phone = person['phone'];

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAvailable ? LPGColors.success.withOpacity(0.1) : LPGColors.error.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: isAvailable ? LPGColors.success : LPGColors.error,
          ),
        ),
        title: Text(user['name'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            if (vehicleNumber != null)
              Text('Vehicle: $vehicleNumber'),
            if (phone != null)
              Text('Phone: $phone'),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAvailable ? LPGColors.success.withOpacity(0.1) : LPGColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isAvailable ? 'Available' : 'Busy',
            style: TextStyle(
              color: isAvailable ? LPGColors.success : LPGColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: LPGColors.textTertiary),
          SizedBox(height: 16),
          Text(message, style: LPGTextStyles.heading3),
        ],
      ),
    );
  }

  Future<void> _assignDelivery(String deliveryId) async {
    // Show dialog to select personnel
    final selectedPersonnel = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Personnel'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _personnel.length,
            itemBuilder: (context, index) {
              final person = _personnel[index];
              final user = person['user'] ?? {};
              return ListTile(
                title: Text(user['name'] ?? 'Unknown'),
                onTap: () => Navigator.pop(context, person),
              );
            },
          ),
        ),
      ),
    );

    if (selectedPersonnel != null) {
      try {
        await ApiService.post('/delivery/assign', {
          'sale_ids': [deliveryId],
          'personnel_id': selectedPersonnel['id'],
        });
        _showSuccess('Delivery assigned successfully');
        _loadData();
      } catch (e) {
        _showError('Failed to assign delivery: $e');
      }
    }
  }

  Future<void> _startRoute(String routeId) async {
    try {
      await ApiService.put('/delivery/routes/$routeId/start', {});
      _showSuccess('Route started');
      _loadData();
    } catch (e) {
      _showError('Failed to start route: $e');
    }
  }

  void _showAddPersonnelDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final vehicleController = TextEditingController();
    final licenseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Delivery Personnel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: vehicleController,
                decoration: InputDecoration(labelText: 'Vehicle Number'),
              ),
              TextField(
                controller: licenseController,
                decoration: InputDecoration(labelText: 'License Number'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.post('/delivery/personnel', {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'vehicle_number': vehicleController.text,
                  'license_number': licenseController.text,
                });
                Navigator.pop(context);
                _showSuccess('Personnel added successfully');
                _loadData();
              } catch (e) {
                _showError('Failed to add personnel: $e');
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.success),
    );
  }
}
