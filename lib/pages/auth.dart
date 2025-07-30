import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../utils/navigation_wrapper.dart';
import './reset_password_page.dart';

// Enum to manage the different views on the authentication page
enum AuthMode { login, signUp, otp, verifyOtp, resetPassword }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthMode _authMode = AuthMode.login;
  bool _loading = false;
  String _emailForOtp = '';

  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      // Check if the event is a password recovery deep link
      if (event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          // Navigate to the dedicated page for setting a new password
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
          );
        }
      } else if (session != null) {
        // Handle all other successful sign-ins (Magic Link, Google, Password)
        _onAuthSuccess();
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _onAuthSuccess() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NavigationWrapper()),
      );
    }
  }

  Future<void> _handlePasswordAuth() async {
    setState(() => _loading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      if (_authMode == AuthMode.login) {
        await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      } else {
        await Supabase.instance.client.auth.signUp(email: email, password: password);
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.signInWithGoogle();
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Google Sign-In failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSendOtp() async {
    setState(() => _loading = true);
    final email = _emailController.text.trim();
    try {
      await SupabaseService.signInWithOtp(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Magic link sent to your email!"), backgroundColor: Colors.green),
        );
        setState(() {
          _emailForOtp = email;
          _authMode = AuthMode.verifyOtp;
        });
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handlePasswordReset() async {
    setState(() => _loading = true);
    final email = _emailController.text.trim();
    try {
      await SupabaseService.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset link sent!"), backgroundColor: Colors.green),
        );
        setState(() => _authMode = AuthMode.login);
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getAppBarTitle())),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              _buildAuthForm(),
              const SizedBox(height: 20),
              if (_authMode == AuthMode.login || _authMode == AuthMode.signUp) ...[
                _buildDivider(),
                const SizedBox(height: 20),
                _buildGoogleSignInButton(),
              ],
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_authMode) {
      case AuthMode.login: return "Login";
      case AuthMode.signUp: return "Sign Up";
      case AuthMode.otp: return "Sign in with Magic Link";
      case AuthMode.verifyOtp: return "Check Your Email";
      case AuthMode.resetPassword: return "Reset Password";
    }
  }

  Widget _buildAuthForm() {
    switch (_authMode) {
      case AuthMode.login:
      case AuthMode.signUp:
        return _buildPasswordForm();
      case AuthMode.otp:
        return _buildEmailForm("Send Magic Link", _handleSendOtp);
      case AuthMode.verifyOtp:
        return _buildVerifyOtpForm();
      case AuthMode.resetPassword:
        return _buildEmailForm("Send Reset Link", _handlePasswordReset);
    }
  }

  Widget _buildPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 8),
        if (_authMode == AuthMode.login)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => setState(() => _authMode = AuthMode.resetPassword), child: const Text("Forgot Password?")),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _handlePasswordAuth,
          child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_authMode == AuthMode.login ? "Login" : "Sign Up"),
        ),
        TextButton(
          onPressed: _loading ? null : () => setState(() => _authMode = _authMode == AuthMode.login ? AuthMode.signUp : AuthMode.login),
          child: Text(_authMode == AuthMode.login ? "Don't have an account? Sign up" : "Already have an account? Login"),
        ),
        TextButton(
          onPressed: _loading ? null : () => setState(() => _authMode = AuthMode.otp),
          child: const Text("Sign in with a Magic Link"),
        ),
      ],
    );
  }

  Widget _buildEmailForm(String buttonText, VoidCallback onSubmit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : onSubmit,
          child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(buttonText),
        ),
        TextButton(onPressed: _loading ? null : () => setState(() => _authMode = AuthMode.login), child: const Text("Back to Login")),
      ],
    );
  }

  Widget _buildVerifyOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("A magic link has been sent to $_emailForOtp. Please check your email and click the link to sign in."),
        const SizedBox(height: 24),
        TextButton(onPressed: _loading ? null : () => setState(() => _authMode = AuthMode.otp), child: const Text("Use a different email")),
      ],
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text("OR")),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _handleGoogleSignIn,
      icon: const Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      label: const Text("Sign in with Google"),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.deepPurple,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.deepPurple),
      ),
    );
  }
}
