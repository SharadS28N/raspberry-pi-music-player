import 'package:flutter/material.dart';
import '../../repositories/auth_repository.dart';
import '../../services/settings_service.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final bool isRootGate;

  const LoginView({
    super.key,
    this.onLoginSuccess,
    this.isRootGate = false,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailCtrl = TextEditingController(text: 'evaluator@openaamps.ai');
  final _passCtrl = TextEditingController(text: 'password123');
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  Future<void> _handleEmailLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AppAuthRepository.instance.signInWithEmail(_emailCtrl.text, _passCtrl.text);
      if (mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeveloperLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailCtrl.text = 'developer@openaamps.ai';
      _passCtrl.text = 'OpenAamps2026!';
    });

    try {
      await AppAuthRepository.instance.signInAsDeveloper(
        email: 'developer@openaamps.ai',
        password: 'OpenAamps2026!',
        name: 'OpenAamps Core Developer',
      );
      if (mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEvaluatorLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AppAuthRepository.instance.signInAsEvaluator(name: 'Professor / Project Evaluator');
      if (mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AppAuthRepository.instance.signInWithGoogle();
      if (mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        if (msg.contains('SHA-1')) {
          _showGoogleSha1Dialog(msg);
        } else {
          setState(() => _errorMessage = msg);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGoogleSha1Dialog(String message) {
    final accent = SettingsService.instance.accentColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: accent, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Google Sign-In Setup',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To enable direct Google OAuth on Android, Google Play Services requires registering your debug/release SHA-1 fingerprint in Firebase Console:',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF121214),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const SelectableText(
                'SHA-1: 92:86:86:5C:7F:76:06:2A:4C:E2:36:2A:80:99:C9:45:8A:55:02:98\n'
                'Package: com.openaamps.open_aamps',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'In the meantime, you can sign in with the full-access Developer Account to test all player features, sync, and DSP!',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent == Colors.white ? Colors.white : accent,
              foregroundColor: accent == Colors.white ? Colors.black : Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleDeveloperLogin();
            },
            child: const Text('Sign in as Developer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = SettingsService.instance.accentColor;
    final canGoBack = Navigator.canPop(context) && !widget.isRootGate;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: canGoBack
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  // Spotify-Style Branding Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF181818),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: Center(
                      child: Icon(Icons.graphic_eq_rounded, color: accent, size: 28),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Log in to OpenAamps',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to synchronize music playback, acoustic preferences, and cloud playlists.',
                    style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email Input Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email address',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _emailCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'name@domain.com',
                        hintStyle: TextStyle(color: Color(0xFF727272)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Password Input Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _passCtrl,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleEmailLogin(),
                            decoration: const InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(color: Color(0xFF727272)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFFB3B3B3),
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Spotify-Style Primary Log In Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent == Colors.white ? Colors.white : accent,
                        foregroundColor: accent == Colors.white ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _handleEmailLogin,
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accent == Colors.white ? Colors.black : Colors.white,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Evaluator 1-Tap Access Button (Subtle Spotify Card)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                        backgroundColor: const Color(0xFF181818),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        '1-Tap Demo / Professor Login',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _isLoading ? null : _handleEvaluatorLogin,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Developer Test Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent == Colors.white ? Colors.white : accent,
                        side: BorderSide(color: (accent == Colors.white ? Colors.white : accent).withValues(alpha: 0.35)),
                        backgroundColor: const Color(0xFF18181C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: Icon(Icons.terminal_rounded, color: accent == Colors.white ? Colors.white : accent, size: 18),
                      label: const Text(
                        'Developer Test Account (Full Sync)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _isLoading ? null : _handleDeveloperLogin,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                        backgroundColor: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google 'G' icon using coloured dots
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Switch to Register
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.isRootGate) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterView(isRootGate: true, onRegisterSuccess: widget.onLoginSuccess),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterView(isRootGate: false, onRegisterSuccess: widget.onLoginSuccess),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Sign up for OpenAamps',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
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
    );
  }
}
