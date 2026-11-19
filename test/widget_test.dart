import 'package:flutter_test/flutter_test.dart';
import 'package:bahmed_idm/main.dart';

void main() {
  testWidgets('BAHMED IDM displays the home screen', (tester) async {
    await tester.pumpWidget(const BahmedIDM());

    expect(find.text('BAHMED IDM'), findsOneWidget);
    expect(find.text('مدير التنزيلات'), findsOneWidget);
    expect(find.text('التنزيلات'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('تنزيل جديد'), findsOneWidget);
  });

  testWidgets('Can switch between downloads and settings', (tester) async {
    await tester.pumpWidget(const BahmedIDM());

    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.text('مكان الحفظ'), findsOneWidget);

    await tester.tap(find.text('التنزيلات'));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد تنزيلات بعد'), findsOneWidget);
  });
}
