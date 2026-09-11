import 'package:flutter_test/flutter_test.dart';
import 'package:open_aamps/main.dart';

void main() {
  testWidgets('OpenAampsApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenAampsApp());
    expect(find.text('OpenAamps'), findsOneWidget);
  });
}
