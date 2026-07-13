import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const _premiumPriceNgn = 15000;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPremium = auth.profile?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Choose your plan',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                  'Upgrade anytime to unlock unlimited listings and featured '
                  'placement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft)),
              const SizedBox(height: 32),
              LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth > 640;
                final cards = [
                  _planCard(
                    context,
                    title: 'Free',
                    price: '₦0',
                    period: 'forever',
                    features: [
                      'Up to ${AppConfig.freeListingLimit} active listings',
                      'Direct messaging with buyers',
                      'Viewing requests',
                      'Standard placement',
                    ],
                    active: !isPremium,
                    cta: !isPremium ? 'Current plan' : null,
                    onTap: null,
                  ),
                  _planCard(
                    context,
                    title: 'Premium',
                    price: '₦${_premiumPriceNgn ~/ 1000}k',
                    period: 'per month',
                    highlighted: true,
                    features: [
                      'Unlimited listings',
                      'Featured placement on home & search',
                      'Priority in search results',
                      'Owner analytics dashboard',
                      'Premium badge',
                    ],
                    active: isPremium,
                    cta: isPremium ? 'Active' : 'Upgrade now',
                    onTap: isPremium
                        ? null
                        : () => _startCheckout(context, auth),
                  ),
                ];
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 20),
                          Expanded(child: cards[1]),
                        ],
                      )
                    : Column(children: [
                        cards[0],
                        const SizedBox(height: 20),
                        cards[1],
                      ]);
              }),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.lock_outline, size: 18, color: AppColors.inkSoft),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payments are processed securely by Flutterwave. Your '
                      'plan activates automatically once payment is verified.',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startCheckout(BuildContext context, AuthProvider auth) {
    // Client kicks off Flutterwave checkout. Verification happens server-side
    // (Supabase Edge Function with the Flutterwave SECRET key) which then flips
    // the user's tier to premium. Here we open the hosted payment link.
    final email = auth.profile?.email ?? '';
    final ref = 'ms-${auth.profile?.id.substring(0, 8)}-'
        '${DateTime.now().millisecondsSinceEpoch}';
    final url = Uri.parse(
      'https://flutterwave.com/pay/matchspace-premium'
      '?email=$email&tx_ref=$ref&amount=$_premiumPriceNgn',
    );
    if (AppConfig.flutterwavePublicKey.startsWith('PASTE_')) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Set up payments'),
          content: const Text(
              'Add your Flutterwave public key in app_config.dart and create '
              'your payment link to enable checkout.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _planCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required List<String> features,
    bool highlighted = false,
    bool active = false,
    String? cta,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.slate900 : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? AppColors.slate900 : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: highlighted ? Colors.white : AppColors.ink)),
            if (highlighted) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Popular',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price,
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: highlighted
                        ? AppColors.ochre
                        : AppColors.terracotta)),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(period,
                  style: TextStyle(
                      color: highlighted
                          ? Colors.white60
                          : AppColors.inkSoft)),
            ),
          ]),
          const SizedBox(height: 20),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Icon(Icons.check_circle,
                      size: 18,
                      color: highlighted
                          ? AppColors.emerald
                          : AppColors.emerald),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f,
                        style: TextStyle(
                            color: highlighted
                                ? Colors.white70
                                : AppColors.ink)),
                  ),
                ]),
              )),
          const SizedBox(height: 20),
          if (cta != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      active ? AppColors.surfaceAlt : AppColors.terracotta,
                  foregroundColor:
                      active ? AppColors.inkSoft : Colors.white,
                ),
                child: Text(cta),
              ),
            ),
        ],
      ),
    );
  }
}
