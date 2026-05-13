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
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB when tab changes
    });
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
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                // Quick assign - show personnel selector for pending deliveries
                if (_pendingDeliveries.isEmpty) {
                  _showError('No pending deliveries to assign');
                  return;
                }
                _showCreateRouteDialog();
              },
              icon: Icon(Icons.assignment),
              label: Text('Assign Deliveries'),
              backgroundColor: LPGColors.warning,
            )
          : _tabController.index == 1
              ? FloatingActionButton.extended(
                  onPressed: _showCreateRouteDialog,
                  icon: Icon(Icons.add_road),
                  label: Text('Create Route'),
                  backgroundColor: LPGColors.primary,
                )
              : _tabController.index == 2
                  ? FloatingActionButton.extended(
                      onPressed: _showAddPersonnelDialog,
                      icon: Icon(Icons.add),
                      label: Text('Add Personnel'),
                    )
                  : null,
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
            Text('Rs${amount.toStringAsFixed(0)}', style: TextStyle(color: LPGColors.success)),
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
    final personnel = route['delivery_personnel'];
    
    // Get user name from nested structure
    String personnelName = 'Unassigned';
    if (personnel != null) {
      final users = personnel['users'];
      if (users != null && users is Map) {
        personnelName = users['name'] ?? 'Unknown';
      } else if (users != null && users is List && users.isNotEmpty) {
        personnelName = users[0]['name'] ?? 'Unknown';
      }
    }

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
                Text(personnelName),
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
            if (status == 'in_progress') ...[
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _completeRoute(route['id']),
                icon: Icon(Icons.check_circle),
                label: Text('Complete Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LPGColors.primary,
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
    // Get user data from nested structure
    final users = person['users'];
    String userName = 'Unknown';
    if (users != null && users is Map) {
      userName = users['name'] ?? 'Unknown';
    } else if (users != null && users is List && users.isNotEmpty) {
      userName = users[0]['name'] ?? 'Unknown';
    }
    
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
        title: Text(userName),
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
              final users = person['users'];
              String userName = 'Unknown';
              if (users != null && users is Map) {
                userName = users['name'] ?? 'Unknown';
              } else if (users != null && users is List && users.isNotEmpty) {
                userName = users[0]['name'] ?? 'Unknown';
              }
              
              final isAvailable = person['is_available'] ?? false;
              
              return ListTile(
                title: Text(userName),
                subtitle: Text(
                  '${person['vehicle_number'] ?? 'No vehicle'} - ${isAvailable ? 'Available' : 'Busy'}',
                ),
                enabled: isAvailable,
                onTap: isAvailable ? () => Navigator.pop(context, person) : null,
              );
            },
          ),
        ),
      ),
    );

    if (selectedPersonnel != null) {
      try {
        await ApiService.post('/delivery/assign', {
          'date': DateTime.now().toIso8601String().split('T')[0],
          'sale_ids': [deliveryId],
          'personnel_id': selectedPersonnel['id'],
        });
        _showSuccess('Delivery assigned successfully. Status updated to "assigned".');
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

  Future<void> _completeRoute(String routeId) async {
    // Confirm before completing
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Route'),
        content: Text('Are you sure you want to mark this route as completed? The assigned personnel will be marked as available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: LPGColors.success),
            child: Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.put('/delivery/routes/$routeId/complete', {});
        _showSuccess('Route completed. Personnel is now available.');
        _loadData();
      } catch (e) {
        _showError('Failed to complete route: $e');
      }
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

  void _showCreateRouteDialog() {
    DateTime selectedDate = DateTime.now();
    String? selectedPersonnelId;
    List<String> selectedSaleIds = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create Delivery Route'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today),
                  title: Text('Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 30)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                SizedBox(height: 16),
                
                // Personnel Selector
                Text('Select Personnel', style: LPGTextStyles.subtitle2),
                SizedBox(height: 8),
                if (_personnel.isEmpty)
                  Text('No personnel available', style: LPGTextStyles.caption)
                else
                  ..._personnel.map((person) {
                    final users = person['users'];
                    String userName = 'Unknown';
                    if (users != null && users is Map) {
                      userName = users['name'] ?? 'Unknown';
                    }
                    final isAvailable = person['is_available'] ?? false;
                    
                    return RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(userName),
                      subtitle: Text(
                        '${person['vehicle_number'] ?? 'No vehicle'} - ${isAvailable ? 'Available' : 'Busy'}',
                      ),
                      value: person['id'],
                      groupValue: selectedPersonnelId,
                      onChanged: isAvailable ? (value) {
                        setDialogState(() => selectedPersonnelId = value);
                      } : null,
                    );
                  }).toList(),
                
                SizedBox(height: 16),
                
                // Pending Deliveries Selector
                Text('Select Deliveries', style: LPGTextStyles.subtitle2),
                SizedBox(height: 8),
                if (_pendingDeliveries.isEmpty)
                  Text('No pending deliveries', style: LPGTextStyles.caption)
                else
                  Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _pendingDeliveries.length,
                      itemBuilder: (context, index) {
                        final delivery = _pendingDeliveries[index];
                        final customer = delivery['customer'] ?? delivery['lpg_customers'] ?? {};
                        final customerName = customer['name'] ?? 'Unknown';
                        final isSelected = selectedSaleIds.contains(delivery['id']);
                        
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(customerName, style: LPGTextStyles.body2),
                          subtitle: Text(
                            customer['address'] ?? 'No address',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: isSelected,
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedSaleIds.add(delivery['id']);
                              } else {
                                selectedSaleIds.remove(delivery['id']);
                              }
                            });
                          },
                        );
                      },
                    ),
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
              onPressed: selectedPersonnelId == null || selectedSaleIds.isEmpty
                  ? null
                  : () async {
                      try {
                        await ApiService.post('/delivery/assign', {
                          'date': selectedDate.toIso8601String().split('T')[0],
                          'personnel_id': selectedPersonnelId,
                          'sale_ids': selectedSaleIds,
                        });
                        Navigator.pop(context);
                        _showSuccess('Route created successfully');
                        _loadData();
                      } catch (e) {
                        _showError('Failed to create route: $e');
                      }
                    },
              child: Text('Create Route'),
            ),
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.success),
    );
  }
}
