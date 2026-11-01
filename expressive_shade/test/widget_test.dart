import 'package:flutter_test/flutter_test.dart';
import 'package:expressive_shade/main.dart';

void main() {
  testWidgets('ExpressiveShade smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpressiveShadeApp());
    expect(find.byType(ExpressiveShadeApp), findsOneWidget);
  });
}
