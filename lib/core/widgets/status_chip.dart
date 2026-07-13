import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final PropertyStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late String label;
    switch (status) {
      case PropertyStatus.approved:
        bg = AppColors.emerald.withOpacity(0.12);
        fg = AppColors.emerald;
        label = 'Live';
        break;
      case PropertyStatus.pending:
        bg = AppColors.amber.withOpacity(0.16);
        fg = const Color(0xFFB07A2E);
        label = 'Pending';
        break;
      case PropertyStatus.rejected:
        bg = AppColors.ruby.withOpacity(0.12);
        fg = AppColors.ruby;
        label = 'Rejected';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
