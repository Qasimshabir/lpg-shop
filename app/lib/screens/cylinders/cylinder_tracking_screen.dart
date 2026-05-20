import 'package:flutter/material.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../services/lpg_api_service.dart';
import '../../models/lpg_product.dart';
import 'package:intl/intl.dart';

class CylinderTrackingScreen extends StatefulWidget {
  const CylinderTrackingScreen({Key? key}) : super(key: key);

  @override
  State<CylinderTrackingScreen> createState() => _CylinderTrackingScreenState();
}

class _CylinderTrackingScreenState extends State<CylinderTrackingScreen> {
  bool _isLoading = true;
  List<dynamic> _trackedCylinders = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadTrackedCylinders();
  }

  Future<void> _loadTrackedCylinders() async {
    try {
      setState(() => _isLoading = true);
      final cylinders = await LPGApiService.getCylinders();
      if (mounted) {
        setState(() {
          _trackedCylinders = cylinders;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Failed to load tracked cylinders: $e');
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
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All Status')),
              PopupMenuItem(value: 'available', child: Text('Available')),
              PopupMenuItem(value: 'in_use', child: Text('In Use')),
              PopupMenuItem(value: 'maintenance', child: Text('Maintenance')),
              PopupMenuItem(value: 'retired', child: Text('Retired')),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/cylinders'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _trackedCylinders.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        _buildTrackedCylindersSection(),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCylinderDialog,
        icon: Icon(Icons.add),
        label: Text('Add to Track'),
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

  Widget _buildTrackedCylindersSection() {
    // Filter tracked cylinders based on selected filter
    List<dynamic> filteredCylinders = _trackedCylinders;
    if (_selectedFilter != 'all') {
      filteredCylinders = _trackedCylinders.where((c) {
        final status = (c['status'] ?? '').toString().toLowerCase();
        return status == _selectedFilter;
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.track_changes, color: LPGColors.primary, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tracked Cylinders',
                    style: LPGTextStyles.heading3,
                  ),
                  Text(
                    'Individual cylinder tracking by SKU',
                    style: LPGTextStyles.caption.copyWith(color: LPGColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: LPGColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${filteredCylinders.length} tracked',
                style: LPGTextStyles.caption.copyWith(
                  color: LPGColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (filteredCylinders.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: LPGColors.textTertiary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _selectedFilter == 'all' 
                          ? 'No cylinders are being tracked yet'
                          : 'No cylinders with ${_selectedFilter.replaceAll('_', ' ')} status',
                      style: LPGTextStyles.body1.copyWith(color: LPGColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click "Add to Track" to start tracking cylinders',
                      style: LPGTextStyles.caption.copyWith(color: LPGColors.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...filteredCylinders.map((cylinder) => _buildTrackedCylinderCard(cylinder)),
      ],
    );
  }

  Widget _buildTrackedCylinderCard(Map<String, dynamic> cylinder) {
    final serialNumber = cylinder['serial_number'] ?? 'N/A';
    final status = cylinder['status'] ?? 'unknown';
    final productId = cylinder['product_id'];
    final createdAt = cylinder['created_at'] != null 
        ? DateTime.parse(cylinder['created_at'])
        : null;

    // Get status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    
    switch (status.toLowerCase()) {
      case 'available':
        statusColor = LPGColors.success;
        statusIcon = Icons.check_circle;
        statusLabel = 'Available';
        break;
      case 'in_use':
        statusColor = LPGColors.warning;
        statusIcon = Icons.local_shipping;
        statusLabel = 'In Use';
        break;
      case 'maintenance':
        statusColor = LPGColors.info;
        statusIcon = Icons.build;
        statusLabel = 'Maintenance';
        break;
      case 'retired':
        statusColor = LPGColors.error;
        statusIcon = Icons.cancel;
        statusLabel = 'Retired';
        break;
      default:
        statusColor = LPGColors.textSecondary;
        statusIcon = Icons.help;
        statusLabel = 'Unknown';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showCylinderDetailsDialog(cylinder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.propane_tank, color: statusColor, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.qr_code, size: 16, color: LPGColors.textSecondary),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                serialNumber,
                                style: LPGTextStyles.subtitle1.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        if (createdAt != null)
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: LPGColors.textTertiary),
                              SizedBox(width: 4),
                              Text(
                                'Tracked since ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                                style: LPGTextStyles.caption.copyWith(
                                  color: LPGColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: LPGTextStyles.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showUpdateStatusDialog(cylinder),
                        icon: Icon(Icons.edit, size: 14),
                        label: Text('Update', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCylinderDetailsDialog(Map<String, dynamic> cylinder) {
    final serialNumber = cylinder['serial_number'] ?? 'N/A';
    final status = cylinder['status'] ?? 'unknown';
    final cylinderId = cylinder['id'];
    final createdAt = cylinder['created_at'] != null 
        ? DateTime.parse(cylinder['created_at'])
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.propane_tank, color: LPGColors.primary),
            SizedBox(width: 8),
            Text('Cylinder Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('SKU', serialNumber),
            _buildDetailRow('Status', status.toUpperCase()),
            if (createdAt != null)
              _buildDetailRow('Tracked Since', DateFormat('MMM dd, yyyy HH:mm').format(createdAt)),
            _buildDetailRow('Cylinder ID', cylinderId ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showUpdateStatusDialog(cylinder);
            },
            icon: Icon(Icons.edit),
            label: Text('Update Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: LPGTextStyles.body2.copyWith(
                fontWeight: FontWeight.bold,
                color: LPGColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: LPGTextStyles.body2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateStatusDialog(Map<String, dynamic> cylinder) async {
    final cylinderId = cylinder['id'];
    String? newStatus = cylinder['status'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Cylinder Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SKU: ${cylinder['serial_number']}',
                style: LPGTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: newStatus,
                decoration: InputDecoration(
                  labelText: 'New Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'available',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: LPGColors.success, size: 20),
                        SizedBox(width: 8),
                        Text('Available'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'in_use',
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping, color: LPGColors.warning, size: 20),
                        SizedBox(width: 8),
                        Text('In Use'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'maintenance',
                    child: Row(
                      children: [
                        Icon(Icons.build, color: LPGColors.info, size: 20),
                        SizedBox(width: 8),
                        Text('Maintenance'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'retired',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: LPGColors.error, size: 20),
                        SizedBox(width: 8),
                        Text('Retired'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() => newStatus = value);
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
              onPressed: () async {
                if (newStatus == null) {
                  _showError('Please select a status');
                  return;
                }

                try {
                  await LPGApiService.updateCylinderStatus(cylinderId, newStatus!);
                  Navigator.pop(context);
                  _showSuccess('Cylinder status updated successfully');
                  _loadTrackedCylinders();
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

  Future<void> _showAddCylinderDialog() async {
    final _formKey = GlobalKey<FormState>();
    final skuController = TextEditingController();
    String? selectedProductId;
    LPGProduct? selectedProduct;
    String? selectedStatus = 'available';
    bool isSubmitting = false;
    
    // Load products for selection (only cylinders)
    List<LPGProduct> products = [];
    try {
      final allProducts = await LPGApiService.getLPGProducts(limit: 100);
      // Filter only cylinder products
      products = allProducts.where((p) => p.productType.toLowerCase() == 'cylinder').toList();
      
      if (products.isEmpty) {
        _showError('No cylinder products available. Please add cylinder products first.');
        return;
      }
    } catch (e) {
      _showError('Failed to load products: $e');
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_circle, color: LPGColors.primary),
              SizedBox(width: 8),
              Text('Add Cylinder to Track'),
            ],
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a cylinder product to start tracking',
                    style: LPGTextStyles.body2.copyWith(color: LPGColors.textSecondary),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedProductId,
                    decoration: InputDecoration(
                      labelText: 'Select Product *',
                      hintText: 'Choose a cylinder product',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.propane_tank),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a product';
                      }
                      return null;
                    },
                    items: products.map<DropdownMenuItem<String>>((product) {
                      final displayText = product.capacity != null 
                          ? '${product.name} - ${product.capacity} kg'
                          : product.name;
                      return DropdownMenuItem<String>(
                        value: product.id,
                        child: Text(displayText),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedProductId = value;
                        // Find the selected product and auto-populate SKU
                        selectedProduct = products.firstWhere((p) => p.id == value);
                        skuController.text = selectedProduct?.sku ?? '';
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: skuController,
                    decoration: InputDecoration(
                      labelText: 'Tracking ID (SKU)',
                      hintText: 'Auto-populated from product',
                      helperText: 'SKU is automatically set from selected product',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                      enabled: false,
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'SKU is required. Please select a product with a valid SKU.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Initial Status *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a status';
                      }
                      return null;
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'available',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: LPGColors.success, size: 20),
                            SizedBox(width: 8),
                            Text('Available'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'in_use',
                        child: Row(
                          children: [
                            Icon(Icons.local_shipping, color: LPGColors.warning, size: 20),
                            SizedBox(width: 8),
                            Text('In Use'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Row(
                          children: [
                            Icon(Icons.build, color: LPGColors.info, size: 20),
                            SizedBox(width: 8),
                            Text('Maintenance'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'retired',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: LPGColors.error, size: 20),
                            SizedBox(width: 8),
                            Text('Retired'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedStatus = value);
                    },
                  ),
                  if (selectedProduct != null) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LPGColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LPGColors.info.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, size: 16, color: LPGColors.info),
                              SizedBox(width: 6),
                              Text(
                                'Product Details',
                                style: LPGTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: LPGColors.info,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 16),
                          _buildInfoRow('Name', selectedProduct!.name),
                          _buildInfoRow('Type', selectedProduct!.cylinderType ?? "N/A"),
                          _buildInfoRow('Capacity', '${selectedProduct!.capacity ?? "N/A"} kg'),
                          _buildInfoRow('SKU', selectedProduct!.sku),
                          _buildInfoRow('Price', 'Rs ${selectedProduct!.price.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }

                setDialogState(() => isSubmitting = true);

                try {
                  // Check if this SKU is already being tracked
                  final existingCylinder = _trackedCylinders.firstWhere(
                    (c) => c['serial_number'] == skuController.text,
                    orElse: () => {},
                  );

                  if (existingCylinder.isNotEmpty) {
                    setDialogState(() => isSubmitting = false);
                    _showError('This cylinder (SKU: ${skuController.text}) is already being tracked.');
                    return;
                  }

                  // Use SKU as the serial number for tracking
                  await LPGApiService.registerCylinder({
                    'serial_number': skuController.text,
                    'product_id': selectedProductId,
                    'status': selectedStatus,
                  });
                  
                  Navigator.pop(context);
                  _showSuccess('Cylinder added to tracking successfully!');
                  await _loadTrackedCylinders();
                } catch (e) {
                  setDialogState(() => isSubmitting = false);
                  _showError('Failed to add cylinder: $e');
                }
              },
              icon: isSubmitting 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.add),
              label: Text(isSubmitting ? 'Adding...' : 'Add to Track'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: LPGTextStyles.caption.copyWith(
                color: LPGColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: LPGTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
