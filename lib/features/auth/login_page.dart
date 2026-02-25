import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ── Validatori ────────────────────────────────────────────────────────────

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email obbligatoria';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Inserisci una email valida';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password obbligatoria';
    if (v.length < 6) return 'Almeno 6 caratteri';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Conferma la password';
    if (v != _passCtrl.text) return 'Le password non coincidono';
    return null;
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
    _formKey.currentState?.reset();
    _confirmCtrl.clear();
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  // ── Azione principale ─────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_mode == _Mode.login) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        // AuthGate gestisce la navigazione automaticamente
      } else {
        final res = await Supabase.instance.client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        // session == null → Supabase ha email confirmation attiva
        if (mounted && res.session == null) {
          setState(() => _signUpEmailSent = true);
        }
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _translateError(e.message));
    } catch (_) {
      if (mounted) setState(() => _error = 'Errore imprevisto. Riprova.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Dialog password dimenticata ───────────────────────────────────────────

  void _showForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
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
              controller: emailCtrl,
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
              final email = emailCtrl.text.trim();
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth
                    .resetPasswordForEmail(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Email di reset inviata! Controlla la posta.'),
                    ),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Errore nell'invio. Riprova."),
                    ),
                  );
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
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Offstage(
                    offstage: _signUpEmailSent,
                    child: _buildForm(),
                  ),
                  if (_signUpEmailSent) _buildEmailConfirmation(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form principale ───────────────────────────────────────────────────────

  Widget _buildForm() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header branding
        _buildHeader(colorScheme, textTheme),
        const SizedBox(height: 32),

        // Mode toggle
        _buildModeToggle(),
        const SizedBox(height: 24),

        // Form fields
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Email
              TextFormField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                onFieldSubmitted: (_) => _passFocus.requestFocus(),
                validator: _validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passCtrl,
                focusNode: _passFocus,
                obscureText: _obscurePass,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: _mode == _Mode.login
                    ? TextInputAction.done
                    : TextInputAction.next,
                onFieldSubmitted: (_) {
                  if (_mode == _Mode.login) {
                    _submit();
                  } else {
                    _confirmFocus.requestFocus();
                  }
                },
                validator: _validatePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),

              // Conferma password (solo signup) — animato
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Offstage(
                  offstage: _mode != _Mode.signup,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextFormField(
                      controller: _confirmCtrl,
                      focusNode: _confirmFocus,
                      obscureText: _obscureConfirm,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: _validateConfirm,
                      decoration: InputDecoration(
                        labelText: 'Conferma password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bottone principale
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

        // Password dimenticata (solo login)
        if (_mode == _Mode.login) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _loading ? null : _showForgotPassword,
              child: const Text('Password dimenticata?'),
            ),
          ),
        ],

        // Errore
        if (_error != null) ...[
          const SizedBox(height: 16),
          _buildErrorBox(Theme.of(context).colorScheme),
        ],
      ],
    );
  }

  // ── Header branding ───────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.fitness_center_rounded,
            size: 40,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'App Palestra',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Il tuo compagno di allenamento',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── Mode toggle ───────────────────────────────────────────────────────────

  Widget _buildModeToggle() {
    return SegmentedButton<_Mode>(
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
    );
  }

  // ── Error box ─────────────────────────────────────────────────────────────

  Widget _buildErrorBox(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  // ── Schermata conferma email ──────────────────────────────────────────────

  Widget _buildEmailConfirmation() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Icon(
          Icons.mark_email_unread_outlined,
          size: 72,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Controlla la tua email',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Abbiamo inviato un link di conferma a',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          _emailCtrl.text.trim(),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Clicca il link nella mail per attivare il tuo account, poi torna qui ad accedere.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _signUpEmailSent = false;
            _mode = _Mode.login;
            _passCtrl.clear();
            _confirmCtrl.clear();
            _error = null;
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
