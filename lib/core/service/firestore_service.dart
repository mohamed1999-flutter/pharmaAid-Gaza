import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pharmacy_models.dart';

/// Central Firestore gateway for all pharmacy data.
class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _pharmacyRef(String uid) {
    return _db.collection('pharmacies').doc(uid);
  }

  static CollectionReference<Map<String, dynamic>> _categoriesRef(String uid) {
    return _pharmacyRef(uid).collection('categories');
  }

  static CollectionReference<Map<String, dynamic>> _medicinesRef(String uid) {
    return _pharmacyRef(uid).collection('medicines');
  }

  static CollectionReference<Map<String, dynamic>> _ordersRef(String uid) {
    return _pharmacyRef(uid).collection('orders');
  }

  /// Creates the pharmacy profile and owner profile in one batch.
  static Future<void> createPharmacyAccount({
    required PharmacyUser user,
  }) async {
    final batch = _db.batch();

    final userRef = _db.collection('users').doc(user.uid);
    final pharmacyRef = _pharmacyRef(user.uid);

    batch.set(userRef, user.toMap());
    batch.set(pharmacyRef, {
      'ownerId': user.uid,
      'name': user.pharmacyName,
      'address': user.pharmacyAddress,
      'location': user.pharmacyLocation,
      'imageUrl': user.pharmacyImageUrl,
      'email': user.email,
      'ownerName': user.name,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Returns the main pharmacy document.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> pharmacyStream(
    String uid,
  ) {
    return _pharmacyRef(uid).snapshots();
  }

  /// Updates the main pharmacy profile.
  static Future<void> updatePharmacyInfo({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _pharmacyRef(
      uid,
    ).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// CATEGORY CRUD

  static Stream<QuerySnapshot<Map<String, dynamic>>> categoriesStream(
    String uid,
  ) {
    return _categoriesRef(
      uid,
    ).orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> addCategory({
    required String uid,
    required PharmacyCategory category,
  }) async {
    await _categoriesRef(uid).doc(category.id).set(category.toMap());
  }

  static Future<void> updateCategory({
    required String uid,
    required PharmacyCategory category,
  }) async {
    await _categoriesRef(uid).doc(category.id).update(category.toMap());
  }

  static Future<void> deleteCategory({
    required String uid,
    required String categoryId,
  }) async {
    await _categoriesRef(uid).doc(categoryId).delete();
  }

  /// MEDICINE CRUD

  static Stream<QuerySnapshot<Map<String, dynamic>>> medicinesStream(
    String uid,
  ) {
    return _medicinesRef(
      uid,
    ).orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> addMedicine({
    required String uid,
    required MedicineModel medicine,
  }) async {
    await _medicinesRef(uid).doc(medicine.id).set(medicine.toMap());
  }

  static Future<void> updateMedicine({
    required String uid,
    required MedicineModel medicine,
  }) async {
    await _medicinesRef(uid).doc(medicine.id).update(medicine.toMap());
  }

  static Future<void> deleteMedicine({
    required String uid,
    required String medicineId,
  }) async {
    await _medicinesRef(uid).doc(medicineId).delete();
  }

  /// ORDERS

  static Stream<QuerySnapshot<Map<String, dynamic>>> ordersStream(
    String uid, {
    String? status,
  }) {
    Query<Map<String, dynamic>> query = _ordersRef(
      uid,
    ).orderBy('createdAt', descending: true);

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots();
  }

  static Future<void> addOrder({
    required String uid,
    required PharmacyOrder order,
  }) async {
    await _ordersRef(uid).doc(order.id).set(order.toMap());
  }

  static Future<void> updateOrderStatus({
    required String uid,
    required String orderId,
    required String status,
  }) async {
    await _ordersRef(uid).doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
