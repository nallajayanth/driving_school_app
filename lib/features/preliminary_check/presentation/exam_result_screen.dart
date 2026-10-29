import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../exam_history/domain/exam_attempt.dart';

/// Screen displaying the results of a completed mock examination session.
class ExamResultScreen extends ConsumerWidget {
  const ExamResultScreen({super.key, required this.attempt});

  final ExamAttempt attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPass = attempt.isPassed;
    final statusColor = isPass ? AppColors.success : AppColors.warning;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Safely navigate back to preliminary check or dashboard rather than the exam runner
        context.go('/preliminary-check');
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Exam Assessment Result', style: AppTextStyles.h3),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Close result',
              onPressed: () => context.go('/dashboard'),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppConstants.spacingSm),

                // Result Badge / Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      isPass
                          ? Icons.emoji_events_rounded
                          : Icons.assignment_turned_in_rounded,
                      size: 44,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingBase),

                // Main headline
                Text(
                  'Preliminary Check Completed!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  'Here is your demonstration assessment summary.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingBase),

                // Clear Mock / Development disclaimer banner
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingBase),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          'DEMONSTRATION ASSESSMENT ONLY: Official passing criteria, bonus questions, and score formulas are unverified and subject to backend API discovery.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingBase),

                // Performance Score Card
                AppCard(
                  child: Column(
                    children: [
                      Text(
                        'DEMONSTRATION SCORE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      Text(
                        '${attempt.scorePercentage.toStringAsFixed(0)}%',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 48,
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusFull,
                          ),
                        ),
                        child: Text(
                          attempt.statusLabel ??
                              (isPass
                                  ? 'Bestanden (Demo)'
                                  : 'Nicht bestanden (Demo)'),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingBase),
                      const Divider(height: 1),
                      const SizedBox(height: AppConstants.spacingBase),

                      // Metrics row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricItem(
                            label: 'Correct',
                            value: '${attempt.pointsScored}',
                            color: AppColors.success,
                          ),
                          _buildMetricDivider(),
                          _buildMetricItem(
                            label: 'Total Questions',
                            value: '${attempt.totalQuestions}',
                            color: AppColors.textPrimary,
                          ),
                          _buildMetricDivider(),
                          _buildMetricItem(
                            label: 'Classes',
                            value: attempt.selectedClasses.join(', '),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.spacingLg),

                // Actions: Return to Dashboard, View History, Retake Exam
                AppButton(
                  label: 'Return to Dashboard',
                  variant: AppButtonVariant.primary,
                  icon: const Icon(Icons.dashboard_rounded, size: 20),
                  onPressed: () => context.go('/dashboard'),
                ),
                const SizedBox(height: AppConstants.spacingSm),

                AppButton(
                  label: 'View Exam History',
                  variant: AppButtonVariant.secondary,
                  icon: const Icon(Icons.history_rounded, size: 20),
                  onPressed: () => context.push('/exam-history'),
                ),
                const SizedBox(height: AppConstants.spacingSm),

                AppButton(
                  label: 'Start Another Preliminary Check',
                  variant: AppButtonVariant.outline,
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  onPressed: () => context.go('/preliminary-check'),
                ),

                const SizedBox(height: AppConstants.spacingXl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h2.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(width: 1, height: 32, color: AppColors.border);
  }
}
