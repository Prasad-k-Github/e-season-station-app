import 'package:flutter/material.dart';

import 'api.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = await StationApi.load();
  runApp(StationApp(api: api));
}

class StationApp extends StatelessWidget {
  final StationApi api;
  const StationApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Season Inspector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A2558)),
        useMaterial3: true,
      ),
      home: LoginScreen(api: api),
    );
  }
}
