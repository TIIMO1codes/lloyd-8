import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'lyrics_page.dart';
import 'favorites_page.dart';
import '../add_song.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? firebaseUser = FirebaseAuth.instance.currentUser;

  // 👤 USER INFO
  String displayName = 'Guest';
  String email = '';
  String? photoUrl;

  final List<Map<String, String>> songs = [
    {
      'title': 'Pogi',
      'artist': 'mica',
      'musicUrl': 'assets/songs/pogi.mp3',
      'lyricsUrl': 'assets/lyrics/pogi.txt',
      'albumArt': 'assets/images/1.jpg',
      'favorite': 'false',
    },
    {
      'title': 'Akap',
      'artist': 'Imago',
      'musicUrl': 'assets/songs/akap.mp3',
      'lyricsUrl': 'assets/lyrics/akap.txt',
      'albumArt': 'assets/images/2.jpg',
      'favorite': 'false',
    },
    {
      'title': 'Multo',
      'artist': 'Cup of Joe',
      'musicUrl': 'assets/songs/multo.mp3',
      'lyricsUrl': 'assets/lyrics/multo.txt',
      'albumArt': 'assets/images/3.jpg',
      'favorite': 'false',
    },
    {
      'title': 'Porque',
      'artist': 'Maldita',
      'musicUrl': 'assets/songs/porque.mp3',
      'lyricsUrl': 'assets/lyrics/porque.txt',
      'albumArt': 'assets/images/4.jpg',
      'favorite': 'false',
    },
    {
      'title': 'Santeria',
      'artist': 'Sublime',
      'musicUrl': 'assets/songs/santeria.mp3',
      'lyricsUrl': 'assets/lyrics/santeria.txt',
      'albumArt': 'assets/images/5.jpg',
      'favorite': 'false',
    },
    {
      'title': 'Migraine',
      'artist': 'Moonstar88',
      'musicUrl': 'assets/songs/migraine.mp3',
      'lyricsUrl': 'assets/lyrics/migraine.txt',
      'albumArt': 'assets/images/6.jpg',
      'favorite': 'false',
    },
    {
      'title': 'Buko',
      'artist': 'Jireh Lim',
      'musicUrl': 'assets/songs/buko.mp3',
      'lyricsUrl': 'assets/lyrics/buko.txt',
      'albumArt': 'assets/images/7.jpg',
      'favorite': 'false',
    },
    {
      'title': 'Mundo',
      'artist': 'IV of Spades',
      'musicUrl': 'assets/songs/mundo.mp3',
      'lyricsUrl': 'assets/lyrics/mundo.txt',
      'albumArt': 'assets/images/8.jpg',
      'favorite': 'false',
    },
    {
      'title': 'Wag na Wag mong Sasabihin',
      'artist': 'Kitche Nadal',
      'musicUrl': 'assets/songs/Handle.mp3',
      'lyricsUrl': 'assets/lyrics/Handle.txt',
      'albumArt': 'assets/images/9.jpg',
      'favorite': 'false',
    },
    {
      'title': 'Narda',
      'artist': 'Kamikazee',
      'musicUrl': 'assets/songs/nardaa.mp3',
      'lyricsUrl': 'assets/lyrics/nardaa.txt',
      'albumArt': 'assets/images/10.jpg',
      'favorite': 'false',
    },
  ];

  List<Map<String, String>> filteredSongs = [];
  final TextEditingController _searchController = TextEditingController();

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    songs.addAll(AddSongPage.addedSongs);
    filteredSongs = List.from(songs);
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
  final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  if (args != null && args['type'] == 'normal') {
    // ✅ NORMAL LOGIN HAS PRIORITY
    setState(() {
      displayName = args['name'] ?? 'User';
      email = args['email'] ?? '';
      photoUrl = null;
    });
  } else if (firebaseUser != null) {
    // ✅ GOOGLE LOGIN
    setState(() {
      displayName = firebaseUser!.displayName ?? 'Google User';
      email = firebaseUser!.email ?? '';
      photoUrl = firebaseUser!.photoURL;
    });
  }
});

  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= SEARCH =================
  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      filteredSongs = songs.where((s) {
        return s['title']!.toLowerCase().contains(q) ||
            s['artist']!.toLowerCase().contains(q);
      }).toList();
    });
  }

  final List<Color> _gradientColors = const [
    Color(0xFF01312D),
    Color(0xFF3A7717),
    Color(0xFF72BF00),
  ];

  // ================= UI =================
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
            child: Column(
              children: [
                // ================= HEADER =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tracks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddSongPage(),
                              ),
                            ).then((_) {
                              setState(() {
                                songs.addAll(AddSongPage.addedSongs);
                                filteredSongs = List.from(songs);
                              });
                            });
                          },
                        ),

                        // ================= PROFILE MENU =================
                        PopupMenuButton<String>(
                          icon: CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl!)
                                : null,
                            child: photoUrl == null
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'G',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          onSelected: (value) {
                            if (value == 'user') {
                              _showProfileDialog();
                            } else if (value == 'favorites') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FavoritesPage(songs: songs),
                                ),
                              );
                            } else if (value == 'logout') {
                              FirebaseAuth.instance.signOut();
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'user',
                              child: Text('Profile Info'),
                            ),
                            PopupMenuItem(
                              value: 'favorites',
                              child: Text('Favorites'),
                            ),
                            PopupMenuItem(
                              value: 'logout',
                              child: Text('Logout'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ================= SEARCH =================
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.search, color: Colors.white70),
                    hintText: 'Search songs or artists',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                ),

                const SizedBox(height: 12),

                // ================= SONG LIST =================
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredSongs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: song['albumArt']!.startsWith('assets/')
                              ? Image.asset(
                                  song['albumArt']!,
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(song['albumArt']!),
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        title: Text(
                          song['title']!,
                          style:
                              const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          song['artist']!,
                          style:
                              const TextStyle(color: Colors.white70),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LyricsPage(
                                songs: filteredSongs,
                                startIndex: index,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= PROFILE DIALOG =================
  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl!) : null,
                backgroundColor: Colors.green.shade100,
                child: photoUrl == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
