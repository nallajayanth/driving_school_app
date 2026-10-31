import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../progress/domain/learning_progress.dart';
import '../../progress/presentation/progress_providers.dart';
import 'widgets/dashboard_action_button.dart';
import 'widgets/status_card.dart';
import 'widgets/tip_banner.dart';

/// Polished mobile Dashboard Screen following the Powerdrive Learning reference design.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final progressAsync = ref.watch(learningProgressProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          await ref.read(learningProgressProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingBase,
            vertical: AppConstants.spacingBase,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dev / Mock Data Notice Badge
              _buildMockDataBanner(),
              const SizedBox(height: AppConstants.spacingMd),

              // Welcome Card with Quick Actions
              _buildWelcomeCard(context, ref, userAsync),
              const SizedBox(height: AppConstants.spacingBase),

              // Learning Progress Section
              _buildProgressSection(context, ref, progressAsync),
              const SizedBox(height: AppConstants.spacingBase),

              // Learning Tip Banner
              const TipBanner(
                tipText:
                    'Tip: You can switch to the pre-test at any time to test your progress!',
              ),
              const SizedBox(height: AppConstants.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  /// Explicit development indicator clarifying that data is mock-driven.
  Widget _buildMockDataBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Development Mode · Local Mock Data',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Welcome card hosting personalized greeting and the 3 blue shortcut buttons.
  Widget _buildWelcomeCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue userAsync,
  ) {
    final userName = userAsync.when(
      data: (user) => user?.name ?? 'Student',
      loading: () => 'Student',
      error: (e, s) => 'Student',
    );
    final resumeState = ref.watch(resumeLearningStateProvider).value;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👋', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Welcome, $userName !',
                  style: AppTextStyles.h1.copyWith(letterSpacing: -0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            "It's great to have you here! Choose how you would like to continue:",
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Resume Learning Action (if available)
          if (resumeState != null &&
              resumeState.lastQuestionNumber != null) ...[
            InkWell(
              onTap: () {
                context.push(
                  '/learning/question/${resumeState.lastQuestionNumber}?id=${resumeState.lastQuestionId}',
                  extra: resumeState.lastQuestionId,
                );
              },
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue Learning',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Resume Question #${resumeState.lastQuestionNumber} (${resumeState.lastModuleCode})',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
          ],

          // Shortcut 1: Practice exam questions
          DashboardActionButton(
            emoji: '🧠',
            label: 'Practice exam questions',
            onTap: () {
              context.go('/learning');
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Shortcut 2: Start preliminary check
          DashboardActionButton(
            emoji: '📝',
            label: 'Start preliminary check',
            onTap: () {
              context.go('/preliminary-check');
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Shortcut 3: Preliminary audit statistics
          DashboardActionButton(
            emoji: '📊',
            label: 'Preliminary audit statistics',
            onTap: () {
              context.push('/exam-history');
            },
          ),
        ],
      ),
    );
  }

  /// Progress section with 4 distinct Leitner cards (Box 0 and Subject 1..3).
  Widget _buildProgressSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<LearningProgress> progressAsync,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Your learning progress',
                  style: AppTextStyles.h2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingBase),

          // Reactive progress content
          progressAsync.when(
            data: (progress) => _buildStatusCardsLayout(context, progress),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            ),
            error: (err, stack) => _buildErrorCard(ref, err.toString()),
          ),
        ],
      ),
    );
  }

  /// Renders the 4 status cards adaptively.
  Widget _buildStatusCardsLayout(
    BuildContext context,
    LearningProgress progress,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVeryNarrow = constraints.maxWidth < 240;

        if (isVeryNarrow) {
          return Column(
            children: [
              StatusCard(
                title: 'Box 0',
                questionCount: progress.box0QuestionsCount,
                statusLabel: 'New or not correct 🔄',
                indicatorColor: AppColors.success,
                isActive: true,
                onTap: () => context.go('/learning'),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              StatusCard(
                title: 'Subject 1',
                questionCount: progress.subject1QuestionsCount,
                statusLabel: '1x correct 👍',
                indicatorColor: AppColors.box1,
                isActive: progress.subject1QuestionsCount > 0,
                onTap: () => context.go('/learning'),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              StatusCard(
                title: 'Subject 2',
                questionCount: progress.subject2QuestionsCount,
                statusLabel: 'Correct twice in a row 💪',
                indicatorColor: AppColors.box2,
                isActive: progress.subject2QuestionsCount > 0,
                onTap: () => context.go('/learning'),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              StatusCard(
                title: 'Subject 3',
                questionCount: progress.subject3QuestionsCount,
                statusLabel: 'Ready for the exam ✅',
                indicatorColor: AppColors.box3,
                isActive: progress.subject3QuestionsCount > 0,
                onTap: () => context.go('/learning'),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatusCard(
                    title: 'Box 0',
                    questionCount: progress.box0QuestionsCount,
                    statusLabel: 'New or not correct 🔄',
                    indicatorColor: AppColors.success,
                    isActive: true,
                    onTap: () => context.go('/learning'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: StatusCard(
                    title: 'Subject 1',
                    questionCount: progress.subject1QuestionsCount,
                    statusLabel: '1x correct 👍',
                    indicatorColor: AppColors.box1,
                    isActive: progress.subject1QuestionsCount > 0,
                    onTap: () => context.go('/learning'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Row(
              children: [
                Expanded(
                  child: StatusCard(
                    title: 'Subject 2',
                    questionCount: progress.subject2QuestionsCount,
                    statusLabel: 'Correct twice in a row 💪',
                    indicatorColor: AppColors.box2,
                    isActive: progress.subject2QuestionsCount > 0,
                    onTap: () => context.go('/learning'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: StatusCard(
                    title: 'Subject 3',
                    questionCount: progress.subject3QuestionsCount,
                    statusLabel: 'Ready for the exam ✅',
                    indicatorColor: AppColors.box3,
                    isActive: progress.subject3QuestionsCount > 0,
                    onTap: () => context.go('/learning'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Error state with retry action.
  Widget _buildErrorCard(WidgetRef ref, String error) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingBase),
      decoration: BoxDecoration(
        color: AppColors.logoutBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to load learning progress',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(learningProgressProvider);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
