// lib/screens/sound_screen.dart
import 'package:flutter/material.dart';
import 'package:alarmreminderappios/services/firestore_service.dart';
import 'package:alarmreminderappios/services/auth_service.dart';
import 'package:alarmreminderappios/models/sound_config_model.dart';
import 'package:alarmreminderappios/models/user_model.dart';

class SoundScreen extends StatefulWidget {
  const SoundScreen({super.key});

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  List<SoundConfigModel> _sounds = [];
  String? _selectedId;
  String _userTier = 'Free';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads user data and available sounds from Firestore.
  Future<void> _load() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final UserModel? user = await FirestoreService.getUser(uid);
    if (!mounted) return;

    setState(() {
      _userTier = user?.subscriptionTier ?? 'Free';
      // load saved sound id if present
      _selectedId = user?.notificationSoundId ?? user?.profileImageUrl;
    });

    // fetch raw list as dynamic to be defensive about types
    final List<dynamic> rawList = await FirestoreService.fetchNotificationSounds();

    // Convert whatever we got into SoundConfigModel reliably:
    final List<SoundConfigModel> sounds = rawList.map<SoundConfigModel>((m) {
      if (m is SoundConfigModel) {
        return m;
      } else if (m is Map<String, dynamic>) {
        final id = (m['id'] as String?) ??
            (m['docId'] as String?) ??
            (m['soundId'] as String?) ??
            DateTime.now().millisecondsSinceEpoch.toString();
        return SoundConfigModel.fromMap(m, id);
      } else if (m is String) {
        return SoundConfigModel(id: m, name: m, uri: '', tier: 'Free');
      } else {
        // Fallback: stringify
        return SoundConfigModel(id: m.toString(), name: m.toString(), uri: '', tier: 'Free');
      }
    }).toList();

    if (!mounted) return;
    setState(() {
      _sounds = sounds;
      _loading = false;
    });
  }

  /// Saves selected sound preference.
  Future<void> _save() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;

    await FirestoreService.updateUserPref(uid, 'notificationSoundId', _selectedId);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Sound preference saved')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Notification Sound')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _sounds.length,
        itemBuilder: (context, index) {
          final s = _sounds[index];

          // Lock tiers above user's level
          final isLocked = (s.tier == 'Champ' && _userTier == 'Free') ||
              (s.tier == 'Grandmaster' &&
                  !['Grandmaster', 'God'].contains(_userTier));

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: RadioListTile<String>(
              title: Text(s.name),
              subtitle: Text('Tier: ${s.tier}'),
              value: s.id,
              groupValue: _selectedId,
              activeColor: Colors.deepPurple,
              onChanged: isLocked
                  ? null
                  : (v) {
                      setState(() => _selectedId = v);
                    },
              secondary: isLocked
                  ? const Icon(Icons.lock, color: Colors.grey)
                  : const Icon(Icons.music_note),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        tooltip: 'Save Sound Selection',
        child: const Icon(Icons.save),
      ),
    );
  }
}
