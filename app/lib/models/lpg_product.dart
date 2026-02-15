class LPGProduct {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String productType; // 'cylinder' or 'accessory'
  final String? cylinderType; // '11.8kg', '15kg', '45.4kg'
  final double? capacity; // in kg
  final String? pressureRating;
  final CylinderStates? cylinderStates;
  final String unit;
  final int stock;
  final int minStock;
  final int maxStock;
  final double price;
  final double costPrice;
  final double depositAmount;
  final double refillPrice;
  final String sku;
  final String? barcode;
  final String? description;
  final List<String> images;
  final Supplier? supplier;
  final bool inspectionRequired;
  final int inspectionInterval; // in months
  final DateTime? lastInspectionDate;
  final DateTime? nextInspectionDue;
  final String? certificationNumber;
  final List<String> tags;
  final double discount;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LPGProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.productType,
    this.cylinderType,
    this.capacity,
    this.pressureRating,
    this.cylinderStates,
    this.unit = 'Piece',
    this.stock = 0,
    this.minStock = 5,
    this.maxStock = 100,
    required this.price,
    required this.costPrice,
    this.depositAmount = 0,
    this.refillPrice = 0,
    required this.sku,
    this.barcode,
    this.description,
    this.images = const [],
    this.supplier,
    this.inspectionRequired = false,
    this.inspectionInterval = 60,
    this.lastInspectionDate,
    this.nextInspectionDue,
    this.certificationNumber,
    this.tags = const [],
    this.discount = 0,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LPGProduct.fromJson(Map<String, dynamic> json) {
    return LPGProduct(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? json['brand_id']?.toString() ?? '',
      category: json['category'] ?? '',
      productType: json['productType'] ?? json['product_type'] ?? 'cylinder',
      cylinderType: json['cylinderType'] ?? json['cylinder_type'],
      capacity: (json['capacity'] ?? json['weight'])?.toDouble(),
      pressureRating: json['pressureRating'] ?? json['pressure_rating'],
      cylinderStates: json['cylinderStates'] ?? json['cylinder_states'] != null 
          ? CylinderStates.fromJson(json['cylinderStates'] ?? json['cylinder_states'])
          : null,
      unit: json['unit'] ?? json['weight_unit'] ?? 'Piece',
      stock: json['stock'] ?? json['stock_quantity'] ?? 0,
      minStock: json['minStock'] ?? json['min_stock'] ?? json['reorder_level'] ?? 5,
      maxStock: json['maxStock'] ?? json['max_stock'] ?? 100,
      price: (json['price'] ?? 0).toDouble(),
      costPrice: (json['costPrice'] ?? json['cost_price'] ?? 0).toDouble(),
      depositAmount: (json['depositAmount'] ?? json['deposit_amount'] ?? 0).toDouble(),
      refillPrice: (json['refillPrice'] ?? json['refill_price'] ?? 0).toDouble(),
      sku: json['sku'] ?? '',
      barcode: json['barcode'],
      description: json['description'],
      images: json['images'] != null 
          ? (json['images'] is List ? List<String>.from(json['images']) : [json['image_url']].where((e) => e != null).cast<String>().toList())
          : [],
      supplier: json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
      inspectionRequired: json['inspectionRequired'] ?? json['inspection_required'] ?? false,
      inspectionInterval: json['inspectionInterval'] ?? json['inspection_interval'] ?? 60,
      lastInspectionDate: json['lastInspectionDate'] ?? json['last_inspection_date'] != null 
          ? DateTime.parse(json['lastInspectionDate'] ?? json['last_inspection_date'])
          : null,
      nextInspectionDue: json['nextInspectionDue'] ?? json['next_inspection_due'] != null 
          ? DateTime.parse(json['nextInspectionDue'] ?? json['next_inspection_due'])
          : null,
      certificationNumber: json['certificationNumber'] ?? json['certification_number'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      discount: (json['discount'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'productType': productType,
      'cylinderType': cylinderType,
      'capacity': capacity,
      'pressureRating': pressureRating,
      'cylinderStates': cylinderStates?.toJson(),
      'unit': unit,
      'stock': stock,
      'minStock': minStock,
      'maxStock': maxStock,
      'price': price,
      'costPrice': costPrice,
      'depositAmount': depositAmount,
      'refillPrice': refillPrice,
      'sku': sku,
      'barcode': barcode,
      'description': description,
      'images': images,
      'supplier': supplier?.toJson(),
      'inspectionRequired': inspectionRequired,
      'inspectionInterval': inspectionInterval,
      'lastInspectionDate': lastInspectionDate?.toIso8601String(),
      'nextInspectionDue': nextInspectionDue?.toIso8601String(),
      'certificationNumber': certificationNumber,
      'tags': tags,
      'discount': discount,
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Getters for computed properties
  int get totalCylinders {
    if (productType == 'cylinder' && cylinderStates != null) {
      return cylinderStates!.empty + cylinderStates!.filled;
    }
    return 0;
  }

  int get availableCylinders {
    if (productType == 'cylinder' && cylinderStates != null) {
      return cylinderStates!.filled;
    }
    return stock;
  }

  String get stockStatus {
    final available = productType == 'cylinder' ? availableCylinders : stock;
    
    if (available == 0) return 'Out of Stock';
    if (available <= minStock) return 'Low Stock';
    if (available >= maxStock) return 'Overstock';
    return 'In Stock';
  }

  double get profitMargin {
    if (costPrice == 0) return 0;
    return ((price - costPrice) / costPrice * 100);
  }

  double get finalPrice {
    return price - (price * discount / 100);
  }

  bool get isInspectionDue {
    if (!inspectionRequired || nextInspectionDue == null) return false;
    return DateTime.now().isAfter(nextInspectionDue!);
  }

  bool get isInspectionDueSoon {
    if (!inspectionRequired || nextInspectionDue == null) return false;
    final daysUntilDue = nextInspectionDue!.difference(DateTime.now()).inDays;
    return daysUntilDue <= 30 && daysUntilDue >= 0;
  }

  String get displayName {
    if (productType == 'cylinder' && cylinderType != null) {
      return '$name ($cylinderType)';
    }
    return name;
  }

  LPGProduct copyWith({
    String? name,
    String? brand,
    String? category,
    String? productType,
    String? cylinderType,
    double? capacity,
    String? pressureRating,
    CylinderStates? cylinderStates,
    String? unit,
    int? stock,
    int? minStock,
    int? maxStock,
    double? price,
    double? costPrice,
    double? depositAmount,
    double? refillPrice,
    String? sku,
    String? barcode,
    String? description,
    List<String>? images,
    Supplier? supplier,
    bool? inspectionRequired,
    int? inspectionInterval,
    DateTime? lastInspectionDate,
    DateTime? nextInspectionDue,
    String? certificationNumber,
    List<String>? tags,
    double? discount,
    bool? isActive,
    String? notes,
  }) {
    return LPGProduct(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      productType: productType ?? this.productType,
      cylinderType: cylinderType ?? this.cylinderType,
      capacity: capacity ?? this.capacity,
      pressureRating: pressureRating ?? this.pressureRating,
      cylinderStates: cylinderStates ?? this.cylinderStates,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      refillPrice: refillPrice ?? this.refillPrice,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      images: images ?? this.images,
      supplier: supplier ?? this.supplier,
      inspectionRequired: inspectionRequired ?? this.inspectionRequired,
      inspectionInterval: inspectionInterval ?? this.inspectionInterval,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      nextInspectionDue: nextInspectionDue ?? this.nextInspectionDue,
      certificationNumber: certificationNumber ?? this.certificationNumber,
      tags: tags ?? this.tags,
      discount: discount ?? this.discount,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class CylinderStates {
  final int empty;
  final int filled;
  final int sold;

  CylinderStates({
    required this.empty,
    required this.filled,
    required this.sold,
  });

  factory CylinderStates.fromJson(Map<String, dynamic> json) {
    return CylinderStates(
      empty: json['empty'] ?? 0,
      filled: json['filled'] ?? 0,
      sold: json['sold'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empty': empty,
      'filled': filled,
      'sold': sold,
    };
  }

  int get total => empty + filled;
}

class Supplier {
  final String? name;
  final String? contact;
  final String? email;

  Supplier({
    this.name,
    this.contact,
    this.email,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      name: json['name'],
      contact: json['contact'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contact': contact,
      'email': email,
    };
  }
}

// Enums for LPG-specific categories
enum LPGProductCategory {
  lpgCylinder('LPG Cylinder'),
  gasPipe('Gas Pipe'),
  regulator('Regulator'),
  gasStove('Gas Stove'),
  gasTandoor('Gas Tandoor'),
  gasHeater('Gas Heater'),
  lpgInstantGeyser('LPG Instant Geyser'),
  safetyEquipment('Safety Equipment'),
  accessories('Accessories'),
  other('Other');

  const LPGProductCategory(this.displayName);
  final String displayName;
}

enum CylinderType {
  small('11.8kg'),
  medium('15kg'),
  large('45.4kg');

  const CylinderType(this.displayName);
  final String displayName;
  
  double get capacity {
    switch (this) {
      case CylinderType.small:
        return 11.8;
      case CylinderType.medium:
        return 15.0;
      case CylinderType.large:
        return 45.4;
    }
  }
}

enum ProductType {
  cylinder('cylinder'),
  accessory('accessory');

  const ProductType(this.value);
  final String value;
}