import 'package:flutter/material.dart';
import '../../models/lpg_customer.dart';
import '../../services/lpg_api_service.dart';
import '../../lpg_theme.dart';
import 'package:intl/intl.dart';

class CustomerDetailScreen extends StatefulWidget {
  final LPGCustomer customer;

  const CustomerDetailScreen({Key? key, required this.customer}) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late LPGCustomer _customer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _refreshCustomer();
  }

  Future<void> _refreshCustomer() async {
    try {
      setState(() => _isLoading = true);
      final updated = await LPGApiService.getLPGCustomer(_customer.id);
      setState(() {
        _customer = updated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addRefill() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddRefillDialog(),
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);
        await LPGApiService.addRefillRecord(_customer.id, result);
        await _refreshCustomer();
        _showSuccess('Refill record added');
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Failed to add refill: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Details'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _refreshCustomer),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _showComingSoon('Edit Customer');
              else if (value == 'delete') _showComingSoon('Delete Customer');
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: LPGColors.error))),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshCustomer,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(),
                  SizedBox(height: 16),
                  _buildStatsCard(),
                  SizedBox(height: 16),
                  _buildPremisesCard(),
                  SizedBox(height: 16),
                  _buildRefillHistoryCard(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRefill,
        icon: Icon(Icons.add),
        label: Text('Add Refill'),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: LPGColors.primary.withOpacity(0.1),
              child: Text(
                _customer.name[0].toUpperCase(),
                style: TextStyle(fontSize: 32, color: LPGColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            Text(_customer.displayName, style: LPGTextStyles.heading2, textAlign: TextAlign.center),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, size: 16, color: LPGColors.textTertiary),
                SizedBox(width: 4),
                Text(_customer.phone, style: LPGTextStyles.body1),
              ],
            ),
            if (_customer.email != null) ...[
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 16, color: LPGColors.textTertiary),
                  SizedBox(width: 4),
                  Text(_customer.email!, style: LPGTextStyles.body2),
                ],
              ),
            ],
            SizedBox(height: 12),
            _buildLoyaltyBadge(_customer.loyaltyTier),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyBadge(String tier) {
    Color color;
    switch (tier) {
      case 'Platinum': color = Color(0xFF9C27B0); break;
      case 'Gold': color = Color(0xFFFFD700); break;
      case 'Silver': color = Color(0xFFC0C0C0); break;
      default: color = Color(0xFFCD7F32);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: color, size: 20),
          SizedBox(width: 8),
          Text(tier, style: LPGTextStyles.subtitle2.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistics', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatBox('Total Refills', '${_customer.totalRefills}', Icons.propane_tank, LPGColors.primary)),
                SizedBox(width: 12),
                Expanded(child: _buildStatBox('Total Spent', '₹${_customer.totalSpent.toStringAsFixed(0)}', Icons.currency_rupee, LPGColors.success)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatBox('Loyalty Points', '${_customer.loyaltyPoints}', Icons.stars, LPGColors.warning)),
                SizedBox(width: 12),
                Expanded(child: _buildStatBox('Credit Used', '₹${_customer.currentCredit.toStringAsFixed(0)}', Icons.account_balance_wallet, LPGColors.info)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(value, style: LPGTextStyles.subtitle1.copyWith(color: color, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(label, style: LPGTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPremisesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Premises', style: LPGTextStyles.subtitle1),
                TextButton.icon(
                  onPressed: () => _showComingSoon('Add Premises'),
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Add'),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_customer.premises.isEmpty)
              Text('No premises added', style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary))
            else
              ..._customer.premises.map((p) => _buildPremisesItem(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremisesItem(Premises premises) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: LPGColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: LPGColors.primary),
              SizedBox(width: 8),
              Expanded(child: Text(premises.name, style: LPGTextStyles.subtitle2)),
              if (premises.isPrimary)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: LPGColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Primary', style: LPGTextStyles.caption.copyWith(color: LPGColors.primary)),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(premises.fullAddress, style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary)),
          SizedBox(height: 4),
          Text('${premises.type} • ${premises.cylinderCapacity}', style: LPGTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildRefillHistoryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Refill History', style: LPGTextStyles.subtitle1),
            SizedBox(height: 12),
            if (_customer.refillHistory.isEmpty)
              Text('No refill history', style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary))
            else
              ..._customer.refillHistory.take(5).map((r) => _buildRefillItem(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildRefillItem(CylinderRefillHistory refill) {
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
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LPGColors.cylinderFilled.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.propane_tank, color: LPGColors.cylinderFilled, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${refill.quantity}x ${refill.cylinderType}', style: LPGTextStyles.body1),
                Text(DateFormat('MMM dd, yyyy').format(refill.refillDate), style: LPGTextStyles.caption),
              ],
            ),
          ),
          Text('₹${refill.totalAmount.toStringAsFixed(0)}', style: LPGTextStyles.subtitle2.copyWith(color: LPGColors.success)),
        ],
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.success),
    );
  }
}

class _AddRefillDialog extends StatefulWidget {
  @override
  State<_AddRefillDialog> createState() => _AddRefillDialogState();
}

class _AddRefillDialogState extends State<_AddRefillDialog> {
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  String _cylinderType = '11.8kg';
  String _paymentMethod = 'Cash';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Refill Record'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _cylinderType,
              decoration: InputDecoration(labelText: 'Cylinder Type'),
              readOnly: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Select Cylinder Type'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ['11.8kg', '15kg', '45.4kg'].map((t) => ListTile(
                        title: Text(t),
                        onTap: () {
                          setState(() => _cylinderType = t);
                          Navigator.pop(context);
                        },
                      )).toList(),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price per Unit', prefixText: '₹ '),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: _paymentMethod,
              decoration: InputDecoration(labelText: 'Payment Method'),
              readOnly: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Select Payment Method'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ['Cash', 'Card', 'UPI', 'Credit'].map((m) => ListTile(
                        title: Text(m),
                        onTap: () {
                          setState(() => _paymentMethod = m);
                          Navigator.pop(context);
                        },
                      )).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final qty = int.tryParse(_quantityController.text);
            final price = double.tryParse(_priceController.text);
            if (qty != null && price != null) {
              Navigator.pop(context, {
                'cylinderType': _cylinderType,
                'quantity': qty,
                'pricePerUnit': price,
                'totalAmount': qty * price,
                'paymentMethod': _paymentMethod,
                'refillDate': DateTime.now().toIso8601String(),
              });
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
