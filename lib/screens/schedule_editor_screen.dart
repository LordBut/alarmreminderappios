// lib/screens/schedule_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:alarmreminderappios/models/schedule_model.dart';
import 'package:alarmreminderappios/services/firestore_service.dart';
import 'package:alarmreminderappios/services/auth_service.dart';

class ScheduleEditorScreen extends StatefulWidget {
  final ScheduleModel? existing;
  const ScheduleEditorScreen({super.key, this.existing});

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<ScheduleEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _repeats = true;
  bool _enabled = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final s = widget.existing!;
      _titleController.text = s.title;
      _bodyController.text = s.body;
      _selectedTime = TimeOfDay(hour: s.hour, minute: s.minute);
      _repeats = s.repeats;
      _enabled = s.enabled;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveSchedule() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      return;
    }

    setState(() => _loading = true);

    final id = widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'body': _bodyController.text.trim(),
      'hour': _selectedTime.hour,
      'minute': _selectedTime.minute,
      'repeats': _repeats,
      'enabled': _enabled,
      // prefer server timestamps, but keep local values for immediate UI consistency
      'updatedAt': DateTime.now(),
      if (widget.existing == null) 'createdAt': DateTime.now(),
    };

    try {
      await FirestoreService.saveSchedule(uid, docId: id, payload: data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule saved')));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.existing == null ? 'New Schedule' : 'Edit Schedule';
    return Scaffold(
      appBar: AppBar(title: Text(titleText)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(controller: _bodyController, decoration: const InputDecoration(labelText: 'Body / Description')),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Time: ${_selectedTime.format(context)}'),
              const Spacer(),
              TextButton(onPressed: _pickTime, child: const Text('Change')),
            ],
          ),
          SwitchListTile(
            value: _repeats,
            onChanged: (v) => setState(() => _repeats = v),
            title: const Text('Repeat daily'),
          ),
          SwitchListTile(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            title: const Text('Enabled'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _saveSchedule,
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Schedule'),
            ),
          ),
        ]),
      ),
    );
  }
}
