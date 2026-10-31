import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/firestore_learning_repository.dart';
import '../domain/learning_unit.dart';
import '../domain/question.dart';
import 'learning_providers.dart';
import 'widgets/class_selector_tabs.dart';
import 'widgets/learning_unit_card.dart';
import 'widgets/question_search_bar.dart';

enum _LearningViewMode { questions, topics }

/// Mobile-first Learning Overview Screen replicating the Powerdrive Learning layout.
/// Connected to live Cloud Firestore Austrian driving theory catalogue (42 GW / 32 B).
class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  bool _isSearching = false;
  _LearningViewMode? _activeView;
  String? _selectedTopicFilter;

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
    final repo = ref.watch(learningRepositoryProvider);
    final isLiveFirestore = repo is FirestoreLearningRepository;

    final classesAsync = ref.watch(drivingClassesProvider);
    final unitsAsync = ref.watch(learningUnitsProvider(selectedClass));
    final questionsAsync = ref.watch(classQuestionsProvider(selectedClass));

    final effectiveView =
        _activeView ??
        (isLiveFirestore
            ? _LearningViewMode.questions
            : _LearningViewMode.topics);

    final questionsCount = questionsAsync.value?.length ?? 0;
    final unitsCount = unitsAsync.value?.length ?? 0;

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
            _buildCatalogBanner(isDemoMode, isLiveFirestore),
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
                  setState(() {
                    _selectedTopicFilter = null;
                  });
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

            // View Switcher (Questions vs Topics)
            _buildViewSwitcher(
              activeView: effectiveView,
              questionCount: questionsCount,
              unitCount: unitsCount,
            ),
            const SizedBox(height: AppConstants.spacingMd),

            // Active View Body
            if (effectiveView == _LearningViewMode.questions) ...[
              _buildQuestionsSection(context, selectedClass, questionsAsync),
            ] else ...[
              unitsAsync.when(
                data: (units) => _buildUnitsList(context, units),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
                error: (err, _) =>
                    _buildErrorCard(selectedClass, err.toString()),
              ),
            ],
            const SizedBox(height: AppConstants.spacing2xl),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogBanner(bool isDemoMode, bool isLiveFirestore) {
    if (isLiveFirestore && !isDemoMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.box3Background,
          borderRadius: BorderRadius.circular(AppConstants.radiusPill),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
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
                'Live Austrian Catalogue · Cloud Firestore',
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

  Widget _buildViewSwitcher({
    required _LearningViewMode activeView,
    required int questionCount,
    required int unitCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildSwitcherTab(
              title: 'Questions ($questionCount)',
              icon: Icons.format_list_bulleted_rounded,
              isSelected: activeView == _LearningViewMode.questions,
              onTap: () {
                setState(() {
                  _activeView = _LearningViewMode.questions;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSwitcherTab(
              title: 'Topics ($unitCount)',
              icon: Icons.grid_view_rounded,
              isSelected: activeView == _LearningViewMode.topics,
              onTap: () {
                setState(() {
                  _activeView = _LearningViewMode.topics;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: AppTextStyles.label.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
            setState(() {
              _selectedTopicFilter = unit.title;
              _activeView = _LearningViewMode.questions;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Showing questions for topic: ${unit.title}'),
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
                'Loading questions from catalogue...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      error: (err, _) =>
          _buildQuestionsErrorCard(selectedClass, err.toString()),
      data: (questions) {
        final filteredQuestions = _selectedTopicFilter == null
            ? questions
            : questions.where((q) {
                final topic = q.topic ?? '';
                final formatted = _formatTopicTitle(topic);
                return formatted.toLowerCase() ==
                        _selectedTopicFilter!.toLowerCase() ||
                    topic.toLowerCase() == _selectedTopicFilter!.toLowerCase();
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedTopicFilter != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Filtered by: $_selectedTopicFilter (${filteredQuestions.length} questions)',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTopicFilter = null;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    '${filteredQuestions.length} questions',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            if (filteredQuestions.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingBase),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No questions match the current filter',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredQuestions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppConstants.spacingSm),
                itemBuilder: (context, index) {
                  final question = filteredQuestions[index];
                  return _buildQuestionCard(context, question);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQuestionCard(BuildContext context, Question question) {
    final isMultiple = question.selectionMode == QuestionSelectionMode.multiple;
    final selectedOptions = ref.watch(
      questionSelectedOptionsProvider(question.id),
    );

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
              // Question Number Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  '#${question.questionNumber}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Driving Class Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  question.drivingClassId,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Topic Pill (if available)
              if (question.topic != null && question.topic!.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSm,
                      ),
                    ),
                    child: Text(
                      _formatTopicTitle(question.topic!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              const Spacer(),

              // Selection mode chip
              Icon(
                isMultiple
                    ? Icons.check_box_outlined
                    : Icons.radio_button_checked,
                size: 13,
                color: isMultiple ? AppColors.primary : AppColors.success,
              ),
              const SizedBox(width: 3),
              Text(
                isMultiple ? 'Multi' : 'Single',
                style: AppTextStyles.caption.copyWith(
                  color: isMultiple ? AppColors.primary : AppColors.success,
                  fontWeight: FontWeight.w700,
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
          const SizedBox(height: 8),

          // Question Text
          Text(
            '#${question.questionNumber}: ${question.text}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.35,
              color: AppColors.textPrimary,
            ),
          ),

          // Options List Display (showing actual options)
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(
              children: question.options.asMap().entries.map((entry) {
                final idx = entry.key;
                final option = entry.value;
                final isSelected = selectedOptions.contains(option.id);
                final letterLabel = String.fromCharCode(65 + idx); // A, B, C, D

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: InkWell(
                    onTap: () {
                      ref
                          .read(questionStudySelectionProvider.notifier)
                          .toggleOption(
                            question.id,
                            option.id,
                            question.selectionMode,
                          );
                    },
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primarySubtle
                            : AppColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border.withValues(alpha: 0.6),
                          width: isSelected ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isMultiple
                                ? (isSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank)
                                : (isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked),
                            size: 15,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$letterLabel. ',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              option.text,
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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

  static String _formatTopicTitle(String topicKey) {
    return topicKey
        .split('_')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
