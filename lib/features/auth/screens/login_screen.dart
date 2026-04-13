import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// ─── Warna & konstanta ───────────────────────────────────────────────────────
const _primary     = Color(0xFF3B5BDB);
const _primaryDark = Color(0xFF2F4AC0);
const _borderColor = Color(0xFFE5E7EB);
const _textPrimary = Color(0xFF111827);
const _textMuted   = Color(0xFF9CA3AF);
const _bgLeft      = Color(0xFFF0F4FF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) return _mobileView(auth);
          return Row(
            children: [
              // ── LEFT PANEL ────────────────────────────────────────────────
              Expanded(
                child: Container(
                  color: _bgLeft,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo placeholder
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.support_agent,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(height: 40),
                          const Text('HelpDesk',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                                  color: _textPrimary, letterSpacing: -0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'Platform tiket bantuan terpadu\nuntuk tim support Anda.',
                            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280),
                                height: 1.6),
                          ),
                          const SizedBox(height: 48),
                          Image.asset('assets/login.jpg',
                              width: 320, fit: BoxFit.contain),
                          const SizedBox(height: 40),
                          // Feature pills
                          Wrap(
                            spacing: 10, runSpacing: 10,
                            children: ['Manajemen tiket', 'Laporan real-time', 'Multi-kategori']
                                .map((f) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _borderColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_outline,
                                              size: 14, color: _primary),
                                          const SizedBox(width: 6),
                                          Text(f,
                                              style: const TextStyle(fontSize: 12,
                                                  color: _textPrimary)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── RIGHT PANEL ───────────────────────────────────────────────
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _formContent(auth, isDark: false),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _formContent(AuthProvider auth, {bool isDark = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selamat datang 👋',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : _textPrimary)),
        const SizedBox(height: 6),
        Text('Masuk ke akun Anda untuk melanjutkan',
            style: TextStyle(fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
        const SizedBox(height: 36),

        _fieldLabel('Email', isDark),
        const SizedBox(height: 6),
        _inputField(
          controller: _emailController,
          hint: 'nama@perusahaan.com',
          icon: Icons.email_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 18),

        _fieldLabel('Password', isDark),
        const SizedBox(height: 6),
        _inputField(
          controller: _passwordController,
          hint: '••••••••',
          icon: Icons.lock_outline,
          isPassword: true,
          isDark: isDark,
        ),
        const SizedBox(height: 28),

        _loginButton(auth),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: Divider(color: isDark ? Colors.white24 : _borderColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('atau',
                  style: TextStyle(fontSize: 12,
                      color: isDark ? Colors.white38 : _textMuted)),
            ),
            Expanded(child: Divider(color: isDark ? Colors.white24 : _borderColor)),
          ],
        ),
        const SizedBox(height: 12),

        _googleLoginButton(auth, isDark),
      ],
    );
  }

  Widget _fieldLabel(String text, bool isDark) => Text(text,
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : _textPrimary));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isDark = false,
  }) {
    final borderSide = BorderSide(
        color: isDark ? Colors.white24 : _borderColor, width: 0.8);
    final focusBorderSide = const BorderSide(color: _primary, width: 1.5);

    return TextField(
      controller: controller,
      obscureText: isPassword && _obscure,
      style: TextStyle(
          fontSize: 14, color: isDark ? Colors.white : _textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 13, color: isDark ? Colors.white38 : _textMuted),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF9FAFB),
        prefixIcon: Icon(icon, size: 17,
            color: isDark ? Colors.white38 : _textMuted),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 17,
                  color: isDark ? Colors.white38 : _textMuted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: borderSide),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: borderSide),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: focusBorderSide),
      ),
    );
  }

  Widget _loginButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: auth.isLoading
            ? null
            : () async {
                if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                  _showSnack('Email dan password wajib diisi');
                  return;
                }
                final success = await auth.login(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                  context,
                );
                if (!success && context.mounted) {
                  _showSnack('Email atau password salah', isError: true);
                }
              },
        child: auth.isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Masuk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _googleLoginButton(AuthProvider auth, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
          foregroundColor: isDark ? Colors.white : _textPrimary,
          side: BorderSide(color: isDark ? Colors.white24 : _borderColor, width: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: auth.isLoading
            ? null
            : () async {
                final success = await auth.loginWithGoogle();
                if (success && context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else if (context.mounted) {
                  _showSnack('Login Google gagal', isError: true);
                }
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/google.png', width: 18),
            const SizedBox(width: 10),
            Text('Lanjutkan dengan Google',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : _textPrimary)),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFDC2626) : _primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── Mobile view ─────────────────────────────────────────────────────────
  Widget _mobileView(AuthProvider auth) {
    return Container(
      color: _primary,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 32),
              _formContent(auth, isDark: true),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}