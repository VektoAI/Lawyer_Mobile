/// Sign-in gate — mobile client; auth against Render-hosted FastAPI + Supabase.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../copy/product_copy.dart';
import '../providers/app_providers.dart';
import '../router_refresh.dart';
import '../models/case_models.dart';
import '../services/auth_deep_link.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/login_hero_art.dart';
import 'vault_backup_ui.dart';

enum _AuthMode { login, signup }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _busy = false;
  String? _helpText;
  String? _recoveryKey;
  DateTime? _resendCooldownUntil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vault = ref.read(vaultStoreProvider);
      if (vault.hasLocalVault && !vault.isUnlocked) {
        setState(() =>
            _helpText = 'Enter your password to unlock cases on this device');
      }
      if (ApiConfig.isLocalDevApi) {
        setState(() => _helpText =
            'This build points at a local API (${ApiConfig.displayHost}) — '
                'it will not work on a phone unless you rebuild with your Render URL.');
      }
      final pending = ref.read(authDeepLinkProvider).pendingUri.value;
      if (pending != null) _handleAuthCallbackUri(pending);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _finishSession(Map<String, dynamic> r,
      {required bool demo, required String password}) async {
    final token = r['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await ref.read(authServiceProvider).saveSession(
            token: token,
            refreshToken: r['refresh_token'] as String?,
          );
    }
    final vault = ref.read(vaultStoreProvider);
    if (demo) {
      await vault.unlockDemo(
        saltB64: r['salt'] as String? ?? 'ZGVtbw1zYWx0LW11bnNoaS12YXVsdC0wMQ==',
        password: r['demo_password'] as String? ?? password,
      );
    } else {
      final uid = r['user_id'] as String? ?? 'local-user';
      final email = r['email'] as String? ?? _email.text.trim();
      final salt = r['salt'] as String?;
      final name = (r['display_name'] as String?)?.trim() ?? _name.text.trim();
      final profile = name.isNotEmpty
          ? ChamberProfile(
              name: name,
              initials: name
                  .split(RegExp(r'\s+'))
                  .where((w) => w.isNotEmpty)
                  .map((w) => w[0])
                  .take(2)
                  .join()
                  .toUpperCase())
          : null;

      if (vault.hasLocalVault) {
        try {
          await vault.unlockWithPassword(password);
        } catch (e) {
          if (salt != null && salt.isNotEmpty) {
            final recovery = await vault.initNewVault(
              uid: uid,
              email: email,
              password: password,
              saltB64: salt,
              initialProfile: profile,
            );
            if (mounted) await showRecoveryKeyDialog(context, recovery);
          } else {
            rethrow;
          }
        }
      } else if (salt != null && salt.isNotEmpty) {
        final recovery = await vault.initNewVault(
          uid: uid,
          email: email,
          password: password,
          saltB64: salt,
          initialProfile: profile,
        );
        if (mounted) await showRecoveryKeyDialog(context, recovery);
      } else {
        throw StateError(
            'Account setup incomplete — contact support or register again');
      }
    }
    notifyRouterVaultChanged();
    if (!mounted) return;
    _toast(demo ? ProductCopy.guestSessionStarted : 'Welcome back');
    context.go('/cases');
  }

  Future<Map<String, dynamic>> _enrichSession(Map<String, dynamic> r) async {
    if (r['salt'] != null &&
        (r['salt'] as String).isNotEmpty &&
        r['user_id'] != null) {
      return r;
    }
    final token = r['token'] as String?;
    if (token == null || token.isEmpty) return r;
    await ref.read(authServiceProvider).saveSession(
          token: token,
          refreshToken: r['refresh_token'] as String?,
        );
    final me = await ref.read(apiClientProvider).get('/me');
    return {
      ...r,
      'user_id': me['id']?.toString(),
      'email': me['email'],
      'salt': me['salt'],
      'display_name': me['display_name'],
    };
  }

  Future<void> _handleAuthCallbackUri(Uri uri) async {
    ref.read(authDeepLinkProvider).pendingUri.value = null;
    if (_busy) return;
    setState(() => _busy = true);
    final auth = ref.read(authServiceProvider);
    try {
      var r = await auth.sessionFromAuthCallbackUri(uri);
      if (r == null) return;
      r = await _enrichSession(r);
      final pending = await auth.readPendingSignup();
      final password = (pending?['password'] as String?) ?? _password.text;
      if (pending != null) {
        final em = pending['email'] as String?;
        if (em != null && em.isNotEmpty) _email.text = em;
        final dn = pending['display_name'] as String?;
        if (dn != null && dn.isNotEmpty) _name.text = dn;
      }
      if (password.isEmpty) {
        setState(() {
          _mode = _AuthMode.login;
          _helpText = ProductCopy.emailVerifiedSignIn;
        });
        _toast(ProductCopy.emailVerifiedSignIn);
        return;
      }
      await _finishSession(r, demo: false, password: password);
      await auth.clearPendingSignup();
      _toast(ProductCopy.emailVerifiedDone);
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Verification link could not be completed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _afterAuth(Map<String, dynamic> r, {required bool demo}) async {
    await _finishSession(r, demo: demo, password: _password.text);
  }

  Future<void> _submit() async {
    final email = _email.text.trim().toLowerCase();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      _toast('Email and password required');
      return;
    }
    if (_mode == _AuthMode.signup && password.length < 8) {
      _toast('Password must be at least 8 characters');
      return;
    }

    setState(() => _busy = true);
    final auth = ref.read(authServiceProvider);
    try {
      if (_mode == _AuthMode.signup) {
        final r = await auth.signup(
          email: email,
          password: password,
          displayName: _name.text.trim(),
          phone: _phone.text.trim(),
        );
        final needsConfirm =
            r['needs_email_confirm'] == true && r['token'] == null;
        if (needsConfirm) {
          setState(() {
            _mode = _AuthMode.login;
            _helpText = ProductCopy.emailVerifyBody;
            _recoveryKey = null;
          });
          _toast(ProductCopy.emailVerifySent);
          return;
        }
        if (r['token'] != null) {
          await _finishSession(r, demo: false, password: password);
        }
        return;
      }

      final r = await auth.login(email, password);
      await _afterAuth(r, demo: r['demo'] == true);
    } on AuthException catch (e) {
      _toast(e.message);
    } on StateError catch (e) {
      // Local vault/crypto errors (e.g. wrong password) — not a network
      // failure, so don't blame the server for it.
      _toast(e.message);
    } catch (e) {
      _toast(
          'Could not reach the server (${ApiConfig.displayHost}). Check network or API URL.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _demo() async {
    setState(() {
      _busy = true;
      _mode = _AuthMode.login;
      _helpText = null;
    });
    try {
      Map<String, dynamic> r;
      try {
        r = await ref.read(authServiceProvider).demoLogin();
      } catch (_) {
        r = {
          'token': 'demo-local-vault',
          'demo': true,
          'user_id': 'demo-local'
        };
      }
      await _afterAuth(r, demo: true);
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast(
          'Demo unavailable — check API at ${ApiConfig.displayHost} or use offline demo fallback');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recoverWithKey() async {
    final vault = ref.read(vaultStoreProvider);
    final controller = TextEditingController();
    final key = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recover with your recovery key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This unlocks the cases already saved on this device, using the '
              'recovery key you saved when you first signed up. It does not '
              'reset your account password.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(labelText: 'Recovery key'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Recover'),
          ),
        ],
      ),
    );
    if (key == null || key.isEmpty) return;

    setState(() => _busy = true);
    try {
      await vault.unlockWithRecovery(key);
      notifyRouterVaultChanged();
      if (!mounted) return;
      _toast('Cases recovered on this device.');
      context.go('/cases');
    } catch (_) {
      _toast(
        vault.hasLocalVault
            ? 'That recovery key did not match this device.'
            : 'No cases saved on this device yet — recovery only restores an existing local vault.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _resendCooldown = Duration(seconds: 45);

  bool get _resendOnCooldown =>
      _resendCooldownUntil != null &&
      DateTime.now().isBefore(_resendCooldownUntil!);

  Future<void> _resendConfirm() async {
    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty) {
      _toast('Enter your email first');
      return;
    }
    if (_resendOnCooldown) {
      _toast('Already sent — give it a minute before trying again');
      return;
    }
    // Supabase's built-in mailer has a low per-address rate limit; repeated
    // taps can silently burn through it with no error surfaced to the app,
    // so throttle client-side before it ever gets that far.
    setState(() => _resendCooldownUntil = DateTime.now().add(_resendCooldown));
    try {
      await ref.read(authServiceProvider).resendConfirmation(email);
      _toast(ProductCopy.resendVerificationSent);
    } on AuthException catch (e) {
      setState(() => _resendCooldownUntil = null);
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Uri?>(
      authDeepLinkProvider.select((n) => n.pendingUri.value),
      (_, uri) {
        if (uri != null) _handleAuthCallbackUri(uri);
      },
    );

    final isSignup = _mode == _AuthMode.signup;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2E27), Color(0xFF163D34), Color(0xFF1A4538)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: MunshiColors.brassGold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                MunshiColors.brassGold.withValues(alpha: 0.5)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('⚖', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Case Vault',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'Fraunces',
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            'Never miss a hearing date',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 2,
                child: Center(
                    child: LoginHeroArt(
                        key: ValueKey(MediaQuery.sizeOf(context).width))),
              ),
              Expanded(
                flex: 5,
                child: Material(
                  color: MunshiColors.ivory,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  clipBehavior: Clip.antiAlias,
                  elevation: 8,
                  shadowColor: Colors.black26,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<_AuthMode>(
                          segments: const [
                            ButtonSegment(
                                value: _AuthMode.login, label: Text('Sign in')),
                            ButtonSegment(
                                value: _AuthMode.signup,
                                label: Text('Register')),
                          ],
                          selected: {_mode},
                          onSelectionChanged: _busy
                              ? null
                              : (s) => setState(() {
                                    _mode = s.first;
                                    if (_mode == _AuthMode.signup) {
                                      _helpText = ProductCopy.emailVerifyBody;
                                    } else {
                                      _helpText = vaultUnlockHint(ref);
                                    }
                                  }),
                          style: ButtonStyle(
                            foregroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              return MunshiColors.inkGreen;
                            }),
                            backgroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return MunshiColors.inkGreen;
                              }
                              return Colors.transparent;
                            }),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isSignup
                              ? 'Create your chamber account'
                              : 'Welcome back',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: MunshiColors.inkGreen,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your case data is encrypted on this device and never leaves it. Our servers only handle sign-in and public court lookups.',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.35),
                        ),
                        if (_helpText != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6EEDD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: MunshiColors.brassGold
                                      .withValues(alpha: 0.35)),
                            ),
                            child: Text(_helpText!,
                                style:
                                    const TextStyle(fontSize: 13, height: 1.4)),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email
                          ],
                          decoration:
                              const InputDecoration(labelText: 'Work email'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          onSubmitted: (_) => _busy ? null : _submit(),
                        ),
                        if (!isSignup)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _busy ? null : _recoverWithKey,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        if (isSignup) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _name,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                                labelText: 'Advocate name'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                            decoration: const InputDecoration(
                                labelText: 'Mobile (WhatsApp reminders)'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: Text(_busy
                              ? 'Please wait…'
                              : (isSignup ? 'Create account' : 'Sign in')),
                        ),
                        if (!isSignup) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: (_busy || _resendOnCooldown)
                                ? null
                                : _resendConfirm,
                            child: Text(
                              _resendOnCooldown
                                  ? 'Sent — check your inbox'
                                  : ProductCopy.resendVerification,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(color: Colors.grey.shade400)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                            ),
                            Expanded(
                                child: Divider(color: Colors.grey.shade400)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _busy ? null : _demo,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(ProductCopy.guestAccessCta),
                              const SizedBox(height: 2),
                              Text(
                                ProductCopy.guestAccessHint,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'API: ${ApiConfig.displayHost}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () => context.push('/privacy'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                            child: Text('Privacy Policy',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                          ),
                        ),
                        if (_recoveryKey != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6EEDD),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_recoveryKey!,
                                style: const TextStyle(
                                    fontSize: 12.5, height: 1.45)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? vaultUnlockHint(WidgetRef ref) {
  final vault = ref.read(vaultStoreProvider);
  if (vault.hasLocalVault && !vault.isUnlocked) {
    return 'Enter your password to unlock cases on this device';
  }
  return null;
}
