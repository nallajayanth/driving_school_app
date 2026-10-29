import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/learning_progress.dart';

/// Card presenting learning metrics and exam readiness for an individual topic.
class TopicProgressCard extends StatelessWidget {
  const TopicProgressCard({super.key, required this.topic, this.onTap});

  final TopicProgress topic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progressFraction = (topic.progressPercentage / 100.0).clamp(0.0, 1.0);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic header with icon and percentage badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.topicName,
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: topic.progressPercentage > 0
                      ? AppColors.primarySubtle
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  border: Border.all(
                    color: topic.progressPercentage > 0
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  '${topic.progressPercentage.toStringAsFixed(1)}%',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: topic.progressPercentage > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
            child: LinearProgressIndicator(
              value: progressFraction,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),

          // Metrics summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Answered: ${topic.answeredQuestions} / ${topic.totalQuestions}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                'Exam ready: ${topic.examReadyQuestions}',
                style: AppTextStyles.caption.copyWith(
                  color: topic.examReadyQuestions > 0
                      ? AppColors.success
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
