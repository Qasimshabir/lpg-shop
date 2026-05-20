import 'package:flutter/material.dart';
import '../../services/lpg_api_service.dart';
import '../../models/lpg_customer.dart';
import '../../lpg_theme.dart';

class AddCustomerScreen extends StatefulWidget {
  final LPGCustomer? customer;
  
  const AddCustomerScreen({Key? key, this.customer}) : super(key: key);

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
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _loadCustomerData();
    }
  }

  void _loadCustomerData() {
    final customer = widget.customer!;
    _nameController.text = customer.name;
    _emailController.text = customer.email ?? '';
    _phoneController.text = customer.phone;
    _alternatePhoneController.text = customer.alternatePhone ?? '';
    _businessNameController.text = customer.businessName ?? '';
    _gstNumberController.text = customer.gstNumber ?? '';
    _creditLimitController.text = customer.creditLimit.toString();
    _customerType = customer.customerType;
    
    // Load first premises if available
    if (customer.premises.isNotEmpty) {
      final premises = customer.premises[0];
      _premisesNameController.text = premises.name ?? '';
      _premisesType = premises.type;
      _streetController.text = premises.address.street;
      _cityController.text = premises.address.city;
      _stateController.text = premises.address.state;
      _pincodeController.text = premises.address.pincode;
      _landmarkController.text = premises.address.landmark ?? '';
      _cylinderCapacity = premises.cylinderCapacity;
    }
  }

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
        'customerType': _customerType,
        'address': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postalCode': _pincodeController.text.trim(),
        'notes': _landmarkController.text.trim().isEmpty ? null : 'Landmark: ${_landmarkController.text.trim()}',
        'isActive': true,
      };

      LPGCustomer savedCustomer;
      
      if (widget.customer != null) {
        // Update existing customer
        savedCustomer = await LPGApiService.updateLPGCustomer(widget.customer!.id, customerData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer updated successfully!'), backgroundColor: LPGColors.success),
          );
        }
      } else {
        // Create new customer
        savedCustomer = await LPGApiService.createLPGCustomer(customerData);
        
        // Add premises for new customer
        if (_premisesNameController.text.trim().isNotEmpty) {
          try {
            final premisesData = {
              'premises_type': _premisesType,
              'address': _streetController.text.trim(),
              'city': _cityController.text.trim(),
              'state': _stateController.text.trim(),
              'postal_code': _pincodeController.text.trim(),
              'is_primary': true,
            };
            
            await LPGApiService.addPremises(savedCustomer.id, premisesData);
          } catch (e) {
            print('Failed to add premises: $e');
            // Don't fail the whole operation if premises creation fails
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer added successfully!'), backgroundColor: LPGColors.success),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save customer: $e'), backgroundColor: LPGColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Customer' : 'Add New Customer')),
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
              decoration: InputDecoration(
                labelText: 'Full Name *',
                hintText: 'Enter customer name',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Name is required';
                }
                if (v.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                if (v.trim().length > 100) {
                  return 'Name must not exceed 100 characters';
                }
                // Check if name contains only letters, spaces, and common punctuation
                if (!RegExp(r"^[a-zA-Z\s\.\-']+$").hasMatch(v.trim())) {
                  return 'Name can only contain letters, spaces, and basic punctuation';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                hintText: '10 or 11-digit mobile number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              maxLength: 11,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required';
                }
                // Remove any spaces or special characters
                final cleaned = v.replaceAll(RegExp(r'[^\d]'), '');
                if (cleaned.length < 10 || cleaned.length > 11) {
                  return 'Phone number must be 10 or 11 digits';
                }
                if (!RegExp(r'^[6-9]\d{9,10}$').hasMatch(cleaned)) {
                  return 'Invalid phone number format';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _alternatePhoneController,
              decoration: InputDecoration(
                labelText: 'Alternate Phone',
                hintText: '10 or 11-digit mobile number (optional)',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              maxLength: 11,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final cleaned = v.replaceAll(RegExp(r'[^\d]'), '');
                if (cleaned.length < 10 || cleaned.length > 11) {
                  return 'Phone number must be 10 or 11 digits';
                }
                if (!RegExp(r'^[6-9]\d{9,10}$').hasMatch(cleaned)) {
                  return 'Invalid phone number format';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'example@email.com (optional)',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                // Basic email validation
                if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v.trim())) {
                  return 'Invalid email format';
                }
                return null;
              },
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
              decoration: InputDecoration(
                labelText: 'Business Name *',
                hintText: 'Enter business name',
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (_customerType == 'Business' || _customerType == 'Institution') {
                  if (v == null || v.trim().isEmpty) {
                    return 'Business name is required';
                  }
                  if (v.trim().length < 2) {
                    return 'Business name must be at least 2 characters';
                  }
                  if (v.trim().length > 200) {
                    return 'Business name must not exceed 200 characters';
                  }
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _gstNumberController,
              decoration: InputDecoration(
                labelText: 'GST Number',
                hintText: '15-character GST number (optional)',
                prefixIcon: Icon(Icons.receipt_long),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 15,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                // GST format: 2 digits (state code) + 10 alphanumeric (PAN) + 1 digit + 1 letter + 1 alphanumeric
                if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$').hasMatch(v.trim())) {
                  return 'Invalid GST number format';
                }
                return null;
              },
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
              decoration: InputDecoration(
                labelText: 'Premises Name *',
                hintText: 'e.g., Home, Office, Factory',
                prefixIcon: Icon(Icons.home),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Premises name is required';
                }
                if (v.trim().length < 2) {
                  return 'Premises name must be at least 2 characters';
                }
                if (v.trim().length > 100) {
                  return 'Premises name must not exceed 100 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _premisesType,
              decoration: InputDecoration(
                labelText: 'Premises Type',
                prefixIcon: Icon(Icons.category),
              ),
              items: ['Residential', 'Commercial', 'Industrial', 'Restaurant', 'Hotel']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _premisesType = v!),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: InputDecoration(
                labelText: 'Street Address *',
                hintText: 'House/Building number, Street name',
                prefixIcon: Icon(Icons.location_on),
              ),
              textCapitalization: TextCapitalization.words,
              maxLines: 2,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Street address is required';
                }
                if (v.trim().length < 5) {
                  return 'Address must be at least 5 characters';
                }
                if (v.trim().length > 200) {
                  return 'Address must not exceed 200 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City *',
                      hintText: 'City name',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'City is required';
                      }
                      if (v.trim().length < 2) {
                        return 'City must be at least 2 characters';
                      }
                      if (!RegExp(r"^[a-zA-Z\s\-]+$").hasMatch(v.trim())) {
                        return 'City can only contain letters';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: 'State *',
                      hintText: 'State name',
                      prefixIcon: Icon(Icons.map),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'State is required';
                      }
                      if (v.trim().length < 2) {
                        return 'State must be at least 2 characters';
                      }
                      if (!RegExp(r"^[a-zA-Z\s\-]+$").hasMatch(v.trim())) {
                        return 'State can only contain letters';
                      }
                      return null;
                    },
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
                    decoration: InputDecoration(
                      labelText: 'Pincode *',
                      hintText: '6-digit pincode',
                      prefixIcon: Icon(Icons.pin_drop),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Pincode is required';
                      }
                      // Remove any non-digit characters
                      final cleaned = v.replaceAll(RegExp(r'[^\d]'), '');
                      if (cleaned.length != 6) {
                        return 'Pincode must be exactly 6 digits';
                      }
                      // Check if it's a valid number (no alphabets)
                      if (!RegExp(r'^\d{6}$').hasMatch(cleaned)) {
                        return 'Pincode must contain only digits';
                      }
                      // Check if it starts with 0 (invalid in India)
                      if (cleaned.startsWith('0')) {
                        return 'Invalid pincode';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _cylinderCapacity,
                    decoration: InputDecoration(
                      labelText: 'Cylinder Size',
                      prefixIcon: Icon(Icons.propane_tank),
                    ),
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
              decoration: InputDecoration(
                labelText: 'Landmark',
                hintText: 'Nearby landmark (optional)',
                prefixIcon: Icon(Icons.place),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (v.trim().length > 200) {
                  return 'Landmark must not exceed 200 characters';
                }
                return null;
              },
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
            SizedBox(height: 8),
            Text(
              'Set credit limit for this customer (optional)',
              style: LPGTextStyles.caption.copyWith(color: LPGColors.textSecondary),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _creditLimitController,
              decoration: InputDecoration(
                labelText: 'Credit Limit',
                hintText: 'Enter amount (0 for no credit)',
                prefixText: 'Rs ',
                prefixIcon: Icon(Icons.account_balance_wallet),
                helperText: 'Maximum credit amount allowed',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Credit limit is required (enter 0 for no credit)';
                }
                final amount = double.tryParse(v.trim());
                if (amount == null) {
                  return 'Please enter a valid number';
                }
                if (amount < 0) {
                  return 'Credit limit cannot be negative';
                }
                if (amount > 1000000) {
                  return 'Credit limit cannot exceed Rs 10,00,000';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isEditing = widget.customer != null;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCustomer,
        child: _isLoading 
          ? CircularProgressIndicator(color: Colors.white) 
          : Text(isEditing ? 'Update Customer' : 'Add Customer'),
      ),
    );
  }
}
