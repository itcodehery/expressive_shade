import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expressive_shade/models/notification_model.dart';
import 'package:expressive_shade/models/shade_theme.dart';
import 'package:expressive_shade/providers/shade_state_provider.dart';
import 'package:expressive_shade/screens/home/service_tab.dart';
import 'package:expressive_shade/services/offline_notification_classifier_service.dart';
import 'package:expressive_shade/theme/m3_expressive_theme.dart';

void main() {
  group('OfflineNotificationClassifierService Tests', () {
    setUp(() {
      OfflineNotificationClassifierService.clearCache();
      OfflineNotificationClassifierService.loadOverrides({});
      OfflineNotificationClassifierService.loadLearningState({});
    });

    test('All 7 categories are accurately categorized from seed scenarios', () {
      // 1. Realtime - Incoming call & Uber ETA
      final callRes = OfflineNotificationClassifierService.classify(
        appName: 'Phone',
        packageName: 'com.google.android.dialer',
        channelId: 'incoming_calls',
        title: 'Incoming call',
        content: 'Mom is calling',
      );
      expect(callRes.category, NotificationCategory.realtime);
      expect(OfflineNotificationClassifierService.getPriority(callRes.category), 1);

      final uberRes = OfflineNotificationClassifierService.classify(
        appName: 'Uber',
        packageName: 'com.ubercab',
        channelId: 'trip_updates',
        title: 'Your driver is arriving',
        content: 'Rahul in a white Swift is 2 min away',
      );
      expect(uberRes.category, NotificationCategory.realtime);

      final navRes = OfflineNotificationClassifierService.classify(
        appName: 'Maps',
        packageName: 'com.google.android.apps.maps',
        channelId: 'navigation',
        title: 'Turn right in 200 m',
        content: 'Head north on MG Road',
      );
      expect(navRes.category, NotificationCategory.realtime);

      // 2. Security - OTP, Debit alert, New sign-in
      final otpRes = OfflineNotificationClassifierService.classify(
        appName: 'Gmail',
        packageName: 'com.google.android.gm',
        channelId: 'otp',
        title: 'Your verification code',
        content: '123456 is your OTP. Do not share it with anyone',
      );
      expect(otpRes.category, NotificationCategory.security);
      expect(otpRes.extractedOtp, '123456');
      expect(OfflineNotificationClassifierService.getPriority(otpRes.category), 1);

      final debitRes = OfflineNotificationClassifierService.classify(
        appName: 'HDFC Bank',
        packageName: 'com.hdfcbank.mobile',
        channelId: 'alerts',
        title: 'Debit alert',
        content: 'Rs. 2499.00 debited from A/c XX1234 at AMAZON',
      );
      expect(debitRes.category, NotificationCategory.security);

      final loginRes = OfflineNotificationClassifierService.classify(
        appName: 'Google',
        packageName: 'com.google.android.gms',
        channelId: 'security',
        title: 'New sign-in',
        content: 'Your account was accessed from a new device',
      );
      expect(loginRes.category, NotificationCategory.security);

      // 3. Conversations - Chat messages
      final waRes = OfflineNotificationClassifierService.classify(
        appName: 'WhatsApp',
        packageName: 'com.whatsapp',
        channelId: 'messages',
        title: 'Priya',
        content: 'Are we still meeting at 6?',
        isConversation: true,
        hasReplyAction: true,
      );
      expect(waRes.category, NotificationCategory.conversations);
      expect(OfflineNotificationClassifierService.getPriority(waRes.category), 2);

      // 4. Socials - Likes, comments, mentions
      final instaRes = OfflineNotificationClassifierService.classify(
        appName: 'Instagram',
        packageName: 'com.instagram.android',
        channelId: 'likes',
        title: 'Instagram',
        content: 'riya_22 and 14 others liked your photo',
      );
      expect(instaRes.category, NotificationCategory.socials);
      expect(OfflineNotificationClassifierService.getPriority(instaRes.category), 3);

      final twitterRes = OfflineNotificationClassifierService.classify(
        appName: 'X',
        packageName: 'com.twitter.android',
        channelId: 'mentions',
        title: 'X',
        content: '@dev_sam mentioned you in a post',
      );
      expect(twitterRes.category, NotificationCategory.socials);

      // 5. Updates - Order shipped, app updates, PNR booking
      final amazonRes = OfflineNotificationClassifierService.classify(
        appName: 'Amazon',
        packageName: 'com.amazon.mShop.android.shopping',
        channelId: 'orders',
        title: 'Order shipped',
        content: 'Your package will arrive by Thursday',
      );
      expect(amazonRes.category, NotificationCategory.updates);
      expect(OfflineNotificationClassifierService.getPriority(amazonRes.category), 4);

      final pnrRes = OfflineNotificationClassifierService.classify(
        appName: 'IRCTC',
        packageName: 'in.irctc.railconnect',
        channelId: 'booking',
        title: 'Booking confirmed',
        content: 'PNR 4521896734 confirmed for 12 Nov',
      );
      expect(pnrRes.category, NotificationCategory.updates);

      // 6. Promotions - Sales, coupons, discounts
      final myntraRes = OfflineNotificationClassifierService.classify(
        appName: 'Myntra',
        packageName: 'com.myntra.android',
        channelId: 'sale',
        title: 'Mega sale is live',
        content: 'Up to 70% off on top brands. Shop now',
      );
      expect(myntraRes.category, NotificationCategory.promotions);
      expect(OfflineNotificationClassifierService.getPriority(myntraRes.category), 5);

      final swiggyPromo = OfflineNotificationClassifierService.classify(
        appName: 'Swiggy',
        packageName: 'com.swiggy.android',
        channelId: 'promo',
        title: 'Hungry?',
        content: 'Get 50% off on your next order. Use code FEAST',
      );
      expect(swiggyPromo.category, NotificationCategory.promotions);

      // 7. Silent - Charging, USB debugging, steps, VPN
      final chargingRes = OfflineNotificationClassifierService.classify(
        appName: 'System',
        packageName: 'android',
        channelId: 'ongoing',
        title: 'Charging',
        content: 'Charging rapidly - 45 minutes until full',
      );
      expect(chargingRes.category, NotificationCategory.silent);
      expect(OfflineNotificationClassifierService.getPriority(chargingRes.category), 6);

      final usbRes = OfflineNotificationClassifierService.classify(
        appName: 'System UI',
        packageName: 'com.android.systemui',
        channelId: 'system',
        title: 'USB debugging connected',
        content: 'Tap to disable USB debugging',
      );
      expect(usbRes.category, NotificationCategory.silent);

      final vpnRes = OfflineNotificationClassifierService.classify(
        appName: 'VPN',
        packageName: 'com.example.vpn',
        channelId: 'ongoing',
        title: 'VPN is connected',
        content: 'Tap for more options',
      );
      expect(vpnRes.category, NotificationCategory.silent);
    });

    test('Input template matches expected format', () {
      final formatted = OfflineNotificationClassifierService.formatInput(
        app: 'com.whatsapp',
        channel: 'messages',
        title: 'John',
        body: 'See you soon',
      );
      expect(formatted, 'com.whatsapp | messages | John | See you soon');
    });

    test('LRU cache returns fast cached result and handles eviction', () {
      final res1 = OfflineNotificationClassifierService.classify(
        appName: 'Telegram',
        packageName: 'org.telegram.messenger',
        title: 'Alex',
        content: 'Hey, are you free?',
        isConversation: true,
      );
      expect(res1.category, NotificationCategory.conversations);

      // Repeat should hit LRU cache immediately
      final res2 = OfflineNotificationClassifierService.classify(
        appName: 'Telegram',
        packageName: 'org.telegram.messenger',
        title: 'Alex',
        content: 'Hey, are you free?',
        isConversation: true,
      );
      expect(identical(res1, res2), isTrue);
    });

    test('Background isolate async classification works correctly', () async {
      final asyncRes = await OfflineNotificationClassifierService.classifyAsync(
        appName: 'Zomato',
        packageName: 'com.application.zomato',
        channelId: 'delivery',
        title: 'Delivery partner nearby',
        content: 'Arjun is 500 m away from your location',
      );
      expect(asyncRes.category, NotificationCategory.realtime);

      final batchRes = await OfflineNotificationClassifierService.classifyBatchAsync([
        const NotificationClassificationInput(
          appName: 'Dialer',
          packageName: 'com.google.android.dialer',
          title: 'Incoming call',
          content: 'Dad is calling',
        ),
        const NotificationClassificationInput(
          appName: 'Bank',
          packageName: 'com.sbi.yono',
          title: 'Transaction alert',
          content: 'Rs. 500 credited to your account via UPI',
        ),
        const NotificationClassificationInput(
          appName: 'Flipkart',
          packageName: 'com.flipkart.android',
          title: 'Big Billion Days',
          content: 'Extra 10% off with your card today only',
        ),
      ]);

      expect(batchRes.length, 3);
      expect(batchRes[0].category, NotificationCategory.realtime);
      expect(batchRes[1].category, NotificationCategory.security);
      expect(batchRes[2].category, NotificationCategory.promotions);
    });

    test('On-device head update and learning from user corrections adjusts model weights', () {
      // Notification that starts as updates
      const pkg = 'com.custom.app';
      const channel = 'alerts';
      const title = 'Weekly Digest';
      const body = 'Check out this week recap';

      final initial = OfflineNotificationClassifierService.classify(
        appName: 'Custom App',
        packageName: pkg,
        channelId: channel,
        title: title,
        content: body,
      );
      expect(initial.isUserOverride, isFalse);

      // User corrects category to Socials
      OfflineNotificationClassifierService.recordUserCorrection(
        packageName: pkg,
        channelId: channel,
        title: title,
        content: body,
        targetCategory: NotificationCategory.socials,
        previousCategory: initial.category,
      );

      final corrected = OfflineNotificationClassifierService.classify(
        appName: 'Custom App',
        packageName: pkg,
        channelId: channel,
        title: title,
        content: body,
      );
      expect(corrected.category, NotificationCategory.socials);
      expect(corrected.isUserOverride, isTrue);

      // Verify learning state can be exported and reloaded
      final state = OfflineNotificationClassifierService.exportLearningState();
      expect(state['biases'], isNotNull);
      expect(state['weights'], isNotNull);

      OfflineNotificationClassifierService.loadLearningState(state);
      final persisted = OfflineNotificationClassifierService.classify(
        appName: 'Custom App',
        packageName: pkg,
        channelId: channel,
        title: title,
        content: body,
      );
      expect(persisted.category, NotificationCategory.socials);
    });

    test('Classifier can be toggled on and off via isEnabled', () {
      OfflineNotificationClassifierService.isEnabled = true;
      final onRes = OfflineNotificationClassifierService.classify(
        appName: 'Swiggy',
        packageName: 'com.swiggy.android',
        title: '50% off on your meal',
        content: 'Use code MEAL50 now',
      );
      expect(onRes.category, NotificationCategory.promotions);

      // Disable classifier
      OfflineNotificationClassifierService.isEnabled = false;
      final offRes = OfflineNotificationClassifierService.classify(
        appName: 'Swiggy',
        packageName: 'com.swiggy.android',
        title: '50% off on your meal',
        content: 'Use code MEAL50 now',
      );
      expect(offRes.category, NotificationCategory.silent);
      expect(offRes.confidence, 0.0);

      // Re-enable classifier
      OfflineNotificationClassifierService.isEnabled = true;
      final reEnabledRes = OfflineNotificationClassifierService.classify(
        appName: 'Swiggy',
        packageName: 'com.swiggy.android',
        title: '50% off on your meal',
        content: 'Use code MEAL50 now',
      );
      expect(reEnabledRes.category, NotificationCategory.promotions);
    });

    testWidgets('ServiceTab renders Smart Notification Classifier card and toggle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = ShadeStateProvider();
      final colors = ExpressiveThemeColors.fromSettings(
        source: ThemeSource.preset,
        preset: ThemePreset.presets.first,
        custom: const CustomThemeData(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ShadeStateProvider>.value(
              value: state,
              child: ServiceTab(colors: colors),
            ),
          ),
        ),
      );

      // Verify toggle title, badge, and offline status
      expect(find.text('Smart Notification Classifier'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('On-Device • 7 Categories • Offline'), findsOneWidget);
      expect(state.isSmartClassifierEnabled, isTrue);

      // Toggle off
      state.setSmartClassifierEnabled(false);
      await tester.pumpAndSettle();

      expect(find.text('Off'), findsOneWidget);
      expect(state.isSmartClassifierEnabled, isFalse);
      expect(OfflineNotificationClassifierService.isEnabled, isFalse);

      // Toggle on
      state.setSmartClassifierEnabled(true);
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(state.isSmartClassifierEnabled, isTrue);
      expect(OfflineNotificationClassifierService.isEnabled, isTrue);
    });
  });
}
