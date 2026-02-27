import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/login_page.dart';

enum _Screen { loading, login, app }

class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  _Screen _screen = _Screen.loading;
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();

    final session = Supabase.instance.client.auth.currentSession;
    _screen = session != null ? _Screen.app : _Screen.login;

    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state.event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.initialSession:
            _screen = state.session != null ? _Screen.app : _Screen.login;
            break;
          case AuthChangeEvent.signedOut:
          case AuthChangeEvent.userDeleted:
            _screen = _Screen.login;
            break;
          default:
            _screen = state.session != null ? _Screen.app : _Screen.login;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case _Screen.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case _Screen.login:
        return Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
        );
      case _Screen.app:
        return widget.child;
    }
  }
}
