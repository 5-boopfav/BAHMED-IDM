import 'package:flutter_test/flutter_test.dart';
import 'package:bahmed_idm/main.dart';

void main() {
  testWidgets(
    'BAHMED IDM displays its home screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(const BahmedIDM());

      expect(find.text('BAHMED IDM'), findsOneWidget);
      expect(find.text('مدير التنزيلات'), findsOneWidget);
    },
  );
}
