import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/property.dart';
import '../../../providers/currency_provider.dart';

/// Featured carousel built on a plain PageView (no external carousel package,
/// so it stays clear of the CarouselController clash in newer Flutter SDKs).
class FeaturedStrip extends StatefulWidget {
  final List<Property> properties;
  const FeaturedStrip({super.key, required this.properties});

  @override
  State<FeaturedStrip> createState() => _FeaturedStripState();
}

class _FeaturedStripState extends State<FeaturedStrip> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    final wide =
        WidgetsBinding.instance.platformDispatcher.views.first.physicalSize
                .width /
            WidgetsBinding.instance.platformDispatcher.views.first
                .devicePixelRatio >
        720;
    _controller = PageController(viewportFraction: wide ? 0.5 : 0.9);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final items = widget.properties;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(children: [
            const Icon(Icons.star_rounded, color: AppColors.ochre),
            const SizedBox(width: 8),
            Text('Featured homes',
                style: Theme.of(context).textTheme.headlineMedium),
          ]),
        ),
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              final p = items[i];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/property',
                    arguments: p.id),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  clipBehavior: Clip.antiAlias,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(20)),
                  child: Stack(fit: StackFit.expand, children: [
                    p.coverUrl.isEmpty
                        ? Container(color: AppColors.surfaceAlt)
                        : CachedNetworkImage(
                            imageUrl: p.coverUrl, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87],
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${p.city}, ${p.state}',
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(currency.price(p.price),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 14),
          Center(
            child: AnimatedSmoothIndicator(
              activeIndex: _current,
              count: items.length,
              effect: const ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
                activeDotColor: AppColors.terracotta,
                dotColor: AppColors.border,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
