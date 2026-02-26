import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/premium_provider.dart';

class PurchaseService {
  static const String _premiumId = 'com.aguahoy.app.premium';
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static ProviderContainer? _container;

  static void initialize(ProviderContainer container) {
    _container = container;
    final purchaseStream = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseStream.listen(_onPurchaseUpdate);
  }

  static void dispose() {
    _subscription?.cancel();
  }

  static Future<void> buyPremium() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return;

    final response =
        await InAppPurchase.instance.queryProductDetails({_premiumId});
    if (response.productDetails.isEmpty) return;

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  static void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == _premiumId) {
          _container?.read(premiumProvider.notifier).setPremium(true);
        }
      }
      if (purchase.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }
}
