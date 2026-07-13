import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({super.key});
  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  final _service = AnalyticsService();
  OwnerAnalytics? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().profile?.id;
    if (uid != null) _data = await _service.forOwner(uid);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('No data yet.'))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    GridView.count(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 700 ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.5,
                      children: [
                        _stat('Listings', '${_data!.totalListings}',
                            Icons.home_work_outlined, AppColors.terracotta),
                        _stat('Total views', '${_data!.totalViews}',
                            Icons.visibility_outlined, AppColors.emerald),
                        _stat('Viewings', '${_data!.totalBookings}',
                            Icons.calendar_today_outlined, AppColors.ochre),
                        _stat('Pending', '${_data!.pending}',
                            Icons.pending_outlined, AppColors.slate500),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text('Views by property',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (_data!.viewsByProperty.isEmpty)
                      const Text('No views recorded yet.',
                          style: TextStyle(color: AppColors.inkSoft))
                    else
                      SizedBox(height: 280, child: _barChart()),
                  ],
                ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.inkSoft, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barChart() {
    final entries = _data!.viewsByProperty.entries.toList();
    final maxVal = entries
        .map((e) => e.value)
        .fold<int>(1, (a, b) => a > b ? a : b)
        .toDouble();
    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) {
                  return const SizedBox();
                }
                final name = entries[i].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    name.length > 8 ? '${name.substring(0, 8)}…' : name,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                color: AppColors.terracotta,
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ]),
        ],
      ),
    );
  }
}
