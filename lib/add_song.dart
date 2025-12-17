import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddSongPage extends StatefulWidget {
  const AddSongPage({super.key});

  static List<Map<String, String>> addedSongs = [];

  @override
  State<AddSongPage> createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddSongPage> {
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _lyricsCtrl = TextEditingController();

  File? mp3File;
  File? albumFile;

  final _gradientColors = const [
    Color(0xFF01312D),
    Color(0xFF3A7717),
    Color(0xFF72BF00),
  ];

  // ---------- MP3 PICKER ----------
  Future<void> pickMp3() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          mp3File = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('MP3 pick error: $e')),
      );
    }
  }

  // ---------- IMAGE PICKER ----------
  Future<void> pickAlbum() async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (img != null) {
        setState(() {
          albumFile = File(img.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image pick error: $e')),
      );
    }
  }

  // ---------- SAVE SONG (FIXED: NO LOGIN REQUIRED) ----------
  Future<void> saveSong() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _artistCtrl.text.trim().isEmpty ||
        mp3File == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, Artist, and MP3 are required')),
      );
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();

      final mp3Path =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp3';
      final savedMp3 = await mp3File!.copy(mp3Path);

      String? albumPath;
      if (albumFile != null) {
        albumPath =
            '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await albumFile!.copy(albumPath);
      }

      final user = FirebaseAuth.instance.currentUser;

      // SAVE TO FIRESTORE (guest allowed)
      await FirebaseFirestore.instance.collection('songs').add({
        'title': _titleCtrl.text.trim(),
        'artist': _artistCtrl.text.trim(),
        'lyrics': _lyricsCtrl.text.trim(),
        'mp3Path': savedMp3.path,
        'albumPath': albumPath,
        'createdBy': user?.uid ?? 'guest',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // SAVE LOCALLY FOR HOME PAGE
      AddSongPage.addedSongs.add({
        'title': _titleCtrl.text.trim(),
        'artist': _artistCtrl.text.trim(),
        'musicUrl': savedMp3.path,
        'lyricsUrl': _lyricsCtrl.text.trim(),
        'albumArt': albumPath ?? '',
        'favorite': 'false',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song saved successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: ListView(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Add Song',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _field(_titleCtrl, 'Title *'),
                const SizedBox(height: 12),
                _field(_artistCtrl, 'Artist *'),
                const SizedBox(height: 12),
                _field(_lyricsCtrl, 'Lyrics', maxLines: 4),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.music_note),
                  label: Text(
                    mp3File == null
                        ? 'Pick MP3'
                        : mp3File!.path.split('/').last,
                  ),
                  onPressed: pickMp3,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Album Cover'),
                  onPressed: pickAlbum,
                ),
                if (albumFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Image.file(albumFile!, height: 160),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: saveSong,
                  child: const Text('Save Song'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String l, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
