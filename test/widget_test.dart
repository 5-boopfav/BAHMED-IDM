import 'package:flutter_test/flutter_test.dart';
import 'package:bahmed_idm/main.dart';

void main() {
  testWidgets('BAHMED IDM home screen loads', (tester) async {
    await tester.pumpWidget(const BahmedIDM());

    expect(find.text('BAHMED IDM'), findsWidgets);
    expect(find.text('مدير التنزيلات'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('التنزيلات'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}
