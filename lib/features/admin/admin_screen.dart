import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/property.dart';
import '../../services/property_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final _service = PropertyService();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<Property> _pending = [];
  List<Property> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _pending = await _service.fetchPending();
    _all = await _service.fetchApproved();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(String id) async {
    await _service.updateStatus(id, PropertyStatus.approved);
    _load();
  }

  Future<void> _reject(String id) async {
    await _service.updateStatus(id, PropertyStatus.rejected);
    _load();
  }

  Future<void> _toggleFeatured(Property p) async {
    await _service.setFeatured(p.id, !p.featured);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin panel'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.terracotta,
          indicatorColor: AppColors.terracotta,
          tabs: [
            Tab(text: 'Pending (${_pending.length})'),
            const Tab(text: 'Live listings'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _pendingList(),
                _liveList(),
              ],
            ),
    );
  }

  Widget _pendingList() {
    if (_pending.isEmpty) {
      return const EmptyState(
        icon: Icons.verified_outlined,
        title: 'All caught up',
        message: 'There are no listings waiting for approval.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final p = _pending[i];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.coverUrl.isNotEmpty)
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CachedNetworkImage(
                      imageUrl: p.coverUrl, fit: BoxFit.cover),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${p.city}, ${p.state} · by ${p.ownerName ?? "—"}',
                        style: const TextStyle(color: AppColors.inkSoft)),
                    const SizedBox(height: 8),
                    Text(p.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.inkSoft)),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approve(p.id),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emerald),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reject(p.id),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _liveList() {
    if (_all.isEmpty) {
      return const EmptyState(
        icon: Icons.home_work_outlined,
        title: 'No live listings',
        message: 'Approved listings will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _all.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = _all[i];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          tileColor: AppColors.surface,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: p.coverUrl.isEmpty
                ? Container(
                    width: 52, height: 52, color: AppColors.surfaceAlt)
                : CachedNetworkImage(
                    imageUrl: p.coverUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover),
          ),
          title: Text(p.title,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${p.city}, ${p.state}'),
          trailing: IconButton(
            tooltip: p.featured ? 'Unfeature' : 'Feature',
            icon: Icon(
              p.featured ? Icons.star_rounded : Icons.star_border_rounded,
              color: p.featured ? AppColors.ochre : AppColors.inkFaint,
            ),
            onPressed: () => _toggleFeatured(p),
          ),
        );
      },
    );
  }
}
