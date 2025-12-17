import 'dart:io';

import 'package:flutter/material.dart';
import 'lyrics_page.dart';

class FavoritesPage extends StatefulWidget {
  final List<Map<String, String>> songs;

  const FavoritesPage({super.key, required this.songs});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final List<Color> _gradientColors = const [
    Color(0xFF01312D),
    Color(0xFF3A7717),
    Color(0xFF72BF00),
  ];

  // ✅ FIX: asset OR local album art
  Widget _buildAlbumArt(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(path),
      width: 54,
      height: 54,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = widget.songs
        .where((s) => s['favorite'] == 'true')
        .toList();

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
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Favorites",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '${favorites.length} Favorite Tracks',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: favorites.isEmpty
                      ? const Center(
                          child: Text(
                            "No favorites yet",
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.separated(
                          itemCount: favorites.length,
                          separatorBuilder: (_, __) =>
                              const Divider(
                                  color: Colors.white24, indent: 70),
                          itemBuilder: (context, index) {
                            final song = favorites[index];

                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildAlbumArt(
                                  song['albumArt'] ?? '',
                                ),
                              ),
                              title: Text(
                                song['title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                song['artist'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white70),
                              ),

                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  setState(() {
                                    song['favorite'] = 'false';
                                  });
                                },
                              ),

                              onTap: () {
                                final realIndex =
                                    widget.songs.indexOf(song);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LyricsPage(
                                      songs: widget.songs,
                                      startIndex: realIndex,
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
