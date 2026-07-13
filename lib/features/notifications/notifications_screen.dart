import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.hasUnread)
            TextButton(
              onPressed: () => context.read<NotificationProvider>().markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              message:
                  'Messages, viewing requests and listing updates will appear here.',
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) => _NotificationTile(item: items[i]),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.read ? Colors.transparent : AppColors.terracottaSoft.withOpacity(0.25),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _color(item.kind).withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon(item.kind), color: _color(item.kind), size: 21),
        ),
        title: Text(item.title,
            style: TextStyle(
                fontWeight: item.read ? FontWeight.w600 : FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(Formatters.timeAgo(item.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.inkFaint)),
          ],
        ),
        trailing: item.read
            ? null
            : Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    color: AppColors.terracotta, shape: BoxShape.circle),
              ),
        onTap: () {
          context.read<NotificationProvider>().markRead(item.id);
          if (item.route != null) {
            Navigator.pushNamed(context, item.route!,
                arguments: item.routeArg);
          }
        },
      ),
    );
  }

  IconData _icon(NotificationKind k) {
    switch (k) {
      case NotificationKind.message:
        return Icons.chat_bubble_outline;
      case NotificationKind.booking:
      case NotificationKind.bookingUpdate:
        return Icons.calendar_today_outlined;
      case NotificationKind.listingApproved:
        return Icons.check_circle_outline;
      case NotificationKind.listingRejected:
        return Icons.cancel_outlined;
      case NotificationKind.review:
        return Icons.star_outline;
      case NotificationKind.system:
        return Icons.info_outline;
    }
  }

  Color _color(NotificationKind k) {
    switch (k) {
      case NotificationKind.message:
        return AppColors.terracotta;
      case NotificationKind.booking:
      case NotificationKind.bookingUpdate:
        return AppColors.ochre;
      case NotificationKind.listingApproved:
        return AppColors.emerald;
      case NotificationKind.listingRejected:
        return AppColors.ruby;
      case NotificationKind.review:
        return AppColors.ochre;
      case NotificationKind.system:
        return AppColors.slate500;
    }
  }
}
