import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/utils/shared_prefs.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'screens/home_screen.dart';   // ← Tambahkan import ini

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefs.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tiket App',
        home: const AuthWrapper(),   // ← Ganti dari LoginScreen ke AuthWrapper
      ),
    );
  }
}

// Widget baru ini mengecek apakah user sudah login atau belum
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Jika sudah ada token → langsung ke HomeScreen
    if (auth.isLoggedIn) {
      return const HomeScreen();
    }

    // Jika belum login → ke LoginScreen
    return const LoginScreen();
  }
}