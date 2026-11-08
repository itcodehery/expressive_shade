import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expressive_shade/features/notifications/notification_card.dart';
import 'package:expressive_shade/models/font_config.dart';
import 'package:expressive_shade/models/notification_model.dart';
import 'package:expressive_shade/models/notification_style.dart';
import 'package:expressive_shade/models/shade_theme.dart';
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
    test('NotificationStyle contains exactly the 5 distinct styles', () {
      expect(NotificationStyle.values.length, 5);
      expect(NotificationStyle.values, contains(NotificationStyle.android17));
      expect(NotificationStyle.values, contains(NotificationStyle.ios));
      expect(NotificationStyle.values, contains(NotificationStyle.oneui));
      expect(NotificationStyle.values, contains(NotificationStyle.compact));
      expect(NotificationStyle.values, contains(NotificationStyle.hyperOS));
    });

    test('Each style provides unique display name and description', () {
      final names = NotificationStyle.values.map((s) => s.displayName).toSet();
      expect(names.length, 5);

      expect(NotificationStyle.compact.displayName, 'Compact Mode');
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
  });
}
