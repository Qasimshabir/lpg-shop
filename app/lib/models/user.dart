class User {
  final String id;
  final String name;
  final String email;
  final String shopName;
  final String ownerName;
  final String? phone;
  final String? address;
  final String? city;
  final String? avatar;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.shopName,
    required this.ownerName,
    this.phone,
    this.address,
    this.city,
    this.avatar,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      shopName: json['shopName'] ?? '',
      ownerName: json['ownerName'] ?? '',
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      avatar: json['avatar'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'shopName': shopName,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'city': city,
      'avatar': avatar,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    String? city,
    String? avatar,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      avatar: avatar ?? this.avatar,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }


}
