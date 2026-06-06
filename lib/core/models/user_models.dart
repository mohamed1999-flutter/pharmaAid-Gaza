import 'package:cloud_firestore/cloud_firestore.dart';

/// Regular customer user
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String role;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, [String? id]) {
    return AppUser(
      uid: id ?? map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      address: map['address'],
      role: map['role'] ?? 'user',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Item in user's cart
class CartItem {
  final String medicineId;
  final String name;
  final String? imageUrl;
  final double price;
  final int quantity;
  final String pharmacyId;
  final String pharmacyName;

  const CartItem({
    required this.medicineId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.pharmacyId,
    required this.pharmacyName,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      medicineId: map['medicineId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
    );
  }

  CartItem copyWith({
    String? medicineId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    String? pharmacyId,
    String? pharmacyName,
  }) {
    return CartItem(
      medicineId: medicineId ?? this.medicineId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
    );
  }

  double get total => price * quantity;
}

/// User order
class UserOrder {
  final String id;
  final String userId;
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyAddress;
  final List<CartItem> items;
  final double total;
  final String status;
  final String? customerNote;
  final String deliveryAddress;
  final String customerPhone;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;

  const UserOrder({
    required this.id,
    required this.userId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.items,
    required this.total,
    required this.status,
    required this.deliveryAddress,
    required this.customerPhone,
    required this.createdAt,
    this.customerNote,
    this.estimatedDelivery,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'status': status,
      'customerNote': customerNote,
      'deliveryAddress': deliveryAddress,
      'customerPhone': customerPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
    };
  }

  factory UserOrder.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserOrder(
      id: id ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      pharmacyAddress: map['pharmacyAddress'] ?? '',
      items: ((map['items'] as List<dynamic>? ?? [])
          .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e)))
          .toList()),
      total: (map['total'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      customerNote: map['customerNote'],
      deliveryAddress: map['deliveryAddress'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedDelivery: (map['estimatedDelivery'] as Timestamp?)?.toDate(),
    );
  }
}

/// Pharmacy display info for user
class PharmacyDisplay {
  final String id;
  final String name;
  final String address;
  final String location;
  final String? imageUrl;
  final double rating;
  final bool isOpen;
  final String? phone;

  const PharmacyDisplay({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.rating,
    required this.isOpen,
    this.imageUrl,
    this.phone,
  });

  factory PharmacyDisplay.fromMap(Map<String, dynamic> map, [String? id]) {
    return PharmacyDisplay(
      id: id ?? map['uid'] ?? map['id'] ?? '',
      name: map['pharmacyName'] ?? map['name'] ?? '',
      address: map['pharmacyAddress'] ?? map['address'] ?? '',
      location: map['pharmacyLocation'] ?? map['location'] ?? '',
      imageUrl: map['pharmacyImageUrl'] ?? map['imageUrl'],
      rating: (map['rating'] ?? 4.5).toDouble(),
      isOpen: map['isOpen'] ?? true,
      phone: map['phone'],
    );
  }
}
