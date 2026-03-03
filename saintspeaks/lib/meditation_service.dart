import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'config_service.dart';

class Meditation {
  final String id;
  final String name;
  final String nameHi;
  final String description;
  final String descriptionHi;
  final int durationMinutes;
  final String category;
  final String audioUrl;
  final String instructor;
  final String difficulty;

  Meditation({
    required this.id,
    required this.name,
    required this.nameHi,
    required this.description,
    required this.descriptionHi,
    required this.durationMinutes,
    required this.category,
    required this.audioUrl,
    required this.instructor,
    required this.difficulty,
  });

  factory Meditation.fromJson(Map<String, dynamic> json) {
    return Meditation(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled Meditation',
      nameHi: json['name_hi'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      descriptionHi: json['description_hi'] ?? json['description'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 0,
      category: json['category'] ?? 'general',
      audioUrl: json['audio_url'] ?? '',
      instructor: json['instructor'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_hi': nameHi,
      'description': description,
      'description_hi': descriptionHi,
      'duration_minutes': durationMinutes,
      'category': category,
      'audio_url': audioUrl,
      'instructor': instructor,
      'difficulty': difficulty,
    };
  }

  String getLocalizedName(String languageCode) {
    return languageCode == 'hi' ? nameHi : name;
  }

  String getLocalizedDescription(String languageCode) {
    return languageCode == 'hi' ? descriptionHi : description;
  }
}

class MeditationService {
  static const String _cacheDataKey = 'cached_meditation_data';
  static const String _lastFetchKey = 'last_meditation_fetch';
  static const String _playCountPrefix = 'meditation_play_count_';
  static const String _downloadedPrefix = 'meditation_downloaded_';
  static List<Meditation>? _cachedMeditations;

  static Future<List<Meditation>> getMeditations() async {
    if (_cachedMeditations != null && _cachedMeditations!.isNotEmpty) {
      return _cachedMeditations!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheDataKey);
      final lastFetch = prefs.getString(_lastFetchKey);

      // Use cached data if less than 7 days old
      if (cachedData != null && lastFetch != null) {
        final lastFetchDate = DateTime.parse(lastFetch);
        final daysSinceLastFetch = DateTime.now().difference(lastFetchDate).inDays;

        if (daysSinceLastFetch < 7) {
          final List<dynamic> dataList = json.decode(cachedData);
          _cachedMeditations = dataList.map((json) => Meditation.fromJson(json)).toList();
          return _cachedMeditations!;
        }
      }

      // Fetch fresh data from config
      final config = await ConfigService.fetchConfig();

      if (config.meditationData.isNotEmpty) {
        _cachedMeditations = config.meditationData;

        // Cache the data
        final jsonData = json.encode(_cachedMeditations!.map((m) => m.toJson()).toList());
        await prefs.setString(_cacheDataKey, jsonData);
        await prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());

        return _cachedMeditations!;
      }
    } catch (e) {
      print('Error fetching meditations: $e');
    }

    return [];
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheDataKey);
    await prefs.remove(_lastFetchKey);
    _cachedMeditations = null;
  }

  // Track play count
  static Future<int> getPlayCount(String meditationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_playCountPrefix$meditationId') ?? 0;
  }

  static Future<void> incrementPlayCount(String meditationId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = await getPlayCount(meditationId);
    await prefs.setInt('$_playCountPrefix$meditationId', currentCount + 1);
  }

  // Track download status
  static Future<bool> isDownloaded(String meditationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_downloadedPrefix$meditationId') ?? false;
  }

  static Future<void> markAsDownloaded(String meditationId, bool downloaded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_downloadedPrefix$meditationId', downloaded);
  }

  // Get local file path for meditation
  static Future<String> getMeditationFilePath(String meditationId, {String? audioUrl}) async {
    final directory = await getApplicationDocumentsDirectory();

    // Determine file extension from URL if provided
    String extension = 'mp3'; // default
    if (audioUrl != null) {
      final uri = Uri.parse(audioUrl);
      final path = uri.path.toLowerCase();
      if (path.endsWith('.m4a')) {
        extension = 'm4a';
      } else if (path.endsWith('.aac')) {
        extension = 'aac';
      } else if (path.endsWith('.mp3')) {
        extension = 'mp3';
      }
    }

    return '${directory.path}/meditations/$meditationId.$extension';
  }

