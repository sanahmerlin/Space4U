import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onLoginClicked;
  const SignupScreen({Key? key, required this.onLoginClicked}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  String? _error;

  void _signup() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await _auth.signUp(
        _emailCtrl.text.trim(), 
        _passCtrl.text.trim(),
        _nameCtrl.text.trim(),
      );
      // Wrapper will handle navigation
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().split(']').last.trim());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text(
              'Join Space4U',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _signup,
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text('Sign Up'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onLoginClicked,
              child: const Text('Already have an account? Log In'),
            ),
          ],
        ),
      ),
    );
  }
}
