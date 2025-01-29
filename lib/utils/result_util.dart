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
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final contributions = ref.watch(githubProvider).contributions;
    final avatarUrls = ref.watch(githubProvider).avatarUrls;

    final double totalContributions =
        contributions.values.fold(0, (sum, value) => sum + value);
    final List<String> logins = contributions.keys.toList();
    final List<String> names = contributions.keys.toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 25,
      children: [
        Expanded(
          flex: 1,
          child: AspectRatio(
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
          ),
        ),
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: contributions.length,
            itemBuilder: (context, i) {
              final login = logins[i];
              final name = names[i];
              final contributionValue = contributions[login] ?? 0.0;
              final percentage = (contributionValue / totalContributions) * 100;
              final avatarEntry = avatarUrls.firstWhere(
                (avatar) => avatar['login'] == login,
                orElse: () => {'avatar_url': ''},
              );
              final avatarUrl = avatarEntry['avatar_url'] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  children: [
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: _getColorForIndex(i),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 15,
                      backgroundImage:
                          avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      backgroundColor: Colors.grey[300],
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '@$login',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> showingSections() {
    final List<Map<String, String>> avatarUrls =
        ref.watch(githubProvider).avatarUrls;
    final Map<String, double> contributions =
        ref.watch(githubProvider).contributions;

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

    final double totalContributions =
        contributions.values.fold(0, (sum, value) => sum + value);
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

      return PieChartSectionData(
        color: _getColorForIndex(i),
        value: (contributionValue / totalContributions) * 100,
        title:
            '${(contributionValue / totalContributions * 100).toStringAsFixed(1)}%',
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
    const colors = [
      AppColors.contentColorBlue,
      AppColors.contentColorYellow,
      AppColors.contentColorPurple,
      AppColors.contentColorGreen,
      AppColors.contentColorPink,
      AppColors.contentColorOrange,
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
        child:
            Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
          return const Icon(Icons.error, color: Colors.red);
        }),
      ),
    );
  }
}
