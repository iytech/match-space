import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_grid.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/property_service.dart';
import '../listings/property_card.dart';
import 'widgets/hero_search.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/featured_strip.dart';
import '../../core/utils/formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PropertyProvider>().loadHome());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final props = context.watch<PropertyProvider>();
    final currency = context.watch<CurrencyProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: const AppLogo(),
        actions: [
          _CurrencyToggle(currency: currency),
          const SizedBox(width: 8),
          if (auth.isLoggedIn) ...[
            _NotificationBell(),
            IconButton(
              tooltip: 'Messages',
              icon: const Icon(Icons.forum_outlined),
              onPressed: () => Navigator.pushNamed(context, '/messages'),
            ),
            IconButton(
              tooltip: 'Saved',
              icon: const Icon(Icons.favorite_border),
              onPressed: () => Navigator.pushNamed(context, '/favorites'),
            ),
            _ProfileMenu(),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/auth'),
                child: const Text('Sign in'),
              ),
            ),
        ],
      ),
      floatingActionButton: (auth.isLoggedIn &&
              (auth.profile?.canListProperties ?? false))
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/create-listing'),
              backgroundColor: AppColors.terracotta,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('List property',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => context.read<PropertyProvider>().loadHome(),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            HeroSearch(
              onSearch: (filter) =>
                  context.read<PropertyProvider>().mergeSearch(
                      query: filter.query, state: filter.state),
            ),
            if (props.featured.isNotEmpty) ...[
              const SizedBox(height: 8),
              FeaturedStrip(properties: props.featured),
            ],
            if (props.recentlyViewed.isNotEmpty)
              _RecentlyViewed(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  Text('Explore listings',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  _FilterButton(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: _TypeFilters(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: props.loading
                  ? const LoadingGrid()
                  : props.listings.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No properties found',
                          message:
                              'Try adjusting your filters or check back soon.',
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 360,
                            mainAxisExtent: 340,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: props.listings.length,
                          itemBuilder: (_, i) {
                            final p = props.listings[i];
                            // Teaser gating: logged-out users see the first 3
                            // listings clearly, the rest blurred with a prompt.
                            const previewCount = 3;
                            final locked =
                                !auth.isLoggedIn && i >= previewCount;
                            return _TeaserCard(
                              locked: locked,
                              child: PropertyCard(
                                property: p,
                                onTap: locked
                                    ? () =>
                                        Navigator.pushNamed(context, '/auth')
                                    : () => Navigator.pushNamed(
                                        context, '/property',
                                        arguments: p.id),
                              ),
                            );
                          },
                        ),
            ),
            if (!auth.isLoggedIn && props.listings.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _UnlockBanner(),
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  final CurrencyProvider currency;
  const _CurrencyToggle({required this.currency});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<CurrencyProvider>().toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(currency.isNgn ? '₦ NGN' : '\$ USD',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.swap_horiz, size: 16),
        ]),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      icon: CircleAvatar(
        radius: 17,
        backgroundColor: AppColors.terracottaSoft,
        child: Text(
          initialOf(auth.profile?.fullName),
          style: const TextStyle(
              color: AppColors.terracottaDark, fontWeight: FontWeight.w700),
        ),
      ),
      onSelected: (v) {
        switch (v) {
          case 'dashboard':
            Navigator.pushNamed(context, '/owner');
            break;
          case 'bookings':
            Navigator.pushNamed(context, '/bookings');
            break;
          case 'admin':
            Navigator.pushNamed(context, '/admin');
            break;
          case 'profile':
            Navigator.pushNamed(context, '/profile');
            break;
          case 'signout':
            context.read<AuthProvider>().signOut();
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'dashboard', child: Text('My listings')),
        const PopupMenuItem(value: 'bookings', child: Text('Viewings')),
        const PopupMenuItem(value: 'profile', child: Text('Profile')),
        if (auth.isAdmin)
          const PopupMenuItem(value: 'admin', child: Text('Admin panel')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'signout', child: Text('Sign out')),
      ],
    );
  }
}

