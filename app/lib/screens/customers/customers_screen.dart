import 'package:flutter/material.dart';
import '../../models/lpg_customer.dart';
import '../../services/lpg_api_service.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<LPGCustomer> _customers = [];
  List<LPGCustomer> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() => _isLoading = true);
      final customers = await LPGApiService.getLPGCustomers(limit: 100);
      setState(() {
        _customers = customers;
        _filterCustomers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load customers: $e');
    }
  }

  void _filterCustomers() {
    setState(() {
      _filteredCustomers = _customers.where((customer) {
        final matchesSearch = customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            customer.phone.contains(_searchQuery);
        final matchesType = _selectedType == 'All' || customer.customerType == _selectedType;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customers'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/customers'),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? _buildEmptyState()
                    : _buildCustomerList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );
          if (result == true) _loadCustomers();
        },
        icon: Icon(Icons.person_add),
        label: Text('Add Customer'),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterCustomers();
              });
            },
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Individual', 'Business', 'Institution'].map((type) {
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type;
                        _filterCustomers();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = _filteredCustomers[index];
          return _buildCustomerCard(customer);
        },
      ),
    );
  }

  Widget _buildCustomerCard(LPGCustomer customer) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CustomerDetailScreen(customer: customer)),
          );
          if (result == true) _loadCustomers();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: LPGColors.primary.withOpacity(0.1),
                    child: Text(
                      customer.name[0].toUpperCase(),
                      style: TextStyle(color: LPGColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.displayName, style: LPGTextStyles.subtitle1),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: LPGColors.textTertiary),
                            SizedBox(width: 4),
                            Text(customer.phone, style: LPGTextStyles.body2),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildLoyaltyBadge(customer.loyaltyTier),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editCustomer(customer);
                      } else if (value == 'delete') {
                        _confirmDelete(customer);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: LPGColors.primary),
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
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip('Type', customer.customerType, LPGColors.info),
                  _buildInfoChip('Refills', '${customer.totalRefills}', LPGColors.success),
                  _buildInfoChip('Spent', '₹${customer.totalSpent.toStringAsFixed(0)}', LPGColors.secondary),
                ],
              ),
              if (customer.isDueForRefill) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LPGColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: LPGColors.warning),
                      SizedBox(width: 8),
                      Text(
                        'Due for refill',
                        style: LPGTextStyles.body2.copyWith(color: LPGColors.warning),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _editCustomer(LPGCustomer customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(customer: customer),
      ),
    );
    if (result == true) _loadCustomers();
  }

  void _confirmDelete(LPGCustomer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomer(customer);
            },
            style: ElevatedButton.styleFrom(backgroundColor: LPGColors.error),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(LPGCustomer customer) async {
    try {
      await LPGApiService.deleteLPGCustomer(customer.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer deleted successfully'),
          backgroundColor: LPGColors.success,
        ),
      );
      _loadCustomers();
    } catch (e) {
      _showError('Failed to delete customer: $e');
    }
  }

  Widget _buildLoyaltyBadge(String tier) {
    Color color;
    switch (tier) {
      case 'Platinum':
        color = Color(0xFF9C27B0);
        break;
      case 'Gold':
        color = Color(0xFFFFD700);
        break;
      case 'Silver':
        color = Color(0xFFC0C0C0);
        break;
      default:
        color = Color(0xFFCD7F32);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        tier,
        style: LPGTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LPGTextStyles.caption),
        SizedBox(height: 2),
        Text(
          value,
          style: LPGTextStyles.body2.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: LPGColors.textTertiary),
          SizedBox(height: 16),
          Text('No customers found', style: LPGTextStyles.heading3),
          SizedBox(height: 8),
          Text('Add your first customer to get started', style: LPGTextStyles.body2),
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
