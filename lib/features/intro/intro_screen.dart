import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';

/// Full-screen animated introduction shown to logged-out visitors.
/// Pure-Flutter animations (no extra packages): an animated gradient field,
/// slow-drifting property "cards", and a staggered entrance for the headline,
/// subcopy and actions.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance; // one-shot staggered entrance
  late final AnimationController _ambient;  // looping background motion

  @override
  void initState() {
    super.initState();
    _entrance =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
          ..forward();
    _ambient = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  // Interval-based staggered fade+slide for a child.
  Widget _staggered(double start, double end, Widget child,
      {Offset from = const Offset(0, 0.18)}) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(from.dx * (1 - anim.value) * 100,
              from.dy * (1 - anim.value) * 100),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wide = size.width > 820;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated gradient field
          AnimatedBuilder(
            animation: _ambient,
            builder: (_, __) {
              final t = _ambient.value * 2 * math.pi;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(math.cos(t), math.sin(t)),
                    end: Alignment(-math.cos(t), -math.sin(t)),
                    colors: const [
                      AppColors.slate900,
                      Color(0xFF241A16),
                      AppColors.terracottaDark,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
                child: const SizedBox.expand(),
              );
            },
          ),

          // 2. Drifting translucent "property cards"
          ..._buildFloatingCards(size),

          // 3. Soft vignette for text legibility
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.1,
                colors: [Colors.transparent, Color(0x66000000)],
              ),
            ),
            child: SizedBox.expand(),
          ),

          // 4. Foreground content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: wide ? 72 : 28, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _staggered(0.0, 0.4,
                      const AppLogoLight(size: 34), from: const Offset(-0.3, 0)),
                  const Spacer(),
                  _staggered(
                    0.15,
                    0.6,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Text('Real estate, reimagined for Nigeria',
                          style: TextStyle(
                              color: Colors.white, fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _staggered(
                    0.25,
                    0.7,
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 720 : 560),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: wide ? 62 : 40,
                            height: 1.04,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.2,
                          ),
                          children: const [
                            TextSpan(text: 'Find the space\nthat '),
                            TextSpan(
                                text: 'matches',
                                style: TextStyle(color: AppColors.ochre)),
                            TextSpan(text: ' your\nnext chapter.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _staggered(
                    0.35,
                    0.8,
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Text(
                        'Browse verified homes and land for sale, rent, and '
                        'lease across Lagos, Abuja, Benin City, Plateau and '
                        'beyond. Message owners directly, book viewings, and '
                        'move with confidence.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: wide ? 17 : 15,
                            height: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  _staggered(
                    0.5,
                    0.95,
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _cta(
                          label: 'Explore listings',
                          filled: true,
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/home'),
                        ),
                        _cta(
                          label: 'Sign in',
                          filled: false,
                          onTap: () =>
                              Navigator.pushNamed(context, '/auth'),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _staggered(
                    0.7,
                    1.0,
                    Row(children: [
                      _stat('Verified', 'listings'),
                      const SizedBox(width: 32),
                      _stat('Direct', 'owner chat'),
                      const SizedBox(width: 32),
                      _stat('Free', 'to browse'),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingCards(Size size) {
    // A few translucent rounded rectangles that drift on a sine path.
    final specs = [
      [0.72, 0.20, 150.0, 200.0, 0.0],
      [0.82, 0.55, 110.0, 150.0, 1.4],
      [0.62, 0.72, 130.0, 175.0, 2.6],
      [0.90, 0.82, 90.0, 120.0, 3.5],
    ];
    return specs.map((s) {
      return AnimatedBuilder(
        animation: _ambient,
        builder: (_, __) {
          final phase = _ambient.value * 2 * math.pi + (s[4] as double);
          final dx = math.sin(phase) * 14;
          final dy = math.cos(phase) * 18;
          return Positioned(
            left: (s[0] as double) * size.width + dx,
            top: (s[1] as double) * size.height + dy,
            child: Opacity(
              opacity: 0.10,
              child: Container(
                width: s[2] as double,
                height: s[3] as double,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _cta(
      {required String label,
      required bool filled,
      required VoidCallback onTap}) {
    return Material(
      color: filled ? AppColors.terracotta : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled
                ? null
                : Border.all(color: Colors.white.withOpacity(0.4), width: 1.4),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            if (filled) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _stat(String big, String small) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(big,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        Text(small,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6), fontSize: 13)),
      ],
    );
  }
}

/// Light version of the wordmark for dark backgrounds.
class AppLogoLight extends StatelessWidget {
  final double size;
  const AppLogoLight({super.key, this.size = 30});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.ochre, AppColors.terracotta],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Icon(Icons.location_on_rounded,
            color: Colors.white, size: size * 0.6),
      ),
      const SizedBox(width: 10),
      Text('Match Space',
          style: TextStyle(
              fontSize: size * 0.72,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5)),
    ]);
  }
}
