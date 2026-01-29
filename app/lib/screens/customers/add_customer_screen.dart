import 'package:flutter/material.dart';
import '../../services/lpg_api_service.dart';
import '../../lpg_theme.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({Key? key}) : super(key: key);

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');
  
  // Premises fields
  final _premisesNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  String _customerType = 'Individual';
  String _premisesType = 'Residential';
  String _cylinderCapacity = '11.8kg';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _businessNameController.dispose();
    _gstNumberController.dispose();
    _creditLimitController.dispose();
    _premisesNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customerData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'alternatePhone': _alternatePhoneController.text.trim().isEmpty ? null : _alternatePhoneController.text.trim(),
        'customerType': _customerType,
        'creditLimit': double.parse(_creditLimitController.text),
        'premises': [
          {
            'name': _premisesNameController.text.trim(),
            'type': _premisesType,
            'address': {
              'street': _streetController.text.trim(),
              'city': _cityController.text.trim(),
              'state': _stateController.text.trim(),
              'pincode': _pincodeController.text.trim(),
              'landmark': _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
            },
            'cylinderCapacity': _cylinderCapacity,
            'isPrimary': true,
          }
        ],
      };

      if (_customerType == 'Business') {
        customerData['businessName'] = _businessNameController.text.trim();
        customerData['gstNumber'] = _gstNumberController.text.trim().isEmpty ? null : _gstNumberController.text.trim();
      }

      await LPGApiService.createLPGCustomer(customerData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer added successfully!'), backgroundColor: LPGColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add customer: $e'), backgroundColor: LPGColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildCustomerTypeSelector(),
            SizedBox(height: 16),
            _buildBasicInfoSection(),
            SizedBox(height: 16),
            if (_customerType == 'Business') ...[
              _buildBusinessInfoSection(),
              SizedBox(height: 16),
            ],
            _buildPremisesSection(),
            SizedBox(height: 16),
            _buildCreditSection(),
            SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerTypeSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Type', style: LPGTextStyles.subtitle1),
            SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'Individual', label: Text('Individual'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'Business', label: Text('Business'), icon: Icon(Icons.business)),
                ButtonSegment(value: 'Institution', label: Text('Institution'), icon: Icon(Icons.account_balance)),
              ],
              selected: {_customerType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _customerType = newSelection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Full Name *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _alternatePhoneController,
              decoration: InputDecoration(labelText: 'Alternate Phone', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Information', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: InputDecoration(labelText: 'Business Name *'),
              validator: (v) => _customerType == 'Business' && (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _gstNumberController,
              decoration: InputDecoration(labelText: 'GST Number'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremisesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Primary Premises', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            TextFormField(
              controller: _premisesNameController,
              decoration: InputDecoration(labelText: 'Premises Name *', hintText: 'e.g., Home, Office'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _premisesType,
              decoration: InputDecoration(labelText: 'Premises Type'),
              items: ['Residential', 'Commercial', 'Industrial', 'Restaurant', 'Hotel']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _premisesType = v!),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: InputDecoration(labelText: 'Street Address *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(labelText: 'City *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(labelText: 'State *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: InputDecoration(labelText: 'Pincode *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _cylinderCapacity,
                    decoration: InputDecoration(labelText: 'Cylinder Size'),
                    items: ['11.8kg', '15kg', '45.4kg']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _cylinderCapacity = v!),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _landmarkController,
              decoration: InputDecoration(labelText: 'Landmark'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Credit Settings', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            TextFormField(
              controller: _creditLimitController,
              decoration: InputDecoration(labelText: 'Credit Limit', prefixText: '₹ '),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCustomer,
        child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Add Customer'),
      ),
    );
  }
}
