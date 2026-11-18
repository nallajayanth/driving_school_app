import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../progress/domain/student_question_progress.dart';
import '../../progress/presentation/progress_providers.dart';
import '../domain/question.dart';
import 'learning_providers.dart';

/// Question detail / preview screen reached when a user selects or searches a question.
///
/// Features (Phase 12):
/// - Automatically records question view in Cloud Firestore (`users/{uid}/question_progress/{questionId}`).
/// - Updates active resume learning checkpoint (`users/{uid}/learning_state/current`).
/// - Interactive single and multiple option selection with real-time persistence.
/// - Bookmark / Unbookmark action with immediate visual feedback.
/// - Manual "Mark as Reviewed" action chip.
/// - Option selection reset action.
/// - Preserves selections per-question across screen navigation.
/// - Shows clear indicators for multiple-choice vs single-choice questions.
/// - Enforces Phase 12 security: direct client Firestore ops, zero grading, answer keys denied.
class QuestionDetailScreen extends ConsumerStatefulWidget {
  const QuestionDetailScreen({
    super.key,
    required this.questionNumber,
    this.questionId,
    this.initialQuestion,
  });

  final int questionNumber;
  final String? questionId;
  final Question? initialQuestion;

  @override
  ConsumerState<QuestionDetailScreen> createState() =>
      _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  String? _lastRecordedQuestionId;