class _TypeFilters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final props = context.watch<PropertyProvider>();
    final current = props.filter.purpose;
    return Wrap(spacing: 8, children: [
      _chip(context, 'All', current == null,
          () => _apply(context, null)),
      _chip(context, 'For sale', current == ListingPurpose.sale,
          () => _apply(context, ListingPurpose.sale)),
      _chip(context, 'For rent', current == ListingPurpose.rent,
          () => _apply(context, ListingPurpose.rent)),
      _chip(context, 'For lease', current == ListingPurpose.lease,
          () => _apply(context, ListingPurpose.lease)),
      _chip(context, 'Short-let', current == ListingPurpose.shortlet,
          () => _apply(context, ListingPurpose.shortlet)),
    ]);
  }

  void _apply(BuildContext context, ListingPurpose? purpose) {
    final f = context.read<PropertyProvider>().filter;
    context.read<PropertyProvider>().applyFilter(PropertyFilter(
          query: f.query,
          type: f.type,
          purpose: purpose,
          state: f.state,
          minPrice: f.minPrice,
          maxPrice: f.maxPrice,
          minBeds: f.minBeds,
        ));
  }

  Widget _chip(
      BuildContext context, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.terracotta : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AppColors.terracotta : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}

class _RecentlyViewed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final props = context.watch<PropertyProvider>();
    final items = props.recentlyViewed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text('Recently viewed',
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final p = items[i];
              final currency = context.read<CurrencyProvider>();
              return InkWell(
                onTap: () => Navigator.pushNamed(context, '/property',
                    arguments: p.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: p.coverUrl.isEmpty
                          ? Container(
                              width: 72,
                              height: 72,
                              color: AppColors.surfaceAlt)
                          : Image.network(p.coverUrl,
                              width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(currency.price(p.price),
                              style: const TextStyle(
                                  color: AppColors.terracotta,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Wraps a property card; when [locked], blurs it and overlays a lock + prompt.
class _TeaserCard extends StatelessWidget {
  final bool locked;
  final Widget child;
  const _TeaserCard({required this.locked, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.slate900.withOpacity(0.42),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  const Text('Sign in to view',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width prompt inviting logged-out users to sign in for the full catalog.
class _UnlockBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.slate900, AppColors.terracottaDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        spacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('See every home on Match Space',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Create a free account to unlock all listings, message '
                  'owners, and save your favourites.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/auth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.terracottaDark,
            ),
            child: const Text('Create free account'),
          ),
        ],
      ),
    );
  }
}

/// App-bar bell showing a live unread-notification count badge.
class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotificationProvider>().unreadCount;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints:
                  const BoxConstraints(minWidth: 17, minHeight: 17),
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.canvas, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

/// Opens the full filter sheet; shows a badge with the count of active filters.
class _FilterButton extends StatelessWidget {
  int _activeCount(PropertyFilter f) {
    var n = 0;
    if (f.type != null) n++;
    if (f.purpose != null) n++;
    if (f.state != null) n++;
    if (f.minBeds != null) n++;
    if (f.minPrice != null || f.maxPrice != null) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<PropertyProvider>().filter;
    final count = _activeCount(filter);
    return OutlinedButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.canvas,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (_) => FilterSheet(
            current: context.read<PropertyProvider>().filter,
            onApply: (f) =>
                context.read<PropertyProvider>().applyFilter(f),
          ),
        );
      },
      icon: const Icon(Icons.tune, size: 18),
      label: Text(count > 0 ? 'Filters ($count)' : 'Filters'),
      style: OutlinedButton.styleFrom(
        foregroundColor: count > 0 ? AppColors.terracotta : AppColors.ink,
        side: BorderSide(
            color: count > 0 ? AppColors.terracotta : AppColors.border),
      ),
    );
  }
}
