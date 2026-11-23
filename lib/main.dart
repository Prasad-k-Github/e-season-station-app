import 'package:flutter/material.dart';

import 'api.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

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
      theme: buildTheme(),
      home: LoginScreen(api: api),
    );
  }
}
