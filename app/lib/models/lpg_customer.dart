class LPGCustomer {
  final String id;
  final String name;
  final String? email;
  final String phone;
  final String? alternatePhone;
  final String customerType;
  final String? businessName;
  final String? gstNumber;
  final List<Premises> premises;
  final List<CylinderRefillHistory> refillHistory;
  final int loyaltyPoints;
  final String loyaltyTier;
  final double totalSpent;
  final int totalRefills;
  final double creditLimit;
  final double currentCredit;
  final String preferredDeliveryTime;
  final String? deliveryInstructions;
  final bool safetyTrainingCompleted;
  final DateTime? safetyTrainingDate;
  final EmergencyContact? emergencyContact;
  final String? notes;
  final bool isActive;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  LPGCustomer({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.alternatePhone,
    this.customerType = 'Individual',
    this.businessName,
    this.gstNumber,
    this.premises = const [],
    this.refillHistory = const [],
    this.loyaltyPoints = 0,
    this.loyaltyTier = 'Bronze',
    this.totalSpent = 0,
    this.totalRefills = 0,
    this.creditLimit = 0,
    this.currentCredit = 0,
    this.preferredDeliveryTime = 'Anytime',
    this.deliveryInstructions,
    this.safetyTrainingCompleted = false,
    this.safetyTrainingDate,
    this.emergencyContact,
    this.notes,
    this.isActive = true,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory LPGCustomer.fromJson(Map<String, dynamic> json) {
    return LPGCustomer(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      alternatePhone: json['alternatePhone'],
      customerType: json['customerType'] ?? 'Individual',
      businessName: json['businessName'],
      gstNumber: json['gstNumber'],
      premises: (json['premises'] as List<dynamic>? ?? [])
          .map((p) => Premises.fromJson(p))
          .toList(),
      refillHistory: (json['refillHistory'] as List<dynamic>? ?? [])
          .map((h) => CylinderRefillHistory.fromJson(h))
          .toList(),
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      loyaltyTier: json['loyaltyTier'] ?? 'Bronze',
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      totalRefills: json['totalRefills'] ?? 0,
      creditLimit: (json['creditLimit'] ?? 0).toDouble(),
      currentCredit: (json['currentCredit'] ?? 0).toDouble(),
      preferredDeliveryTime: json['preferredDeliveryTime'] ?? 'Anytime',
      deliveryInstructions: json['deliveryInstructions'],
      safetyTrainingCompleted: json['safetyTrainingCompleted'] ?? false,
      safetyTrainingDate: json['safetyTrainingDate'] != null
          ? DateTime.parse(json['safetyTrainingDate'])
          : null,
      emergencyContact: json['emergencyContact'] != null
          ? EmergencyContact.fromJson(json['emergencyContact'])
          : null,
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'customerType': customerType,
      'businessName': businessName,
      'gstNumber': gstNumber,
      'premises': premises.map((p) => p.toJson()).toList(),
      'refillHistory': refillHistory.map((h) => h.toJson()).toList(),
      'loyaltyPoints': loyaltyPoints,
      'loyaltyTier': loyaltyTier,
      'totalSpent': totalSpent,
      'totalRefills': totalRefills,
      'creditLimit': creditLimit,
      'currentCredit': currentCredit,
      'preferredDeliveryTime': preferredDeliveryTime,
      'deliveryInstructions': deliveryInstructions,
      'safetyTrainingCompleted': safetyTrainingCompleted,
      'safetyTrainingDate': safetyTrainingDate?.toIso8601String(),
      'emergencyContact': emergencyContact?.toJson(),
      'notes': notes,
      'isActive': isActive,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Getters for computed properties
  String get loyaltyStatus {
    if (loyaltyPoints >= 2000) return 'Platinum';
    if (loyaltyPoints >= 1000) return 'Gold';
    if (loyaltyPoints >= 500) return 'Silver';
    return 'Bronze';
  }

  double get availableCredit {
    return (creditLimit - currentCredit).clamp(0, double.infinity);
  }

  Premises? get primaryPremises {
    try {
      return premises.firstWhere((p) => p.isPrimary);
    } catch (e) {
      return premises.isNotEmpty ? premises.first : null;
    }
  }

  double get averageMonthlyConsumption {
    if (refillHistory.isEmpty) return 0;
    
    final totalConsumption = refillHistory.fold<double>(0, (sum, refill) {
      final cylinderWeight = _getCylinderWeight(refill.cylinderType);
      return sum + (cylinderWeight * refill.quantity);
    });
    
    final monthsActive = ((DateTime.now().difference(createdAt).inDays) / 30).ceil().clamp(1, double.infinity);
    return totalConsumption / monthsActive;
  }

  DateTime? get lastRefillDate {
    if (refillHistory.isEmpty) return null;
    return refillHistory
        .map((r) => r.refillDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  DateTime? get nextExpectedRefill {
    final lastRefill = lastRefillDate;
    if (lastRefill == null) return null;
    
    final avgConsumption = averageMonthlyConsumption;
    if (avgConsumption == 0) return null;
    
    final daysToNextRefill = (30 / (avgConsumption / 14.2)).ceil(); // Assuming 14.2kg average
    return lastRefill.add(Duration(days: daysToNextRefill));
  }

  bool get isDueForRefill {
    final nextRefill = nextExpectedRefill;
    if (nextRefill == null) return false;
    return DateTime.now().isAfter(nextRefill);
  }

  String get displayName {
    if (customerType == 'Business' && businessName != null && businessName!.isNotEmpty) {
      return '$businessName ($name)';
    }
    return name;
  }

  double _getCylinderWeight(String cylinderType) {
    switch (cylinderType) {
      case '11.8kg':
        return 11.8;
      case '15kg':
        return 15.0;
      case '45.4kg':
        return 45.4;
      default:
        return 14.2; // Default average
    }
  }

  LPGCustomer copyWith({
    String? name,
    String? email,
    String? phone,
    String? alternatePhone,
    String? customerType,
    String? businessName,
    String? gstNumber,
    List<Premises>? premises,
    List<CylinderRefillHistory>? refillHistory,
    int? loyaltyPoints,
    String? loyaltyTier,
    double? totalSpent,
    int? totalRefills,
    double? creditLimit,
    double? currentCredit,
    String? preferredDeliveryTime,
    String? deliveryInstructions,
    bool? safetyTrainingCompleted,
    DateTime? safetyTrainingDate,
    EmergencyContact? emergencyContact,
    String? notes,
    bool? isActive,
    List<String>? tags,
  }) {
    return LPGCustomer(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      customerType: customerType ?? this.customerType,
      businessName: businessName ?? this.businessName,
      gstNumber: gstNumber ?? this.gstNumber,
      premises: premises ?? this.premises,
      refillHistory: refillHistory ?? this.refillHistory,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      totalSpent: totalSpent ?? this.totalSpent,
      totalRefills: totalRefills ?? this.totalRefills,
      creditLimit: creditLimit ?? this.creditLimit,
      currentCredit: currentCredit ?? this.currentCredit,
      preferredDeliveryTime: preferredDeliveryTime ?? this.preferredDeliveryTime,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      safetyTrainingCompleted: safetyTrainingCompleted ?? this.safetyTrainingCompleted,
      safetyTrainingDate: safetyTrainingDate ?? this.safetyTrainingDate,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class Premises {
  final String id;
  final String name;
  final String type;
  final Address address;
  final String connectionType;
  final String cylinderCapacity;
  final double estimatedMonthlyConsumption;
  final String? deliveryInstructions;
  final bool isActive;
  final bool isPrimary;

  Premises({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.connectionType = 'Direct',
    this.cylinderCapacity = '11.8kg',
    this.estimatedMonthlyConsumption = 0,
    this.deliveryInstructions,
    this.isActive = true,
    this.isPrimary = false,
  });

  factory Premises.fromJson(Map<String, dynamic> json) {
    return Premises(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Residential',
      address: Address.fromJson(json['address'] ?? {}),
      connectionType: json['connectionType'] ?? 'Direct',
      cylinderCapacity: json['cylinderCapacity'] ?? '11.8kg',
      estimatedMonthlyConsumption: (json['estimatedMonthlyConsumption'] ?? 0).toDouble(),
      deliveryInstructions: json['deliveryInstructions'],
      isActive: json['isActive'] ?? true,
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type,
      'address': address.toJson(),
      'connectionType': connectionType,
      'cylinderCapacity': cylinderCapacity,
      'estimatedMonthlyConsumption': estimatedMonthlyConsumption,
      'deliveryInstructions': deliveryInstructions,
      'isActive': isActive,
      'isPrimary': isPrimary,
    };
  }

  String get fullAddress {
    return '${address.street}, ${address.city}, ${address.state} - ${address.pincode}';
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      landmark: json['landmark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
    };
  }
}

class CylinderRefillHistory {
  final String id;
  final String premises;
  final String cylinderType;
  final String? cylinderSerialNumber;
  final DateTime refillDate;
  final int quantity;
  final double pricePerUnit;
  final double totalAmount;
  final double depositAmount;
  final double refundAmount;
  final String paymentMethod;
  final String? deliveryAddress;
  final String deliveryStatus;
  final DateTime? deliveryDate;
  final String? notes;
  final String soldBy;

  CylinderRefillHistory({
    required this.id,
    required this.premises,
    required this.cylinderType,
    this.cylinderSerialNumber,
    required this.refillDate,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    this.depositAmount = 0,
    this.refundAmount = 0,
    this.paymentMethod = 'Cash',
    this.deliveryAddress,
    this.deliveryStatus = 'Delivered',
    this.deliveryDate,
    this.notes,
    required this.soldBy,
  });

  factory CylinderRefillHistory.fromJson(Map<String, dynamic> json) {
    return CylinderRefillHistory(
      id: json['_id'] ?? '',
      premises: json['premises'] ?? '',
      cylinderType: json['cylinderType'] ?? '',
      cylinderSerialNumber: json['cylinderSerialNumber'],
      refillDate: DateTime.parse(json['refillDate'] ?? DateTime.now().toIso8601String()),
      quantity: json['quantity'] ?? 0,
      pricePerUnit: (json['pricePerUnit'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      depositAmount: (json['depositAmount'] ?? 0).toDouble(),
      refundAmount: (json['refundAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      deliveryAddress: json['deliveryAddress'],
      deliveryStatus: json['deliveryStatus'] ?? 'Delivered',
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      notes: json['notes'],
      soldBy: json['soldBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'premises': premises,
      'cylinderType': cylinderType,
      'cylinderSerialNumber': cylinderSerialNumber,
      'refillDate': refillDate.toIso8601String(),
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'depositAmount': depositAmount,
      'refundAmount': refundAmount,
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
      'deliveryStatus': deliveryStatus,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'notes': notes,
      'soldBy': soldBy,
    };
  }
}

class EmergencyContact {
  final String? name;
  final String? phone;
  final String? relationship;

  EmergencyContact({
    this.name,
    this.phone,
    this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      phone: json['phone'],
      relationship: json['relationship'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }
}

// Enums for LPG Customer
enum CustomerType {
  individual('Individual'),
  business('Business'),
  institution('Institution');

  const CustomerType(this.displayName);
  final String displayName;
}

enum PremisesType {
  residential('Residential'),
  commercial('Commercial'),
  industrial('Industrial'),
  restaurant('Restaurant'),
  hotel('Hotel'),
  other('Other');

  const PremisesType(this.displayName);
  final String displayName;
}

enum ConnectionType {
  direct('Direct'),
  distributor('Distributor'),
  bulk('Bulk');

  const ConnectionType(this.displayName);
  final String displayName;
}

enum LoyaltyTier {
  bronze('Bronze'),
  silver('Silver'),
  gold('Gold'),
  platinum('Platinum');

  const LoyaltyTier(this.displayName);
  final String displayName;
}

enum DeliveryTime {
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening'),
  anytime('Anytime');

  const DeliveryTime(this.displayName);
  final String displayName;
}