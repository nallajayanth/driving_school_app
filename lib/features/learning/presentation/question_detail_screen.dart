import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import 'learning_providers.dart';

/// Question detail / preview screen reached when a user calls a question by number.
/// Explicitly preserves unverified business rules without inventing submission or scoring logic.
class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key, required this.questionNumber});

  final int questionNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(questionLookupProvider(questionNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text('Question #$questionNumber', style: AppTextStyles.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: questionAsync.when(
        data: (question) {
          if (question == null) {
            return Center(
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
                      'Please verify the question number or select another topic unit.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driving Class and Question Number Tag
                Row(
                  children: [
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
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      'Question #${question.questionNumber}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
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
                          height: 1.4,
                        ),
                      ),
                      if (question.mediaUrl != null) ...[
                        const SizedBox(height: AppConstants.spacingBase),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingBase),

                // Answer Options List (Preview Mode)
                Text(
                  'Answer Options',
                  style: AppTextStyles.h3.copyWith(fontSize: 15),
                ),
                const SizedBox(height: AppConstants.spacingSm),

                ...question.options.map((option) {
                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.spacingSm,
                    ),
                    padding: const EdgeInsets.all(AppConstants.spacingBase),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMd,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingMd),
                        Expanded(
                          child: Text(
                            option.text,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppConstants.spacingBase),

                // Notice Banner regarding pending verification of scoring rules
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
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notice: Question answering, answer submission, immediate feedback, and Leitner progression rules are preserved pending verification against the source platform API.',
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading question: $err')),
      ),
    );
  }
}
