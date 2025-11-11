// lib/screens/schedule_list_screen.dart
import 'package:flutter/material.dart';
import 'package:alarmreminderappios/models/schedule_model.dart';
import 'package:alarmreminderappios/services/firestore_service.dart';
import 'package:alarmreminderappios/services/auth_service.dart';
import 'package:alarmreminderappios/screens/schedule_editor_screen.dart';
import 'package:alarmreminderappios/screens/profile_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  List<ScheduleModel> _schedules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      // Not signed in — nothing to load
      if (mounted) {
        setState(() {
          _schedules = [];
          _loading = false;
        });
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final coll = await FirestoreService.getUserSchedules(uid);
      if (!mounted) return;
      setState(() {
        _schedules = coll;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      // optionally show snack bar / log
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load schedules: $e')));
    }
  }

  Future<void> _toggleSchedule(ScheduleModel s) async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    final updated = s.copyWith(enabled: !s.enabled);

    final payload = updated.toMap();
    try {
      await FirestoreService.saveSchedule(uid, docId: s.id, payload: payload);
      if (!mounted) return;
      await _loadSchedules();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update schedule: $e')));
    }
  }

  Future<void> _deleteSchedule(ScheduleModel s) async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    try {
      await FirestoreService.deleteSchedule(uid, s.id);
      if (!mounted) return;
      await _loadSchedules();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete schedule: $e')));
    }
  }

  void _openEditor([ScheduleModel? s]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScheduleEditorScreen(existing: s)),
    ).then((_) {
      if (!mounted) return;
      _loadSchedules();
    });
  }

  void _openProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedules'),
        actions: [
          IconButton(onPressed: _openProfile, icon: const Icon(Icons.person)),
          IconButton(onPressed: AuthService.signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? const Center(child: Text('No schedules yet. Tap + to add one.'))
              : ListView.builder(
                  itemCount: _schedules.length,
                  itemBuilder: (context, index) {
                    final s = _schedules[index];
                    final time = '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: ListTile(
                        title: Text(s.title),
                        subtitle: Text('Time: $time  |  ${s.repeats ? "Repeats" : "Once"}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Switch(
                            value: s.enabled,
                            onChanged: (_) => _toggleSchedule(s),
                          ),
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _openEditor(s)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteSchedule(s)),
                        ]),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
