import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import './screens/login.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: MaterialTheme(TextTheme.of(context)).light(),
      home: Scaffold(body: Center(child: LoginScreen())),
    );
  }
}
