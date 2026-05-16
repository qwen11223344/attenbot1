import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/home_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, data) async {
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  runApp(const AttendBotApp());
}

class AttendBotApp extends StatelessWidget {
  const AttendBotApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AttendBot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F7F2),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
