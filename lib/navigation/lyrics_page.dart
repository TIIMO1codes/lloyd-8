import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

class LyricsPage extends StatefulWidget {
  final List<Map<String, String>> songs;
  final int startIndex;

  const LyricsPage({super.key, required this.songs, this.startIndex = 0});

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

    // Animated gradient background
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

  Future<void> _loadSong() async {
    final currentSong = _songs[_currentIndex];
    await _player.stop();

    setState(() {
      _isPlaying = false;
      _lyrics = "Loading lyrics...";
      _currentAlbumArt = currentSong['albumArt'] ?? '';
    });

    final musicUrl = currentSong['musicUrl'] ?? '';
    final lyricsPath = currentSong['lyricsUrl'] ?? '';

    try {
      final data = await rootBundle.loadString(lyricsPath);
      setState(() => _lyrics = data);
    } catch (_) {
      setState(() => _lyrics = "Lyrics not found.");
    }

    if (musicUrl.isNotEmpty) {
      final assetRelative = musicUrl.replaceFirst('assets/', '');
      await _player.setSource(AssetSource(assetRelative));
      await _player.resume();
      setState(() => _isPlaying = true);
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
    _currentIndex = (_currentIndex - 1 + _songs.length) % _songs.length;
    _loadSong();
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Widget _buildAlbumArt(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.white10,
        child: const Icon(Icons.music_note, size: 64, color: Colors.white70),
      );
    }
    if (url.startsWith("http")) {
      return Image.network(url, fit: BoxFit.cover);
    }
    return Image.asset(url, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final song = _songs[_currentIndex];

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _colorController,
            builder: (context, child) {
              return Container(
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
              );
            },
          ),

          // Blurred album art background
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
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),

                    // Favorite button
                    InkWell(
                      onTap: () {
                        setState(() {
                          song['favorite'] = song['favorite'] == 'true'
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

                // Album Art
                Center(
                  child: Column(
                    children: [
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        song['artist'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Lyrics & Player Section
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
                            final newPos = Duration(seconds: value.toInt());
                            await _player.seek(newPos);
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(_position),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              _formatTime(_duration),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: _playPrevSong,
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white.withOpacity(0.08),
                                child: const Icon(
                                  Icons.skip_previous,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 30),
                            InkWell(
                              onTap: _togglePlay,
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white.withOpacity(0.15),
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 30),
                            InkWell(
                              onTap: _playNextSong,
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white.withOpacity(0.08),
                                child: const Icon(
                                  Icons.skip_next,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
