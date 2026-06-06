import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pharmacy_models.dart';
import '../models/user_models.dart';
import 'auth_service.dart';

/// Central Firestore gateway for all pharmacy data.
class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _cashOnDelivery = 'cash_on_delivery';
  static const String _paymentStatusPending = 'pending';
  static const String _paymentStatusCashOnDelivery = 'cash_on_delivery';

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

  static DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _db.collection('users').doc(uid);
  }

  static CollectionReference<Map<String, dynamic>> _userCartRef(String uid) {
    return _userRef(uid).collection('cart');
  }

  static CollectionReference<Map<String, dynamic>> _userOrdersRef(String uid) {
    return _userRef(uid).collection('orders');
  }

  static CollectionReference<Map<String, dynamic>> _pharmaciesPublicRef() {
    return _db.collection('pharmacies');
  }

  static String _toNonEmptyString(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static Future<String> _resolveCustomerName({
    required String userId,
    String fallback = 'Customer',
  }) async {
    try {
      final snapshot = await _userRef(userId).get();
      if (!snapshot.exists) return fallback;

      final data = snapshot.data();
      if (data == null) return fallback;

      final name = _toNonEmptyString(data['name']);
      if (name.isNotEmpty) return name;

      final fullName = _toNonEmptyString(data['fullName']);
      if (fullName.isNotEmpty) return fullName;

      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  static Map<String, dynamic> _buildUserOrderMap({
    required UserOrder order,
    required String customerName,
    required String paymentMethod,
  }) {
    return {
      ...order.toMap(),
      'customerName': customerName,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentMethod == _cashOnDelivery
          ? _paymentStatusCashOnDelivery
          : _paymentStatusPending,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> _buildPharmacyOrderMap({
    required UserOrder order,
    required String customerName,
    required String paymentMethod,
  }) {
    final pharmacyOrder = PharmacyOrder(
      id: order.id,
      customerName: customerName,
      customerPhone: order.customerPhone,
      address: order.deliveryAddress,
      items: order.items
          .map(
            (item) => OrderItem(
              medicineId: item.medicineId,
              name: item.name,
              quantity: item.quantity,
              unitPrice: item.price,
            ),
          )
          .toList(),
      total: order.total,
      status: order.status,
      note: order.customerNote,
      createdAt: order.createdAt,
    );

    return {
      ...pharmacyOrder.toMap(),
      'customerName': customerName,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentMethod == _cashOnDelivery
          ? _paymentStatusCashOnDelivery
          : _paymentStatusPending,
      'updatedAt': FieldValue.serverTimestamp(),
    };
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

  /// USER & CUSTOMER OPERATIONS

  /// Get all pharmacies for user to browse
  static Stream<QuerySnapshot<Map<String, dynamic>>> pharmaciesStream() {
    return _pharmaciesPublicRef().snapshots();
  }

  /// Get specific pharmacy details
  static Future<DocumentSnapshot<Map<String, dynamic>>> getPharmacyDetails(
    String pharmacyId,
  ) async {
    return _pharmaciesPublicRef().doc(pharmacyId).get();
  }

  /// Get medicines from a specific pharmacy
  static Stream<QuerySnapshot<Map<String, dynamic>>> pharmacyMedicinesStream(
    String pharmacyId, {
    String? categoryId,
  }) {
    Query<Map<String, dynamic>> query = _pharmacyRef(
      pharmacyId,
    ).collection('medicines').where('isAvailable', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots();
  }

  /// Get categories from a specific pharmacy
  static Stream<QuerySnapshot<Map<String, dynamic>>> pharmacyCategoriesStream(
    String pharmacyId,
  ) {
    return _pharmacyRef(pharmacyId)
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get user cart
  static Stream<QuerySnapshot<Map<String, dynamic>>> userCartStream(
    String uid,
  ) {
    return _userCartRef(uid).snapshots();
  }

  /// Add item to cart
  static Future<void> addToCart({
    required String uid,
    required CartItem item,
  }) async {
    await _userCartRef(uid).doc(item.medicineId).set(item.toMap());
  }

  /// Update cart item quantity
  static Future<void> updateCartItem({
    required String uid,
    required String medicineId,
    required int quantity,
  }) async {
    await _userCartRef(uid).doc(medicineId).update({'quantity': quantity});
  }

  /// Remove item from cart
  static Future<void> removeFromCart({
    required String uid,
    required String medicineId,
  }) async {
    await _userCartRef(uid).doc(medicineId).delete();
  }

  /// Clear entire cart
  static Future<void> clearCart(String uid) async {
    final snapshot = await _userCartRef(uid).get();
    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Create user order
  ///
  /// Saves the order in:
  /// - users/{userId}/orders/{orderId}
  /// - pharmacies/{pharmacyId}/orders/{orderId}
  /// - clears users/{userId}/cart after success
  ///
  /// Default payment method is cash on delivery.
  static Future<void> createUserOrder({
    required UserOrder order,
    bool clearCartAfterSuccess = true,
    String paymentMethod = _cashOnDelivery,
  }) async {
    if (order.items.isEmpty) {
      throw StateError('Cannot create an order with an empty cart.');
    }

    final customerName = await _resolveCustomerName(
      userId: order.userId,
      fallback: 'Customer',
    );

    final batch = _db.batch();

    final userOrderRef = _userOrdersRef(order.userId).doc(order.id);
    final pharmacyOrderRef = _ordersRef(order.pharmacyId).doc(order.id);

    batch.set(
      userOrderRef,
      _buildUserOrderMap(
        order: order,
        customerName: customerName,
        paymentMethod: paymentMethod,
      ),
    );

    batch.set(
      pharmacyOrderRef,
      _buildPharmacyOrderMap(
        order: order,
        customerName: customerName,
        paymentMethod: paymentMethod,
      ),
    );

    if (clearCartAfterSuccess) {
      final cartSnapshot = await _userCartRef(order.userId).get();
      for (final doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  /// Update user order status
  static Future<void> updateUserOrderStatus({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    await _userOrdersRef(userId).doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update order status in both user and pharmacy collections.
  static Future<void> updateOrderStatusEverywhere({
    required String userId,
    required String pharmacyId,
    required String orderId,
    required String status,
  }) async {
    final batch = _db.batch();

    batch.update(_userOrdersRef(userId).doc(orderId), {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_ordersRef(pharmacyId).doc(orderId), {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Get user profile
  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(
    String uid,
  ) async {
    return _userRef(uid).get();
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _userRef(
      uid,
    ).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getPharmacyProfile(
    String uid,
  ) async {
    return _pharmacyRef(uid).get();
  }

  static Future<bool> pharmacyProfileExists(String uid) async {
    final snapshot = await _pharmacyRef(uid).get();
    return snapshot.exists;
  }

  static Future<bool> userProfileExists(String uid) async {
    final snapshot = await _userRef(uid).get();
    return snapshot.exists;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> userOrdersStream(
    String uid, {
    String? status,
  }) {
    if (uid.trim().isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    Query<Map<String, dynamic>> query = _userOrdersRef(
      uid,
    ).orderBy('createdAt', descending: true);

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots();
  }

  /// CHAT OPERATIONS

  static CollectionReference<Map<String, dynamic>> _chatsRef() {
    return _db.collection('chats');
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> userChatsStream(
    String userId,
  ) {
    return _chatsRef()
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> pharmacyChatsStream(
    String pharmacyId,
  ) {
    return _chatsRef()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> chatMessagesStream(
    String chatId,
  ) {
    return _chatsRef()
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<String> getOrCreateChatRoom({
    required String userId,
    required String userName,
    required String pharmacyId,
    required String pharmacyName,
    String? userImageUrl,
    String? pharmacyImageUrl,
  }) async {
    final chatId = '${userId}_$pharmacyId';
    final doc = await _chatsRef().doc(chatId).get();

    if (!doc.exists) {
      await _chatsRef().doc(chatId).set({
        'userId': userId,
        'userName': userName,
        'userImageUrl': userImageUrl,
        'pharmacyId': pharmacyId,
        'pharmacyName': pharmacyName,
        'pharmacyImageUrl': pharmacyImageUrl,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'userUnreadCount': 0,
        'pharmacyUnreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    required bool isPharmacySender,
  }) async {
    final batch = _db.batch();
    final chatDocRef = _chatsRef().doc(chatId);
    final messageRef = chatDocRef.collection('messages').doc();

    batch.set(messageRef, {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    final updateData = {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    };

    if (isPharmacySender) {
      updateData['userUnreadCount'] = FieldValue.increment(1);
    } else {
      updateData['pharmacyUnreadCount'] = FieldValue.increment(1);
    }

    batch.update(chatDocRef, updateData);

    await batch.commit();
  }

  static Stream<int> totalUnreadCountStream(String uid, bool isPharmacy) {
    if (uid.isEmpty) return Stream.value(0);
    return (isPharmacy ? pharmacyChatsStream(uid) : userChatsStream(uid)).map((
      snapshot,
    ) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        count +=
            (isPharmacy
                    ? (data['pharmacyUnreadCount'] ?? 0)
                    : (data['userUnreadCount'] ?? 0))
                as int;
      }
      return count;
    });
  }

  static Future<void> markChatAsRead({
    required String chatId,
    required bool isPharmacy,
  }) async {
    final batch = _db.batch();
    final chatDocRef = _chatsRef().doc(chatId);

    final updateData = <String, dynamic>{};
    if (isPharmacy) {
      updateData['pharmacyUnreadCount'] = 0;
    } else {
      updateData['userUnreadCount'] = 0;
    }
    batch.update(chatDocRef, updateData);

    // Also mark messages as read
    final messagesSnapshot = await chatDocRef
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('receiverId', isEqualTo: AuthService.currentUser?.uid)
        .get();

    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
