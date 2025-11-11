// lib/widgets/app_drawer.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

typedef DrawerNav = void Function(String screen);

class AppDrawer extends StatefulWidget {
  final DrawerNav onNavigate;
  final VoidCallback onLogout;

  const AppDrawer({super.key, required this.onNavigate, required this.onLogout});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  UserModel? _user;
  bool _loading = true;
  Map<String, dynamic> _prefs = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final user = await FirestoreService.getUser(uid);
    final prefs = await FirestoreService.getUserPrefs(uid);
    setState(() {
      _user = user;
      _prefs = prefs;
      _loading = false;
    });
  }

  Widget _profileRow() {
    ImageProvider? image;
    final url = _user?.profileImageUrl;
    if (url != null && url.isNotEmpty) {
      // treat as URL; if you stored base64 previously this will be a plain string so decode if needed
      try {
        image = NetworkImage(url);
      } catch (_) {
        image = null;
      }
    }
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: image,
        child: image == null ? const Icon(Icons.person) : null,
      ),
      title: Text(_user?.username ?? 'Guest'),
      subtitle: Text(_user?.email ?? ''),
      onTap: () => widget.onNavigate('profile'),
    );
  }

  Widget _menuButton(String label, String screen, {Widget? trailing}) {
    return ListTile(
      title: Text(label),
      trailing: trailing,
      onTap: () {
        Navigator.of(context).pop(); // close drawer
        widget.onNavigate(screen);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _profileRow(),
                  const Divider(),
                  _menuButton('Home', 'landing'),
                  _menuButton(
                    'Settings',
                    'settings',
                    trailing: (_prefs['schedulesEnabled'] as bool? ?? false)
                        ? const Icon(Icons.warning, color: Colors.orange)
                        : null,
                  ),
                  _menuButton('Sounds / Callstyle', 'sounds'),
                  _menuButton('App List Selection', 'applist'),
                  _menuButton('Coaches Selection', 'coaches'),
                  _menuButton('Membership / Contributions', 'membership'),
                  _menuButton('Share Accomplishments', 'accomplishments'),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () {
                      widget.onLogout();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
