import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/property_service.dart';

class HeroSearch extends StatefulWidget {
  final ValueChanged<PropertyFilter> onSearch;
  const HeroSearch({super.key, required this.onSearch});
  @override
  State<HeroSearch> createState() => _HeroSearchState();
}

class _HeroSearchState extends State<HeroSearch> {
  final _query = TextEditingController();
  String? _state;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search() {
    widget.onSearch(PropertyFilter(
      query: _query.text.trim(),
      state: _state,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 720;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: EdgeInsets.all(wide ? 44 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.slate900, AppColors.slate800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spaces that match',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('how you want to live',
              style: TextStyle(
                  color: AppColors.ochre,
                  fontSize: wide ? 40 : 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: wide
                ? Row(children: [
                    Expanded(flex: 3, child: _searchField()),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: _stateField()),
                    const SizedBox(width: 8),
                    _searchButton(),
                  ])
                : Column(children: [
                    _searchField(),
                    const SizedBox(height: 8),
                    _stateField(),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: _searchButton()),
                  ]),
          ),
        ],
      ),
    );
  }

  Widget _searchField() => TextField(
        controller: _query,
        onSubmitted: (_) => _search(),
        decoration: const InputDecoration(
          hintText: 'Search city, area or title',
          prefixIcon: Icon(Icons.search, color: AppColors.inkFaint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      );

  Widget _stateField() => DropdownButtonFormField<String>(
        value: _state,
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'State',
          prefixIcon: Icon(Icons.place_outlined, color: AppColors.inkFaint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Any state')),
          ...AppOptions.states.map(
              (s) => DropdownMenuItem(value: s, child: Text(s))),
        ],
        onChanged: (v) => setState(() => _state = v),
      );

  Widget _searchButton() => ElevatedButton.icon(
        onPressed: _search,
        icon: const Icon(Icons.search, size: 18),
        label: const Text('Search'),
      );
}
