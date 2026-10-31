import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../progress/domain/question_bookmark.dart';
import '../../progress/domain/resume_learning_state.dart';
import '../../progress/domain/student_question_progress.dart';
import '../../progress/presentation/progress_providers.dart';
import '../data/firestore_learning_repository.dart';
import '../domain/learning_unit.dart';
import '../domain/question.dart';
import 'learning_providers.dart';
import 'widgets/class_selector_tabs.dart';
import 'widgets/learning_unit_card.dart';
import 'widgets/question_search_bar.dart';

enum _LearningViewMode { questions, topics, bookmarks }

/// Mobile-first Learning Overview Screen replicating the Powerdrive Learning layout.
/// Connected to live Cloud Firestore Austrian driving theory catalogue (42 GW / 32 B).
/// Includes Phase 12 student progress pills, bookmarks list, and continue learning checkpoint.
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
    final bookmarksAsync = ref.watch(bookmarksListProvider);
    final resumeStateAsync = ref.watch(resumeLearningStateProvider);

    final effectiveView =
        _activeView ??
        (isLiveFirestore
            ? _LearningViewMode.questions
            : _LearningViewMode.topics);

    final questionsCount = questionsAsync.value?.length ?? 0;
    final unitsCount = unitsAsync.value?.length ?? 0;
    final bookmarksCount = bookmarksAsync.value?.length ?? 0;
    final resumeState = resumeStateAsync.value;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(drivingClassesProvider);
        ref.invalidate(learningUnitsProvider(selectedClass));
        ref.invalidate(classQuestionsProvider(selectedClass));
        ref.invalidate(bookmarksListProvider);
        ref.invalidate(resumeLearningStateProvider);
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

            // Resume Learning Banner (if active checkpoint exists)
            if (resumeState != null &&
                resumeState.lastQuestionNumber != null) ...[
              _buildResumeLearningBanner(context, resumeState),
              const SizedBox(height: AppConstants.spacingMd),
            ],

            // View Switcher (Questions vs Topics vs Bookmarks)
            _buildViewSwitcher(
              activeView: effectiveView,
              questionCount: questionsCount,
              unitCount: unitsCount,
              bookmarkCount: bookmarksCount,
            ),
            const SizedBox(height: AppConstants.spacingMd),

            // Active View Body
            if (effectiveView == _LearningViewMode.questions) ...[
              _buildQuestionsSection(context, selectedClass, questionsAsync),
            ] else if (effectiveView == _LearningViewMode.topics) ...[
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
            ] else ...[
              _buildBookmarksSection(context, bookmarksAsync),
            ],
            const SizedBox(height: AppConstants.spacing2xl),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeLearningBanner(
    BuildContext context,
    ResumeLearningState resumeState,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue Learning',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Question #${resumeState.lastQuestionNumber} (${resumeState.lastModuleCode})',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (resumeState.lastQuestionNumber != null) {
                context.push(
                  '/learning/question/${resumeState.lastQuestionNumber}?id=${resumeState.lastQuestionId}',
                  extra: resumeState.lastQuestionId,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Resume',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
    required int bookmarkCount,
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
          const SizedBox(width: 4),
          Expanded(
            child: _buildSwitcherTab(
              title: 'Bookmarks ($bookmarkCount)',
              icon: Icons.bookmark_rounded,
              isSelected: activeView == _LearningViewMode.bookmarks,
              onTap: () {
                setState(() {
                  _activeView = _LearningViewMode.bookmarks;
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: AppTextStyles.label.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
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
          },
        );
      },
    );
  }

  Widget _buildBookmarksSection(
    BuildContext context,
    AsyncValue<List<QuestionBookmark>> bookmarksAsync,
  ) {
    return bookmarksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingBase),
        decoration: BoxDecoration(
          color: AppColors.logoutBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 24),
            const SizedBox(height: 8),
            Text('Failed to load bookmarks', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.spacingXl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.bookmark_border_rounded,
                    size: 44,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    'No bookmarked questions yet',
                    style: AppTextStyles.h3.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap the bookmark icon on any question in GW or Category B to save it for quick review.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
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
                Text(
                  'Bookmarked Questions (${bookmarks.length})',
                  style: AppTextStyles.h3.copyWith(fontSize: 15),
                ),
                Text(
                  'Across GW & Category B',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookmarks.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppConstants.spacingSm),
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return AppCard(
                  onTap: () {
                    if (bookmark.questionNumber != null) {
                      context.push(
                        '/learning/question/${bookmark.questionNumber}?id=${bookmark.questionId}',
                        extra: bookmark.questionId,
                      );
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (bookmark.questionNumber != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySubtle,
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.radiusSm,
                                      ),
                                    ),
                                    child: Text(
                                      '#${bookmark.questionNumber}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusSm,
                                    ),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    bookmark.moduleCode,
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (bookmark.topic != null &&
                                    bookmark.topic!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _formatTopicTitle(bookmark.topic!),
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bookmark.questionText ??
                                  'Question #${bookmark.questionNumber ?? bookmark.questionId}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.bookmark_remove_rounded,
                          color: Color(0xFFF59E0B),
                        ),
                        tooltip: 'Remove bookmark',
                        onPressed: () {
                          ref
                              .read(learningProgressRepositoryProvider)
                              .toggleBookmark(
                                questionId: bookmark.questionId,
                                moduleCode: bookmark.moduleCode,
                                topic: bookmark.topic,
                                questionNumber: bookmark.questionNumber,
                                questionText: bookmark.questionText,
                              );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
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
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
      error: (err, _) =>
          _buildQuestionsErrorCard(selectedClass, err.toString()),
      data: (questions) {
        final filteredQuestions = _selectedTopicFilter == null
            ? questions
            : questions.where((q) {
                if (q.topic == null) return false;
                final formattedTopic = _formatTopicTitle(q.topic!);
                return formattedTopic.toLowerCase() ==
                    _selectedTopicFilter!.toLowerCase();
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
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Filtered by topic: $_selectedTopicFilter',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
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
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textMuted,
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
    final progress = ref.watch(singleQuestionProgressProvider(question.id));
    final isBookmarked = ref.watch(isQuestionBookmarkedProvider(question.id));

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

              // Study Status Pill
              if (progress != null) ...[
                _buildStatusPill(progress.studyStatus),
                const SizedBox(width: 6),
              ],

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

              // Bookmark icon button
              InkWell(
                onTap: () {
                  ref
                      .read(learningProgressRepositoryProvider)
                      .toggleBookmark(
                        questionId: question.id,
                        moduleCode: question.drivingClassId,
                        topic: question.topic,
                        questionNumber: question.questionNumber,
                        questionText: question.text,
                      );
                },
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                    color: isBookmarked
                        ? const Color(0xFFF59E0B)
                        : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 4),

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
                            moduleCode: question.drivingClassId,
                            topic: question.topic,
                            questionNumber: question.questionNumber,
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

  Widget _buildStatusPill(StudyStatus status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case StudyStatus.reviewed:
        bg = AppColors.box3Background;
        fg = AppColors.success;
        label = 'Reviewed';
        icon = Icons.check_circle_rounded;
        break;
      case StudyStatus.inProgress:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'In Progress';
        icon = Icons.edit_note_rounded;
        break;
      case StudyStatus.viewed:
        bg = AppColors.primarySubtle;
        fg = AppColors.primary;
        label = 'Viewed';
        icon = Icons.visibility_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
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

  static String _formatTopicTitle(String topicKey) {
    return topicKey
        .split('_')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
