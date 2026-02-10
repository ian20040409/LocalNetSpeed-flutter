// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:localnetspeed_flutter/ui/content_view.dart';
import 'package:localnetspeed_flutter/view_models/content_view_model.dart';

void main() {
  testWidgets('ContentView smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContentViewModel()),
        ],
        child: const MaterialApp(
          home: ContentView(),
        ),
      ),
    );

    // Verify that platform specific UI is shown
    expect(find.text('LocalNetSpeed'), findsOneWidget);
    expect(find.text('開始測試'), findsNothing); // Because default is Server mode
    expect(find.text('啟動伺服器'), findsOneWidget);
    expect(find.byIcon(Icons.network_wifi), findsOneWidget);
  });
}
