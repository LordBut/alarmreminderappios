// lib/screens/landing_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignUp;

  const LandingScreen({super.key, required this.onLogin, required this.onSignUp});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _schedulesEnabled = false;
  bool _loading = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = AuthService.currentUid;
    setState(() {
      _uid = uid;
    });
    if (uid != null) {
      final prefs = await FirestoreService.getUserPrefs(uid);
      setState(() {
        _schedulesEnabled = prefs['schedulesEnabled'] as bool? ?? false;
      });
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _toggleSchedules() async {
    if (_uid == null) {
      // require login
      widget.onLogin();
      return;
    }
    final newVal = !_schedulesEnabled;
    setState(() => _schedulesEnabled = newVal);
    await FirestoreService.updateUserPref(_uid!, 'schedulesEnabled', newVal);
    if (newVal) {
      await FirestoreService.syncSchedulesToLocal(_uid!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedules enabled')));
    } else {
      await NotificationService.cancelAll();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedules disabled')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Landing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          const SizedBox(height: 16),
          const FlutterLogo(size: 80),
          const SizedBox(height: 16),
          Text('Welcome${AuthService.currentUid != null ? "" : " (please sign in)"}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text('Stay focused and motivated. Use scheduled reminders to replace background monitoring.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _toggleSchedules,
            child: Text(_schedulesEnabled ? 'Disable Scheduled Reminders' : 'Enable Scheduled Reminders'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/schedules'), child: const Text('Manage Schedules')),
          const SizedBox(height: 12),
          if (AuthService.currentUid == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: widget.onLogin, child: const Text('Login')),
                TextButton(onPressed: widget.onSignUp, child: const Text('Sign up')),
              ],
            ),
        ]),
      ),
    );
  }
}
