import '../models/notification_model.dart';
import 'offline_notification_classifier_service.dart';

export 'offline_notification_classifier_service.dart'
    show NotificationClassificationInput, NotificationClassificationResult;

/// Smart Notification Categorization Engine
///
/// Delegates to the offline notification classifier engine featuring:
/// - 7 classes (Realtime, Security, Conversations, Socials, Updates, Promotions, Silent)
/// - Background Isolate execution for smooth shade performance
/// - LRU and channel caching
/// - Confidence thresholding and fallback
/// - On-device dynamic weight updates from user corrections
class SmartNotificationClassifier {
  SmartNotificationClassifier._();

  static bool get isEnabled => OfflineNotificationClassifierService.isEnabled;
  static set isEnabled(bool value) =>
      OfflineNotificationClassifierService.isEnabled = value;

  static void loadOverrides(Map<String, dynamic> raw) {
    OfflineNotificationClassifierService.loadOverrides(raw);
  }

  static Map<String, String> exportOverrides() {
    return OfflineNotificationClassifierService.exportOverrides();
  }

  static void setUserOverride({
    required String packageName,
    String channelId = '',
    required NotificationCategory category,
  }) {
    OfflineNotificationClassifierService.setUserOverride(
      packageName: packageName,
      channelId: channelId,
      category: category,
    );
  }

  static NotificationCategory? getUserOverride(
    String packageName, [
    String channelId = '',
  ]) {
    return OfflineNotificationClassifierService.getUserOverride(
      packageName,
      channelId,
    );
  }

  static void recordUserCorrection({
    required String packageName,
    String channelId = '',
    required String title,
    required String content,
    required NotificationCategory targetCategory,
    NotificationCategory? previousCategory,
  }) {
    OfflineNotificationClassifierService.recordUserCorrection(
      packageName: packageName,
      channelId: channelId,
      title: title,
      content: content,
      targetCategory: targetCategory,
      previousCategory: previousCategory,
    );
  }

  static String? extractOtp(String title, String content) {
    return OfflineNotificationClassifierService.extractOtp(title, content);
  }

  static NotificationClassificationResult classify({
    required String appName,
    required String packageName,
    required String title,
    required String content,
    String channelId = '',
    String androidCategory = '',
    bool isConversation = false,
    bool isMessagingStyle = false,
    bool hasReplyAction = false,
  }) {
    return OfflineNotificationClassifierService.classify(
      appName: appName,
      packageName: packageName,
      title: title,
      content: content,
      channelId: channelId,
      androidCategory: androidCategory,
      isConversation: isConversation,
      isMessagingStyle: isMessagingStyle,
      hasReplyAction: hasReplyAction,
    );
  }

  static Future<NotificationClassificationResult> classifyAsync({
    required String appName,
    required String packageName,
    required String title,
    required String content,
    String channelId = '',
    String androidCategory = '',
    bool isConversation = false,
    bool isMessagingStyle = false,
    bool hasReplyAction = false,
  }) {
    return OfflineNotificationClassifierService.classifyAsync(
      appName: appName,
      packageName: packageName,
      title: title,
      content: content,
      channelId: channelId,
      androidCategory: androidCategory,
      isConversation: isConversation,
      isMessagingStyle: isMessagingStyle,
      hasReplyAction: hasReplyAction,
    );
  }

  static Future<List<NotificationClassificationResult>> classifyBatchAsync(
    List<NotificationClassificationInput> inputs,
  ) {
    return OfflineNotificationClassifierService.classifyBatchAsync(inputs);
  }

  static void clearCache() {
    OfflineNotificationClassifierService.clearCache();
  }
}
