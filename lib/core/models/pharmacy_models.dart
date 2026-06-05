import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a pharmacy owner and the pharmacy profile itself.
class PharmacyUser {
  final String uid;
  final String name;
  final String email;
  final String pharmacyName;
  final String pharmacyAddress;
  final String pharmacyLocation;
  final String? pharmacyImageUrl;
  final String role;
  final DateTime createdAt;

  const PharmacyUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.pharmacyLocation,
    required this.role,
    required this.createdAt,
    this.pharmacyImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'pharmacyLocation': pharmacyLocation,
      'pharmacyImageUrl': pharmacyImageUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PharmacyUser.fromMap(Map<String, dynamic> map) {
    return PharmacyUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      pharmacyAddress: map['pharmacyAddress'] ?? '',
      pharmacyLocation: map['pharmacyLocation'] ?? '',
      pharmacyImageUrl: map['pharmacyImageUrl'],
      role: map['role'] ?? 'pharmacy',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Main pharmacy categories like stomach medicine, antibiotics, etc.
class PharmacyCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final String imageUrl;
  final DateTime createdAt;

  const PharmacyCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PharmacyCategory.fromMap(Map<String, dynamic> map) {
    return PharmacyCategory(
      id: map['id'] ?? '',
      nameAr: map['nameAr'] ?? '',
      nameEn: map['nameEn'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// A real medicine/product entry.
class MedicineModel {
  final String id;
  final String categoryId;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String composition;
  final String dosage;
  final String form;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  const MedicineModel({
    required this.id,
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.composition,
    required this.dosage,
    required this.form,
    required this.price,
    required this.stock,
    required this.isAvailable,
    required this.createdAt,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'composition': composition,
      'dosage': dosage,
      'form': form,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      nameAr: map['nameAr'] ?? '',
      nameEn: map['nameEn'] ?? '',
      descriptionAr: map['descriptionAr'] ?? '',
      descriptionEn: map['descriptionEn'] ?? '',
      composition: map['composition'] ?? '',
      dosage: map['dosage'] ?? '',
      form: map['form'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stock: (map['stock'] ?? 0).toInt(),
      imageUrl: map['imageUrl'],
      isAvailable: map['isAvailable'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// A single item inside an order.
class OrderItem {
  final String medicineId;
  final String name;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.medicineId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      medicineId: map['medicineId'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
    );
  }
}

/// Customer order stored inside pharmacy/orders.
class PharmacyOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String address;
  final List<OrderItem> items;
  final double total;
  final String status;
  final String? note;
  final DateTime createdAt;

  const PharmacyOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': address,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'status': status,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PharmacyOrder.fromMap(Map<String, dynamic> map) {
    return PharmacyOrder(
      id: map['id'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      address: map['address'] ?? '',
      items: ((map['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList()),
      total: (map['total'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      note: map['note'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
