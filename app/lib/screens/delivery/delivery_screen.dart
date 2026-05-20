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
    final deliveryStatus = delivery['delivery_status'] ?? 'pending';
    final saleDate = delivery['sale_date'] ?? delivery['saleDate'];

    Color statusColor;
    IconData statusIcon;
    switch (deliveryStatus) {
      case 'delivered':
        statusColor = LPGColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'in_transit':
        statusColor = LPGColors.info;
        statusIcon = Icons.local_shipping;
        break;
      case 'assigned':
        statusColor = LPGColors.warning;
        statusIcon = Icons.assignment_turned_in;
        break;
      case 'failed':
        statusColor = LPGColors.error;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = LPGColors.textSecondary;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDeliveryDetails(delivery),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      customer['name'] ?? 'Unknown Customer',
                      style: LPGTextStyles.subtitle1,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'assign':
                          _assignDelivery(delivery['id']);
                          break;
                        case 'status':
                          _showUpdateStatusDialog(delivery);
                          break;
                        case 'details':
                          _showDeliveryDetails(delivery);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (deliveryStatus == 'pending')
                        PopupMenuItem(
                          value: 'assign',
                          child: Row(
                            children: [
                              Icon(Icons.assignment, size: 20),
                              SizedBox(width: 8),
                              Text('Assign'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(Icons.update, size: 20),
                            SizedBox(width: 8),
                            Text('Update Status'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info, size: 20),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  SizedBox(width: 4),
                  Text(
                    deliveryStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: LPGColors.textSecondary),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LPGTextStyles.body2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: LPGColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        saleDate != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(saleDate)) : 'N/A',
                        style: LPGTextStyles.caption,
                      ),
                    ],
                  ),
                  Text(
                    'Rs${amount.toStringAsFixed(0)}',
                    style: LPGTextStyles.subtitle1.copyWith(color: LPGColors.success),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                Row(
                  children: [
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
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditRouteDialog(route);
                            break;
                          case 'delete':
                            _deleteRoute(route['id'], status);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (status != 'in_progress')
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (status != 'in_progress')
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: LPGColors.error),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: LPGColors.error)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
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
    final licenseNumber = person['license_number'] ?? person['licenseNumber'];

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
              Row(
                children: [
                  Icon(Icons.directions_car, size: 14, color: LPGColors.textSecondary),
                  SizedBox(width: 4),
                  Text('Vehicle: $vehicleNumber'),
                ],
              ),
            if (phone != null)
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: LPGColors.textSecondary),
                  SizedBox(width: 4),
                  Text('Phone: $phone'),
                ],
              ),
            if (licenseNumber != null)
              Row(
                children: [
                  Icon(Icons.badge, size: 14, color: LPGColors.textSecondary),
                  SizedBox(width: 4),
                  Text('License: $licenseNumber'),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
                  fontSize: 12,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditPersonnelDialog(person);
                    break;
                  case 'delete':
                    _deletePersonnel(person['id']);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: LPGColors.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: LPGColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.add_road, color: LPGColors.primary),
                      SizedBox(width: 8),
                      Text('Create Delivery Route', style: LPGTextStyles.heading3),
                    ],
                  ),
                ),
                Divider(height: 1),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Picker
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.calendar_today, color: LPGColors.primary),
                          title: Text('Delivery Date'),
                          subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                          trailing: Icon(Icons.edit),
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
                        Text('Select Personnel', style: LPGTextStyles.subtitle1),
                        SizedBox(height: 8),
                        if (_personnel.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text('No personnel available', style: LPGTextStyles.body2),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: _personnel.map((person) {
                                final users = person['users'];
                                String userName = 'Unknown';
                                if (users != null && users is Map) {
                                  userName = users['name'] ?? 'Unknown';
                                }
                                final isAvailable = person['is_available'] ?? false;
                                
                                return RadioListTile<String>(
                                  title: Text(userName),
                                  subtitle: Text(
                                    '${person['vehicle_number'] ?? 'No vehicle'} - ${isAvailable ? 'Available' : 'Busy'}',
                                    style: TextStyle(
                                      color: isAvailable ? LPGColors.success : LPGColors.error,
                                    ),
                                  ),
                                  value: person['id'],
                                  groupValue: selectedPersonnelId,
                                  onChanged: isAvailable ? (value) {
                                    setDialogState(() => selectedPersonnelId = value);
                                  } : null,
                                );
                              }).toList(),
                            ),
                          ),
                        
                        SizedBox(height: 16),
                        
                        // Pending Deliveries Selector
                        Text('Select Deliveries', style: LPGTextStyles.subtitle1),
                        SizedBox(height: 8),
                        if (_pendingDeliveries.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text('No pending deliveries', style: LPGTextStyles.body2),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: BoxConstraints(maxHeight: 250),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _pendingDeliveries.length,
                              itemBuilder: (context, index) {
                                final delivery = _pendingDeliveries[index];
                                final customer = delivery['customer'] ?? delivery['lpg_customers'] ?? {};
                                final customerName = customer['name'] ?? 'Unknown';
                                final isSelected = selectedSaleIds.contains(delivery['id']);
                                
                                return CheckboxListTile(
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
                ),
                
                // Actions
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
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
                        icon: Icon(Icons.check),
                        label: Text('Create Route'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LPGColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  // Show delivery details dialog
  void _showDeliveryDetails(Map<String, dynamic> delivery) {
    final customer = delivery['customer'] ?? delivery['lpg_customers'] ?? {};
    final deliveryAddress = delivery['delivery_address'] ?? delivery['deliveryAddress'];
    final address = deliveryAddress ?? customer['address'] ?? 'No address';
    final totalAmount = delivery['total_amount'] ?? delivery['totalAmount'] ?? 0;
    final amount = (totalAmount is num) ? totalAmount.toDouble() : 0.0;
    final deliveryStatus = delivery['delivery_status'] ?? 'pending';
    final saleDate = delivery['sale_date'] ?? delivery['saleDate'];
    final saleItems = delivery['sale_items'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: LPGColors.primary),
            SizedBox(width: 8),
            Text('Delivery Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', customer['name'] ?? 'Unknown'),
              _buildDetailRow('Phone', customer['phone'] ?? 'N/A'),
              _buildDetailRow('Address', address),
              _buildDetailRow('Status', deliveryStatus.toUpperCase()),
              _buildDetailRow('Date', saleDate != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(saleDate)) : 'N/A'),
              _buildDetailRow('Amount', 'Rs${amount.toStringAsFixed(0)}'),
              if (saleItems is List && saleItems.isNotEmpty) ...[
                SizedBox(height: 12),
                Text('Items:', style: LPGTextStyles.subtitle1),
                ...saleItems.map((item) => Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Text('• ${item['product_name'] ?? 'Item'} x ${item['quantity']}'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: LPGTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value, style: LPGTextStyles.body2),
          ),
        ],
      ),
    );
  }

  // Update delivery status dialog
  void _showUpdateStatusDialog(Map<String, dynamic> delivery) {
    final currentStatus = delivery['delivery_status'] ?? 'pending';
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Delivery Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('Pending'),
                value: 'pending',
                groupValue: selectedStatus,
                onChanged: (value) => setDialogState(() => selectedStatus = value!),
              ),
              RadioListTile<String>(
                title: Text('Assigned'),
                value: 'assigned',
                groupValue: selectedStatus,
                onChanged: (value) => setDialogState(() => selectedStatus = value!),
              ),
              RadioListTile<String>(
                title: Text('In Transit'),
                value: 'in_transit',
                groupValue: selectedStatus,
                onChanged: (value) => setDialogState(() => selectedStatus = value!),
              ),
              RadioListTile<String>(
                title: Text('Delivered'),
                value: 'delivered',
                groupValue: selectedStatus,
                onChanged: (value) => setDialogState(() => selectedStatus = value!),
              ),
              RadioListTile<String>(
                title: Text('Failed'),
                value: 'failed',
                groupValue: selectedStatus,
                onChanged: (value) => setDialogState(() => selectedStatus = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.put('/delivery/${delivery['id']}/status', {
                    'delivery_status': selectedStatus,
                  });
                  Navigator.pop(context);
                  _showSuccess('Delivery status updated successfully');
                  _loadData();
                } catch (e) {
                  _showError('Failed to update status: $e');
                }
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Edit route dialog
  void _showEditRouteDialog(Map<String, dynamic> route) {
    DateTime selectedDate = DateTime.parse(route['date']);
    String? selectedPersonnelId = route['personnel_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: LPGColors.primary),
              SizedBox(width: 8),
              Text('Edit Route'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: LPGColors.primary),
                  title: Text('Delivery Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  trailing: Icon(Icons.edit),
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
                Text('Select Personnel', style: LPGTextStyles.subtitle1),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: _personnel.map((person) {
                      final users = person['users'];
                      String userName = 'Unknown';
                      if (users != null && users is Map) {
                        userName = users['name'] ?? 'Unknown';
                      }
                      final isAvailable = person['is_available'] ?? false;
                      
                      return RadioListTile<String>(
                        title: Text(userName),
                        subtitle: Text(
                          '${person['vehicle_number'] ?? 'No vehicle'} - ${isAvailable ? 'Available' : 'Busy'}',
                          style: TextStyle(
                            color: isAvailable ? LPGColors.success : LPGColors.error,
                          ),
                        ),
                        value: person['id'],
                        groupValue: selectedPersonnelId,
                        onChanged: (value) {
                          setDialogState(() => selectedPersonnelId = value);
                        },
                      );
                    }).toList(),
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
              onPressed: selectedPersonnelId == null
                  ? null
                  : () async {
                      try {
                        await ApiService.put('/delivery/routes/${route['id']}', {
                          'date': selectedDate.toIso8601String().split('T')[0],
                          'personnel_id': selectedPersonnelId,
                        });
                        Navigator.pop(context);
                        _showSuccess('Route updated successfully');
                        _loadData();
                      } catch (e) {
                        _showError('Failed to update route: $e');
                      }
                    },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Delete route
  Future<void> _deleteRoute(String routeId, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: LPGColors.error),
            SizedBox(width: 8),
            Text('Delete Route'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this route?'),
            SizedBox(height: 12),
            if (status == 'in_progress')
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LPGColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LPGColors.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: LPGColors.error, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cannot delete route in progress',
                        style: TextStyle(color: LPGColors.error),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LPGColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LPGColors.warning),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This will:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('• Reset associated deliveries to pending'),
                    Text('• Mark personnel as available'),
                    Text('• Cannot be undone'),
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
          if (status != 'in_progress')
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: LPGColors.error),
              child: Text('Delete'),
            ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('/delivery/routes/$routeId');
        _showSuccess('Route deleted successfully');
        _loadData();
      } catch (e) {
        _showError('Failed to delete route: $e');
      }
    }
  }

  // Edit personnel dialog
  void _showEditPersonnelDialog(Map<String, dynamic> person) {
    final users = person['users'];
    String userName = 'Unknown';
    if (users != null && users is Map) {
      userName = users['name'] ?? 'Unknown';
    }

    final phoneController = TextEditingController(text: person['phone'] ?? '');
    final vehicleController = TextEditingController(text: person['vehicle_number'] ?? '');
    final licenseController = TextEditingController(text: person['license_number'] ?? '');
    bool isAvailable = person['is_available'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: LPGColors.primary),
              SizedBox(width: 8),
              Text('Edit Personnel'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: userName),
                  decoration: InputDecoration(labelText: 'Name'),
                  enabled: false,
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Enter phone number',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: vehicleController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Number',
                    hintText: 'Enter vehicle number',
                  ),
                ),
                TextField(
                  controller: licenseController,
                  decoration: InputDecoration(
                    labelText: 'License Number',
                    hintText: 'Enter license number',
                  ),
                ),
                SizedBox(height: 8),
                SwitchListTile(
                  title: Text('Available'),
                  value: isAvailable,
                  onChanged: (value) {
                    setDialogState(() => isAvailable = value);
                  },
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
                  await ApiService.put('/delivery/personnel/${person['id']}', {
                    'phone': phoneController.text,
                    'vehicle_number': vehicleController.text,
                    'license_number': licenseController.text,
                    'is_available': isAvailable,
                  });
                  Navigator.pop(context);
                  _showSuccess('Personnel updated successfully');
                  _loadData();
                } catch (e) {
                  _showError('Failed to update personnel: $e');
                }
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Delete personnel
  Future<void> _deletePersonnel(String personnelId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: LPGColors.error),
            SizedBox(width: 8),
            Text('Delete Personnel'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this personnel?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LPGColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LPGColors.warning),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: LPGColors.warning, size: 20),
                      SizedBox(width: 8),
                      Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('Cannot delete personnel assigned to active routes.'),
                  Text('This action cannot be undone.'),
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
            style: ElevatedButton.styleFrom(backgroundColor: LPGColors.error),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('/delivery/personnel/$personnelId');
        _showSuccess('Personnel deleted successfully');
        _loadData();
      } catch (e) {
        _showError('Failed to delete personnel: $e');
      }
    }
  }
}
