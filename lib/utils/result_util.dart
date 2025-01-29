

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_contributions/Providers/github_provider.dart';

import '../presentations/ressourses/app_colors.dart';


class PieChartSample3 extends ConsumerStatefulWidget {
  const PieChartSample3({super.key});

  @override
  PieChartSample3State createState() => PieChartSample3State();
}

class PieChartSample3State extends ConsumerState<PieChartSample3> {
  List<Map<String, String>> get avatarUrls =>
      ref.watch(githubProvider).avatarUrls;

  int touchedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 0,
          centerSpaceRadius: 0,
          sections: showingSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    if (avatarUrls.isEmpty) {
      return [
        PieChartSectionData(
          color: AppColors.contentColorBlue,
          value: 1,
          title: 'No data',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    final totalContributions = avatarUrls.length;

    return List.generate(avatarUrls.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final widgetSize = isTouched ? 55.0 : 40.0;

      final author = avatarUrls[i];
      final value = 100 / totalContributions;

      return PieChartSectionData(
        color: _getColorForIndex(i),
        value: value,
        title: '${value.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _Badge(
          author['avatar_url'] ?? '',
          size: widgetSize,
          borderColor: AppColors.contentColorBlack,
        ),
        badgePositionPercentageOffset: .98,
      );
    });
  }

  Color _getColorForIndex(int index) {
    // Retourne une couleur différente pour chaque section
    const colors = [
      AppColors.contentColorBlue,
      AppColors.contentColorYellow,
      AppColors.contentColorPurple,
      AppColors.contentColorGreen,
    ];
    return colors[index % colors.length];
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      this.url, {
        required this.size,
        required this.borderColor,
      });

  final String url;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
          return const Icon(Icons.error, color: Colors.red);
        }),
      ),
    );
  }
}
