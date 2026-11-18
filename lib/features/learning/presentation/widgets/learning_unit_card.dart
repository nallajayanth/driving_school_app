import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/learning_unit.dart';

/// Topic / Learning Unit Card matching the reference Powerdrive Learning design.
/// Features a sleek left blue accent stripe, exam readiness bar, Leitner status counters, and phase label.
class LearningUnitCard extends StatelessWidget {
  const LearningUnitCard({super.key, required this.unit, this.onTap});

  final LearningUnit unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progressFraction = unit.totalQuestions > 0
        ? (unit.examReadyCount / unit.totalQuestions).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header with book icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.folder_outlined,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Text(
                unit.categoryName,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),

        // Unit Content Card with left accent line
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.03),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              child: Stack(
                children: [
                  // Blue vertical stripe on the left edge
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppConstants.radiusMd - 1),
                          bottomLeft: Radius.circular(
                            AppConstants.radiusMd - 1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main card content with left padding to give room to the accent stripe
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppConstants.spacingBase,
                      right: AppConstants.spacingSm + 4,
                      top: AppConstants.spacingBase,
                      bottom: AppConstants.spacingBase,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Exam-Ready Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                unit.title,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '${unit.examReadyCount} / ${unit.totalQuestions} Exam-ready',
                                style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Linear Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Bottom Row: Status counters and Phase label
                        _buildCountersAndPhaseRow(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountersAndPhaseRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 290;

        final counters = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusCounter('🔄', unit.box0Count),
            const SizedBox(width: 4),
            _buildStatusCounter('👍', unit.box1Count),
            const SizedBox(width: 4),
            _buildStatusCounter('💪', unit.box2Count),
            const SizedBox(width: 4),
            _buildStatusCounter('✅', unit.box3Count),
          ],
        );

        final phase = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${unit.readinessPercentage.toInt()}% · ${unit.phaseLabel} ',
                style: AppTextStyles.label.copyWith(
                  color: unit.readinessPercentage > 0
                      ? AppColors.primary
                      : AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(unit.phaseIcon, style: const TextStyle(fontSize: 11)),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [counters, const SizedBox(height: 6), phase],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            counters,
            const SizedBox(width: 4),
            Flexible(child: phase),
          ],
        );
      },
    );
  }

  Widget _buildStatusCounter(String emoji, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10.5)),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
