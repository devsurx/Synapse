import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isTimerRunning = false;
  bool _isMuted = false;

  int _totalFocusMinutes = 0;
  int _currentLevel = 1;
  double _currentExp = 0.0; // Added to sync with homepage
  int _streak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGardenData();
    _setupAudio();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> _loadGardenData() async {
    final prefs = await SharedPreferences.getInstance();

    int mins = prefs.getInt('focus_minutes') ?? 0;
    int streak = prefs.getInt('streak') ?? 0;
    int level = prefs.getInt('garden_level') ?? 1;
    double exp = prefs.getDouble('garden_exp') ?? 0.0;
    String? lastDateStr = prefs.getString('last_focus_date');

    if (lastDateStr != null) {
      DateTime lastDate = DateTime.parse(lastDateStr);
      DateTime today = DateTime.now();
      if (today.difference(lastDate).inDays > 1) {
        streak = 0;
        await prefs.setInt('streak', 0);
      }
    }

    setState(() {
      _totalFocusMinutes = mins;
      _currentLevel = level;
      _currentExp = exp;
      _streak = streak;
      _isLoading = false;
    });
  }

  void _toggleTimer() async {
    HapticFeedback.lightImpact();
    if (_isTimerRunning) {
      _timer?.cancel();
      await _audioPlayer.pause();
    } else {
      if (!_isMuted) await _audioPlayer.resume();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _completeSession();
        }
      });
    }
    setState(() => _isTimerRunning = !_isTimerRunning);
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();

    // EXP Logic synced with Homepage (Each session = 0.25 EXP)
    double newExp = _currentExp + 0.25;
    int newLevel = _currentLevel;

    if (newExp >= 1.0) {
      newExp = 0.0;
      newLevel++;
      _showUnlockPopup(newLevel);
    }

    int updatedStreak = _streak;
    DateTime today = DateTime.now();
    String? lastDateStr = prefs.getString('last_focus_date');

    if (lastDateStr == null) {
      updatedStreak = 1;
    } else {
      DateTime lastDate = DateTime.parse(lastDateStr);
      if (today.difference(lastDate).inDays == 1) {
        updatedStreak++;
      } else if (today.difference(lastDate).inDays > 1)
        updatedStreak = 1;
    }

    // Save using shared keys
    await prefs.setInt('focus_minutes', _totalFocusMinutes + 25);
    await prefs.setInt('garden_level', newLevel);
    await prefs.setDouble('garden_exp', newExp);
    await prefs.setInt('streak', updatedStreak);
    await prefs.setString('last_focus_date', today.toIso8601String());

    setState(() {
      _totalFocusMinutes += 25;
      _currentLevel = newLevel;
      _currentExp = newExp;
      _streak = updatedStreak;
      _isTimerRunning = false;
      _secondsRemaining = 25 * 60;
    });

    await _audioPlayer.stop();
    HapticFeedback.heavyImpact();
  }

  // Visual Rank Logic
  String _getRank() {
    if (_currentLevel >= 50) return "FOREST SPIRIT";
    if (_currentLevel >= 20) return "FLOWER CHILD";
    if (_currentLevel >= 10) return "GARDEN GUARDIAN";
    return "SEED SOWER";
  }

  String _getEmoji() {
    if (_currentLevel >= 50) return "🌳";
    if (_currentLevel >= 20) return "🌸";
    if (_currentLevel >= 10) return "🪴";
    if (_currentLevel >= 5) return "🌿";
    return "🌱";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8DAA91)),
        ),
      );
    }

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getThemeGradient(),
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  _buildGardenCore(),
                  const SizedBox(height: 20),
                  Text(
                    _getRank(),
                    style: const TextStyle(
                      color: Color(0xFF8DAA91),
                      letterSpacing: 4,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTimerDisplay(),
                  const SizedBox(height: 40),
                  _buildStartButton(),
                  const SizedBox(height: 60),
                  _buildStatsCard(),
                  const SizedBox(height: 140),
                ],
              ),
            ),
            _buildTopBar(),
          ],
        ),
      ),
    );
  }

  // UI Helper methods stay similar but use synced _currentExp
  Widget _buildStatsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(25),
          color: Colors.white.withOpacity(0.03),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "LEVEL $_currentLevel",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "STREAK: $_streak",
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _currentExp, // Linked EXP
                backgroundColor: Colors.white10,
                color: const Color(0xFF8DAA91),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Rest of garden.dart helper methods: _getThemeGradient, _buildGardenCore, etc.)
  List<Color> _getThemeGradient() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return [const Color(0xFF142B1A), const Color(0xFF0F0F0F)];
    }
    if (hour >= 11 && hour < 17) {
      return [const Color(0xFF1B2E21), const Color(0xFF0F0F0F)];
    }
    if (hour >= 17 && hour < 20) {
      return [const Color(0xFF2E241B), const Color(0xFF0F0F0F)];
    }
    return [const Color(0xFF0A141D), const Color(0xFF050505)];
  }

  Widget _buildGardenCore() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) => Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF8DAA91,
                    ).withOpacity(0.1 + (_animController.value * 0.05)),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          ...List.generate(
            math.min(5 + _currentLevel, 15),
            (i) => _buildFirefly(i),
          ),
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.08).animate(
              CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
            ),
            child: Text(_getEmoji(), style: const TextStyle(fontSize: 130)),
          ),
        ],
      ),
    );
  }

  Widget _buildFirefly(int i) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final t = _animController.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(math.cos(t + i) * 120, math.sin(t + i) * 120),
          child: Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: Color(0xFF8DAA91),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerDisplay() {
    return Text(
      "${(_secondsRemaining ~/ 60)}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
      style: const TextStyle(
        fontSize: 90,
        fontWeight: FontWeight.w100,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _toggleTimer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
        decoration: BoxDecoration(
          color: _isTimerRunning ? Colors.white10 : const Color(0xFF8DAA91),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          _isTimerRunning ? "PAUSE" : "START FOCUS",
          style: TextStyle(
            color: _isTimerRunning ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 60,
      right: 20,
      child: IconButton(
        icon: Icon(
          _isMuted ? Icons.volume_off : Icons.volume_up,
          color: Colors.white38,
        ),
        onPressed: () => setState(() {
          _isMuted = !_isMuted;
          _audioPlayer.setVolume(_isMuted ? 0 : 1);
        }),
      ),
    );
  }

  void _showUnlockPopup(int level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2E21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "LEVEL UP!",
          style: TextStyle(color: Color(0xFF8DAA91)),
        ),
        content: Text(
          "You've reached Level $level and unlocked new garden energy!",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "AWESOME",
              style: TextStyle(color: Color(0xFF8DAA91)),
            ),
          ),
        ],
      ),
    );
  }
}
