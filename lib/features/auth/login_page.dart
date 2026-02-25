import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Blocca le sostituzioni multi-carattere inviate dall'IME senza una selezione
// esplicita dell'utente. Su Android (MIUI, Gboard gesture, ecc.) la tastiera
// può sostituire il testo corrente con una parola intera in un singolo evento,
// causando il ripristino del testo già cancellato.
// Regola: se il cursore è collassato (nessuna selezione), è ammessa al massimo
// 1 carattere aggiunto per evento. Se c'è una selezione (es. "seleziona tutto"
// + incolla), la modifica è sempre permessa → il copia/incolla funziona.
class _SingleCharInputFormatter extends TextInputFormatter {
  const _SingleCharInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Cancellazioni e selezioni → sempre permesse
    if (newValue.text.length <= oldValue.text.length) return newValue;
    // L'utente aveva una selezione (incolla / sostituisci selezione) → permessa
    if (!oldValue.selection.isCollapsed) return newValue;
    // Aggiunta di esattamente 1 carattere → normale digitazione → permessa
    if (newValue.text.length == oldValue.text.length + 1) return newValue;
    // Più caratteri aggiunti con cursore collassato → sostituzione IME → bloccata
    return oldValue;
  }
}

enum _Mode { login, signup }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  _Mode _mode = _Mode.login;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _signUpEmailSent = false;
  String? _globalError;

  // Valori dei campi
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _confirmedEmail = '';

  // Errori di validazione per ogni campo
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ── Validazione ──────────────────────────────────────────────────────────

  bool _validate() {
    String? emailErr;
    String? passErr;
    String? confirmErr;

    if (_email.trim().isEmpty) {
      emailErr = 'Email obbligatoria';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(_email.trim())) {
      emailErr = 'Inserisci una email valida';
    }

    if (_password.isEmpty) {
      passErr = 'Password obbligatoria';
    } else if (_password.length < 6) {
      passErr = 'Almeno 6 caratteri';
    }

    if (_mode == _Mode.signup) {
      if (_confirmPassword.isEmpty) {
        confirmErr = 'Conferma la password';
      } else if (_confirmPassword != _password) {
        confirmErr = 'Le password non coincidono';
      }
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
      _confirmError = confirmErr;
    });

    return emailErr == null && passErr == null && confirmErr == null;
  }

  // ── Traduzione errori Supabase ────────────────────────────────────────────

  String _translateError(String msg) {
    if (msg.contains('Invalid login credentials')) {
      return 'Email o password non corretti';
    }
    if (msg.contains('User already registered')) {
      return 'Email già registrata. Prova ad accedere.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Conferma prima la tua email';
    }
    if (msg.contains('Password should be')) {
      return 'Password troppo debole (min. 6 caratteri)';
    }
    if (msg.contains('rate limit')) {
      return 'Troppi tentativi. Attendi qualche minuto.';
    }
    return msg;
  }

  // ── Cambio modalità ───────────────────────────────────────────────────────

  void _switchMode(_Mode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _email = '';
      _password = '';
      _confirmPassword = '';
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _globalError = null;
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() {
      _loading = true;
      _globalError = null;
    });
    try {
      if (_mode == _Mode.login) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _email.trim(),
          password: _password,
        );
      } else {
        _confirmedEmail = _email.trim();
        final res = await Supabase.instance.client.auth.signUp(
          email: _email.trim(),
          password: _password,
        );
        if (mounted && res.session == null) {
          setState(() => _signUpEmailSent = true);
        }
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _globalError = _translateError(e.message));
    } catch (_) {
      if (mounted) setState(() => _globalError = 'Errore imprevisto. Riprova.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Dialog password dimenticata ───────────────────────────────────────────

  void _showForgotPassword() {
    final ctrl = TextEditingController(text: _email.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reimposta password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inserisci la tua email e ti invieremo un link per reimpostare la password.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () async {
              final email = ctrl.text.trim();
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth
                    .resetPasswordForEmail(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Email di reset inviata! Controlla la posta.'),
                  ));
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Errore nell'invio. Riprova."),
                  ));
                }
              }
            },
            child: const Text('Invia link'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _signUpEmailSent
                  ? _buildConfirmScreen()
                  : _buildLoginForm(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Branding ──
        Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 40,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'App Palestra',
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Il tuo compagno di allenamento',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ── Toggle login / registrati ──
        SegmentedButton<_Mode>(
          segments: const [
            ButtonSegment(
              value: _Mode.login,
              label: Text('Accedi'),
              icon: Icon(Icons.login_rounded),
            ),
            ButtonSegment(
              value: _Mode.signup,
              label: Text('Registrati'),
              icon: Icon(Icons.person_add_outlined),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => _switchMode(s.first),
        ),
        const SizedBox(height: 24),

        // ── Email ──
        TextField(
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          // Blocca sostituzioni IME multi-carattere (bug MIUI / Gboard gesture).
          // Permette ancora incolla tramite "seleziona tutto → incolla".
          inputFormatters: const [_SingleCharInputFormatter()],
          onChanged: (v) {
            _email = v;
            if (_emailError != null) setState(() => _emailError = null);
          },
          onSubmitted: (_) => _passFocus.requestFocus(),
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _emailError,
          ),
        ),
        const SizedBox(height: 16),

        // ── Password ──
        TextField(
          focusNode: _passFocus,
          obscureText: _obscurePass,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction:
              _mode == _Mode.login ? TextInputAction.done : TextInputAction.next,
          onChanged: (v) {
            _password = v;
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          onSubmitted: (_) {
            if (_mode == _Mode.login) {
              _submit();
            } else {
              _confirmFocus.requestFocus();
            }
          },
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            errorText: _passwordError,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),

        // ── Conferma password (solo signup) ──
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _mode == _Mode.signup
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextField(
                    focusNode: _confirmFocus,
                    obscureText: _obscureConfirm,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onChanged: (v) {
                      _confirmPassword = v;
                      if (_confirmError != null) {
                        setState(() => _confirmError = null);
                      }
                    },
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Conferma password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      errorText: _confirmError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),

        // ── Bottone principale ──
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _mode == _Mode.login ? 'Accedi' : 'Crea account',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),

        // ── Password dimenticata ──
        if (_mode == _Mode.login) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _loading ? null : _showForgotPassword,
              child: const Text('Password dimenticata?'),
            ),
          ),
        ],

        // ── Errore globale (Supabase) ──
        if (_globalError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: cs.onErrorContainer, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _globalError!,
                    style: TextStyle(color: cs.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Schermata conferma email ──────────────────────────────────────────────

  Widget _buildConfirmScreen() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Icon(Icons.mark_email_unread_outlined, size: 72, color: cs.primary),
        const SizedBox(height: 24),
        Text(
          'Controlla la tua email',
          textAlign: TextAlign.center,
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Abbiamo inviato un link di conferma a',
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          _confirmedEmail,
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Clicca il link nella mail per attivare il tuo account, poi torna qui ad accedere.',
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _signUpEmailSent = false;
            _mode = _Mode.login;
            _email = '';
            _password = '';
            _confirmPassword = '';
            _confirmedEmail = '';
            _globalError = null;
          }),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Torna al login'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
