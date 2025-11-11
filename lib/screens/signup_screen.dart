// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signup() async {
    setState(() { _loading = true; _error = null; });
    if (_password.text != _confirm.text) {
      setState(() { _error = 'Passwords do not match'; _loading = false; });
      return;
    }
    try {
      final user = await AuthService.signUp(_email.text.trim(), _password.text.trim(), _username.text.trim());
      if (user != null) {
        // create initial profile with empty selections
        await FirestoreService.createInitialUserProfile(user.uid, _username.text.trim(), _email.text.trim());
        if (mounted) Navigator.pop(context);
      } else {
        setState(() { _error = 'Sign up failed'; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          TextField(controller: _confirm, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true),
          const SizedBox(height: 12),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loading ? null : _signup, child: _loading ? const CircularProgressIndicator() : const Text('Create account')),
        ]),
      ),
    );
  }
}
