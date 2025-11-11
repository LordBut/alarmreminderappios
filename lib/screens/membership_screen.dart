// lib/screens/membership_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/billing_service.dart';

class MembershipScreen extends StatefulWidget {
  final VoidCallback onNavigateBack;
  const MembershipScreen({super.key, required this.onNavigateBack});
  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  bool _loading = true;
  Map<String, ProductDetailsData> _products = {};
  String _currentTier = 'Free';

  @override
  void initState() {
    super.initState();
    _loadBilling();
  }

  Future<void> _loadBilling() async {
    final uid = AuthService.currentUid;
    // load current tier from Firestore (helper)
    _currentTier = await BillingService.getUserTier(uid);
    final products = await BillingService.querySubscriptions();
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  Future<void> _purchase(String productId) async {
    setState(() => _loading = true);
    try {
      await BillingService.purchaseSubscription(productId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase started')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Options'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onNavigateBack),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Current membership: $_currentTier', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ..._products.entries.map((e) {
            final id = e.key;
            final p = e.value;
            return Card(
              child: ListTile(
                title: Text(p.title ?? id),
                subtitle: Text(p.description ?? ''),
                trailing: ElevatedButton(
                  onPressed: () => _purchase(id),
                  child: Text(p.price ?? 'Buy'),
                ),
              ),
            );
          }).toList()
        ],
      ),
    );
  }
}
