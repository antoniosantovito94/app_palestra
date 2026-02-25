import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/login_page.dart';

class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.data?.session
            ?? Supabase.instance.client.auth.currentSession;
        // LoginPage è nel builder di MaterialApp.router, quindi sopra il
        // Navigator del router e senza Overlay disponibile. TextField richiede
        // un Overlay antenato per la selezione del testo → lo forniamo qui.
        if (session == null) {
          return Overlay(
            initialEntries: [
              OverlayEntry(builder: (_) => const LoginPage()),
            ],
          );
        }
        return child;
      },
    );
  }
}