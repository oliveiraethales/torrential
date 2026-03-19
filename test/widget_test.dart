import 'package:flutter_test/flutter_test.dart';
import 'package:torrential/main.dart';

void main() {
  testWidgets('App starts and shows loading', (WidgetTester tester) async {
    await tester.pumpWidget(const TorrentialApp());
    expect(find.byType(TorrentialApp), findsOneWidget);
  });
}
