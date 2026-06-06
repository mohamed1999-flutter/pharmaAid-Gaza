import 'package:flutter/foundation.dart';

import '../models/user_models.dart';
import '../service/firestore_service.dart';

/// Manages shopping cart state and operations
class CartProvider with ChangeNotifier {
  final String userId;
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  CartProvider({required this.userId}) {
    _loadCart();
  }

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _items.length;
  double get total => _items.fold(0.0, (sum, item) => sum + item.total);

  /// Group items by pharmacy
  Map<String, List<CartItem>> get itemsByPharmacy {
    final Map<String, List<CartItem>> grouped = {};
    for (var item in _items) {
      grouped.putIfAbsent(item.pharmacyId, () => []).add(item);
    }
    return grouped;
  }

  /// Check if all items are from the same pharmacy
  bool get isSinglePharmacy => itemsByPharmacy.length <= 1;

  Future<void> _loadCart() async {
    if (userId.isEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await FirestoreService.userCartStream(userId).first;
      _items = snapshot.docs
          .map((doc) => CartItem.fromMap(doc.data()))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add item to cart
  Future<void> addItem(CartItem item) async {
    try {
      final existingIndex = _items.indexWhere(
        (i) => i.medicineId == item.medicineId,
      );

      if (existingIndex != -1) {
        // Update quantity if item exists
        final updatedItem = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity + item.quantity,
        );
        _items[existingIndex] = updatedItem;
        await FirestoreService.updateCartItem(
          uid: userId,
          medicineId: item.medicineId,
          quantity: updatedItem.quantity,
        );
      } else {
        // Add new item
        _items.add(item);
        await FirestoreService.addToCart(uid: userId, item: item);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String medicineId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(medicineId);
      return;
    }

    try {
      final index = _items.indexWhere((i) => i.medicineId == medicineId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(quantity: quantity);
        await FirestoreService.updateCartItem(
          uid: userId,
          medicineId: medicineId,
          quantity: quantity,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String medicineId) async {
    try {
      _items.removeWhere((i) => i.medicineId == medicineId);
      await FirestoreService.removeFromCart(
        uid: userId,
        medicineId: medicineId,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      _items.clear();
      await FirestoreService.clearCart(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear items for a specific pharmacy
  Future<void> clearPharmacyCart(String pharmacyId) async {
    try {
      final itemsToRemove = _items
          .where((i) => i.pharmacyId == pharmacyId)
          .toList();
      for (var item in itemsToRemove) {
        await FirestoreService.removeFromCart(
          uid: userId,
          medicineId: item.medicineId,
        );
      }
      _items.removeWhere((i) => i.pharmacyId == pharmacyId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get items for a specific pharmacy
  List<CartItem> getItemsForPharmacy(String pharmacyId) {
    return _items.where((item) => item.pharmacyId == pharmacyId).toList();
  }

  /// Get total for a specific pharmacy
  double getTotalForPharmacy(String pharmacyId) {
    return getItemsForPharmacy(
      pharmacyId,
    ).fold(0.0, (sum, item) => sum + item.total);
  }
}
