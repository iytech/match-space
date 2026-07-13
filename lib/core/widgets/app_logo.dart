import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Wordmark: a clay keystone mark + "Match Space" set in Fraunces.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const AppLogo({super.key, this.size = 28, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.terracotta, AppColors.terracottaDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(Icons.location_on_rounded,
              color: Colors.white, size: size * 0.6),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Text('Match Space',
              style: GoogleFonts.fraunces(
                fontSize: size * 0.72,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                letterSpacing: -0.5,
              )),
        ],
      ],
    );
  }
}
