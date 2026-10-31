import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../authentication/data/firebase_auth_repository.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/learning_progress.dart';
import '../domain/student_learning_summary.dart';
import '../domain/student_question_progress.dart';
import 'progress_providers.dart';
import 'widgets/subject_distribution_chart.dart';
import 'widgets/topic_progress_card.dart';

/// Progress Dashboard and Learning Analytics Screen.
///
/// Features (Phase 12):
/// - Live Firebase mode: Displays real Firestore question activity, viewed counts,
///   in-progress counts, reviewed counts (GW and B), bookmarks count, and recently viewed questions.
/// - Strictly avoids fabricating scores, accuracy %, pass rates, or rankings without backend grading.
/// - Offline demo mode: Clearly preserves Leitner box distribution (Fach 0–3) for demo purposes.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    final authRepo = ref.watch(authRepositoryProvider);
    final isLiveFirebase = authRepo is FirebaseAuthRepository && !isDemoMode;

    if (!isLiveFirebase) {
      return _buildDemoModeScaffold(context, ref);
    }

    return _buildLiveFirebaseScaffold(context, ref);
  }

  // ===========================================================================
  // LIVE FIREBASE LEARNING PROGRESS VIEW
  // ===========================================================================

  Widget _buildLiveFirebaseScaffold(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(studentLearningSummaryProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentLearningSummaryProvider);
            ref.invalidate(studentProgressMapProvider);
            ref.invalidate(bookmarksListProvider);
          },
          child: summaryAsync.when(
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
                      'Failed to load learning progress',
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
                        ref.invalidate(studentLearningSummaryProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),
            data: (summary) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.spacingBase),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Cloud Firestore Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingSm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.box3Background,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_done_rounded,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'LIVE AUSTRIAN LEARNING ACTIVITY · CLOUD FIRESTORE',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                      'Track your question study progress, reviewed questions, and saved bookmarks.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),

                    // 4 Key Activity Counters Grid
                    _buildActivityMetricsGrid(summary),
                    const SizedBox(height: AppConstants.spacingLg),

                    // Module Breakdown Card (GW vs Category B Reviewed & Bookmarks)
                    _buildModuleBreakdownCard(context, summary),
                    const SizedBox(height: AppConstants.spacingLg),

                    // Recently Viewed Questions
                    Text('Recently viewed questions', style: AppTextStyles.h3),
                    const SizedBox(height: AppConstants.spacingSm),
                    if (summary.recentlyViewedQuestions.isEmpty)
                      _buildEmptyRecentQuestionsCard()
                    else
                      ...summary.recentlyViewedQuestions.map(
                        (q) => _buildRecentQuestionCard(context, q),
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

  Widget _buildActivityMetricsGrid(StudentLearningSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'AVAILABLE',
                value: '${summary.totalAvailableQuestions}',
                subtitle: 'Total Questions',
                emoji: '📚',
                bgColor: AppColors.primarySubtle,
                accentColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppConstants.spacingBase),
            Expanded(
              child: _buildMetricTile(
                title: 'VIEWED',
                value: '${summary.viewedCount}',
                subtitle: 'Questions Opened',
                emoji: '👀',
                bgColor: const Color(0xFFEFF6FF),
                accentColor: const Color(0xFF1D4ED8),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingBase),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'IN PROGRESS',
                value: '${summary.inProgressCount}',
                subtitle: 'Options Selected',
                emoji: '⏳',
                bgColor: const Color(0xFFFEF3C7),
                accentColor: const Color(0xFFB45309),
              ),
            ),
            const SizedBox(width: AppConstants.spacingBase),
            Expanded(
              child: _buildMetricTile(
                title: 'REVIEWED',
                value: '${summary.reviewedCount}',
                subtitle: 'Marked Reviewed',
                emoji: '✅',
                bgColor: AppColors.box3Background,
                accentColor: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required String emoji,
    required Color bgColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            value,
            style: AppTextStyles.h1.copyWith(
              fontSize: 26,
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleBreakdownCard(
    BuildContext context,
    StudentLearningSummary summary,
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
                  'Review Progress by Category',
                  style: AppTextStyles.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingBase),

          // GW Questions Reviewed
          _buildCategoryProgressRow(
            categoryCode: 'GW',
            categoryName: 'General Knowledge',
            reviewedCount: summary.gwReviewedCount,
            totalCount: 42,
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Category B Questions Reviewed
          _buildCategoryProgressRow(
            categoryCode: 'B',
            categoryName: 'Passenger Car',
            reviewedCount: summary.bReviewedCount,
            totalCount: 32,
          ),
          const SizedBox(height: AppConstants.spacingBase),
          const Divider(),
          const SizedBox(height: AppConstants.spacingSm),

          // Bookmarks total row
          Row(
            children: [
              const Icon(
                Icons.bookmark_rounded,
                size: 20,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bookmarked Questions',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                ),
                child: Text(
                  '${summary.totalBookmarks} saved',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFB45309),
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

  Widget _buildCategoryProgressRow({
    required String categoryCode,
    required String categoryName,
    required int reviewedCount,
    required int totalCount,
  }) {
    final fraction = totalCount > 0
        ? (reviewedCount / totalCount).clamp(0.0, 1.0)
        : 0.0;
    final percent = (fraction * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: Text(
                categoryCode,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                categoryName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$reviewedCount / $totalCount ($percent%)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              fraction > 0 ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentQuestionCard(
    BuildContext context,
    StudentQuestionProgress progress,
  ) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      onTap: () {
        if (progress.questionNumber != null) {
          context.push(
            '/learning/question/${progress.questionNumber}?id=${progress.questionId}',
            extra: progress.questionId,
          );
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
            child: Text(
              '#${progress.questionNumber ?? progress.questionId}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              progress.moduleCode,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              progress.topic != null && progress.topic!.isNotEmpty
                  ? progress.topic!.replaceAll('_', ' ')
                  : progress.questionId,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(progress.studyStatus),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(StudyStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case StudyStatus.reviewed:
        bg = AppColors.box3Background;
        fg = AppColors.success;
        label = 'Reviewed';
        break;
      case StudyStatus.inProgress:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'In Progress';
        break;
      case StudyStatus.viewed:
        bg = AppColors.primarySubtle;
        fg = AppColors.primary;
        label = 'Viewed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildEmptyRecentQuestionsCard() {
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
                'No recently viewed questions',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Questions you open in the Learning tab will appear here.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // OFFLINE DEMO MODE VIEW (PRESERVES EXISTING MOCK LEITNER SYSTEM)
  // ===========================================================================

  Widget _buildDemoModeScaffold(BuildContext context, WidgetRef ref) {
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
                              'DEVELOPMENT PREVIEW · DEMO MODE',
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
