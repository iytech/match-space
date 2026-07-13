import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  final _service = BookingService();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<ViewingBooking> _asOwner = [];
  List<ViewingBooking> _asRequester = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _asOwner = await _service.forOwner();
    _asRequester = await _service.forRequester();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setStatus(String id, BookingStatus s) async {
    await _service.setStatus(id, s);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viewings'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.terracotta,
          indicatorColor: AppColors.terracotta,
          tabs: const [
            Tab(text: 'Requests for me'),
            Tab(text: 'My requests'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _list(_asOwner, isOwner: true),
                _list(_asRequester, isOwner: false),
              ],
            ),
    );
  }

  Widget _list(List<ViewingBooking> items, {required bool isOwner}) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No viewings yet',
        message: isOwner
            ? 'When buyers request to view your properties, they appear here.'
            : 'Book a viewing on any property to see it here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = items[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(b.propertyTitle ?? 'Property',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                _statusBadge(b.status),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.schedule, size: 15, color: AppColors.inkSoft),
                const SizedBox(width: 4),
                Text(Formatters.dateTime(b.scheduledFor),
                    style: const TextStyle(color: AppColors.inkSoft)),
              ]),
              if (isOwner && b.requesterName != null) ...[
                const SizedBox(height: 4),
                Text('Requested by ${b.requesterName}',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 13)),
              ],
              if (b.note != null && b.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(b.note!,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              if (isOwner && b.status == BookingStatus.requested) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _setStatus(b.id, BookingStatus.confirmed),
                      child: const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _setStatus(b.id, BookingStatus.declined),
                      child: const Text('Decline'),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(BookingStatus s) {
    late Color c;
    switch (s) {
      case BookingStatus.confirmed:
        c = AppColors.emerald;
        break;
      case BookingStatus.declined:
        c = AppColors.ruby;
        break;
      case BookingStatus.completed:
        c = AppColors.slate500;
        break;
      default:
        c = AppColors.amber;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(s.name,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
