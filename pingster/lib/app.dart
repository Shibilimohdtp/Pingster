import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class PingsterApp extends StatelessWidget {
  const PingsterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Pingster',
      theme: PingsterTheme.lightTheme,
      darkTheme: PingsterTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
