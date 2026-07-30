import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:munshi_mobile/copy/product_copy.dart';
import 'package:munshi_mobile/main.dart';

void main() {
  testWidgets('shows sign-in gate when vault locked', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MunshiMobileApp()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text(ProductCopy.guestAccessCta), findsOneWidget);
  });
}
