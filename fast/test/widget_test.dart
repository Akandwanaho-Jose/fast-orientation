import 'package:fast/core/theme/fast_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FAST brand shell renders with the production title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        title: FastBrand.appTitle,
        theme: FastBrand.theme(),
        home: const Scaffold(body: Text(FastBrand.shortName)),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.title, FastBrand.appTitle);
    expect(app.theme?.colorScheme.primary, FastBrand.primary);
    expect(find.text(FastBrand.shortName), findsOneWidget);
  });
}
