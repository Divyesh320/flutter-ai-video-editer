import '../../../core/models/settings_models.dart';

/// Utility class for quota-related calculations and checks
class QuotaUtils {
  QuotaUtils._();

  /// Warning threshold percentage (80%)
  static const double warningThreshold = 0.80;

  /// Exceeded threshold percentage (100%)
  static const double exceededThreshold = 1.0;

  /// Check if usage is at or above warning threshold (80%)
  static bool isNearQuotaLimit(UsageStats stats) {
    if (stats.quotaLimit <= 0) return false;
    return stats.usagePercentage >= warningThreshold;
  }

  /// Check if usage has exceeded quota (100%)
  static bool isQuotaExceeded(UsageStats stats) {
    return stats.quotaUsed >= stats.quotaLimit;
  }

  /// Get warning message based on usage level
  static String? getWarningMessage(UsageStats stats) {
    if (isQuotaExceeded(stats)) {
      return 'You have exceeded your quota. Please upgrade to continue.';
    }
    if (isNearQuotaLimit(stats)) {
      final percentage = (stats.usagePercentage * 100).toInt();
      return 'You have used $percentage% of your quota.';
    }
    return null;
  }

  /// Check if a request should be blocked due to quota
  static bool shouldBlockRequest(UsageStats? stats) {
    if (stats == null) return false;
    return isQuotaExceeded(stats);
  }

  /// Get remaining quota as a formatted string
  static String getRemainingQuotaText(UsageStats stats) {
    final remaining = stats.quotaRemaining;
    if (remaining <= 0) {
      return 'No quota remaining';
    }
    return '$remaining requests remaining';
  }

  /// Get usage percentage as a formatted string
  static String getUsagePercentageText(UsageStats stats) {
    final percentage = (stats.usagePercentage * 100).toInt();
    return '$percentage%';
  }
}
