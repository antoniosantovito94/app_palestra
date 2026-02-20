import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'App Palestra',
      routerConfig: appRouter,
      builder: (context, child) => AuthGate(child: child ?? const SizedBox()),
    );
  }
}