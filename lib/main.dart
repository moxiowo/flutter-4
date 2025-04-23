import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:math';

void main() => runApp(const MusicApp());

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '音樂播放器',
      theme: ThemeData.dark(),
      home: const MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer player = AudioPlayer();

  final List<Map<String, String>> playlist = [
    {
      "title": "好きだから",
      "url": "assets/audio/好きだから.mp3",
      "cover": "assets/images/1.jpg",
      "artist": "Yuika",
    },
    {
      "title": "夜撫でるメノウ",
      "url": "assets/audio/夜撫でるメノウ.mp3",
      "cover": "assets/images/2.jpg",
      "artist": "Ayase",
    },
    {
      "title": "たふん",
      "url": "assets/audio/たふん.mp3",
      "cover": "assets/images/3.jpg",
      "artist": "YOASOBI",
    },
  ];

  int currentIndex = 0;
  bool isShuffle = false;
  bool isRepeat = false;
  double currentVolume = 1.0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    playCurrentSong();

    player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        if (isRepeat) {
          await playCurrentSong();
        } else if (isShuffle) {
          int newIndex = currentIndex;
          while (newIndex == currentIndex && playlist.length > 1) {
            newIndex = _random.nextInt(playlist.length);
          }
          currentIndex = newIndex;
          await playCurrentSong();
        } else if (currentIndex < playlist.length - 1) {
          currentIndex++;
          await playCurrentSong();
        }
      }
    });
  }

  Future<void> playCurrentSong() async {
    await player.setAsset(playlist[currentIndex]['url']!);
    await player.setVolume(currentVolume);
    await player.play();
    setState(() {});
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Stream<DurationState> get _durationStateStream =>
      Rx.combineLatest2<Duration, Duration?, DurationState>(
        player.positionStream,
        player.durationStream,
        (position, duration) => DurationState(position, duration ?? Duration.zero),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('音樂播放器')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                playlist[currentIndex]['cover']!,
                height: 240,
                width: 240,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 100),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              playlist[currentIndex]['title']!,
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              playlist[currentIndex]['artist']!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            StreamBuilder<DurationState>(
              stream: _durationStateStream,
              builder: (context, snapshot) {
                final durationState = snapshot.data;
                final position = durationState?.position ?? Duration.zero;
                final total = durationState?.total ?? Duration.zero;

                return Column(
                  children: [
                    Slider(
                      min: 0.0,
                      max: total.inMilliseconds.toDouble(),
                      value: position.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                      onChanged: (value) {
                        player.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(position)),
                        Text(formatDuration(total)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 播放控制列
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 36,
                  onPressed: () async {
                    if (currentIndex > 0) {
                      currentIndex--;
                      await playCurrentSong();
                    }
                  },
                ),
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;
                    return IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                      iconSize: 64,
                      onPressed: () => isPlaying ? player.pause() : player.play(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 36,
                  onPressed: () async {
                    if (currentIndex < playlist.length - 1) {
                      currentIndex++;
                      await playCurrentSong();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),

            // 🔊 音量控制列（Icon + Slider）
            Row(
              children: [
                const Icon(Icons.volume_up, size: 24),
                Expanded(
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    value: currentVolume,
                    label: "${(currentVolume * 100).round()}%",
                    onChanged: (value) {
                      setState(() {
                        currentVolume = value;
                      });
                      player.setVolume(currentVolume);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),


            const SizedBox(height: 16),

            // 模式按鈕列
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    isRepeat ? Icons.repeat_one : Icons.repeat,
                    color: isRepeat ? Colors.blueAccent : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isRepeat = !isRepeat;
                      if (isRepeat) isShuffle = false;
                    });
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: isShuffle ? Colors.blueAccent : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isShuffle = !isShuffle;
                      if (isShuffle) isRepeat = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class DurationState {
  final Duration position;
  final Duration total;
  DurationState(this.position, this.total);
}
