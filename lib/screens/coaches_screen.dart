// lib/screens/coaches_screen.dart
import 'package:flutter/material.dart';
import 'package:alarmreminderappios/services/firestore_service.dart';
import 'package:alarmreminderappios/services/auth_service.dart';
import 'package:alarmreminderappios/models/coach_data.dart';

class CoachesScreen extends StatefulWidget {
  final VoidCallback onNavigateBack;
  const CoachesScreen({super.key, required this.onNavigateBack});

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  bool _loading = true;
  List<CoachData> _coaches = [];
  // Use final where possible
  final Map<String, Map<String, String?>> _selectedVideos = {};
  final Map<String, Map<String, bool>> _selectedCoaches = {};

  @override
  void initState() {
    super.initState();
    _fetchCoaches();
  }

  Future<void> _fetchCoaches() async {
    try {
      final coaches = await FirestoreService.fetchCoaches();
      if (!mounted) return;
      setState(() {
        _coaches = coaches;
        for (final c in coaches) {
          _selectedVideos[c.id] = {'mild': null, 'medium': null, 'aggressive': null};
          _selectedCoaches[c.id] = {'mild': false, 'medium': false, 'aggressive': false};
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load coaches: $e')));
    }
  }

  Future<void> _save() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to save your selections')));
      return;
    }

    setState(() => _loading = true);
    try {
      await FirestoreService.saveSelectedCoaches(uid, _selectedVideos, _selectedCoaches);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      widget.onNavigateBack();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Build a list of widgets for coaches
    final List<Widget> children = _coaches.map((c) {
      final coachId = c.id;
      final coachName = c.name ?? 'Coach';

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(coachName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              for (final att in ['mild', 'medium', 'aggressive'])
                Row(
                  children: [
                    Checkbox(
                      value: _selectedCoaches[coachId]?[att] ?? false,
                      onChanged: (v) {
                        setState(() {
                          _selectedCoaches[coachId]?[att] = v ?? false;
                        });
                      },
                    ),
                    Text(att),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // placeholder for choosing a video — implement picker/selector later
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Choose Video'),
                            content: const Text('Video selection is not implemented yet.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                            ],
                          ),
                        );
                      },
                      child: const Text('Choose video'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }).toList();

    // Append final Save button
    children.addAll([
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _save,
        child: const Text('Save'),
      ),
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coaches Selection'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onNavigateBack),
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: children),
    );
  }
}
