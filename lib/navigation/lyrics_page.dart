import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

class LyricsPage extends StatefulWidget {
  final List<Map<String, String>> songs;
  final int startIndex;

  const LyricsPage({
    super.key,
    required this.songs,
    this.startIndex = 0,
  });

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  late List<Map<String, String>> _songs;
  int _currentIndex = 0;
  String _lyrics = "Loading lyrics...";
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late String _currentAlbumArt;

  // Animated background
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  @override
  void initState() {
    super.initState();

    _songs = widget.songs;
    _currentIndex = widget.startIndex;
    _currentAlbumArt = _songs[_currentIndex]['albumArt'] ?? '';

    _player.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });

    _player.onPlayerComplete.listen((_) {
      _playNextSong();
    });

    _loadSong();

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _colorAnimation1 = ColorTween(
      begin: Colors.green.shade900,
      end: Colors.green.shade300,
    ).animate(_colorController);

    _colorAnimation2 = ColorTween(
      begin: Colors.blue.shade900,
      end: Colors.purple.shade300,
    ).animate(_colorController);
  }

  @override
  void dispose() {
    _player.dispose();
    _colorController.dispose();
    super.dispose();
  }

  // ---------------- FIXED LOADER ----------------
  Future<void> _loadSong() async {
    final currentSong = _songs[_currentIndex];
    await _player.stop();

    setState(() {
      _isPlaying = false;
      _lyrics = "Loading lyrics...";
      _currentAlbumArt = currentSong['albumArt'] ?? '';
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    final musicUrl = currentSong['musicUrl'] ?? '';
    final lyricsData = currentSong['lyricsUrl'] ?? '';

    // ✅ FIX LYRICS (asset OR plain text)
    try {
      if (lyricsData.startsWith('assets/')) {
        _lyrics = await rootBundle.loadString(lyricsData);
      } else {
        _lyrics =
            lyricsData.isEmpty ? "Lyrics not available." : lyricsData;
      }
    } catch (_) {
      _lyrics = "Lyrics not found.";
    }

    // ✅ FIX AUDIO (asset OR local file)
    try {
      if (musicUrl.startsWith('assets/')) {
        await _player.setSource(
          AssetSource(musicUrl.replaceFirst('assets/', '')),
        );
      } else {
        await _player.setSource(DeviceFileSource(musicUrl));
      }

      await _player.resume();
      setState(() => _isPlaying = true);
    } catch (_) {
      // silently fail (prevents crash)
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _playNextSong() {
    _currentIndex = (_currentIndex + 1) % _songs.length;
    _loadSong();
  }

  void _playPrevSong() {
    _currentIndex =
        (_currentIndex - 1 + _songs.length) % _songs.length;
    _loadSong();
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  // ✅ FIX ALBUM ART (asset OR local)
  Widget _buildAlbumArt(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.white10,
        child: const Icon(Icons.music_note,
            size: 64, color: Colors.white70),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final song = _songs[_currentIndex];

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _colorController,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _colorAnimation1.value ?? Colors.green,
                    _colorAnimation2.value ?? Colors.purple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Opacity(
                opacity: 0.07,
                child: _buildAlbumArt(_currentAlbumArt),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // HEADER
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setState(() {
                          song['favorite'] =
                              song['favorite'] == 'true'
                                  ? 'false'
                                  : 'true';
                        });
                      },
                      child: Icon(
                        song['favorite'] == 'true'
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.more_vert, color: Colors.white),
                  ],
                ),

                const SizedBox(height: 10),

                // ALBUM ART
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildAlbumArt(_currentAlbumArt),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  song['title'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  song['artist'] ?? '',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 20),

                // LYRICS + PLAYER
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _lyrics,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Slider(
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                          value: _position.inSeconds.toDouble().clamp(
                                0,
                                _duration.inSeconds == 0
                                    ? 1
                                    : _duration.inSeconds.toDouble(),
                              ),
                          max: _duration.inSeconds == 0
                              ? 1
                              : _duration.inSeconds.toDouble(),
                          onChanged: (value) async {
                            await _player.seek(
                              Duration(seconds: value.toInt()),
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatTime(_position),
                                style: const TextStyle(
                                    color: Colors.white70)),
                            Text(_formatTime(_duration),
                                style: const TextStyle(
                                    color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: _playPrevSong,
                              child: const CircleAvatar(
                                radius: 28,
                                backgroundColor:
                                    Colors.white24,
                                child: Icon(Icons.skip_previous,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 30),
                            InkWell(
                              onTap: _togglePlay,
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor:
                                    Colors.white.withOpacity(0.15),
                                child: Icon(
                                  _isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 30),
                            InkWell(
                              onTap: _playNextSong,
                              child: const CircleAvatar(
                                radius: 28,
                                backgroundColor:
                                    Colors.white24,
                                child: Icon(Icons.skip_next,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