  // Helper to get file extension from meditation
  static String _getFileExtension(String audioUrl) {
    final uri = Uri.parse(audioUrl);
    final path = uri.path.toLowerCase();
    if (path.endsWith('.m4a')) return 'm4a';
    if (path.endsWith('.aac')) return 'aac';
    if (path.endsWith('.mp3')) return 'mp3';
    return 'mp3'; // default
  }

  // Download meditation file
  static Future<void> downloadMeditation(
    Meditation meditation, {
    Function(double)? onProgress,
  }) async {
    try {
      final filePath = await getMeditationFilePath(meditation.id, audioUrl: meditation.audioUrl);
      final file = File(filePath);
      final extension = _getFileExtension(meditation.audioUrl);

      // Create directory if it doesn't exist
      await file.parent.create(recursive: true);

      // Download the file
      final dio = Dio();

      // Add headers to ensure we get proper audio format
      await dio.download(
        meditation.audioUrl,
        filePath,
        options: Options(
          headers: {
            'Accept': 'audio/mpeg,audio/mp3,audio/aac,audio/mp4,audio/m4a,audio/*',
            'User-Agent': 'Talk with Saints App',
          },
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      // Validate the downloaded file
      final downloadedFile = File(filePath);
      if (await downloadedFile.exists()) {
        final size = await downloadedFile.length();
        print('Downloaded file size: $size bytes');
        print('File extension: .$extension');

        // Check if it's a valid audio file by reading header
        if (size > 100) {
          final bytes = await downloadedFile.openRead(0, 10).first;
          final header = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
          print('File header: $header');

          // Detect actual file type from header
          String detectedType = 'unknown';

          // Check for MP3 (starts with 'FF FB' or 'FF F3' or 'FF F2' or has ID3 tag)
          if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
            detectedType = 'MP3';
          } else if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
            detectedType = 'MP3 with ID3';
          }
          // Check for M4A/AAC/MP4 (starts with 00 00 00 xx 'ftyp')
          else if (bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0x00 &&
                   (bytes[3] >= 0x18 && bytes[3] <= 0x24)) {
            detectedType = 'M4A/AAC/MP4';
          }
          // Check for plain AAC (starts with 'FF Fx' where x is F0-FF)
          else if (bytes[0] == 0xFF && (bytes[1] & 0xF0) == 0xF0) {
            detectedType = 'AAC';
          }

          print('Detected file type: $detectedType');

          if (detectedType == 'unknown') {
            print('WARNING: Could not identify audio format. Header: $header');
          } else {
            print('File appears to be a valid $detectedType file');
          }
        }
      }

      // Mark as downloaded
      await markAsDownloaded(meditation.id, true);
      print('Meditation downloaded: ${meditation.name}');
    } catch (e) {
      print('Error downloading meditation: $e');
      rethrow;
    }
  }

  // Delete meditation file
  static Future<void> deleteMeditation(String meditationId, {String? audioUrl}) async {
    try {
      // Try all possible extensions if audioUrl not provided
      if (audioUrl == null) {
        final directory = await getApplicationDocumentsDirectory();
        final extensions = ['mp3', 'm4a', 'aac'];

        for (final ext in extensions) {
          final filePath = '${directory.path}/meditations/$meditationId.$ext';
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
            print('Deleted: $filePath');
          }
        }
      } else {
        final filePath = await getMeditationFilePath(meditationId, audioUrl: audioUrl);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          print('Deleted: $filePath');
        }
      }

      await markAsDownloaded(meditationId, false);
    } catch (e) {
      print('Error deleting meditation: $e');
    }
  }

  // Get categories
  static List<String> getCategories(List<Meditation> meditations) {
    final categories = meditations.map((m) => m.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Filter by category
  static List<Meditation> filterByCategory(List<Meditation> meditations, String category) {
    return meditations.where((m) => m.category == category).toList();
  }

  // Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny;
      case 'breathing':
        return Icons.air;
      case 'chakra':
        return Icons.spa;
      case 'relaxation':
        return Icons.self_improvement;
      case 'mantra':
        return Icons.music_note;
      case 'evening':
        return Icons.nightlight;
      default:
        return Icons.self_improvement;
    }
  }

  // Get difficulty color
  static Color getDifficultyColor(String difficulty, Brightness brightness) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade700;
      case 'intermediate':
        return brightness == Brightness.dark ? Colors.orange.shade300 : Colors.orange.shade700;
      case 'advanced':
        return brightness == Brightness.dark ? Colors.red.shade300 : Colors.red.shade700;
      default:
        return brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }
}

