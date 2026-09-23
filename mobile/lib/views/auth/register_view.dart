import 'package:flutter/material.dart';
import '../../repositories/auth_repository.dart';
import '../../services/settings_service.dart';
import 'login_view.dart';

class RegisterView extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;
  final bool isRootGate;

  const RegisterView({
    super.key,
    this.onRegisterSuccess,
    this.isRootGate = false,
  });

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final List<String> _selectedGenres = ['Rock', 'Synthwave', 'Indie'];
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  final List<String> _availableGenres = [
    'Rock',
    'Pop',
    'Synthwave',
    'Lo-Fi',
    'EDM',
    'Hip-Hop',
    'Classical',
    'Jazz',
    'Indie',
    'Alternative',
    'R&B',
    'Ambient',
  ];

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AppAuthRepository.instance.signUpWithEmail(
        email: _emailCtrl.text,
        password: _passCtrl.text,
        displayName: _nameCtrl.text,
        preferredGenres: _selectedGenres,
      );
      if (mounted) {
        if (widget.onRegisterSuccess != null) {
          widget.onRegisterSuccess!();
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = SettingsService.instance.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginView(isRootGate: widget.isRootGate)),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create an account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign up to personalize your music player, train your acoustic taste vector, and manage playlists.',
                    style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),

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
                    const SizedBox(height: 18),
                  ],

                  // Full Name
                  Text(
                    "What's your name?",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                      controller: _nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Enter your profile name',
                        hintStyle: TextStyle(color: Color(0xFF727272)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email Address
                  Text(
                    "What's your email?",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'name@domain.com',
                        hintStyle: TextStyle(color: Color(0xFF727272)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Text(
                    'Create a password',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                            decoration: const InputDecoration(
                              hintText: 'Use at least 6 characters',
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
                  const SizedBox(height: 22),

                  // Preferred Genres Onboarding
                  Text(
                    'Choose music you like (Initial Taste Seed)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableGenres.map((genre) {
                      final isSelected = _selectedGenres.contains(genre);
                      return FilterChip(
                        label: Text(genre),
                        selected: isSelected,
                        selectedColor: accent == Colors.white ? Colors.white : accent,
                        backgroundColor: const Color(0xFF242424),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? (accent == Colors.white ? Colors.black : Colors.white)
                              : const Color(0xFFB3B3B3),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? (accent == Colors.white ? Colors.white : accent)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGenres.add(genre);
                            } else {
                              _selectedGenres.remove(genre);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
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
                      onPressed: _isLoading ? null : _handleRegister,
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
                              'Sign Up',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Switch to Login
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginView(isRootGate: widget.isRootGate),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Log in',
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
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
