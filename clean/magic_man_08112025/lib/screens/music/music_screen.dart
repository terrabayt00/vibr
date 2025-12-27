import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:magic/style/color/brand_color.dart';
import '../../widgets/custom_circle.dart';

class MusicScreen extends StatefulWidget {
  final VoidCallback? onMusicStopped;

  const MusicScreen({super.key, this.onMusicStopped});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> with WidgetsBindingObserver {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  List<AudioSource> _tracks = [];
  List<String> _trackNames = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _volume = 1.0;
  bool _musicModeActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Сразу запускаем инициализацию аудио
    Future.delayed(Duration.zero, () {
      _initAudio();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Останавливаем музыку при закрытии экрана
    _stopMusic();
    _player.dispose();
    super.dispose();
  }

  void _stopMusic() {
    try {
      _player.pause();
      _player.stop();
      // Вызываем колбэк для уведомления главного экрана
      if (widget.onMusicStopped != null) {
        widget.onMusicStopped!();
      }
    } catch (e) {
      print('❌ Ошибка остановки музыки: $e');
    }
  }

  Future<void> _initAudio() async {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      print('🎵 Инициализация музыкального плеера...');

      // Настраиваем аудио сессию
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      print('✅ Аудио сессия настроена');

      // Загружаем треки из папки assets/music
      await _loadTracks();

      if (_tracks.isNotEmpty) {
        print('🎵 Создаю плейлист с ${_tracks.length} трэков');
        await _playlist.addAll(_tracks);
        await _player.setAudioSource(_playlist);

        // Добавляем обработчик ошибок
        _player.playbackEventStream.listen((event) {},
            onError: (e) {
              print('❌ Ошибка воспроизведения: $e');
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'Ошибка воспроизведения: $e';
                });
              }
            });

        // Слушаем изменение трека
        _player.currentIndexStream.listen((index) {
          if (index != null && mounted) {
            setState(() {
              _currentIndex = index;
              print('🎵 Текущий трэк: ${index + 1}');
            });
          }
        });

        // Слушаем состояние воспроизведения
        _player.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
            });
          }
          print('🎵 Статус: ${state.processingState}');
        });

        // Автоматически запускаем первый трек
        try {
          await _player.play();
          if (mounted) {
            setState(() {
              _isPlaying = true;
            });
          }
        } catch (e) {
          print('⚠️ Не удалось автоматически запустить трек: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      print('✅ Музыкальный плеер готов');

    } catch (e) {
      print('❌ Ошибка инициализации аудио: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Ошибка инициализации: $e';
        });
      }
    }
  }

  Future<void> _loadTracks() async {
    if (!mounted) return;

    setState(() {
      _tracks.clear();
      _trackNames.clear();
    });

    try {
      print('🎵 Загружаю трэки из папки assets/music/...');

      // Список MP3 файлов в папке assets/music/
      // Добавьте здесь ваши реальные файлы
      final localTracks = [
        {
          'path': 'assets/music/song1.mp3',
          'name': 'ПЕРВЫЙ ТРЭК',
        },
        {
          'path': 'assets/music/song2.mp3',
          'name': 'ВТОРОЙ ТРЭК',
        },
        {
          'path': 'assets/music/song3.mp3',
          'name': 'ТРЕТИЙ ТРЭК',
        },
        {
          'path': 'assets/music/song4.mp3',
          'name': 'ЧЕТВЕРТЫЙ ТРЭК',
        },
        {
          'path': 'assets/music/song5.mp3',
          'name': 'ПЯТЫЙ ТРЭК',
        },
      ];

      int loadedCount = 0;

      for (var track in localTracks) {
        try {
          print('🔍 Проверяю файл: ${track['path']}');

          // Добавляем трек из assets
          final audioSource = AudioSource.asset(track['path']!);

          if (mounted) {
            setState(() {
              _tracks.add(audioSource);
              _trackNames.add(track['name']!);
            });
          }

          loadedCount++;
          print('✅ Добавлено: ${track['name']}');

        } catch (e) {
          print('❌ Ошибка добавления трэка ${track['path']}: $e');
        }
      }

      if (_tracks.isEmpty) {
        print('⚠️ Трэков не найдено в папке assets/music/!');
        print('ℹ️ Добавьте MP3 файлы в папку assets/music/');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Не удалось загрузить трэки';
          });
        }
      } else {
        print('🎵 Успешно загружено $loadedCount трэков');
      }

    } catch (e) {
      print('❌ Ошибка загрузки трэков: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Ошибка загрузки: $e';
        });
      }
    }
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
        print('⏸️ Пауза');
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      } else {
        await _player.play();
        print('▶️ Воспроизведение');
        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
        }
      }
    } catch (e) {
      print('❌ Ошибка play/pause: $e');
      // Если ошибка, пробуем перезапустить
      if (_tracks.isNotEmpty) {
        try {
          await _player.seek(Duration.zero, index: 0);
          await _player.play();
          if (mounted) {
            setState(() {
              _isPlaying = true;
            });
          }
        } catch (e2) {
          print('❌ Ошибка перезапуска: $e2');
        }
      }
    }
  }

  Future<void> _nextTrack() async {
    try {
      if (_currentIndex < _tracks.length - 1) {
        await _player.seekToNext();
        print('⏭️ Следующий трэк');
      } else {
        await _player.seek(Duration.zero, index: 0);
        print('🔁 Возврат к началу');
      }
    } catch (e) {
      print('❌ Ошибка next track: $e');
    }
  }

  Future<void> _previousTrack() async {
    try {
      final position = _player.position;
      if (position.inSeconds > 3) {
        await _player.seek(Duration.zero);
        print('⏮️ Начало трэка');
      } else if (_currentIndex > 0) {
        await _player.seekToPrevious();
        print('⏮️ Предыдущий трэк');
      }
    } catch (e) {
      print('❌ Ошибка previous track: $e');
    }
  }

  Future<void> _seekToTrack(int index) async {
    try {
      if (index >= 0 && index < _tracks.length) {
        await _player.seek(Duration.zero, index: index);
        await _player.play();
        if (mounted) {
          setState(() {
            _currentIndex = index;
            _isPlaying = true;
          });
        }
        print('🎵 Переход к трэку ${index + 1}');
      }
    } catch (e) {
      print('❌ Ошибка перехода к трэку: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            // Останавливаем музыку при закрытии
            _stopMusic();
            Navigator.pop(context);
          },
          icon: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.arrow_back,
              color: BrandColor.kText,
              size: 28.0,
            ),
          ),
        ),
        title: Row(
          children: [
            const Text(
              'МУЗЫКА',
              style: TextStyle(
                color: BrandColor.kText,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8.0),
            const Icon(
              Icons.arrow_drop_down,
              color: BrandColor.kText,
              size: 28.0,
            ),
            const Spacer(),
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final processingState = state?.processingState;
                final playing = state?.playing ?? false;

                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: BrandColor.kRed,
                      strokeWidth: 2,
                    ),
                  );
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    PercentageColorCircle(
                      size: 30.0,
                      color: BrandColor.kRedLight,
                      percent: 100,
                    ),
                    PercentageColorCircle(
                      size: 32.0,
                      color: playing ? BrandColor.kRed : Colors.grey,
                      percent: 25,
                      isSmall: true,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 18.0),
          ],
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/music_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Если идет загрузка, показываем индикатор
    if (_isLoading) {
      return _buildLoading();
    }

    // Если ошибка
    if (_hasError) {
      return _buildError();
    }

    // Если нет треков
    if (_tracks.isEmpty) {
      return _buildNoTracks();
    }

    // Показываем плеер
    return _buildPlayer();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: BrandColor.kRed,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          const Text(
            'ЗАГРУЗКА МУЗЫКИ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Найдено ${_tracks.length} трэков',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 80,
          ),
          const SizedBox(height: 20),
          const Text(
            'ОШИБКА ЗАГРУЗКИ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _initAudio,
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColor.kRed,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'ПОВТОРИТЬ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTracks() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.music_off,
            color: Colors.white70,
            size: 80,
          ),
          const SizedBox(height: 20),
          const Text(
            'НЕТ МУЗЫКАЛЬНЫХ ФАЙЛОВ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Добавьте MP3 файлы в папку assets/music/',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _initAudio,
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColor.kRed,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'ПОПРОБОВАТЬ СНОВА',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () => _showTrackList(context),
              icon: SizedBox(
                height: 50.0,
                width: 50.0,
                child: Image.asset('assets/images/ic_list.png'),
              ),
            ),
          ],
        ),

        const Spacer(),

        StreamBuilder<bool>(
          stream: _player.playingStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isPlaying ? 220 : 200,
              height: isPlaying ? 220 : 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isPlaying ? 25 : 20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isPlaying ? 0.4 : 0.3),
                    blurRadius: isPlaying ? 25 : 20,
                    spreadRadius: isPlaying ? 8 : 5,
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BrandColor.kRed.withOpacity(0.8),
                    BrandColor.kRedLight.withOpacity(0.4),
                  ],
                ),
              ),
              child: Icon(
                Icons.music_note,
                color: Colors.white,
                size: isPlaying ? 90 : 80,
              ),
            );
          },
        ),

        const SizedBox(height: 30),

        StreamBuilder<int?>(
          stream: _player.currentIndexStream,
          builder: (context, snapshot) {
            final index = snapshot.data ?? 0;
            return Text(
              _trackNames.isNotEmpty && index < _trackNames.length
                  ? _trackNames[index]
                  : 'ЛОКАЛЬНЫЙ ТРЭК',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            );
          },
        ),

        const SizedBox(height: 10),

        StreamBuilder<int?>(
          stream: _player.currentIndexStream,
          builder: (context, snapshot) {
            final index = snapshot.data ?? 0;
            return Text(
              'Трек ${index + 1} из ${_tracks.length}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            );
          },
        ),

        const SizedBox(height: 30),

        StreamBuilder<Duration?>(
          stream: _player.durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;

            return StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, positionSnapshot) {
                var position = positionSnapshot.data ?? Duration.zero;
                if (position > duration) position = duration;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                        activeTrackColor: BrandColor.kRed,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: BrandColor.kRed,
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble(),
                        min: 0,
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          _player.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),

        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _previousTrack,
              icon: const Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: 45,
              ),
            ),

            const SizedBox(width: 20),

            StreamBuilder<bool>(
              stream: _player.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return InkWell(
                  onTap: _playPause,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isPlaying ? 85 : 80,
                    height: isPlaying ? 85 : 80,
                    decoration: BoxDecoration(
                      color: BrandColor.kRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: BrandColor.kRed.withOpacity(isPlaying ? 0.7 : 0.5),
                          blurRadius: isPlaying ? 25 : 20,
                          spreadRadius: isPlaying ? 8 : 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: isPlaying ? 45 : 40,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 20),

            IconButton(
              onPressed: _nextTrack,
              icon: const Icon(
                Icons.skip_next,
                color: Colors.white,
                size: 45,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        StreamBuilder<double>(
          stream: _player.volumeStream,
          builder: (context, snapshot) {
            final volume = snapshot.data ?? 1.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  volume == 0 ? Icons.volume_mute : Icons.volume_down,
                  color: Colors.white70,
                  size: 24,
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: volume,
                    min: 0,
                    max: 1,
                    onChanged: (value) {
                      _player.setVolume(value);
                      if (mounted) {
                        setState(() {
                          _volume = value;
                        });
                      }
                    },
                    activeColor: BrandColor.kRed,
                    inactiveColor: Colors.white.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.volume_up,
                  color: Colors.white70,
                  size: 24,
                ),
              ],
            );
          },
        ),

        const Spacer(),

        Column(
          children: [
            Text(
              'ТРЭК ${_currentIndex + 1} / ${_tracks.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final processingState = state?.processingState;

                String status = 'ГОТОВ';
                Color statusColor = Colors.green;

                if (processingState == ProcessingState.loading) {
                  status = 'ЗАГРУЗКА...';
                  statusColor = Colors.yellow;
                } else if (processingState == ProcessingState.buffering) {
                  status = 'БУФЕРИЗАЦИЯ...';
                  statusColor = Colors.orange;
                } else if (processingState == ProcessingState.ready) {
                  status = 'ГОТОВ К ВОСПРОИЗВЕДЕНИЮ';
                  statusColor = Colors.green;
                } else if (processingState == ProcessingState.idle) {
                  status = 'ОСТАНОВЛЕНО';
                  statusColor = Colors.grey;
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  void _showTrackList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'СПИСОК ТРЭКОВ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Всего треков: ${_tracks.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _trackNames.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        color: Colors.white70,
                        size: 60,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Папка assets/music/ пуста',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Добавьте MP3 файлы',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _trackNames.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? BrandColor.kRed
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: _currentIndex == index
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        _trackNames[index],
                        style: TextStyle(
                          color: _currentIndex == index
                              ? BrandColor.kRed
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: _currentIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'Трек ${index + 1}',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: _currentIndex == index
                          ? const Icon(
                        Icons.equalizer,
                        color: BrandColor.kRed,
                      )
                          : null,
                      onTap: () {
                        _seekToTrack(index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.kRed,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'ЗАКРЫТЬ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}