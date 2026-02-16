class PurchaseHistory {
  final String id;
  final String invoiceNumber;
  final DateTime saleDate;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryStatus;
  final String? deliveryAddress;
  final String? notes;
  final List<PurchaseItem> items;

  PurchaseHistory({
    required this.id,
    required this.invoiceNumber,
    required this.saleDate,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryStatus,
    this.deliveryAddress,
    this.notes,
    required this.items,
  });

  factory PurchaseHistory.fromJson(Map<String, dynamic> json) {
    return PurchaseHistory(
      id: json['id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      saleDate: DateTime.parse(json['sale_date']),
      totalAmount: double.parse(json['total_amount'].toString()),
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      deliveryStatus: json['delivery_status'] ?? '',
      deliveryAddress: json['delivery_address'],
      notes: json['notes'],
      items: (json['sale_items'] as List?)
              ?.map((item) => PurchaseItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'sale_date': saleDate.toIso8601String(),
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'delivery_status': deliveryStatus,
      'delivery_address': deliveryAddress,
      'notes': notes,
      'sale_items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class PurchaseItem {
  final String id;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final ProductInfo? product;

  PurchaseItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.product,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: double.parse(json['unit_price'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      product: json['lpg_products'] != null
          ? ProductInfo.fromJson(json['lpg_products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'lpg_products': product?.toJson(),
    };
  }
}

class ProductInfo {
  final String id;
  final String name;
  final String category;
  final String? brandName;
  final String? imageUrl;

  ProductInfo({
    required this.id,
    required this.name,
    required this.category,
    this.brandName,
    this.imageUrl,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      brandName: json['brands']?['title'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'brands': brandName != null ? {'title': brandName} : null,
      'image_url': imageUrl,
    };
  }
}

class PurchaseSummary {
  final String customerId;
  final String customerCode;
  final String customerName;
  final String? phone;
  final String? email;
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;
  final DateTime? lastPurchaseDate;
  final DateTime? firstPurchaseDate;
  final int ordersLast30Days;
  final int ordersLast90Days;
  final double spentLast30Days;
  final double pendingAmount;

  PurchaseSummary({
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    this.phone,
    this.email,
    required this.totalOrders,
    required this.totalSpent,
    required this.averageOrderValue,
    this.lastPurchaseDate,
    this.firstPurchaseDate,
    required this.ordersLast30Days,
    required this.ordersLast90Days,
    required this.spentLast30Days,
    required this.pendingAmount,
  });

  factory PurchaseSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseSummary(
      customerId: json['customer_id'] ?? '',
      customerCode: json['customer_code'] ?? '',
      customerName: json['customer_name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      totalOrders: json['total_orders'] ?? 0,
      totalSpent: double.parse(json['total_spent'].toString()),
      averageOrderValue: double.parse(json['average_order_value'].toString()),
      lastPurchaseDate: json['last_purchase_date'] != null
          ? DateTime.parse(json['last_purchase_date'])
          : null,
      firstPurchaseDate: json['first_purchase_date'] != null
          ? DateTime.parse(json['first_purchase_date'])
          : null,
      ordersLast30Days: json['orders_last_30_days'] ?? 0,
      ordersLast90Days: json['orders_last_90_days'] ?? 0,
      spentLast30Days: double.parse(json['spent_last_30_days'].toString()),
      pendingAmount: double.parse(json['pending_amount'].toString()),
    );
  }
}

class CustomerLifetimeValue {
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;
  final DateTime? firstPurchase;
  final DateTime? lastPurchase;
  final int customerLifetimeDays;
  final DateTime? predictedNextPurchase;
  final String loyaltyTier;

  CustomerLifetimeValue({
    required this.totalOrders,
    required this.totalSpent,
    required this.averageOrderValue,
    this.firstPurchase,
    this.lastPurchase,
    required this.customerLifetimeDays,
    this.predictedNextPurchase,
    required this.loyaltyTier,
  });

  factory CustomerLifetimeValue.fromJson(Map<String, dynamic> json) {
    return CustomerLifetimeValue(
      totalOrders: json['total_orders'] ?? 0,
      totalSpent: double.parse(json['total_spent'].toString()),
      averageOrderValue: double.parse(json['average_order_value'].toString()),
      firstPurchase: json['first_purchase'] != null
          ? DateTime.parse(json['first_purchase'])
          : null,
      lastPurchase: json['last_purchase'] != null
          ? DateTime.parse(json['last_purchase'])
          : null,
      customerLifetimeDays: json['customer_lifetime_days'] ?? 0,
      predictedNextPurchase: json['predicted_next_purchase'] != null
          ? DateTime.parse(json['predicted_next_purchase'])
          : null,
      loyaltyTier: json['loyalty_tier'] ?? 'Bronze',
    );
  }
}

class ProductPreference {
  final String productId;
  final String productName;
  final String? brandName;
  final String? imageUrl;
  final int purchaseCount;
  final int totalQuantity;
  final double totalSpent;
  final DateTime? lastPurchased;
  final double averagePrice;

  ProductPreference({
    required this.productId,
    required this.productName,
    this.brandName,
    this.imageUrl,
    required this.purchaseCount,
    required this.totalQuantity,
    required this.totalSpent,
    this.lastPurchased,
    required this.averagePrice,
  });

  factory ProductPreference.fromJson(Map<String, dynamic> json) {
    return ProductPreference(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      brandName: json['brand_name'],
      imageUrl: json['image_url'],
      purchaseCount: json['purchase_count'] ?? 0,
      totalQuantity: json['total_quantity'] ?? 0,
      totalSpent: double.parse(json['total_spent'].toString()),
      lastPurchased: json['last_purchased'] != null
          ? DateTime.parse(json['last_purchased'])
          : null,
      averagePrice: double.parse(json['average_price'].toString()),
    );
  }
}

class MonthlyTrend {
  final String month;
  final double totalAmount;
  final int orderCount;

  MonthlyTrend({
    required this.month,
    required this.totalAmount,
    required this.orderCount,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] ?? '',
      totalAmount: double.parse(json['totalAmount'].toString()),
      orderCount: json['orderCount'] ?? 0,
    );
  }
}
