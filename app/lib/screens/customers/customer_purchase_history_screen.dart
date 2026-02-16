import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_history.dart';
import '../../services/purchase_history_service.dart';
import '../../widgets/product_image_widget.dart';

class CustomerPurchaseHistoryScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerPurchaseHistoryScreen({
    Key? key,
    required this.customerId,
    required this.customerName,
  }) : super(key: key);

  @override
  State<CustomerPurchaseHistoryScreen> createState() =>
      _CustomerPurchaseHistoryScreenState();
}

class _CustomerPurchaseHistoryScreenState
    extends State<CustomerPurchaseHistoryScreen>
    with SingleTickerProviderStateMixin {
  final PurchaseHistoryService _service = PurchaseHistoryService();
  late TabController _tabController;

  List<PurchaseHistory> _purchases = [];
  PurchaseSummary? _summary;
  CustomerLifetimeValue? _ltv;
  List<ProductPreference> _preferences = [];
  List<MonthlyTrend> _trends = [];

  bool _isLoading = true;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _service.getCustomerPurchaseHistory(
          widget.customerId,
          limit: _pageSize,
          offset: _currentPage * _pageSize,
        ),
        _service.getCustomerPurchaseSummary(widget.customerId),
        _service.getCustomerLifetimeValue(widget.customerId),
        _service.getCustomerProductPreferences(widget.customerId),
        _service.getMonthlyPurchaseTrends(widget.customerId),
      ]);

      setState(() {
        final historyData = results[0] as Map<String, dynamic>;
        _purchases = historyData['purchases'] as List<PurchaseHistory>;
        _hasMore = historyData['pagination']['hasMore'] ?? false;

        _summary = results[1] as PurchaseSummary?;
        _ltv = results[2] as CustomerLifetimeValue?;
        _preferences = results[3] as List<ProductPreference>;
        _trends = results[4] as List<MonthlyTrend>;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load purchase history');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customerName}\'s History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Purchases', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Summary', icon: Icon(Icons.analytics)),
            Tab(text: 'Preferences', icon: Icon(Icons.favorite)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPurchasesTab(),
                _buildSummaryTab(),
                _buildPreferencesTab(),
                _buildTrendsTab(),
              ],
            ),
    );
  }

  Widget _buildPurchasesTab() {
    if (_purchases.isEmpty) {
      return const Center(
        child: Text('No purchase history found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _purchases.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _purchases.length) {
            return _buildLoadMoreButton();
          }

          final purchase = _purchases[index];
          return _buildPurchaseCard(purchase);
        },
      ),
    );
  }

  Widget _buildPurchaseCard(PurchaseHistory purchase) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showPurchaseDetails(purchase),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    purchase.invoiceNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(purchase.paymentStatus),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM dd, yyyy - hh:mm a').format(purchase.saleDate),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${purchase.items.length} item(s)',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    '₹${purchase.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (purchase.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                ...purchase.items.take(2).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          ProductImageWidget(
                            imageUrl: item.product?.imageUrl,
                            size: 32,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.product?.name ?? 'Unknown'} (x${item.quantity})',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (purchase.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(
                      '+${purchase.items.length - 2} more...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'partial':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_summary == null || _ltv == null) {
      return const Center(child: Text('No summary data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            'Total Orders',
            _summary!.totalOrders.toString(),
            Icons.shopping_cart,
            Colors.blue,
          ),
          _buildSummaryCard(
            'Total Spent',
            '₹${_summary!.totalSpent.toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
          _buildSummaryCard(
            'Average Order Value',
            '₹${_summary!.averageOrderValue.toStringAsFixed(2)}',
            Icons.analytics,
            Colors.orange,
          ),
          _buildSummaryCard(
            'Loyalty Tier',
            _ltv!.loyaltyTier,
            Icons.star,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Last 30 Days', '${_summary!.ordersLast30Days} orders'),
          _buildInfoRow('Last 90 Days', '${_summary!.ordersLast90Days} orders'),
          _buildInfoRow(
            'Spent (30 days)',
            '₹${_summary!.spentLast30Days.toStringAsFixed(2)}',
          ),
          if (_summary!.pendingAmount > 0)
            _buildInfoRow(
              'Pending Amount',
              '₹${_summary!.pendingAmount.toStringAsFixed(2)}',
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    if (_preferences.isEmpty) {
      return const Center(child: Text('No product preferences found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _preferences.length,
      itemBuilder: (context, index) {
        final pref = _preferences[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ProductImageWidget(
              imageUrl: pref.imageUrl,
              size: 50,
            ),
            title: Text(pref.productName),
            subtitle: Text(
              '${pref.brandName ?? 'Unknown Brand'} • Purchased ${pref.purchaseCount} times',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${pref.totalSpent.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${pref.totalQuantity} units',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    if (_trends.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trends.length,
      itemBuilder: (context, index) {
        final trend = _trends[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.blue),
            title: Text(
              DateFormat('MMMM yyyy').format(DateTime.parse(trend.month)),
            ),
            subtitle: Text('${trend.orderCount} orders'),
            trailing: Text(
              '₹${trend.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          setState(() => _currentPage++);
          _loadData();
        },
        child: const Text('Load More'),
      ),
    );
  }

  void _showPurchaseDetails(PurchaseHistory purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                purchase.invoiceNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMMM dd, yyyy - hh:mm a')
                    .format(purchase.saleDate),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: purchase.items.length,
                  itemBuilder: (context, index) {
                    final item = purchase.items[index];
                    return ListTile(
                      leading: ProductImageWidget(
                        imageUrl: item.product?.imageUrl,
                        size: 50,
                      ),
                      title: Text(item.product?.name ?? 'Unknown Product'),
                      subtitle: Text(
                        '${item.product?.brandName ?? ''} • ₹${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}',
                      ),
                      trailing: Text(
                        '₹${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹${purchase.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
