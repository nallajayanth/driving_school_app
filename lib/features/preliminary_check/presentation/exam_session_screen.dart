import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../exam_history/presentation/exam_providers.dart';
import '../../learning/domain/question.dart';

/// Screen managing active mock examination question answering and navigation.
class ExamSessionScreen extends ConsumerStatefulWidget {
  const ExamSessionScreen({super.key});

  @override
  ConsumerState<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends ConsumerState<ExamSessionScreen> {
  Future<bool> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Exit Examination?', style: AppTextStyles.h3),
        content: Text(
          'Your current answers in this mock examination session will not be saved.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Continue Exam'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.logout,
              foregroundColor: AppColors.textInverse,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  Future<void> _showFinishConfirmationDialog(
    BuildContext context,
    ExamSessionState session,
  ) async {
    final unanswered = session.totalQuestions - session.answeredCount;
    final message = unanswered > 0
        ? 'You have answered ${session.answeredCount} of ${session.totalQuestions} questions.\n\n$unanswered questions remain unanswered. Are you sure you want to finish and submit your exam?'
        : 'You have answered all ${session.totalQuestions} questions. Are you ready to submit your assessment?';

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Finish Examination', style: AppTextStyles.h3),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Review Questions'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Finish & Submit'),
          ),
        ],
      ),
    );

    if (shouldSubmit == true && context.mounted) {
      final attempt = await ref.read(examSessionProvider.notifier).submitExam();

      if (attempt != null && context.mounted) {
        context.go('/exam-result', extra: attempt);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(examSessionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit(context);
        if (shouldExit && context.mounted) {
          ref.read(examSessionProvider.notifier).resetSession();
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/preliminary-check');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Exit exam',
            onPressed: () async {
              final shouldExit = await _confirmExit(context);
              if (shouldExit && context.mounted) {
                ref.read(examSessionProvider.notifier).resetSession();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/preliminary-check');
                }
              }
            },
          ),
          title: Text('Mock Examination', style: AppTextStyles.h3),
          actions: [
            if (!session.isLoading && session.questions.isNotEmpty)
              TextButton(
                onPressed: session.isSubmitting
                    ? null
                    : () => _showFinishConfirmationDialog(context, session),
                child: Text(
                  'Finish',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(child: _buildSessionBody(context, session)),
      ),
    );
  }

  Widget _buildSessionBody(BuildContext context, ExamSessionState session) {
    if (session.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (session.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingBase),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppConstants.spacingBase),
              Text(session.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: AppConstants.spacingBase),
              AppButton(
                label: 'Go Back',
                isFullWidth: false,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/preliminary-check');
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    if (session.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingBase),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.quiz_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppConstants.spacingBase),
              Text(
                'No mock questions available for the selected classes.',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingBase),
              AppButton(
                label: 'Return',
                isFullWidth: false,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/preliminary-check');
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = session.currentQuestion;
    if (currentQuestion == null) {
      return const SizedBox.shrink();
    }

    final progressRatio = (session.currentIndex + 1) / session.totalQuestions;

    return Column(
      children: [
        // Demo mode banner
        Container(
          width: double.infinity,
          color: AppColors.primarySubtle,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const Icon(
                Icons.science_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demonstration Examination · Unverified scoring rules',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress indicator
        LinearProgressIndicator(
          value: progressRatio,
          backgroundColor: AppColors.border,
          color: AppColors.primary,
          minHeight: 4,
        ),

        // Main question content (scrollable)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question header: class & counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
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
                        'Class ${currentQuestion.drivingClassId}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'Question ${session.currentIndex + 1} of ${session.totalQuestions}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm),

                // Question number badge
                Text(
                  '#${currentQuestion.questionNumber}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXs),

                // Question text
                Text(
                  currentQuestion.text,
                  style: AppTextStyles.h2.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppConstants.spacingBase),

                // Optional illustration / diagram placeholder
                _buildQuestionDiagramPlaceholder(currentQuestion),

                const SizedBox(height: AppConstants.spacingBase),

                // Options list heading & selection mode hint
                Row(
                  children: [
                    Text(
                      currentQuestion.selectionMode ==
                              QuestionSelectionMode.multiple
                          ? 'Select all correct answers:'
                          : 'Select the correct answer:',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            currentQuestion.selectionMode ==
                                QuestionSelectionMode.multiple
                            ? AppColors.primarySubtle
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                      ),
                      child: Text(
                        currentQuestion.selectionMode ==
                                QuestionSelectionMode.multiple
                            ? 'Multiple Choice'
                            : 'Single Choice',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              currentQuestion.selectionMode ==
                                  QuestionSelectionMode.multiple
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm),

                // Options
                ...currentQuestion.options.map((option) {
                  final isSelected = session.isOptionSelected(
                    currentQuestion.id,
                    option.id,
                  );
                  final isMultiple =
                      currentQuestion.selectionMode ==
                      QuestionSelectionMode.multiple;

                  return _buildAnswerOptionCard(
                    context: context,
                    option: option,
                    isSelected: isSelected,
                    isMultiple: isMultiple,
                    onTap: () {
                      ref
                          .read(examSessionProvider.notifier)
                          .toggleOption(
                            currentQuestion.id,
                            option.id,
                            currentQuestion.selectionMode,
                          );
                    },
                  );
                }),

                const SizedBox(height: AppConstants.spacingBase),
              ],
            ),
          ),
        ),

        // Bottom Controls: Previous / Next / Finish
        _buildBottomActionBar(context, session),
      ],
    );
  }

  Widget _buildQuestionDiagramPlaceholder(Question question) {
    if (question.mediaUrl != null && question.mediaUrl!.isNotEmpty) {
      return Container(
        width: double.infinity,
        height: 180,
        margin: const EdgeInsets.only(bottom: AppConstants.spacingBase),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          question.mediaUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              'Image unavailable',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingBase),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.traffic_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacingBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driving Theory Situation',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Road traffic situation in Austria (Class ${question.drivingClassId})',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptionCard({
    required BuildContext context,
    required QuestionAnswerOption option,
    required bool isSelected,
    bool isMultiple = false,
    required VoidCallback onTap,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      onTap: onTap,
      borderColor: isSelected ? AppColors.primary : AppColors.border,
      backgroundColor: isSelected ? AppColors.primarySubtle : AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox or Radio indicator
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: isMultiple ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isMultiple ? BorderRadius.circular(4) : null,
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
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
          const SizedBox(width: AppConstants.spacingBase),

          // Option text
          Expanded(
            child: Text(
              option.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, ExamSessionState session) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingBase,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.05),
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: AppButton(
              label: 'Previous',
              variant: AppButtonVariant.outline,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              onPressed: session.isFirstQuestion
                  ? null
                  : () {
                      ref.read(examSessionProvider.notifier).previousQuestion();
                    },
            ),
          ),
          const SizedBox(width: AppConstants.spacingBase),

          // Next / Finish button
          Expanded(
            child: session.isLastQuestion
                ? AppButton(
                    label: 'Finish',
                    variant: AppButtonVariant.primary,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    isLoading: session.isSubmitting,
                    onPressed: () =>
                        _showFinishConfirmationDialog(context, session),
                  )
                : AppButton(
                    label: 'Next',
                    variant: AppButtonVariant.primary,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    onPressed: () {
                      ref.read(examSessionProvider.notifier).nextQuestion();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