  void _recordViewIfNeeded(Question question) {
    if (_lastRecordedQuestionId == question.id) return;
    _lastRecordedQuestionId = question.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(learningProgressRepositoryProvider)
          .recordQuestionViewed(
            questionId: question.id,
            moduleCode: question.drivingClassId,
            topic: question.topic,
            questionNumber: question.questionNumber,
          );
      ref
          .read(learningProgressRepositoryProvider)
          .updateResumeLearningState(
            moduleCode: question.drivingClassId,
            questionId: question.id,
            questionNumber: question.questionNumber,
            questionText: question.text,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialQuestion != null) {
      _recordViewIfNeeded(widget.initialQuestion!);
      return _buildScaffold(context, widget.initialQuestion!);
    }

    final questionAsync =
        (widget.questionId != null && widget.questionId!.trim().isNotEmpty)
        ? ref.watch(questionByIdProvider(widget.questionId!.trim()))
        : ref.watch(questionLookupProvider(widget.questionNumber));

    return questionAsync.when(
      data: (question) {
        if (question == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Question #${widget.questionNumber}',
                style: AppTextStyles.h3,
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppConstants.spacingBase),
                    Text(
                      'Question #${widget.questionNumber} not found',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Please verify the question number or select another topic in the catalog.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        _recordViewIfNeeded(question);
        return _buildScaffold(context, question);
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(
            'Question #${widget.questionNumber}',
            style: AppTextStyles.h3,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Question #${widget.questionNumber}',
            style: AppTextStyles.h3,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
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
                Text('Error loading question', style: AppTextStyles.h3),
                const SizedBox(height: AppConstants.spacingSm),
                Text(err.toString(), textAlign: TextAlign.center),
                const SizedBox(height: AppConstants.spacingBase),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(
                    questionLookupProvider(widget.questionNumber),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, Question question) {
    final selectedOptions = ref.watch(
      questionSelectedOptionsProvider(question.id),
    );
    final isBookmarked = ref.watch(isQuestionBookmarkedProvider(question.id));
    final progress = ref.watch(singleQuestionProgressProvider(question.id));
    final isReviewed = progress?.studyStatus == StudyStatus.reviewed;
    final isMultiple = question.selectionMode == QuestionSelectionMode.multiple;
    final isUnknown = question.selectionMode == QuestionSelectionMode.unknown;

    // Check Answer state
    final checkAsync = ref.watch(questionCheckProvider(question.id));
    final checkResult = checkAsync.asData?.value;
    final isChecked = checkResult != null;
    final isExamCorrect = checkResult?.isCorrect == true;
    final correctOptionIds = checkResult?.correctOptionIds ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question #${question.questionNumber}',
          style: AppTextStyles.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Bookmark Action
          IconButton(
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isBookmarked ? const Color(0xFFF59E0B) : null,
            ),
            tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Question',
            onPressed: () {
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
          ),

          // Reset selection button
          if (selectedOptions.isNotEmpty)
            TextButton(
              onPressed: () {
                ref
                    .read(questionCheckResultsProvider.notifier)
                    .reset(question.id);
                ref
                    .read(questionStudySelectionProvider.notifier)
                    .clearQuestion(
                      question.id,
                      moduleCode: question.drivingClassId,
                      topic: question.topic,
                      questionNumber: question.questionNumber,
                    );
              },
              child: Text(
                'Reset',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata chips row
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Class chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusPill,
                    ),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    'Class ${question.drivingClassId}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Question canonical ID badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusPill,
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    question.id,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Selection Mode Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isMultiple
                        ? AppColors.primarySubtle
                        : (isUnknown
                              ? AppColors.surfaceVariant
                              : AppColors.box3Background),
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusPill,
                    ),
                    border: Border.all(
                      color: isMultiple
                          ? AppColors.primary
                          : (isUnknown ? AppColors.border : AppColors.success),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMultiple
                            ? Icons.check_box_outlined
                            : (isUnknown
                                  ? Icons.help_outline
                                  : Icons.radio_button_checked),
                        size: 13,
                        color: isMultiple
                            ? AppColors.primaryDark
                            : (isUnknown
                                  ? AppColors.textSecondary
                                  : AppColors.success),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMultiple
                            ? 'Multiple Choice'
                            : (isUnknown ? 'Mode Unknown' : 'Single Choice'),
                        style: AppTextStyles.label.copyWith(
                          color: isMultiple
                              ? AppColors.primaryDark
                              : (isUnknown
                                    ? AppColors.textSecondary
                                    : AppColors.success),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Mark as Reviewed Interactive Chip
                InkWell(
                  onTap: () {
                    ref
                        .read(learningProgressRepositoryProvider)
                        .markQuestionReviewed(
                          questionId: question.id,
                          moduleCode: question.drivingClassId,
                          reviewed: !isReviewed,
                          topic: question.topic,
                          questionNumber: question.questionNumber,
                        );
                  },
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isReviewed
                          ? AppColors.box3Background
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusPill,
                      ),
                      border: Border.all(
                        color: isReviewed
                            ? AppColors.success
                            : AppColors.border,
                        width: isReviewed ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isReviewed
                              ? Icons.check_circle_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 14,
                          color: isReviewed
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isReviewed ? 'Reviewed ✓' : 'Mark as reviewed',
                          style: AppTextStyles.label.copyWith(
                            color: isReviewed
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: isReviewed
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Topic description if available
            if (question.topic != null && question.topic!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.folder_open_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _formatTopicTitle(question.topic!),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppConstants.spacingMd),

            // Question Statement Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  // Display media illustration ONLY if mediaUrl is non-null and not empty
                  if (question.mediaUrl != null &&
                      question.mediaUrl!.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingBase),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMd,
                      ),
                      child: Image.network(
                        question.mediaUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          color: AppColors.surfaceVariant,
                          alignment: Alignment.center,
                          child: Text(
                            'Image unavailable',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingBase),

            // Options Header & Instructions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMultiple
                      ? 'Select all correct options:'
                      : 'Select the correct option:',
                  style: AppTextStyles.h3.copyWith(fontSize: 15),
                ),
                if (selectedOptions.isNotEmpty)
                  Text(
                    '${selectedOptions.length} selected',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),

            // Unknown Mode Warning Banner
            if (isUnknown)
              Container(
                margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                padding: const EdgeInsets.all(AppConstants.spacingBase),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notice: Question selection mode is unverified. Options cannot be selected.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Interactive Answer Options
            ...question.options.map((option) {
              final isSelected = selectedOptions.contains(option.id);
              final isCorrectOption =
                  isChecked && correctOptionIds.contains(option.id);
              final isIncorrectSelection =
                  isChecked && isSelected && !isCorrectOption;

              // Color determination
              Color borderColor = isSelected ? AppColors.primary : AppColors.border;
              Color backgroundColor = isSelected
                  ? AppColors.primarySubtle
                  : AppColors.surface;

              if (isChecked) {
                if (isCorrectOption) {
                  borderColor = AppColors.success;
                  backgroundColor = AppColors.box3Background;
                } else if (isIncorrectSelection) {
                  borderColor = AppColors.error;
                  backgroundColor = AppColors.logoutBackground;
                } else {
                  borderColor = AppColors.border.withValues(alpha: 0.6);
                  backgroundColor = AppColors.surface;
                }
              }

              return AppCard(
                margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                onTap: isUnknown
                    ? null
                    : () {
                        // Reset verification if user changes selection
                        if (isChecked) {
                          ref
                              .read(questionCheckResultsProvider.notifier)
                              .reset(question.id);
                        }
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
                borderColor: borderColor,
                backgroundColor: backgroundColor,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox or Radio Icon
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: isMultiple
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                        borderRadius: isMultiple
                            ? BorderRadius.circular(4)
                            : null,
                        color: isChecked
                            ? (isCorrectOption
                                  ? AppColors.success
                                  : (isIncorrectSelection
                                        ? AppColors.error
                                        : Colors.transparent))
                            : (isSelected
                                  ? AppColors.primary
                                  : Colors.transparent),
                        border: Border.all(
                          color: isChecked
                              ? (isCorrectOption
                                    ? AppColors.success
                                    : (isIncorrectSelection
                                          ? AppColors.error
                                          : AppColors.textMuted))
                              : (isSelected
                                    ? AppColors.primary
                                    : AppColors.textMuted),
                          width: 2,
                        ),
                      ),
                      child: isChecked
                          ? (isCorrectOption
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : (isIncorrectSelection
                                      ? const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null))
                          : (isSelected
                                ? Icon(
                                    isMultiple ? Icons.check : Icons.circle,
                                    size: isMultiple ? 14 : 10,
                                    color: AppColors.textInverse,
                                  )
                                : null),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.text,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isChecked
                                  ? (isCorrectOption
                                        ? AppColors.textPrimary
                                        : (isIncorrectSelection
                                              ? AppColors.error
                                              : AppColors.textSecondary))
                                  : (isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary),
                              fontWeight: isSelected || isCorrectOption
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          if (isCorrectOption) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Correct answer',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (isIncorrectSelection) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cancel_rounded,
                                  size: 13,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Your selection (incorrect)',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Error display if validation failed
            if (checkAsync.hasError) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingBase),
                decoration: BoxDecoration(
                  color: AppColors.logoutBackground,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Could not verify answer. Please check backend connection.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(questionCheckResultsProvider.notifier)
                            .checkAnswer(
                              questionId: question.id,
                              selectedOptionIds: selectedOptions.toList(),
                              moduleCode: question.drivingClassId,
                              topic: question.topic,
                              questionNumber: question.questionNumber,
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],

            // Verification Result Feedback Banner
            if (isChecked) ...[
              const SizedBox(height: AppConstants.spacingBase),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingBase),
                decoration: BoxDecoration(
                  color: isExamCorrect
                      ? AppColors.box3Background
                      : AppColors.logoutBackground,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(
                    color: isExamCorrect ? AppColors.success : AppColors.error,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isExamCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isExamCorrect
                              ? AppColors.success
                              : AppColors.error,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isExamCorrect
                                ? 'Correct! Well done.'
                                : 'Incorrect answer',
                            style: AppTextStyles.h3.copyWith(
                              color: isExamCorrect
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (checkResult.explanation != null &&
                        checkResult.explanation!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        checkResult.explanation!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ] else if (!isExamCorrect) ...[
                      const SizedBox(height: 6),
                      Text(
                        isMultiple
                            ? 'Review the green highlighted options. In Austria, all correct options must be selected with no incorrect choices.'
                            : 'Review the correct option highlighted in green above.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingBase),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(questionCheckResultsProvider.notifier)
                            .reset(question.id);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Check Answer Action Controls
              const SizedBox(height: AppConstants.spacingBase),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: selectedOptions.isEmpty ||
                              checkAsync.isLoading ||
                              isUnknown
                          ? null
                          : () {
                              ref
                                  .read(
                                    questionCheckResultsProvider.notifier,
                                  )
                                  .checkAnswer(
                                    questionId: question.id,
                                    selectedOptionIds: selectedOptions.toList(),
                                    moduleCode: question.drivingClassId,
                                    topic: question.topic,
                                    questionNumber: question.questionNumber,
                                  );
                            },
                      icon: checkAsync.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.fact_check_outlined, size: 20),
                      label: Text(
                        checkAsync.isLoading ? 'Checking...' : 'Check Answer',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (selectedOptions.isNotEmpty && !checkAsync.isLoading) ...[
                    const SizedBox(width: AppConstants.spacingSm),
                    OutlinedButton(
                      onPressed: () {
                        ref
                            .read(questionCheckResultsProvider.notifier)
                            .reset(question.id);
                        ref
                            .read(questionStudySelectionProvider.notifier)
                            .clearQuestion(
                              question.id,
                              moduleCode: question.drivingClassId,
                              topic: question.topic,
                              questionNumber: question.questionNumber,
                            );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                        ),
                      ),
                      child: const Text('Reset selections'),
                    ),
                  ],
                ],
              ),
            ],

            const SizedBox(height: AppConstants.spacingBase),

            // Study Information Notice
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
                    Icons.security_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notice: Question answering, answer selection, and interactive practice are enabled. Answer verification checks options against the official answer keys, and your study progress is saved automatically.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTopicTitle(String rawTopic) {
    return rawTopic
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
