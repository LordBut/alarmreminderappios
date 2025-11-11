// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// Services (package imports so analyzer finds them reliably)
import 'package:alarmreminderappios/services/notification_service.dart';
import 'package:alarmreminderappios/services/auth_service.dart';
import 'package:alarmreminderappios/services/firestore_service.dart';

// Screens
import 'package:alarmreminderappios/screens/login_screen.dart';
import 'package:alarmreminderappios/screens/signup_screen.dart';
import 'package:alarmreminderappios/screens/landing_screen.dart';
import 'package:alarmreminderappios/screens/schedule_list_screen.dart';
import 'package:alarmreminderappios/screens/schedule_editor_screen.dart';
import 'package:alarmreminderappios/screens/profile_screen.dart';
import 'package:alarmreminderappios/screens/membership_screen.dart';
import 'package:alarmreminderappios/screens/accomplishments_screen.dart';
import 'package:alarmreminderappios/screens/coaches_screen.dart';
import 'package:alarmreminderappios/screens/sound_screen.dart';

// Widgets
import 'package:alarmreminderappios/screens/app_drawer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service (timezones + platform init)
  await NotificationService.init();

  // Initialize Auth service (if you have any non-trivial init)
  await AuthService.init();

  runApp(const AlarmReminderApp());
}

class AlarmReminderApp extends StatelessWidget {
  const AlarmReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Genevolut',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // RootRouter decides what to show based on auth state
      home: const RootRouter(),

      // Named routes for quick navigation from anywhere in the app.
      // NOTE: for routes that need callbacks we create them using the `context`
      // inside the builder so navigation works as expected.
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/signup': (ctx) => const SignupScreen(),
        '/landing': (ctx) => LandingScreen(
              onLogin: () => Navigator.of(ctx).pushNamed('/login'),
              onSignUp: () => Navigator.of(ctx).pushNamed('/signup'),
            ),
        '/schedules': (ctx) => const ScheduleListScreen(),
        '/schedule-editor': (ctx) => const ScheduleEditorScreen(),
        '/profile': (ctx) => const ProfileScreen(),
        '/membership': (ctx) => MembershipScreen(onNavigateBack: () => Navigator.of(ctx).pop()),
        '/accomplishments': (ctx) => AccomplishmentsScreen(onNavigateBack: () => Navigator.of(ctx).pop()),
        '/coaches': (ctx) => CoachesScreen(onNavigateBack: () => Navigator.of(ctx).pop()),
        '/sounds': (ctx) => const SoundScreen(),
        '/debug-scheduler': (ctx) => const DebugSchedulerScreen(),
      },
    );
  }
}

/// RootRouter listens to auth changes and displays the appropriate root.
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  bool _initialized = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _initAuthListener();
  }

  void _initAuthListener() {
    // AuthService should expose a stream or callback registration for auth state changes.
    AuthService.onAuthStateChanged((user) async {
      // Update state
      if (!mounted) return;
      setState(() {
        _loggedIn = user != null;
        _initialized = true;
      });

      if (user != null) {
        // sync schedules from Firestore to local notifications whenever a user logs in
        try {
          await FirestoreService.syncSchedulesToLocal(user.uid);
        } catch (e) {
          // optionally log
        }
      } else {
        // optionally perform cleanup on sign-out
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If logged in show the main landing screen wrapped in AppShell,
    // otherwise show the login flow.
    return _loggedIn ? const AppShell() : const LoginScreen();
  }
}

/// AppShell is the main scaffold used when a user is signed in.
/// It includes the AppDrawer (sidebar) and a body that defaults to LandingScreen.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // current route name shown in the body
  String _current = '/landing';

  void _navigate(String screen) {
    setState(() {
      _current = '/$screen'.replaceAll('//', '/'); // normalize
    });
    // close drawer if open
    Navigator.of(context).maybePop();
  }

  void _logout() {
    AuthService.signOut();
    // FirestoreService or NotificationService cleanup can happen on sign out if necessary.
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Widget _buildBody() {
    switch (_current) {
      case '/schedules':
        return const ScheduleListScreen();
      case '/profile':
        return const ProfileScreen();
      case '/membership':
        return MembershipScreen(onNavigateBack: () => _navigate('landing'));
      case '/accomplishments':
        return AccomplishmentsScreen(onNavigateBack: () => _navigate('landing'));
      case '/coaches':
        return CoachesScreen(onNavigateBack: () => _navigate('landing'));
      case '/sounds':
        return const SoundScreen();
      case '/landing':
      default:
        return LandingScreen(
          onLogin: () => Navigator.of(context).pushNamed('/login'),
          onSignUp: () => Navigator.of(context).pushNamed('/signup'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genevolut'),
      ),
      drawer: AppDrawer(
        onNavigate: (screenKey) {
          // The drawer sends logical keys like "LandingPage", "Profile", "MembershipScreen"
          // Map those keys to our route / navigation names
          switch (screenKey) {
            case 'LandingPage':
            case 'Home':
              _navigate('landing');
              break;
            case 'SettingsPage':
              _navigate('profile');
              break;
            case 'SoundListSection':
              _navigate('sounds');
              break;
            case 'AppListSection':
              _navigate('schedules');
              break;
            case 'VideoSelectionScreen':
            case 'Coaches Selection':
              _navigate('coaches');
              break;
            case 'MembershipScreen':
              _navigate('membership');
              break;
            case 'AccomplishmentsScreen':
              _navigate('accomplishments');
              break;
            case 'UserProfileScreen':
            case 'Profile':
              _navigate('profile');
              break;
            default:
              _navigate('landing');
          }
        },
        onLogout: _logout,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/schedules'),
        child: const Icon(Icons.alarm),
        tooltip: 'Manage schedules',
      ),
    );
  }
}

/// DebugSchedulerScreen kept for quick testing of scheduler behavior.
/// You can remove this later.
class DebugSchedulerScreen extends StatefulWidget {
  const DebugSchedulerScreen({super.key});

  @override
  State<DebugSchedulerScreen> createState() => _DebugSchedulerScreenState();
}

class _DebugSchedulerScreenState extends State<DebugSchedulerScreen> {
  TimeOfDay? _selectedTime;

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (!mounted) return;
    setState(() => _selectedTime = time);
  }

  Future<void> _scheduleTest() async {
    if (_selectedTime == null) return;
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    await NotificationService.scheduleDaily(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: 'Test Reminder',
      body: 'This is a test reminder scheduled from debug screen',
      hour: _selectedTime!.hour,
      minute: _selectedTime!.minute,
      repeats: false,
      // payload is optional here — not required by our wrapper
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scheduled for ${_selectedTime!.format(context)}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Scheduler')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_selectedTime == null ? 'No time selected' : 'Selected: ${_selectedTime!.format(context)}'),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.access_time), label: const Text('Pick time')),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: _scheduleTest, icon: const Icon(Icons.alarm), label: const Text('Schedule test notification')),
        ]),
      ),
    );
  }
}
