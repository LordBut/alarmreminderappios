// lib/screens/accomplishments_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alarmreminderappios/services/auth_service.dart';
import 'package:alarmreminderappios/services/storage_service.dart';
import 'package:alarmreminderappios/services/firestore_service.dart';
import 'package:alarmreminderappios/models/post_model.dart';

class AccomplishmentsScreen extends StatefulWidget {
  final VoidCallback onNavigateBack;
  const AccomplishmentsScreen({super.key, required this.onNavigateBack});

  @override
  State<AccomplishmentsScreen> createState() => _AccomplishmentsScreenState();
}

class _AccomplishmentsScreenState extends State<AccomplishmentsScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _pickedFile;
  String? _mediaType;
  bool _loading = false;
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await FirestoreService.getRecentPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      // non-fatal: show an indicator if you want
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load posts: $e')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
      if (picked == null) return;
      if (!mounted) return;
      setState(() {
        _pickedFile = File(picked.path);
        _mediaType = 'image';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;
      if (!mounted) return;
      setState(() {
        _pickedFile = File(picked.path);
        _mediaType = 'video';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video pick failed: $e')));
    }
  }

  Future<void> _submit() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login')));
      return;
    }

    setState(() => _loading = true);

    try {
      String? mediaUrl;
      if (_pickedFile != null) {
        mediaUrl = await StorageService().uploadPostMedia(_pickedFile!, uid);
      }

      final now = DateTime.now();
      final post = PostModel(
        id: '',
        ownerUid: uid,
        text: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
        mediaUrl: mediaUrl,
        mediaType: _mediaType,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
      );

      await FirestoreService.createPost(post);

      if (!mounted) return;
      // reset UI
      setState(() {
        _textController.clear();
        _pickedFile = null;
        _mediaType = null;
      });

      // reload posts
      await _loadPosts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Widget _buildPostTile(PostModel p) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(p.text ?? '(media)'),
        subtitle: Text('by ${p.ownerUid} — expires ${p.expiresAt.toLocal().toIso8601String().split('T').first}'),
        leading: p.mediaUrl != null
            ? (p.mediaType == 'image'
                ? Image.network(p.mediaUrl!, width: 56, height: 56, fit: BoxFit.cover)
                : const Icon(Icons.videocam))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Accomplishments'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onNavigateBack),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(hintText: 'Write about your accomplishment...'),
            minLines: 1,
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          Row(children: [
            ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Image')),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed: _pickVideo, icon: const Icon(Icons.videocam), label: const Text('Video')),
            const Spacer(),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post'),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: _posts.isEmpty
                ? const Center(child: Text('No posts yet'))
                : ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (ctx, i) {
                      return _buildPostTile(_posts[i]);
                    },
                  ),
          )
        ]),
      ),
    );
  }
}
