import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/currency_provider.dart';

class MortgageCalculator extends StatefulWidget {
  final num price;
  const MortgageCalculator({super.key, required this.price});
  @override
  State<MortgageCalculator> createState() => _MortgageCalculatorState();
}

class _MortgageCalculatorState extends State<MortgageCalculator> {
  double _downPct = 20;
  double _rate = AppConfig.defaultMortgageRate;
  double _years = 20;

  double get _principal =>
      widget.price.toDouble() * (1 - _downPct / 100);

  double get _monthly {
    final r = _rate / 100 / 12;
    final n = _years * 12;
    if (r == 0) return _principal / n;
    return _principal * r * math.pow(1 + r, n) / (math.pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calculate_outlined, color: AppColors.terracotta),
            const SizedBox(width: 8),
            Text('Mortgage estimator',
                style: Theme.of(context).textTheme.titleLarge),
          ]),
          const SizedBox(height: 16),
          _slider('Down payment', '${_downPct.round()}%', _downPct, 0, 80,
              (v) => setState(() => _downPct = v)),
          _slider('Interest rate', '${_rate.toStringAsFixed(1)}%', _rate, 5, 35,
              (v) => setState(() => _rate = v)),
          _slider('Term', '${_years.round()} yrs', _years, 5, 30,
              (v) => setState(() => _years = v)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              const Text('Estimated monthly payment',
                  style: TextStyle(color: AppColors.inkSoft)),
              const SizedBox(height: 4),
              Text(currency.fullPrice(_monthly),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracotta)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, String value, double v, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracotta)),
        ]),
        Slider(
          value: v,
          min: min,
          max: max,
          activeColor: AppColors.terracotta,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
