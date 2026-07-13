import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/property_service.dart';

/// Bottom-sheet filter panel for price range, property type, bedrooms, purpose
/// and state. Returns a PropertyFilter via [onApply]. Preserves the existing
/// text query already in the active filter.
class FilterSheet extends StatefulWidget {
  final PropertyFilter current;
  final ValueChanged<PropertyFilter> onApply;
  const FilterSheet({super.key, required this.current, required this.onApply});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late PropertyType? _type = widget.current.type;
  late ListingPurpose? _purpose = widget.current.purpose;
  late String? _state = widget.current.state;
  late int? _minBeds = widget.current.minBeds;
  late RangeValues _price;

  // Price slider bounds (NGN). Covers rentals up to high-end sales.
  static const double _priceMin = 0;
  static const double _priceMax = 500000000; // ₦500m

  @override
  void initState() {
    super.initState();
    _price = RangeValues(
      (widget.current.minPrice ?? _priceMin).toDouble().clamp(_priceMin, _priceMax),
      (widget.current.maxPrice ?? _priceMax).toDouble().clamp(_priceMin, _priceMax),
    );
  }

  String _fmtPrice(double v) {
    if (v >= 1000000000) return '₦${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(0)}M';
    if (v >= 1000) return '₦${(v / 1000).toStringAsFixed(0)}K';
    return '₦${v.toStringAsFixed(0)}';
  }

  void _reset() {
    setState(() {
      _type = null;
      _purpose = null;
      _state = null;
      _minBeds = null;
      _price = const RangeValues(_priceMin, _priceMax);
    });
  }

  void _apply() {
    widget.onApply(PropertyFilter(
      query: widget.current.query,
      type: _type,
      purpose: _purpose,
      state: _state,
      minBeds: _minBeds,
      minPrice: _price.start <= _priceMin ? null : _price.start,
      maxPrice: _price.end >= _priceMax ? null : _price.end,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(children: [
              Text('Filters',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ]),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _label('Purpose'),
                Wrap(spacing: 8, children: [
                  _choice('Any', _purpose == null,
                      () => setState(() => _purpose = null)),
                  ...ListingPurpose.values.map((p) => _choice(
                        AppOptions.purposeChips[p]!,
                        _purpose == p,
                        () => setState(() => _purpose = p),
                      )),
                ]),
                const SizedBox(height: 20),
                _label('Property type'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _choice('Any', _type == null,
                      () => setState(() => _type = null)),
                  ...PropertyType.values.map((t) => _choice(
                        AppOptions.propertyTypeLabels[t]!,
                        _type == t,
                        () => setState(() => _type = t),
                      )),
                ]),
                const SizedBox(height: 20),
                _label('Price range'),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_fmtPrice(_price.start),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta)),
                  Text(_price.end >= _priceMax
                      ? '${_fmtPrice(_price.end)}+'
                      : _fmtPrice(_price.end),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta)),
                ]),
                RangeSlider(
                  values: _price,
                  min: _priceMin,
                  max: _priceMax,
                  activeColor: AppColors.terracotta,
                  onChanged: (v) => setState(() => _price = v),
                ),
                const SizedBox(height: 12),
                _label('Bedrooms (minimum)'),
                Wrap(spacing: 8, children: [
                  _choice('Any', _minBeds == null,
                      () => setState(() => _minBeds = null)),
                  ...[1, 2, 3, 4, 5].map((n) => _choice(
                        '$n+',
                        _minBeds == n,
                        () => setState(() => _minBeds = n),
                      )),
                ]),
                const SizedBox(height: 20),
                _label('State'),
                DropdownButtonFormField<String>(
                  value: _state,
                  isExpanded: true,
                  decoration: const InputDecoration(hintText: 'Any state'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any state')),
                    ...AppOptions.states.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) => setState(() => _state = v),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('Show results'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
      );

  Widget _choice(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
