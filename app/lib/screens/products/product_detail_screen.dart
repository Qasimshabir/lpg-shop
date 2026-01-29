import 'package:flutter/material.dart';
import '../../models/lpg_product.dart';
import '../../services/lpg_api_service.dart';
import '../../lpg_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final LPGProduct product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late LPGProduct _product;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _refreshProduct() async {
    try {
      setState(() => _isLoading = true);
      final updated = await LPGApiService.getLPGProduct(_product.id);
      setState(() {
        _product = updated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to refresh: $e');
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete this product? This action cannot be undone.'),
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

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);
      await LPGApiService.deleteLPGProduct(_product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: LPGColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to delete: $e');
    }
  }

  Future<void> _updateCylinderState(String state, int quantity, String operation) async {
    try {
      setState(() => _isLoading = true);
      final updated = await LPGApiService.updateCylinderState(
        _product.id,
        state,
        quantity,
        operation: operation,
      );
      setState(() {
        _product = updated;
        _isLoading = false;
      });
      _showSuccess('Cylinder state updated');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshProduct,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showComingSoon('Edit Product');
              } else if (value == 'delete') {
                _deleteProduct();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: LPGColors.error)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshProduct,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(),
                  SizedBox(height: 16),
                  _buildDetailsCard(),
                  SizedBox(height: 16),
                  _buildPricingCard(),
                  SizedBox(height: 16),
                  if (_product.productType == 'cylinder') ...[
                    _buildCylinderStatesCard(),
                    SizedBox(height: 16),
                    _buildCylinderActionsCard(),
                  ] else
                    _buildStockCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _product.productType == 'cylinder'
                    ? LPGColors.primary.withOpacity(0.1)
                    : LPGColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _product.productType == 'cylinder' ? Icons.propane_tank : Icons.build,
                size: 60,
                color: _product.productType == 'cylinder' ? LPGColors.primary : LPGColors.secondary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              _product.displayName,
              style: LPGTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '${_product.brand} • ${_product.category}',
              style: LPGTextStyles.body1.copyWith(color: LPGColors.textTertiary),
            ),
            SizedBox(height: 12),
            _buildStatusChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text = _product.stockStatus;
    
    switch (_product.stockStatus) {
      case 'Out of Stock':
        color = LPGColors.error;
        break;
      case 'Low Stock':
        color = LPGColors.warning;
        break;
      case 'Overstock':
        color = LPGColors.info;
        break;
      default:
        color = LPGColors.success;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: LPGTextStyles.body2.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Details', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            _buildDetailRow('SKU', _product.sku),
            if (_product.productType == 'cylinder') ...[
              _buildDetailRow('Cylinder Type', _product.cylinderType ?? 'N/A'),
              _buildDetailRow('Capacity', '${_product.capacity ?? 0} kg'),
              _buildDetailRow('Pressure Rating', _product.pressureRating ?? 'N/A'),
            ],
            _buildDetailRow('Unit', _product.unit),
            if (_product.description != null && _product.description!.isNotEmpty) ...[
              Divider(height: 24),
              Text('Description', style: LPGTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(_product.description!, style: LPGTextStyles.body2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pricing', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPriceBox('Selling Price', _product.price, LPGColors.success),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildPriceBox('Cost Price', _product.costPrice, LPGColors.info),
                ),
              ],
            ),
            if (_product.productType == 'cylinder') ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceBox('Deposit', _product.depositAmount, LPGColors.warning),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildPriceBox('Refill Price', _product.refillPrice, LPGColors.secondary),
                  ),
                ],
              ),
            ],
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
                  Text('Profit Margin', style: LPGTextStyles.body1),
                  Text(
                    '${_product.profitMargin.toStringAsFixed(1)}%',
                    style: LPGTextStyles.subtitle1.copyWith(
                      color: LPGColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBox(String label, double amount, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: LPGTextStyles.caption),
          SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: LPGTextStyles.subtitle1.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCylinderStatesCard() {
    final states = _product.cylinderStates;
    if (states == null) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cylinder Inventory', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCylinderStateBox('Empty', states.empty, LPGColors.cylinderEmpty),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildCylinderStateBox('Filled', states.filled, LPGColors.cylinderFilled),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildCylinderStateBox('Sold', states.sold, LPGColors.cylinderSold),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: states.total > 0 ? states.filled / states.total : 0,
              backgroundColor: LPGColors.cylinderEmpty,
              valueColor: AlwaysStoppedAnimation<Color>(LPGColors.cylinderFilled),
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Text(
              'Available: ${states.filled} / ${states.total}',
              style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCylinderStateBox(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildCylinderActionsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUpdateStateDialog('filled', 'add'),
                    icon: Icon(Icons.add),
                    label: Text('Add Filled'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LPGColors.cylinderFilled,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUpdateStateDialog('empty', 'add'),
                    icon: Icon(Icons.add),
                    label: Text('Add Empty'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LPGColors.cylinderEmpty,
                      foregroundColor: LPGColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showExchangeDialog(),
                icon: Icon(Icons.swap_horiz),
                label: Text('Exchange Cylinders'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock Information', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            _buildDetailRow('Current Stock', '${_product.stock}'),
            _buildDetailRow('Minimum Stock', '${_product.minStock}'),
            _buildDetailRow('Maximum Stock', '${_product.maxStock}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary)),
          Text(value, style: LPGTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showUpdateStateDialog(String state, String operation) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${state.toUpperCase()} Cylinders'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Quantity',
            hintText: 'Enter number of cylinders',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text);
              if (quantity != null && quantity > 0) {
                Navigator.pop(context);
                _updateCylinderState(state, quantity, operation);
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showExchangeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exchange Cylinders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Exchange empty cylinders for filled ones'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'Number of cylinders to exchange',
              ),
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
              final quantity = int.tryParse(controller.text);
              if (quantity != null && quantity > 0) {
                Navigator.pop(context);
                try {
                  setState(() => _isLoading = true);
                  final updated = await LPGApiService.exchangeCylinder(_product.id, quantity);
                  setState(() {
                    _product = updated;
                    _isLoading = false;
                  });
                  _showSuccess('Cylinders exchanged successfully');
                } catch (e) {
                  setState(() => _isLoading = false);
                  _showError('Failed to exchange: $e');
                }
              }
            },
            child: Text('Exchange'),
          ),
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
