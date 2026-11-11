import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expressive_shade/features/notifications/notification_card.dart';
import 'package:expressive_shade/features/notifications/notification_list.dart';
import 'package:expressive_shade/models/font_config.dart';
import 'package:expressive_shade/models/notification_model.dart';
import 'package:expressive_shade/models/notification_style.dart';
import 'package:expressive_shade/models/shade_theme.dart';
import 'package:expressive_shade/services/smart_notification_classifier.dart';
import 'package:expressive_shade/theme/m3_expressive_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final colors = ExpressiveThemeColors.fromSettings(
    source: ThemeSource.preset,
    preset: ThemePreset.presets.first,
    custom: const CustomThemeData(),
  );
  final font = FontConfig.availableFonts.first;

  group('NotificationStyle Enum and Extension Tests', () {
    test('NotificationStyle contains exactly the 6 distinct styles', () {
      expect(NotificationStyle.values.length, 6);
      expect(NotificationStyle.values, contains(NotificationStyle.android17));
      expect(NotificationStyle.values, contains(NotificationStyle.ios));
      expect(NotificationStyle.values, contains(NotificationStyle.oneui));
      expect(NotificationStyle.values, contains(NotificationStyle.compact));
      expect(NotificationStyle.values, contains(NotificationStyle.hyperOS));
      expect(NotificationStyle.values, contains(NotificationStyle.joined));
    });

    test('Each style provides unique display name and description', () {
      final names = NotificationStyle.values.map((s) => s.displayName).toSet();
      expect(names.length, 6);

      expect(NotificationStyle.compact.displayName, 'Compact Mode');
      expect(NotificationStyle.joined.displayName, 'Joined');
      for (final style in NotificationStyle.values) {
        expect(style.displayName.isNotEmpty, isTrue);
        expect(style.description.isNotEmpty, isTrue);
      }
    });
  });

  group('NotificationCard Widget Rendering Tests', () {
    const sampleNotif = NotificationModel(
      id: 'test_notif_1',
      packageName: 'com.google.android.apps.messaging',
      appName: 'Messages',
      title: 'Alice Chen',
      content: 'Are we still meeting at 3 PM today?',
      timeAgo: 'Just now',
      appIcon: Icons.message_rounded,
      appColor: Color(0xFF1E88E5),
      isOngoing: true, // Specifically test ongoing notification to verify progress bar is gone
      actions: [
        NotificationAction(index: 0, title: 'Reply', hasRemoteInput: true),
        NotificationAction(index: 1, title: 'Mark as read', hasRemoteInput: false),
      ],
    );

    testWidgets('Other styles are collapsed by default and expand on chevron tap', (tester) async {
      final expandableStyles = [
        NotificationStyle.android17,
        NotificationStyle.ios,
        NotificationStyle.oneui,
        NotificationStyle.hyperOS,
      ];

      for (final style in expandableStyles) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationCard(
                key: ValueKey('test_card_${style.name}'),
                notification: sampleNotif,
                colors: colors,
                font: font,
                style: style,
                onDismiss: () {},
                onActionTap: (_) {},
              ),
            ),
          ),
        );

        // Header content visible
        expect(find.text('Alice Chen'), findsOneWidget);

        // Actions are collapsed by default in other styles!
        expect(find.text('Mark as read'), findsNothing);

        // Tap chevron to expand
        final chevron = find.byIcon(Icons.keyboard_arrow_down_rounded);
        expect(chevron, findsOneWidget);
        await tester.tap(chevron);
        await tester.pumpAndSettle();

        // After expanding, actions are visible
        expect(find.text('Reply'), findsOneWidget);
        expect(find.text('Mark as read'), findsOneWidget);

        // Verify NO progress bar exists even though isOngoing is true
        expect(find.byType(FractionallySizedBox), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      }
    });

    testWidgets('Joined Style renders two-column layout with clock time, app name and title', (tester) async {
      final joinedNotif = sampleNotif.copyWith(
        appName: 'Slack',
        title: 'Shared meeting-notes',
        content: 'Notes from today team sync...',
        timeAgo: '17:46',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: joinedNotif,
              colors: colors,
              font: font,
              style: NotificationStyle.joined,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('17:46'), findsOneWidget);
      expect(find.text('Slack'), findsOneWidget);
      expect(find.text('Shared meeting-notes'), findsOneWidget);
    });

    test('iOS relative timestamps format correctly as now, 3m ago, etc.', () {
      final nowNotif = sampleNotif.copyWith(timeAgo: 'Just now');
      expect(nowNotif.relativeTime, 'now');

      final threeMinAgo = DateTime.now().subtract(const Duration(minutes: 3)).millisecondsSinceEpoch;
      final threeMinNotif = sampleNotif.copyWith(postTime: threeMinAgo);
      expect(threeMinNotif.relativeTime, '3m ago');

      final fourMinAgo = DateTime.now().subtract(const Duration(minutes: 4)).millisecondsSinceEpoch;
      final fourMinNotif = sampleNotif.copyWith(postTime: fourMinAgo);
      expect(fourMinNotif.relativeTime, '4m ago');
    });

    testWidgets('Compact Mode renders sleek card and primary pill action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: sampleNotif,
              colors: colors,
              font: font,
              style: NotificationStyle.compact,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Resting state: title and primary action are visible
      expect(find.textContaining('Alice Chen'), findsOneWidget);
      expect(find.text('Reply'), findsOneWidget);

      // Full action tray is not open yet
      expect(find.text('Mark as read'), findsNothing);
    });

    testWidgets('Compact Mode reveals full action tray on swipe right', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: sampleNotif,
              colors: colors,
              font: font,
              style: NotificationStyle.compact,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Drag right partially to reveal action tray
      await tester.drag(find.byType(NotificationCard), const Offset(80, 0));
      await tester.pumpAndSettle();

      // Now both actions are visible in the action tray!
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Mark as read'), findsOneWidget);
    });

    testWidgets('Compact Mode fully swiping right dismisses the notification', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: sampleNotif,
              colors: colors,
              font: font,
              style: NotificationStyle.compact,
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      // Drag right past dismiss threshold
      await tester.drag(find.byType(NotificationCard), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('Non-clearable notification cannot be dismissed on swipe', (tester) async {
      bool dismissed = false;
      final nonClearableNotif = sampleNotif.copyWith(isClearable: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: nonClearableNotif,
              colors: colors,
              font: font,
              style: NotificationStyle.compact,
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      // Drag right past dismiss threshold
      await tester.drag(find.byType(NotificationCard), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(dismissed, isFalse);
    });

    testWidgets('Smart OTP extraction renders 1-tap Copy OTP pill on NotificationCard', (tester) async {
      final otpRes = SmartNotificationClassifier.classify(
        appName: 'Messages',
        packageName: 'com.google.android.apps.messaging',
        title: 'Google Verification',
        content: 'Your verification code is 482910. Do not share this OTP.',
      );

      expect(otpRes.category, NotificationCategory.security);
      expect(otpRes.extractedOtp, '482910');

      final otpNotif = sampleNotif.copyWith(
        title: 'Google Verification',
        content: 'Your verification code is 482910. Do not share this OTP.',
        category: otpRes.category,
        extractedOtp: otpRes.extractedOtp,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: otpNotif,
              colors: colors,
              font: font,
              style: NotificationStyle.android17,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Copy 482910'), findsOneWidget);
    });

    test('Tier 1 & Tier 2 SmartNotificationClassifier categorizes accurately and respects user overrides', () {
      // 1. Direct message -> People
      final chatRes = SmartNotificationClassifier.classify(
        appName: 'WhatsApp',
        packageName: 'com.whatsapp',
        title: 'Matt',
        content: 'Hey! Are we still down for meeting up on Saturday?',
        isConversation: true,
        hasReplyAction: true,
      );
      expect(chatRes.category, NotificationCategory.people);

      // 2. Order delivery -> Updates
      final orderRes = SmartNotificationClassifier.classify(
        appName: 'Amazon',
        packageName: 'com.amazon.mShop.android.shopping',
        title: 'Out for delivery',
        content: 'Your package #402-119 is arriving today by 5 PM.',
        channelId: 'order_updates',
      );
      expect(orderRes.category, NotificationCategory.updates);

      // 3. Marketing promo -> Promotions
      final promoRes = SmartNotificationClassifier.classify(
        appName: 'Swiggy',
        packageName: 'in.swiggy.android',
        title: 'Flash Sale: 60% OFF!',
        content: 'Use promo code TREAT60 for free delivery on your next order.',
      );
      expect(promoRes.category, NotificationCategory.promotions);

      // 4. Social activity -> Social (even when comment has a question mark and reply action!)
      final socialRes = SmartNotificationClassifier.classify(
        appName: 'Instagram',
        packageName: 'com.instagram.android',
        title: 'Instagram',
        content: 'dev_sharma commented on your photo: "Clean setup! What monitor is that?"',
        hasReplyAction: true,
      );
      expect(socialRes.category, NotificationCategory.social);

      // 4b. Instagram 1-on-1 Direct Message -> People
      final instaDmRes = SmartNotificationClassifier.classify(
        appName: 'Instagram',
        packageName: 'com.instagram.android',
        title: 'tanya_kapoor',
        content: 'Haha no way! Tell me everything when we meet tomorrow',
        isConversation: true,
        hasReplyAction: true,
      );
      expect(instaDmRes.category, NotificationCategory.people);

      // 4c. Bank UPI debit inside SMS app (even with isConversation: true & hasReplyAction: true) -> Security
      final bankSmsRes = SmartNotificationClassifier.classify(
        appName: 'Messages',
        packageName: 'com.google.android.apps.messaging',
        title: 'AD-HDFCBK-S',
        content: 'Sent Rs.350.00 from HDFC Bank A/c *4421 to Zomato via UPI Ref 6312894012.',
        isConversation: true,
        hasReplyAction: true,
      );
      expect(bankSmsRes.category, NotificationCategory.security);

      // 4d. Courier AWB tracking inside SMS app -> Updates
      final courierSmsRes = SmartNotificationClassifier.classify(
        appName: 'Messages',
        packageName: 'com.google.android.apps.messaging',
        title: 'AD-DELHVY-S',
        content: 'Delhivery Shipment AWB 8819203124 from Nykaa is out for delivery with agent Ramesh.',
        isConversation: true,
        hasReplyAction: true,
      );
      expect(courierSmsRes.category, NotificationCategory.updates);

      // 4e. Brand marketing inside WhatsApp Business (with "expires at midnight" & "promo code") -> Promotions
      final waPromoRes = SmartNotificationClassifier.classify(
        appName: 'WhatsApp',
        packageName: 'com.whatsapp',
        title: 'Lenskart',
        content: 'Hey! Your ₹500 discount voucher expires at midnight. Use promo code EYE500 to shop now.',
        isConversation: true,
        hasReplyAction: true,
      );
      expect(waPromoRes.category, NotificationCategory.promotions);

      // 4f. Zomato discount on dinner order -> Promotions (not Updates!)
      final zomatoPromoRes = SmartNotificationClassifier.classify(
        appName: 'Zomato',
        packageName: 'com.application.zomato',
        title: 'Get ₹150 OFF on your dinner order!',
        content: 'Flash sale is live for the next 2 hours. Order now before the deal expires!',
      );
      expect(zomatoPromoRes.category, NotificationCategory.promotions);

      // 4g. YouTube Premium trial -> Promotions (not Social!)
      final ytPromoRes = SmartNotificationClassifier.classify(
        appName: 'YouTube',
        packageName: 'com.google.android.youtube',
        title: 'Try YouTube Premium Free for 1 Month',
        content: 'Watch ad-free videos offline and get YouTube Music Premium. Start free trial.',
      );
      expect(ytPromoRes.category, NotificationCategory.promotions);

      // 5. User Override takes precedence
      SmartNotificationClassifier.setUserOverride(
        packageName: 'in.swiggy.android',
        channelId: 'promo_channel',
        category: NotificationCategory.updates,
      );
      final overridden = SmartNotificationClassifier.classify(
        appName: 'Swiggy',
        packageName: 'in.swiggy.android',
        channelId: 'promo_channel',
        title: 'Flash Sale: 60% OFF!',
        content: 'Use promo code TREAT60.',
      );
      expect(overridden.category, NotificationCategory.updates);
      expect(overridden.isUserOverride, isTrue);

      SmartNotificationClassifier.loadOverrides({});
    });

    testWidgets('NotificationList renders category filter chips and bundles low-priority promos', (tester) async {
      final list = [
        sampleNotif,
        const NotificationModel(
          id: 'promo_1',
          packageName: 'com.shop.one',
          appName: 'ShopOne',
          title: '50% OFF Flash Sale',
          content: 'Use coupon SAVE50 to shop now!',
          timeAgo: '2m',
          appIcon: Icons.local_offer_rounded,
          appColor: Colors.orange,
        ),
        const NotificationModel(
          id: 'promo_2',
          packageName: 'com.shop.two',
          appName: 'ShopTwo',
          title: 'Limited time offer: Free shipping',
          content: 'Claim your reward and discount today.',
          timeAgo: '5m',
          appIcon: Icons.local_offer_rounded,
          appColor: Colors.deepOrange,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotificationList(
                notifications: list,
                colors: colors,
                font: font,
                onDismiss: (_) {},
              ),
            ),
          ),
        ),
      );

      // Category filter chips visible
      expect(find.text('All 3'), findsOneWidget);
      expect(find.text('Conversations 1'), findsOneWidget);
      expect(find.text('Promotions 2'), findsOneWidget);

      // High-priority message is visible at top, while the 2 promos are bundled into the digest card
      expect(find.text('Alice Chen'), findsOneWidget);
      expect(find.text('Promotions'), findsOneWidget);
      expect(find.text('50% OFF Flash Sale'), findsNothing);

      // Tap the Promotions bundle card to expand it
      await tester.tap(find.text('Promotions'));
      await tester.pumpAndSettle();

      expect(find.text('50% OFF Flash Sale'), findsOneWidget);
    });

    testWidgets('NotificationList category chips support swipe-through selection', (tester) async {
      final list = [
        sampleNotif,
        const NotificationModel(
          id: 'promo_1',
          packageName: 'com.shop.one',
          appName: 'ShopOne',
          title: '50% OFF Flash Sale',
          content: 'Use coupon SAVE50 to shop now!',
          timeAgo: '2m',
          appIcon: Icons.local_offer_rounded,
          appColor: Colors.orange,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotificationList(
                notifications: list,
                colors: colors,
                font: font,
                onDismiss: (_) {},
              ),
            ),
          ),
        ),
      );

      // Initially 'All' is selected
      expect(find.text('All 2'), findsOneWidget);
      expect(find.text('Conversations 1'), findsOneWidget);
      expect(find.text('Promotions 1'), findsOneWidget);

      // Both notifications visible in All
      expect(find.text('Alice Chen'), findsOneWidget);
      expect(find.text('50% OFF Flash Sale'), findsOneWidget);

      // Drag across chips to Promotions
      final promoChip = find.text('Promotions 1');
      await tester.drag(promoChip, const Offset(-10, 0));
      await tester.pumpAndSettle();

      // Tap or touch-swiping to Promotions shows only the promo
      await tester.tap(promoChip);
      await tester.pumpAndSettle();

      expect(find.text('50% OFF Flash Sale'), findsOneWidget);
      expect(find.text('Alice Chen'), findsNothing);
    });
  });
}
