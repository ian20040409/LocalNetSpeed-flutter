import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/content_view.dart';
import 'view_models/content_view_model.dart';

void main() {
  runApp(const LocalNetSpeedApp());
}

class LocalNetSpeedApp extends StatelessWidget {
  const LocalNetSpeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContentViewModel()),
      ],
      child: MaterialApp(
        title: 'LocalNetSpeed',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS Grouped Background color approx
          cardColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF2F2F7),
            scrolledUnderElevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          cardColor: const Color(0xFF1C1C1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            scrolledUnderElevation: 0,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const ContentView(),
      ),
    );
  }
}