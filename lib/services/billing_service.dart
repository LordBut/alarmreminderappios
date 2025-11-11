// lib/services/billing_service.dart
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A wrapper around the in_app_purchase package and Firestore.
class BillingService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Product data container
  /// (Used in MembershipScreen to display title/price)
  static Future<Map<String, ProductDetailsData>> querySubscriptions(
      [List<String>? productIds]) async {
    // Default list of subscription product IDs if not provided
    final ids = productIds ??
        <String>{
          'genevolut_tier_pro',
          'genevolut_tier_premium',
          'genevolut_tier_elite',
        };

    final response = await _iap.queryProductDetails(ids.toSet());
    final result = <String, ProductDetailsData>{};

    for (final p in response.productDetails) {
      result[p.id] = ProductDetailsData(
        id: p.id,
        title: p.title,
        description: p.description,
        price: p.price,
      );
    }

    return result;
  }

  /// Start a subscription purchase
  static Future<void> purchaseSubscription(String productId) async {
    final available = await _iap.isAvailable();
    if (!available) throw Exception('In-App Purchases not available');

    final detailsResponse =
        await _iap.queryProductDetails({productId}.toSet());
    if (detailsResponse.productDetails.isEmpty) {
      throw Exception('Product not found: $productId');
    }

    final productDetails = detailsResponse.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    _iap.buyNonConsumable(purchaseParam: purchaseParam);

    // Optionally listen to purchase updates
    _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        if (p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored) {
          await _deliverEntitlement(p.productID);
          await _iap.completePurchase(p);
        }
      }
    });
  }

  /// Called after a successful purchase to deliver entitlements
  static Future<void> _deliverEntitlement(String productId) async {
    // Map your product ID to membership tier
    String tier;
    if (productId.contains('pro')) {
      tier = 'Pro';
    } else if (productId.contains('premium')) {
      tier = 'Premium';
    } else {
      tier = 'Elite';
    }

    final uid = await _getCurrentUid();
    if (uid == null) return;

    await _db.collection('users').doc(uid).set(
      {'subscriptionTier': tier, 'updatedAt': DateTime.now()},
      SetOptions(merge: true),
    );
  }

  /// Fetch user membership tier from Firestore
  static Future<String> getUserTier(String? uid) async {
    if (uid == null) return 'Free';
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['subscriptionTier'] as String?) ?? 'Free';
  }

  /// Internal helper (if you use FirebaseAuth elsewhere)
  static Future<String?> _getCurrentUid() async {
    try {
      // Use your AuthService if already imported
      final userDoc = await FirebaseFirestore.instance
          .collection('current_user')
          .doc('meta')
          .get();
      return userDoc.data()?['uid'];
    } catch (_) {
      return null;
    }
  }
}

/// Lightweight product details model (cleaner for the UI)
class ProductDetailsData {
  final String id;
  final String? title;
  final String? description;
  final String? price;

  ProductDetailsData({
    required this.id,
    this.title,
    this.description,
    this.price,
  });
}
