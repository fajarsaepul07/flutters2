import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            return _mobileView(auth);
          }

          return Row(
            children: [
              /// LEFT IMAGE
              Expanded(
                child: Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Image.asset(
                        'assets/login.jpg',
                        width: 350,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              /// RIGHT FORM
              Expanded(
                child: Container(
                  color: const Color(0xFF2F80ED),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "WELCOME",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 50),

                          _inputField(
                            controller: _emailController,
                            hint: "Email",
                          ),
                          const SizedBox(height: 20),

                          _inputField(
                            controller: _passwordController,
                            hint: "Password",
                            isPassword: true,
                          ),
                          const SizedBox(height: 30),

                          _loginButton(auth),
                        ],
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

  /// ================= BUTTON LOGIN =================
  Widget _loginButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: auth.isLoading
            ? null
            : () async {
                if (_emailController.text.isEmpty ||
                    _passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Email dan password wajib diisi"),
                    ),
                  );
                  return;
                }

                bool success = await auth.login(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                  context,
                );

                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Login gagal"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
        child: auth.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "SUBMIT",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// ================= INPUT =================
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// ================= MOBILE =================
  Widget _mobileView(AuthProvider auth) {
    return Container(
      color: const Color(0xFF2F80ED),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "WELCOME",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              _inputField(
                controller: _emailController,
                hint: "Email",
              ),
              const SizedBox(height: 20),

              _inputField(
                controller: _passwordController,
                hint: "Password",
                isPassword: true,
              ),
              const SizedBox(height: 30),

              _loginButton(auth), // 🔥 PAKAI FUNCTION YANG SAMA
            ],
          ),
        ),
      ),
    );
  }
}