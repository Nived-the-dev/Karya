import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'neo.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with AutomaticKeepAliveClientMixin<ProgressScreen> {
  @override
  bool get wantKeepAlive => true;
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selected = dayOnly(DateTime.now());
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final a = ref.watch(appProvider);
    return a.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) {
        final now = DateTime.now();
        final last7 = List.generate(
          7,
          (i) => DateTime(now.year, now.month, now.day - 6 + i),
        );
        final weekly = last7.map((d) => statsFor(data.habits, d)).toList();
        final tasksDone = last7
            .map(
              (d) => data.tasks
                  .where(
                    (t) =>
                        t.completedAt != null &&
                        t.completedAt!.substring(0, 10) == dayKey(d),
                  )
                  .length,
            )
            .toList();
        final done = weekly.fold(0, (v, s) => v + s.completed);
        final opportunities = weekly.fold(0, (v, s) => v + s.scheduled);
        final length = DateTime(month.year, month.month + 1, 0).day;
        final offset = DateTime(month.year, month.month).weekday - 1;
        final dates = List.generate(
          offset + length,
          (i) => i < offset
              ? null
              : DateTime(month.year, month.month, i - offset + 1),
        );
        final selectedHabits = data.habits
            .where((h) => h.scheduledOn(selected))
            .toList();
        return ScreenBody(
          children: [
            Headline('YOUR PROGRESS', 'Real check-ins. Real momentum.'),
            Row(
              children: [
                Expanded(
                  child: NeoCard(
                    color: themeColor(context, 1),
                    child: Column(
                      children: [
                        const Text(
                          'THIS WEEK',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '$done',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                            color: Colors.black,
                          ),
                        ),
                        const Text(
                          'habit check-ins',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeoCard(
                    color: themeColor(context, 2),
                    child: Column(
                      children: [
                        const Text(
                          'COMPLETION',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          opportunities == 0
                              ? '—'
                              : '${(done / opportunities * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '$opportunities scheduled',
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAST 7 DAYS',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 175,
                    child: BarChart(
                      BarChartData(
                        minY: 0,
                        maxY:
                            (weekly
                                        .map((s) => s.scheduled)
                                        .fold(1, (p, n) => n > p ? n : p) +
                                    1)
                                .toDouble(),
                        barTouchData: BarTouchData(enabled: true),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                return i < 0 || i > 6
                                    ? const SizedBox.shrink()
                                    : Text(
                                        DateFormat('E').format(last7[i]),
                                        style: const TextStyle(fontSize: 10),
                                      );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < 7; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: weekly[i].completed.toDouble(),
                                  color: themeColor(context, i),
                                  width: 20,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bars show completed habits per day. Days without scheduled habits have no completion rate.',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TASKS COMPLETED · LAST 7 DAYS',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: (tasksDone.reduce((a, b) => a > b ? a : b) + 1)
                            .toDouble(),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, meta) {
                                final i = v.toInt();
                                return i < 0 || i >= 7
                                    ? const SizedBox.shrink()
                                    : Text(
                                        DateFormat('E').format(last7[i]),
                                        style: const TextStyle(fontSize: 10),
                                      );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < 7; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: tasksDone[i].toDouble(),
                                  color: themeColor(context, 3),
                                  width: 20,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Text(
                    'Counts reflect actual completion timestamps.',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            NeoCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'MONTHLY HEATMAP',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () => month = DateTime(month.year, month.month - 1),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(DateFormat('MMM yyyy').format(month)),
                      IconButton(
                        onPressed:
                            month.year == now.year && month.month == now.month
                            ? null
                            : () => setState(
                                () => month = DateTime(
                                  month.year,
                                  month.month + 1,
                                ),
                              ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      for (final s in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                        Expanded(
                          child: Center(
                            child: Text(
                              s,
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: dates.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                        ),
                    itemBuilder: (ctx, i) {
                      final d = dates[i];
                      if (d == null) return const SizedBox.shrink();
                      final stat = statsFor(data.habits, d);
                      final rate = stat.rate;
                      final future = d.isAfter(dayOnly(now));
                      final bg = future || rate == null
                          ? Colors.grey.shade300
                          : rate == 0
                          ? const Color(0xFFFFE9DD)
                          : rate < .5
                          ? const Color(0xFFFFD51D)
                          : rate < 1
                          ? const Color(0xFFA6E529)
                          : const Color(0xFF59C9A8);
                      final active = dayKey(d) == dayKey(selected);
                      return InkWell(
                        onTap: d.isAfter(dayOnly(now))
                            ? null
                            : () => setState(() => selected = d),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: bg,
                            border: Border.all(
                              color: active ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${d.day}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: [
                      const Text('No schedule', style: TextStyle(fontSize: 11)),
                      for (final label in ['0%', '1–49%', '50–99%', '100%'])
                        Text('• $label', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            NeoCard(
              color: themeColor(context, 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('d MMM yyyy').format(selected),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    selectedHabits.isEmpty
                        ? 'No habits scheduled'
                        : '${selectedHabits.where((h) => h.doneOn(selected)).length}/${selectedHabits.length} completed',
                    style: const TextStyle(color: Colors.black),
                  ),
                  for (final h in selectedHabits)
                    Text(
                      '${h.doneOn(selected) ? '✓' : '○'} ${h.name}',
                      style: const TextStyle(color: Colors.black),
                    ),
                ],
              ),
            ),
            Text(
              'INDIVIDUAL HABITS',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            if (data.habits.isEmpty)
              const EmptyState(
                'No graph data yet.',
                'Create a habit and check it off.',
              ),
            ...data.habits.map((h) {
              final scheduled = last7.where(h.scheduledOn).length;
              final count = last7
                  .where((d) => h.scheduledOn(d) && h.doneOn(d))
                  .length;
              return NeoCard(
                child: Row(
                  children: [
                    Icon(iconFor(h.icon)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        h.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      scheduled == 0
                          ? 'Not scheduled'
                          : '$count/$scheduled this week',
                    ),
                  ],
                ),
              );
            }),
            NeoCard(
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${data.completed} tasks finished overall • ${data.pending} remaining',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
