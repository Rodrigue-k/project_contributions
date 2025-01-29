

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_contributions/Providers/github_provider.dart';

import '../presentations/ressourses/app_colors.dart';


class Result extends ConsumerStatefulWidget {
  const Result({super.key});

  @override
  ResultState createState() => ResultState();
}

class ResultState extends ConsumerState<Result> {
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
    List<Map<String, String>> avatarUrls = ref.watch(githubProvider).avatarUrls;
    final Map<String, double> contributions = ref.watch(githubProvider).contributions;

    print("Avatar URLs: $avatarUrls");
    print("Contributions: $contributions");

    if (contributions.isEmpty) {
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

    final double totalContributions = contributions.values.fold(0, (sum, value) => sum + value);
    final List<String> logins = contributions.keys.toList();

    return List.generate(contributions.length, (i) {
      final login = logins[i];
      final contributionValue = contributions[login] ?? 0.0;

      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final widgetSize = isTouched ? 55.0 : 40.0;

      final avatarEntry = avatarUrls.firstWhere(
            (avatar) => avatar['login'] == login,
        orElse: () => {'avatar_url': ''},
      );
      final avatarUrl = avatarEntry['avatar_url'] ?? '';

      print("Login: $login - Avatar URL: $avatarUrl");

      return PieChartSectionData(
        color: _getColorForIndex(i),
        value: (contributionValue / totalContributions) * 100,
        title: '${(contributionValue / totalContributions * 100).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _Badge(
          avatarUrl,
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
