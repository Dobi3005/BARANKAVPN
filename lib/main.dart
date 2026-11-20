import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'services/tray.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.init();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(420, 760),
        minimumSize: Size(380, 640),
        center: true,
        title: 'Баранка VPN',
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
    await TrayService().init(state);
  }

  runApp(BarankaApp(state: state));
}

class BarankaApp extends StatelessWidget {
  final AppState state;
  const BarankaApp({super.key, required this.state});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Баранка VPN',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: HomeScreen(state: state),
      );
}