class MeditationPage extends StatefulWidget {
  @override
  _MeditationPageState createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage> {
  List<Meditation> meditations = [];
  bool isLoading = true;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadMeditations();
  }

  Future<void> _loadMeditations() async {
    try {
      final data = await MeditationService.getMeditations();
      setState(() {
        meditations = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading meditations: $e')),
      );
    }
  }

  Future<void> _refreshMeditations() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Clear ONLY the meditation list cache (keeps downloaded files and play counts)
      await MeditationService.clearCache();

      // Reload data from config
      final data = await MeditationService.getMeditations();

      setState(() {
        meditations = data;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Meditation list refreshed! Downloaded files preserved.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  List<Meditation> get filteredMeditations {
    if (selectedCategory == null || selectedCategory == 'all') {
      return meditations;
    }
    return MeditationService.filterByCategory(meditations, selectedCategory!);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meditate Deeply',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: brightness == Brightness.dark
            ? Colors.purple.shade900
            : Colors.purple.shade50,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshMeditations,
            tooltip: 'Refresh meditation list',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: brightness == Brightness.dark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.purple.shade900, Colors.grey.shade900],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.purple.shade50, Colors.white],
                ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : meditations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.self_improvement, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No meditations available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Category filter
                      _buildCategoryFilter(brightness),
                      // Meditation list
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredMeditations.length,
                          itemBuilder: (context, index) {
                            final meditation = filteredMeditations[index];
                            return _buildMeditationCard(meditation, brightness, languageCode);
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCategoryFilter(Brightness brightness) {
    final categories = ['all', ...MeditationService.getCategories(meditations)];

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category || (selectedCategory == null && category == 'all');

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category == 'all' ? 'All' : category.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category == 'all' ? null : category;
                });
              },
              selectedColor: brightness == Brightness.dark ? Colors.purple.shade700 : Colors.purple.shade100,
              backgroundColor: brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeditationCard(Meditation meditation, Brightness brightness, String languageCode) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MeditationPlayerPage(meditation: meditation),
          ),
        ).then((_) => setState(() {})),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: brightness == Brightness.dark ? Colors.purple.shade800 : Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  MeditationService.getCategoryIcon(meditation.category),
                  color: brightness == Brightness.dark ? Colors.purple.shade100 : Colors.purple.shade700,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              // Meditation info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.getLocalizedName(languageCode),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: brightness == Brightness.dark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    if (meditation.instructor.isNotEmpty)
                      Text(
                        'by ${meditation.instructor}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Text(
                          '${meditation.durationMinutes} min',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: MeditationService.getDifficultyColor(meditation.difficulty, brightness).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            meditation.difficulty.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: MeditationService.getDifficultyColor(meditation.difficulty, brightness),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: MeditationService.getPlayCount(meditation.id),
                      builder: (context, snapshot) {
                        final playCount = snapshot.data ?? 0;
                        if (playCount > 0) {
                          return Text(
                            'Played $playCount time${playCount > 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeditationPlayerPage extends StatefulWidget {
  final Meditation meditation;

  MeditationPlayerPage({required this.meditation});

  @override
  _MeditationPlayerPageState createState() => _MeditationPlayerPageState();
}

class _MeditationPlayerPageState extends State<MeditationPlayerPage> {
  bool isDownloaded = false;
  bool isDownloading = false;
  bool isPlaying = false;
  bool isPaused = false;
  double downloadProgress = 0.0;
  int playCount = 0;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  // Audio player
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _checkDownloadStatus();
    _loadPlayCount();
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();

    // Configure audio session for iOS
    if (Platform.isIOS) {
      _configureAudioSession();
    }

    // Listen to player state changes
    _audioPlayer?.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
          // Only set isPaused if we're not playing AND not completed/idle
          isPaused = !state.playing &&
                     state.processingState != ProcessingState.completed &&
                     state.processingState != ProcessingState.idle;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer?.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          totalDuration = duration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer?.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });

    // Listen to completion
    _audioPlayer?.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && mounted) {
        print('Meditation playback completed, resetting state');

        // Thoroughly reset player to allow replaying (use .then() to avoid async listener issues)
        _audioPlayer?.stop().then((_) {
          return _audioPlayer?.seek(Duration.zero);
        }).catchError((e) {
          print('Note: Error during completion reset: $e');
        });

        setState(() {
          isPlaying = false;
          isPaused = false;
          currentPosition = Duration.zero;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meditation completed! 🧘'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _configureAudioSession() async {
    if (Platform.isIOS) {
      try {
        // Configure iOS audio session for playback
        await _audioPlayer?.setAudioSource(
          AudioSource.uri(Uri.parse('asset:///assets/audio/silence.mp3')),
        ).catchError((e) {
          // Ignore error if silence file doesn't exist
          print('Note: Silence asset not found, continuing without pre-warming');
        });
      } catch (e) {
        print('Audio session pre-configuration note: $e');
      }
    }
  }

  Future<void> _checkDownloadStatus() async {
    final downloaded = await MeditationService.isDownloaded(widget.meditation.id);
    setState(() {
      isDownloaded = downloaded;
    });
  }

  Future<void> _loadPlayCount() async {
    final count = await MeditationService.getPlayCount(widget.meditation.id);
    setState(() {
      playCount = count;
    });
  }

  Future<void> _downloadAndPlay() async {
    if (isDownloaded) {
      // Play the downloaded file
      await _playMeditation();
    } else {
      // Download first
      setState(() {
        isDownloading = true;
      });

      try {
        await MeditationService.downloadMeditation(
          widget.meditation,
          onProgress: (progress) {
            setState(() {
              downloadProgress = progress;
            });
          },
        );

        setState(() {
          isDownloaded = true;
          isDownloading = false;
        });

        // Auto-play after download
        await _playMeditation();
      } catch (e) {
        setState(() {
          isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading: $e')),
        );
      }
    }
  }

  Future<void> _playMeditation() async {
    try {
      // Get the local file path with correct extension
      final filePath = await MeditationService.getMeditationFilePath(
        widget.meditation.id,
        audioUrl: widget.meditation.audioUrl,
      );
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('Audio file not found. Please download again.');
      }

      // Verify file is not empty
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Audio file is empty. Please download again.');
      }

      print('Playing meditation from: $filePath (size: $fileSize bytes)');

      // Read first few bytes to check file format
      final bytes = await file.openRead(0, 4).first;
      print('File header bytes: ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      // Increment play count
      await MeditationService.incrementPlayCount(widget.meditation.id);
      await _loadPlayCount();

      // Properly reset the player before setting new source
      print('Resetting audio player state...');
      try {
        await _audioPlayer?.stop();
        await _audioPlayer?.seek(Duration.zero);
      } catch (e) {
        print('Note: Error during reset (player may be idle): $e');
      }

      // Reset UI state
      if (mounted) {
        setState(() {
          currentPosition = Duration.zero;
          totalDuration = Duration.zero;
          isPlaying = false;
          isPaused = false;
        });
      }

      // Small delay to ensure player state is fully reset
      await Future.delayed(Duration(milliseconds: 150));

      // Try local file first, fallback to streaming on iOS if needed
      try {
        print('Setting audio source from local file...');
        await _audioPlayer?.setAudioSource(
          AudioSource.file(filePath),
        );
        print('Starting playback...');
        await _audioPlayer?.play();
        print('Playback started successfully');
      } catch (localFileError) {
        print('Local file playback failed: $localFileError');

        // iOS fallback: Try streaming from URL if local file fails
        if (Platform.isIOS) {
          print('Attempting iOS fallback: streaming from URL...');
          try {
            await _audioPlayer?.setAudioSource(
              AudioSource.uri(Uri.parse(widget.meditation.audioUrl)),
            );
            await _audioPlayer?.play();
            print('Streaming playback started successfully');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playing via streaming (local file had issues)'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (streamError) {
            print('Streaming also failed: $streamError');
            throw Exception(
              'Could not play audio. Local file error: $localFileError. '
              'Streaming error: $streamError'
            );
          }
        } else {
          rethrow;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing: ${widget.meditation.name}'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error playing meditation: $e');
      if (mounted) {
        // Provide helpful error message
        String errorMessage = 'Error playing audio';
        if (e.toString().contains('11800')) {
          errorMessage = 'Audio format not supported. Try deleting and re-downloading.';
        } else if (e.toString().contains('not found')) {
          errorMessage = 'Audio file not found. Please download first.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Delete',
              textColor: Colors.white,
              onPressed: () => _deleteMeditation(),
            ),
          ),
        );
      }
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    }
  }

  Future<void> _pauseMeditation() async {
    await _audioPlayer?.pause();
  }

  Future<void> _resumeMeditation() async {
    await _audioPlayer?.play();
  }

  Future<void> _stopMeditation() async {
    await _audioPlayer?.stop();
    await _audioPlayer?.seek(Duration.zero);
    setState(() {
      currentPosition = Duration.zero;
    });
  }

  Future<void> _deleteMeditation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Meditation'),
        content: Text('Are you sure you want to delete this meditation? You can re-download it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await MeditationService.deleteMeditation(
        widget.meditation.id,
        audioUrl: widget.meditation.audioUrl,
      );
      setState(() {
        isDownloaded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meditation deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.meditation.getLocalizedName(languageCode),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: brightness == Brightness.dark ? Colors.purple.shade900 : Colors.purple.shade50,
        actions: [
          if (isDownloaded)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: _deleteMeditation,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: brightness == Brightness.dark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.purple.shade900, Colors.grey.shade900],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.purple.shade50, Colors.white],
                ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large meditation icon
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: brightness == Brightness.dark
                          ? [Colors.purple.shade700, Colors.purple.shade900]
                          : [Colors.purple.shade100, Colors.purple.shade300],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 30,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    MeditationService.getCategoryIcon(widget.meditation.category),
                    size: 100,
                    color: brightness == Brightness.dark ? Colors.white : Colors.purple.shade800,
                  ),
                ),
                SizedBox(height: 40),

                // Meditation info
                Text(
                  widget.meditation.getLocalizedName(languageCode),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                if (widget.meditation.instructor.isNotEmpty)
                  Text(
                    'by ${widget.meditation.instructor}',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                SizedBox(height: 16),
                Text(
                  widget.meditation.getLocalizedDescription(languageCode),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),

                // Duration and difficulty
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoChip(
                      Icons.timer,
                      '${widget.meditation.durationMinutes} min',
                      brightness,
                    ),
                    SizedBox(width: 16),
                    _buildInfoChip(
                      Icons.signal_cellular_alt,
                      widget.meditation.difficulty,
                      brightness,
                      color: MeditationService.getDifficultyColor(widget.meditation.difficulty, brightness),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Play count
                if (playCount > 0)
                  Text(
                    'Played $playCount time${playCount > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),

                SizedBox(height: 40),

                // Download/Play button
                if (isDownloading)
                  Column(
                    children: [
                      CircularProgressIndicator(value: downloadProgress),
                      SizedBox(height: 16),
                      Text(
                        'Downloading... ${(downloadProgress * 100).toInt()}%',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  )
                else if (!isDownloaded)
                  ElevatedButton.icon(
                    onPressed: _downloadAndPlay,
                    icon: Icon(Icons.download),
                    label: Text(
                      'DOWNLOAD & PLAY',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  )
                else
                  // Playback controls for downloaded meditation
                  Column(
                    children: [
                      // Progress bar
                      if (totalDuration.inSeconds > 0)
                        Column(
                          children: [
                            Slider(
                              value: currentPosition.inSeconds.toDouble(),
                              max: totalDuration.inSeconds.toDouble(),
                              onChanged: (value) async {
                                final position = Duration(seconds: value.toInt());
                                await _audioPlayer?.seek(position);
                              },
                              activeColor: Colors.purple.shade700,
                              inactiveColor: Colors.grey.shade300,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(currentPosition),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  Text(
                                    _formatDuration(totalDuration),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),

                      // Play/Pause/Stop controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Stop button
                          if (isPlaying || isPaused)
                            IconButton(
                              icon: Icon(Icons.stop_circle, size: 48),
                              color: Colors.red.shade400,
                              onPressed: _stopMeditation,
                              tooltip: 'Stop',
                            ),

                          SizedBox(width: 16),

                          // Play/Pause button
                          IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled
                                  : isPaused
                                      ? Icons.play_circle_filled
                                      : Icons.play_circle_filled,
                              size: 72,
                            ),
                            color: Colors.purple.shade700,
                            onPressed: () {
                              if (isPlaying) {
                                _pauseMeditation();
                              } else if (isPaused) {
                                _resumeMeditation();
                              } else {
                                _playMeditation();
                              }
                            },
                            tooltip: isPlaying ? 'Pause' : 'Play',
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Status text
                      Text(
                        isPlaying
                            ? 'Playing...'
                            : isPaused
                                ? 'Paused'
                                : 'Ready to play',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Brightness brightness, {Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color ?? (brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color ?? (brightness == Brightness.dark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    // Dispose must be synchronous - just dispose the player
    // The player will handle cleanup internally
    _audioPlayer?.dispose();
    super.dispose();
  }
}
