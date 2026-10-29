import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/learning_progress.dart';
import 'progress_providers.dart';
import 'widgets/subject_distribution_chart.dart';
import 'widgets/topic_progress_card.dart';

/// Progress Dashboard and Learning Analytics Screen.
/// Displays overall questions answered, learning-level milestone,
/// Leitner box distribution chart (Fach 0–3), and topic progress.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(learningProgressProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(learningProgressProvider.notifier).refresh();
          },
          child: progressAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingBase),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppConstants.spacingBase),
                    Text(
                      'Failed to load learning analytics',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppConstants.spacingBase),
                    AppButton(
                      label: 'Retry',
                      isFullWidth: false,
                      onPressed: () {
                        ref.read(learningProgressProvider.notifier).refresh();
                      },
                    ),
                  ],
                ),
              ),
            ),
            data: (progress) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            Icons.analytics_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'DEVELOPMENT PREVIEW · PROGRESS ANALYTICS',
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

                    // Title & Description
                    Text('Learning progress', style: AppTextStyles.h1),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      'Track your overall learning statistics, Leitner box distribution, and individual topic progress.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),

                    // Overall Learning Statistics Section
                    _buildOverallStatistics(context, progress),
                    const SizedBox(height: AppConstants.spacingLg),

                    // Subject Distribution Chart (Fach 0 - 3)
                    SubjectDistributionChart(progress: progress),
                    const SizedBox(height: AppConstants.spacingLg),

                    // Topic Progress Section
                    Text('Progress per topic', style: AppTextStyles.h3),
                    const SizedBox(height: AppConstants.spacingSm),

                    if (progress.topicsProgress.isEmpty)
                      _buildEmptyTopicsCard()
                    else
                      ...progress.topicsProgress.map(
                        (topic) => TopicProgressCard(
                          topic: topic,
                          onTap: () => context.go('/learning'),
                        ),
                      ),

                    const SizedBox(height: AppConstants.spacingXl),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverallStatistics(
    BuildContext context,
    LearningProgress progress,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Overall Learning Statistics',
                  style: AppTextStyles.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingBase),

          // Two metric blocks (adaptive layout)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 280;

              final questionsCard = _buildQuestionsStudiedCard(progress);
              final levelCard = _buildLevelCard(progress);

              if (isNarrow) {
                return Column(
                  children: [
                    questionsCard,
                    const SizedBox(height: AppConstants.spacingSm),
                    levelCard,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: questionsCard),
                  const SizedBox(width: AppConstants.spacingBase),
                  Expanded(child: levelCard),
                ],
              );
            },
          ),

          // If learner has 0 questions answered, show helpful starter tip
          if (progress.totalQuestionsAnswered == 0) ...[
            const SizedBox(height: AppConstants.spacingBase),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingSm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ready to begin? Practice questions in the Learning tab to build up your knowledge rank.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionsStudiedCard(LearningProgress progress) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📝', style: TextStyle(fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  'STUDIED',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            '${progress.totalQuestionsAnswered}',
            style: AppTextStyles.h1.copyWith(
              fontSize: 26,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Questions answered',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(LearningProgress progress) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.box1Background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.box1.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.currentLearningLevelIcon,
                style: const TextStyle(fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  'LEVEL',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.box1,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            progress.currentLearningLevel,
            style: AppTextStyles.h1.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Milestone rank',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTopicsCard() {
    return AppCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.spacingBase,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 36,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'No topic analytics available',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
