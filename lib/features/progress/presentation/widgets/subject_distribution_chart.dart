import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/learning_progress.dart';

/// Interactive chart displaying the distribution of questions across subject levels (Fach 0 to Fach 3).
class SubjectDistributionChart extends StatelessWidget {
  const SubjectDistributionChart({super.key, required this.progress});

  final LearningProgress progress;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribution by subject level',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Leitner distribution across study boxes (Fach 0 – 3)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingBase),

          // Bar Chart
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final titles = ['Fach 0', 'Fach 1', 'Fach 2', 'Fach 3'];
                      final title = groupIndex < titles.length
                          ? titles[groupIndex]
                          : '';
                      return BarTooltipItem(
                        '$title\n${rod.toY.toStringAsFixed(0)}%',
                        AppTextStyles.caption.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Fach 0', 'Fach 1', 'Fach 2', 'Fach 3'];
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[index],
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBarGroup(0, progress.fach0Value, AppColors.box0),
                  _buildBarGroup(1, progress.fach1Value, AppColors.box1),
                  _buildBarGroup(2, progress.fach2Value, AppColors.box2),
                  _buildBarGroup(3, progress.fach3Value, AppColors.box3),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingBase),

          // Detail Legend Grid
          _buildLegendRow(context),
          const SizedBox(height: AppConstants.spacingSm),
          const Divider(height: 1),
          const SizedBox(height: AppConstants.spacingSm),

          // Development notice footnote
          Text(
            'Note: Distribution percentages reflect current mock telemetry. Official Leitner transition formulas require backend API confirmation.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildLegendRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 280;

        final item0 = _buildLegendItem(
          label: 'Fach 0',
          subLabel: 'New / not correct',
          value: '${progress.fach0Value.toStringAsFixed(0)}%',
          count: '${progress.box0QuestionsCount} questions',
          color: AppColors.box0,
        );

        final item1 = _buildLegendItem(
          label: 'Fach 1',
          subLabel: '1x correct',
          value: '${progress.fach1Value.toStringAsFixed(0)}%',
          count: '${progress.subject1QuestionsCount} questions',
          color: AppColors.box1,
        );

        final item2 = _buildLegendItem(
          label: 'Fach 2',
          subLabel: '2x in a row',
          value: '${progress.fach2Value.toStringAsFixed(0)}%',
          count: '${progress.subject2QuestionsCount} questions',
          color: AppColors.box2,
        );

        final item3 = _buildLegendItem(
          label: 'Fach 3',
          subLabel: 'Ready for exam',
          value: '${progress.fach3Value.toStringAsFixed(0)}%',
          count: '${progress.subject3QuestionsCount} questions',
          color: AppColors.box3,
        );

        if (isNarrow) {
          return Column(
            children: [
              item0,
              const SizedBox(height: AppConstants.spacingSm),
              item1,
              const SizedBox(height: AppConstants.spacingSm),
              item2,
              const SizedBox(height: AppConstants.spacingSm),
              item3,
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: item0),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(child: item1),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Row(
              children: [
                Expanded(child: item2),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(child: item3),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem({
    required String label,
    required String subLabel,
    required String value,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      value,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
