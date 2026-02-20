import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? error;

 String? _validateInputs() {
  final email = emailCtrl.text.trim();
  final pass = passCtrl.text;

  if (email.isEmpty) return 'Inserisci una email.';
  // check minimo (non perfetto, ma sufficiente)
  if (!email.contains('@')) return 'Email non valida.';
  if (pass.isEmpty) return 'Inserisci una password.';
  if (pass.length < 6) return 'La password deve avere almeno 6 caratteri.';
  return null;
}

Future<void> _signIn() async {
  final validationError = _validateInputs();
  if (validationError != null) {
    setState(() => error = validationError);
    return;
  }

  setState(() { loading = true; error = null; });
  try {
    await Supabase.instance.client.auth.signInWithPassword(
      email: emailCtrl.text.trim(),
      password: passCtrl.text,
    );
  } on AuthException catch (e) {
    setState(() => error = e.message);
  } catch (e) {
    setState(() => error = 'Errore: $e');
  } finally {
    if (mounted) setState(() => loading = false);
  }
}

Future<void> _signUp() async {
  final validationError = _validateInputs();
  if (validationError != null) {
    setState(() => error = validationError);
    return;
  }

  setState(() { loading = true; error = null; });
  try {
    await Supabase.instance.client.auth.signUp(
      email: emailCtrl.text.trim(),
      password: passCtrl.text,
    );
    // se hai Email confirmation ON: non entrerai loggato finché non confermi la mail
  } on AuthException catch (e) {
    setState(() => error = e.message);
  } catch (e) {
    setState(() => error = 'Errore: $e');
  } finally {
    if (mounted) setState(() => loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: loading ? null : _signUp,
                            child: const Text('Registrati'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: loading ? null : _signIn,
                            child: loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Accedi'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}