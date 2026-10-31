import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/question.dart';
import 'learning_providers.dart';

/// Question detail / preview screen reached when a user selects or searches a question.
///
/// Features:
/// - Supports interactive single and multiple option selection.
/// - Preserves selections per-question across screen navigation.
/// - Shows clear indicators for multiple-choice vs single-choice questions.
/// - Safely handles null media (no broken placeholders).
/// - Enforces Phase 11 security: never reads answer keys or attempts unverified grading.
class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({
    super.key,
    required this.questionNumber,
    this.initialQuestion,
  });

  final int questionNumber;
  final Question? initialQuestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialQuestion != null) {
      return _buildScaffold(context, ref, initialQuestion!);
    }

    final questionAsync = ref.watch(questionLookupProvider(questionNumber));

    return questionAsync.when(
      data: (question) {
        if (question == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Question #$questionNumber', style: AppTextStyles.h3),
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
                      'Question #$questionNumber not found',
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

        return _buildScaffold(context, ref, question);
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text('Question #$questionNumber', style: AppTextStyles.h3),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          title: Text('Question #$questionNumber', style: AppTextStyles.h3),
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
                  onPressed: () =>
                      ref.invalidate(questionLookupProvider(questionNumber)),
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

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    Question question,
  ) {
    final selectedOptions = ref.watch(
      questionSelectedOptionsProvider(question.id),
    );
    final isMultiple = question.selectionMode == QuestionSelectionMode.multiple;
    final isUnknown = question.selectionMode == QuestionSelectionMode.unknown;

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
          if (selectedOptions.isNotEmpty)
            TextButton(
              onPressed: () {
                ref
                    .read(questionStudySelectionProvider.notifier)
                    .clearQuestion(question.id);
              },
              child: Text(
                'Clear',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
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
                            : (isUnknown ? 'Unknown Mode' : 'Single Choice'),
                        style: AppTextStyles.label.copyWith(
                          color: isMultiple
                              ? AppColors.primaryDark
                              : (isUnknown
                                    ? AppColors.textSecondary
                                    : AppColors.success),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Topic chip (if present)
                if (question.topic != null && question.topic!.isNotEmpty)
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
                    ),
                    child: Text(
                      question.topic!,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
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

              return AppCard(
                margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                onTap: isUnknown
                    ? null
                    : () {
                        ref
                            .read(questionStudySelectionProvider.notifier)
                            .toggleOption(
                              question.id,
                              option.id,
                              question.selectionMode,
                            );
                      },
                borderColor: isSelected ? AppColors.primary : AppColors.border,
                backgroundColor: isSelected
                    ? AppColors.primarySubtle
                    : AppColors.surface,
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
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              isMultiple ? Icons.check : Icons.circle,
                              size: isMultiple ? 14 : 10,
                              color: AppColors.textInverse,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Text(
                        option.text,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppConstants.spacingBase),

            // Practice Mode Notice regarding Phase 12 Cloud Functions verification
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
                      'Notice: Question answering, answer selection, and interactive practice are enabled. Answer submission, immediate feedback, and scoring rules are preserved pending Phase 12 Cloud Functions verification.',
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
}
