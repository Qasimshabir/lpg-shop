import 'package:flutter/material.dart';
import '../../models/lpg_customer.dart';
import '../../models/lpg_product.dart';
import '../../services/lpg_api_service.dart';
import '../../lpg_theme.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({Key? key}) : super(key: key);

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  bool _isLoading = false;
  LPGCustomer? _selectedCustomer;
  List<LPGCustomer> _customers = [];
  List<LPGProduct> _products = [];
  final List<Map<String, dynamic>> _cartItems = [];
  String _paymentMethod = 'Cash';
  final _discountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final results = await Future.wait([
        LPGApiService.getLPGCustomers(limit: 100),
        LPGApiService.getLPGProducts(limit: 100),
      ]);
      setState(() {
        _customers = results[0] as List<LPGCustomer>;
        _products = results[1] as List<LPGProduct>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load data: $e');
    }
  }

  void _addToCart(LPGProduct product) {
    showDialog(
      context: context,
      builder: (context) => _AddToCartDialog(product: product),
    ).then((result) {
      if (result != null) {
        setState(() {
          _cartItems.add({
            'product': result['product'],
            'productName': result['productName'],
            'quantity': result['quantity'],
            'unitPrice': result['unitPrice'],
            'subtotal': result['subtotal'],
          });
        });
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() => _cartItems.removeAt(index));
  }

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + item['subtotal']);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _total => (_subtotal - _discount).clamp(0, double.infinity);

  Future<void> _createSale() async {
    if (_cartItems.isEmpty) {
      _showError('Please add at least one item');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final saleData = {
        'customer_id': _selectedCustomer?.id,
        'items': _cartItems.map((item) => {
          'product_id': item['product'],
          'quantity': item['quantity'],
          'unit_price': item['unitPrice'],
        }).toList(),
        'payment_method': _paymentMethod,
        'payment_status': _paymentMethod == 'Credit' ? 'pending' : 'paid',
      };

      print('Creating sale with data: $saleData');
      
      await LPGApiService.createLPGSale(saleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale created successfully!'), backgroundColor: LPGColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Sale creation error: $e');
      setState(() => _isLoading = false);
      _showError('Failed to create sale: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create New Sale')),
      body: _isLoading && _products.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      _buildCustomerSelector(),
                      SizedBox(height: 16),
                      _buildProductSelector(),
                      SizedBox(height: 16),
                      _buildCart(),
                      SizedBox(height: 16),
                      _buildPaymentSection(),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildCustomerSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer', style: LPGTextStyles.subtitle1),
            SizedBox(height: 12),
            InkWell(
              onTap: () => _showCustomerPicker(),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: LPGColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: LPGColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCustomer?.displayName ?? 'Walk-in Customer (Tap to select)',
                        style: LPGTextStyles.body1,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Products', style: LPGTextStyles.subtitle1),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showProductPicker(),
              icon: Icon(Icons.add),
              label: Text('Select Product'),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cart (${_cartItems.length} items)', style: LPGTextStyles.subtitle1),
            SizedBox(height: 12),
            if (_cartItems.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No items in cart', style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary)),
                ),
              )
            else
              ..._cartItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildCartItem(item, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LPGColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['productName'], style: LPGTextStyles.body1),
                SizedBox(height: 4),
                Text(
                  '${item['quantity']} x Rs${item['unitPrice'].toStringAsFixed(0)}',
                  style: LPGTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            'Rs${item['subtotal'].toStringAsFixed(0)}',
            style: LPGTextStyles.subtitle2.copyWith(color: LPGColors.success),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: LPGColors.error, size: 20),
            onPressed: () => _removeFromCart(index),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment', style: LPGTextStyles.subtitle1),
            SizedBox(height: 12),
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
            SizedBox(height: 16),
            TextFormField(
              controller: _discountController,
              decoration: InputDecoration(labelText: 'Discount', prefixText: 'Rs '),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:', style: LPGTextStyles.body1),
                Text('Rs${_subtotal.toStringAsFixed(2)}', style: LPGTextStyles.body1),
              ],
            ),
            if (_discount > 0) ...[
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Discount:', style: LPGTextStyles.body2.copyWith(color: LPGColors.error)),
                  Text('-Rs${_discount.toStringAsFixed(2)}', style: LPGTextStyles.body2.copyWith(color: LPGColors.error)),
                ],
              ),
            ],
            Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: LPGTextStyles.heading3),
                Text('Rs${_total.toStringAsFixed(2)}', style: LPGTextStyles.heading3.copyWith(color: LPGColors.success)),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading || _cartItems.isEmpty ? null : _createSale,
                child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Complete Sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Select Customer', style: LPGTextStyles.heading3),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Walk-in Customer'),
              onTap: () {
                setState(() => _selectedCustomer = null);
                Navigator.pop(context);
              },
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final customer = _customers[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(customer.name[0])),
                    title: Text(customer.displayName),
                    subtitle: Text(customer.phone),
                    onTap: () {
                      setState(() => _selectedCustomer = customer);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Select Product', style: LPGTextStyles.heading3),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ListTile(
                      leading: Icon(product.productType == 'cylinder' ? Icons.propane_tank : Icons.build),
                      title: Text(product.displayName),
                      subtitle: Text('Rs${product.price.toStringAsFixed(0)} • Stock: ${product.availableCylinders}'),
                      trailing: Icon(Icons.add_circle, color: LPGColors.primary),
                      onTap: () {
                        Navigator.pop(context);
                        _addToCart(product);
                      },
                    );
                  },
                ),
              ),
            ],
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
}

class _AddToCartDialog extends StatefulWidget {
  final LPGProduct product;

  const _AddToCartDialog({required this.product});

  @override
  State<_AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<_AddToCartDialog> {
  final _quantityController = TextEditingController(text: '1');
  late double _unitPrice;

  @override
  void initState() {
    super.initState();
    _unitPrice = widget.product.price;
  }

  @override
  Widget build(BuildContext context) {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final subtotal = quantity * _unitPrice;

    return AlertDialog(
      title: Text('Add to Cart'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.product.displayName, style: LPGTextStyles.subtitle1),
          SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 16),
          TextFormField(
            initialValue: _unitPrice.toString(),
            decoration: InputDecoration(labelText: 'Unit Price', prefixText: 'Rs '),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _unitPrice = double.tryParse(v) ?? widget.product.price),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LPGColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:', style: LPGTextStyles.body1),
                Text('Rs${subtotal.toStringAsFixed(2)}', style: LPGTextStyles.subtitle1.copyWith(color: LPGColors.success)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (quantity > 0) {
              Navigator.pop(context, {
                'product': widget.product.id,
                'productName': widget.product.displayName,
                'quantity': quantity,
                'unitPrice': _unitPrice,
                'subtotal': subtotal,
              });
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
