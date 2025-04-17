import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/auth.dart';
import 'navigation_wrapper.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      return const NavigationWrapper(); // ✅ user is logged in
    } else {
      return const AuthPage(); // 🔐 show login/signup
    }
  }
}
