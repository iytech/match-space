import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/property.dart';
import '../../providers/currency_provider.dart';
import '../../providers/property_provider.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  const PropertyCard({super.key, required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final props = context.watch<PropertyProvider>();
    final isFav = props.isFavorite(property.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: property.coverUrl.isEmpty
                      ? Container(
                          color: AppColors.surfaceAlt,
                          child: const Icon(Icons.home_work_outlined,
                              size: 40, color: AppColors.inkFaint),
                        )
                      : CachedNetworkImage(
                          imageUrl: property.coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceAlt),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceAlt,
                            child: const Icon(Icons.broken_image_outlined,
                                color: AppColors.inkFaint),
                          ),
                        ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.62),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      property.purposeBadge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5),
                    ),
                  ),
                ),
                if (property.featured)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          AppColors.ochre,
                          AppColors.terracotta,
                        ]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 13),
                        SizedBox(width: 3),
                        Text('Featured',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ]),
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      iconSize: 19,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppColors.terracotta : AppColors.inkSoft,
                      ),
                      onPressed: () =>
                          context.read<PropertyProvider>().toggleFavorite(property.id),
                    ),
                  ),
                ),
                if (property.isClosed)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.45),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.slate900,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(property.closedLabel.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                fontSize: 14)),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(currency.price(property.price),
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.terracotta)),
                      if (property.pricePeriod != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          property.isShortlet ? '/wk' : '/yr',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSoft),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.place_outlined,
                        size: 14, color: AppColors.inkFaint),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text('${property.city}, ${property.state}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.inkSoft)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    if (property.isLand) ...[
                      _meta(Icons.landscape_outlined,
                          '${property.areaSqm.round()}m²'),
                      if (property.titleDocument != null)
                        _meta(Icons.description_outlined, 'Titled'),
                    ] else ...[
                      _meta(Icons.bed_outlined, '${property.bedrooms}'),
                      _meta(Icons.bathtub_outlined, '${property.bathrooms}'),
                      _meta(Icons.straighten,
                          '${property.areaSqm.round()}m²'),
                    ],
                    const Spacer(),
                    if (property.reviewCount > 0)
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            size: 15, color: AppColors.ochre),
                        const SizedBox(width: 2),
                        Text(property.avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(children: [
          Icon(icon, size: 15, color: AppColors.inkSoft),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
        ]),
      );
}
