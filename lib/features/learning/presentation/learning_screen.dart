import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/learning_unit.dart';
import '../domain/question.dart';
import 'learning_providers.dart';
import 'widgets/class_selector_tabs.dart';
import 'widgets/learning_unit_card.dart';
import 'widgets/question_search_bar.dart';

/// Mobile-first Learning Overview Screen replicating the Powerdrive Learning layout.
/// Connected to live Cloud Firestore Austrian driving theory catalogue (42 GW / 32 B).
class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  bool _isSearching = false;

  Future<void> _handleQuestionSearch(int questionNumber) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final repo = ref.read(learningRepositoryProvider);
      final currentClass = ref.read(selectedLearningClassProvider);
      final question = await repo.getQuestionByNumber(
        questionNumber,
        drivingClassId: currentClass,
      );

      if (!mounted) return;

      if (question != null) {
        context.push('/learning/question/$questionNumber', extra: question);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Question #$questionNumber was not found in the catalog.',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedClass = ref.watch(selectedLearningClassProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);
    final classesAsync = ref.watch(drivingClassesProvider);
    final unitsAsync = ref.watch(learningUnitsProvider(selectedClass));
    final questionsAsync = ref.watch(classQuestionsProvider(selectedClass));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(drivingClassesProvider);
        ref.invalidate(learningUnitsProvider(selectedClass));
        ref.invalidate(classQuestionsProvider(selectedClass));
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
            // Dev / Mock / Live Status Banner
            _buildCatalogBanner(isDemoMode),
            const SizedBox(height: AppConstants.spacingMd),

            // Header and Question Search Box
            AppCard(
              padding: const EdgeInsets.all(AppConstants.spacingBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📘', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          'Your learning units at a glance',
                          style: AppTextStyles.h2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingBase),

                  // Question search bar
                  QuestionSearchBar(
                    isLoading: _isSearching,
                    onSearch: _handleQuestionSearch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Class selector tabs (GW, B)
            classesAsync.when(
              data: (classes) => ClassSelectorTabs(
                classes: classes,
                selectedClassCode: selectedClass,
                onClassSelected: (code) {
                  ref
                      .read(selectedLearningClassProvider.notifier)
                      .selectClass(code);
                },
              ),
              loading: () => const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('Failed to load classes: $e'),
            ),
            const SizedBox(height: AppConstants.spacingMd),

            // Learning Units List (Topics overview)
            unitsAsync.when(
              data: (units) => _buildUnitsList(context, units),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
              error: (err, _) => _buildErrorCard(selectedClass, err.toString()),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Questions Section (Full list of questions for the selected class)
            _buildQuestionsSection(context, selectedClass, questionsAsync),
            const SizedBox(height: AppConstants.spacing2xl),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogBanner(bool isDemoMode) {
    if (isDemoMode) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.box3Background,
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_done_rounded,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Live Austrian Catalogue · Cloud Firestore (42 GW / 32 B)',
              style: AppTextStyles.label.copyWith(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsList(BuildContext context, List<LearningUnit> units) {
    if (units.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                'No learning units available for this class',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: units.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.spacingBase),
      itemBuilder: (context, index) {
        final unit = units[index];
        return LearningUnitCard(
          unit: unit,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Selected topic: ${unit.title} (${unit.totalQuestions} questions)',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuestionsSection(
    BuildContext context,
    String selectedClass,
    AsyncValue<List<Question>> questionsAsync,
  ) {
    return questionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: 10),
              Text(
                'Loading questions...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      error: (err, _) =>
          _buildQuestionsErrorCard(selectedClass, err.toString()),
      data: (questions) {
        if (questions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.spacingBase),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'No questions found for Class $selectedClass',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Category $selectedClass Questions',
                    style: AppTextStyles.h3.copyWith(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusPill,
                    ),
                  ),
                  child: Text(
                    '${questions.length} questions',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppConstants.spacingSm),
              itemBuilder: (context, index) {
                final question = questions[index];
                return _buildQuestionCard(context, question);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionCard(BuildContext context, Question question) {
    final isMultiple = question.selectionMode == QuestionSelectionMode.multiple;

    return AppCard(
      onTap: () {
        context.push(
          '/learning/question/${question.questionNumber}',
          extra: question,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Question Number Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  '#${question.questionNumber}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Module Code Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  question.drivingClassId,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),

              const Spacer(),

              // Selection mode chip
              Icon(
                isMultiple
                    ? Icons.check_box_outlined
                    : Icons.radio_button_checked,
                size: 12,
                color: isMultiple ? AppColors.primary : AppColors.success,
              ),
              const SizedBox(width: 3),
              Text(
                isMultiple ? 'Multi' : 'Single',
                style: AppTextStyles.caption.copyWith(
                  color: isMultiple ? AppColors.primary : AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Question Text Preview (prefixed with question number)
          Text(
            '#${question.questionNumber}: ${question.text}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Bottom metadata: topic and option count
          Row(
            children: [
              if (question.topic != null && question.topic!.isNotEmpty) ...[
                Flexible(
                  child: Text(
                    question.topic!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '•',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                '${question.options.length} options',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsErrorCard(String currentClass, String error) {
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
                  'Failed to load Firestore questions',
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
              ref.invalidate(classQuestionsProvider(currentClass));
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

  Widget _buildErrorCard(String currentClass, String error) {
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
                  'Failed to load learning units',
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
              ref.invalidate(learningUnitsProvider(currentClass));
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
