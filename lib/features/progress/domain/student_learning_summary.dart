import 'student_question_progress.dart';

/// Aggregated, verified learning metrics for an authenticated Firebase student.
///
/// CRITICAL:
/// Only contains learning activity metrics calculated directly from user subcollections:
/// - Total available questions
/// - Questions viewed
/// - Questions in progress
/// - Questions marked as reviewed
/// - GW questions reviewed
/// - B questions reviewed
/// - Total bookmarks
/// - Recently viewed questions
///
/// Under Spark-plan constraints and client security rules, this model strictly
/// omits scores, accuracy %, passing %, and rankings since no backend grading exists.
class StudentLearningSummary {
  const StudentLearningSummary({
    this.totalAvailableQuestions = 74,
    this.viewedCount = 0,
    this.inProgressCount = 0,
    this.reviewedCount = 0,
    this.gwReviewedCount = 0,
    this.bReviewedCount = 0,
    this.totalBookmarks = 0,
    this.recentlyViewedQuestions = const [],
  });

  final int totalAvailableQuestions;
  final int viewedCount;
  final int inProgressCount;
  final int reviewedCount;
  final int gwReviewedCount;
  final int bReviewedCount;
  final int totalBookmarks;
  final List<StudentQuestionProgress> recentlyViewedQuestions;

  Map<String, dynamic> toJson() {
    return {
      'totalAvailableQuestions': totalAvailableQuestions,
      'viewedCount': viewedCount,
      'inProgressCount': inProgressCount,
      'reviewedCount': reviewedCount,
      'gwReviewedCount': gwReviewedCount,
      'bReviewedCount': bReviewedCount,
      'totalBookmarks': totalBookmarks,
      'recentlyViewedQuestions': recentlyViewedQuestions
          .map((q) => q.toJson())
          .toList(),
    };
  }

  factory StudentLearningSummary.fromJson(Map<String, dynamic> json) {
    return StudentLearningSummary(
      totalAvailableQuestions: (json['totalAvailableQuestions'] as int?) ?? 74,
      viewedCount: (json['viewedCount'] as int?) ?? 0,
      inProgressCount: (json['inProgressCount'] as int?) ?? 0,
      reviewedCount: (json['reviewedCount'] as int?) ?? 0,
      gwReviewedCount: (json['gwReviewedCount'] as int?) ?? 0,
      bReviewedCount: (json['bReviewedCount'] as int?) ?? 0,
      totalBookmarks: (json['totalBookmarks'] as int?) ?? 0,
      recentlyViewedQuestions:
          (json['recentlyViewedQuestions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    StudentQuestionProgress.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
