import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/property.dart';
import '../../services/engagement_service.dart';
import 'property_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _engagement = EngagementService();
  List<Property> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _items = await _engagement.favorites();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved properties')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'No saved properties',
                  message:
                      'Tap the heart on any listing to save it for later.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisExtent: 340,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => PropertyCard(
                    property: _items[i],
                    onTap: () => Navigator.pushNamed(context, '/property',
                        arguments: _items[i].id),
                  ),
                ),
    );
  }
}
