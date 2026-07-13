import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/property.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/property_provider.dart';
import '../../services/property_service.dart';
import '../../services/review_service.dart';
import '../../services/engagement_service.dart';
import '../../services/messaging_service.dart';
import '../bookings/book_viewing_sheet.dart';
import '../reviews/reviews_section.dart';
import '../tools/mortgage_calculator.dart';
import '../messaging/chat_screen.dart';
import '../../core/utils/formatters.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});
  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final _service = PropertyService();
  final _reviews = ReviewService();
  final _engagement = EngagementService();
  Property? _property;
  List<Review> _reviewList = [];
  int _activeMedia = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _service.fetchById(widget.propertyId);
    if (p != null) {
      _service.incrementView(p.id);
      _engagement.recordView(p.id);
      _reviewList = await _reviews.forProperty(p.id);
    }
    if (mounted) setState(() {
      _property = p;
      _loading = false;
    });
  }

  Future<void> _startChat() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.pushNamed(context, '/auth');
      return;
    }
    final p = _property!;
    final convoId = await MessagingService()
        .getOrCreateConversation(propertyId: p.id, ownerId: p.ownerId);
    if (mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChatScreen(
                    conversationId: convoId,
                    title: p.ownerName ?? 'Owner',
                  )));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_property == null) {
      return const Scaffold(
          body: Center(child: Text('This property is no longer available.')));
    }
    final p = _property!;
    final currency = context.watch<CurrencyProvider>();
    final wide = MediaQuery.of(context).size.width > 900;
    final props = context.watch<PropertyProvider>();
    final isFav = props.isFavorite(p.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? AppColors.terracotta : null),
            onPressed: () =>
                context.read<PropertyProvider>().toggleFavorite(p.id),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (p.isClosed)
            Container(
              width: double.infinity,
              color: AppColors.slate900,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('This property has been ${p.closedLabel.toLowerCase()}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          _Gallery(
            property: p,
            active: _activeMedia,
            onSelect: (i) => setState(() => _activeMedia = i),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _details(p, currency)),
                      const SizedBox(width: 32),
                      Expanded(flex: 2, child: _sidebar(p, currency)),
                    ],
                  )
                : Column(children: [
                    _details(p, currency),
                    const SizedBox(height: 24),
                    _sidebar(p, currency),
                  ]),
          ),
        ],
      ),
    );
  }

  Widget _details(Property p, CurrencyProvider currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.terracottaSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
                AppOptions.propertyTypeLabels[p.type] ?? p.type.name,
                style: const TextStyle(
                    color: AppColors.terracottaDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Text(p.purposeBadge,
              style: const TextStyle(color: AppColors.inkSoft)),
        ]),
        const SizedBox(height: 14),
        Text(p.title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.place_outlined,
              size: 18, color: AppColors.inkSoft),
          const SizedBox(width: 4),
          Text('${p.address}, ${p.city}, ${p.state}',
              style: Theme.of(context).textTheme.bodyMedium),
        ]),
        const SizedBox(height: 20),
        Wrap(spacing: 24, runSpacing: 12, children: [
          if (p.isLand) ...[
            _feature(Icons.landscape_outlined,
                '${p.areaSqm.round()} m²', 'Plot size'),
            if (p.titleDocument != null)
              _feature(Icons.description_outlined, p.titleDocument!, 'Title'),
          ] else ...[
            _feature(Icons.bed_outlined, '${p.bedrooms}', 'Bedrooms'),
            _feature(Icons.bathtub_outlined, '${p.bathrooms}', 'Bathrooms'),
            _feature(Icons.straighten, '${p.areaSqm.round()} m²', 'Area'),
          ],
          if (p.isForLease && p.leaseTermYears != null)
            _feature(Icons.schedule, '${p.leaseTermYears} yrs', 'Lease term'),
          _feature(Icons.visibility_outlined, '${p.viewCount}', 'Views'),
        ]),
        const Divider(height: 40),
        Text('About this property',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(p.description,
            style: Theme.of(context).textTheme.bodyLarge),
        if (p.amenities.isNotEmpty) ...[
          const Divider(height: 40),
          Text('Amenities', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: p.amenities
                .map((a) => Chip(
                      avatar: const Icon(Icons.check_circle,
                          size: 16, color: AppColors.emerald),
                      label: Text(a),
                    ))
                .toList(),
          ),
        ],
        if (p.isForSale) ...[
          const Divider(height: 40),
          MortgageCalculator(price: p.price),
        ],
        const Divider(height: 40),
        ReviewsSection(
          propertyId: p.id,
          reviews: _reviewList,
          avgRating: p.avgRating,
          onAdded: _load,
        ),
      ],
    );
  }

  Widget _sidebar(Property p, CurrencyProvider currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currency.fullPrice(p.price),
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.terracotta)),
          if (p.pricePeriod != null)
            Text(p.pricePeriod!, style: const TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 20),
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.terracottaSoft,
              child: Text(initialOf(p.ownerName, 'O'),
                  style: const TextStyle(
                      color: AppColors.terracottaDark,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(p.ownerName ?? 'Property owner',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (p.ownerIsAgent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified_user_outlined,
                            size: 12, color: AppColors.emerald),
                        SizedBox(width: 3),
                        Text('Agent',
                            style: TextStyle(
                                color: AppColors.emerald,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ],
                ]),
                Text(p.ownerIsAgent ? 'Verified agent' : 'Listing owner',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 13)),
              ],
            ),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Message owner'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                if (!auth.isLoggedIn) {
                  Navigator.pushNamed(context, '/auth');
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BookViewingSheet(property: p),
                );
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: const Text('Book a viewing'),
            ),
          ),
          if (p.ownerPhone != null && p.ownerPhone!.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:${p.ownerPhone}')),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: const Text('Call owner'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.terracotta),
        const SizedBox(height: 6),
        Text(value,
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  final Property property;
  final int active;
  final ValueChanged<int> onSelect;
  const _Gallery(
      {required this.property, required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final media = property.media;
    if (media.isEmpty) {
      return Container(
        height: 320,
        color: AppColors.surfaceAlt,
        child: const Center(
            child: Icon(Icons.home_work_outlined,
                size: 60, color: AppColors.inkFaint)),
      );
    }
    return Column(children: [
      SizedBox(
        height: 420,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: media[active].url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppColors.surfaceAlt),
        ),
      ),
      if (media.length > 1)
        Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: media.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                width: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: i == active
                        ? AppColors.terracotta
                        : AppColors.border,
                    width: i == active ? 2.4 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(fit: StackFit.expand, children: [
                  CachedNetworkImage(
                      imageUrl: media[i].url, fit: BoxFit.cover),
                  if (media[i].isVideo)
                    const Center(
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.white)),
                ]),
              ),
            ),
          ),
        ),
    ]);
  }
}
