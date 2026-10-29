import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/exam_attempt.dart';
import 'exam_providers.dart';

/// Screen displaying preliminary audit statistics, examination history,
/// and performance trend visualization.
class ExamHistoryScreen extends ConsumerWidget {
  const ExamHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(examHistoryProvider);
    final totalCountAsync = ref.watch(totalExamsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your preliminary exams', style: AppTextStyles.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingBase),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppConstants.spacingBase),
                  Text('Failed to load exam history: $err'),
                  const SizedBox(height: AppConstants.spacingBase),
                  AppButton(
                    label: 'Retry',
                    isFullWidth: false,
                    onPressed: () {
                      ref.invalidate(examHistoryProvider);
                      ref.invalidate(totalExamsCountProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
          data: (attempts) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Development/Mock badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingSm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSm,
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'AUDIT STATISTICS · HISTORICAL ATTEMPTS (MOCK)',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingBase),

                  // Top Action Card: Start new preliminary check & total count
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preliminary Audits',
                                    style: AppTextStyles.h2,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total examinations taken: ${totalCountAsync.asData?.value ?? attempts.length}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingBase),
                        AppButton(
                          label: 'Start new preliminary check',
                          icon: const Icon(Icons.add_rounded, size: 20),
                          onPressed: () => context.go('/preliminary-check'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingLg),

                  // Performance Trend Chart Section (if attempts exist)
                  if (attempts.isNotEmpty) ...[
                    Text('Performance Trend', style: AppTextStyles.h3),
                    const SizedBox(height: AppConstants.spacingSm),
                    _buildPerformanceChartCard(attempts),
                    const SizedBox(height: AppConstants.spacingLg),
                  ],

                  // History List Header
                  Text('Examination History', style: AppTextStyles.h3),
                  const SizedBox(height: AppConstants.spacingSm),

                  // Attempts list or Empty State
                  if (attempts.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...attempts.map((attempt) => _buildAttemptCard(attempt)),

                  const SizedBox(height: AppConstants.spacingXl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPerformanceChartCard(List<ExamAttempt> attempts) {
    // Reverse chronologically for the chart so oldest is at x=0, newest at x=N-1
    final chronologicalAttempts = attempts.reversed.toList();
    final spots = <FlSpot>[];

    for (int i = 0; i < chronologicalAttempts.length; i++) {
      spots.add(FlSpot(i.toDouble(), chronologicalAttempts[i].scorePercentage));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score Progression (%)',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Target: 80% (Demo)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingBase),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                minX: 0,
                maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1.0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
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
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < chronologicalAttempts.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '#${index + 1}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptCard(ExamAttempt attempt) {
    final dateFormat = DateFormat('dd.MM.yyyy, HH:mm');
    final formattedDate = dateFormat.format(attempt.dateTime);
    final isPassed = attempt.isPassed;
    final statusColor = isPassed ? AppColors.success : AppColors.error;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Classes & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Class badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Class ${attempt.selectedClasses.join(", ")}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Date
              Text(
                formattedDate,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),

          // Result & Score row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attempt.formattedScore,
                    style: AppTextStyles.h2.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${attempt.pointsScored} points of ${attempt.totalQuestions}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  attempt.statusLabel ??
                      (isPassed ? 'Bestanden' : 'Nicht bestanden'),
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return AppCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppConstants.spacingBase),
              Text('No preliminary exams taken yet', style: AppTextStyles.h3),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                'Complete a preliminary check to record your progress and track performance trends.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingBase),
              AppButton(
                label: 'Take First Preliminary Check',
                isFullWidth: false,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                onPressed: () => context.go('/preliminary-check'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
