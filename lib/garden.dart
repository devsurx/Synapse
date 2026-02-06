import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

enum PomodoroPhase { focus, shortBreak, longBreak }

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _animController; // Garden breathing
  late AnimationController _pulseController; // Spotify pulse
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _timer;
  bool _isTimerRunning = false;
  bool _isMuted = false;
  bool _isLoading = true;

  // Mechanics & Spotify State
  bool _isWilted = false;
  bool _isPetting = false;
  bool _isMusicPlaying = false;

  // Timer Settings
  int _focusMins = 25;
  int _shortBreakMins = 5;
  int _longBreakMins = 15;
  int _sessionsUntilLongBreak = 4;

  // Session State
  int _secondsRemaining = 25 * 60;
  int _completedSessions = 0;
  PomodoroPhase _currentPhase = PomodoroPhase.focus;

  // Stats
  int _totalFocusMinutes = 0;
  int _currentLevel = 1;
  double _currentExp = 0.0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _setupAudio();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _focusMins = prefs.getInt('pomodoro_focus') ?? 25;
      _shortBreakMins = prefs.getInt('pomodoro_short') ?? 5;
      _longBreakMins = prefs.getInt('pomodoro_long') ?? 15;
      _sessionsUntilLongBreak = prefs.getInt('pomodoro_count') ?? 4;
      _totalFocusMinutes = prefs.getInt('focus_minutes') ?? 0;
      _currentLevel = prefs.getInt('garden_level') ?? 1;
      _currentExp = prefs.getDouble('garden_exp') ?? 0.0;
      _streak = prefs.getInt('streak') ?? 0;
      _secondsRemaining = _focusMins * 60;
      _isLoading = false;
    });
  }

  // --- Logic ---

  void _toggleTimer() async {
    HapticFeedback.lightImpact();
    if (_isTimerRunning) {
      if (_currentPhase == PomodoroPhase.focus) _triggerWither();
      _timer?.cancel();
      _pulseController.stop();
      await _audioPlayer.pause();
    } else {
      if (!_isMuted) await _audioPlayer.resume();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
            // Pulse Spotify icon if in last 60 seconds of Focus
            if (_secondsRemaining <= 60 &&
                _currentPhase == PomodoroPhase.focus &&
                _isMusicPlaying) {
              if (!_pulseController.isAnimating)
                _pulseController.repeat(reverse: true);
            }
          });
        } else {
          _handlePhaseCompletion();
        }
      });
    }
    setState(() => _isTimerRunning = !_isTimerRunning);
  }

  void _triggerWither() {
    setState(() {
      _isWilted = true;
      _streak = 0;
    });
    HapticFeedback.vibrate();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isWilted = false);
    });
  }

  void _handlePetting() {
    if (_isWilted) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPetting = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isPetting = false);
    });
  }

  void _handlePhaseCompletion() async {
    _timer?.cancel();
    _pulseController.stop();
    HapticFeedback.heavyImpact();

    if (_currentPhase == PomodoroPhase.focus) {
      _completedSessions++;
      _streak++;
      await _syncFocusProgress();
      if (_completedSessions % _sessionsUntilLongBreak == 0) {
        _currentPhase = PomodoroPhase.longBreak;
        _secondsRemaining = _longBreakMins * 60;
      } else {
        _currentPhase = PomodoroPhase.shortBreak;
        _secondsRemaining = _shortBreakMins * 60;
      }
    } else {
      _currentPhase = PomodoroPhase.focus;
      _secondsRemaining = _focusMins * 60;
    }
    setState(() => _isTimerRunning = false);
    _toggleTimer();
  }

  Future<void> _syncFocusProgress() async {
    final prefs = await SharedPreferences.getInstance();
    double newExp = _currentExp + 0.25;
    int newLevel = _currentLevel;
    if (newExp >= 1.0) {
      newExp = 0.0;
      newLevel++;
      _showUnlockPopup(newLevel);
    }
    _totalFocusMinutes += _focusMins;
    await prefs.setInt('focus_minutes', _totalFocusMinutes);
    await prefs.setInt('garden_level', newLevel);
    await prefs.setDouble('garden_exp', newExp);
    await prefs.setInt('streak', _streak);
    setState(() {
      _currentLevel = newLevel;
      _currentExp = newExp;
    });
  }

  void _launchSpotify() async {
    final Uri url = Uri.parse("spotify:home");
    if (!await launchUrl(url)) {
      await launchUrl(Uri.parse("https://open.spotify.com"));
    }
  }

  // --- UI Components ---

  Widget _buildTopBar() {
    Color accent = _isWilted ? Colors.redAccent : const Color(0xFF8DAA91);

    return Positioned(
      top: 60,
      left: 15,
      right: 15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white38),
            onPressed: _showSettings,
          ),

          // Spotify Pulse Pill
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _isMusicPlaying = !_isMusicPlaying);
              if (_isMusicPlaying) _launchSpotify();
              if (!_isMusicPlaying) _pulseController.stop();
            },
            child: ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(
                  parent: _pulseController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      border: Border.all(
                        color: _isMusicPlaying ? accent : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.music_note,
                          color: _isMusicPlaying
                              ? const Color(0xFF1DB954)
                              : Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isMusicPlaying ? "SYNCED" : "SPOTIFY",
                          style: TextStyle(
                            color: _isMusicPlaying
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white38,
            ),
            onPressed: () => setState(() {
              _isMuted = !_isMuted;
              _audioPlayer.setVolume(_isMuted ? 0 : 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenCore() {
    return Center(
      child: GestureDetector(
        onTap: _handlePetting,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, _) => Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isWilted ? Colors.red : const Color(0xFF8DAA91))
                          .withOpacity(0.1 + (_animController.value * 0.05)),
                      blurRadius: _isPetting ? 120 : 80,
                      spreadRadius: _isPetting ? 40 : 20,
                    ),
                  ],
                ),
              ),
            ),
            ...List.generate(
              math.min(5 + _currentLevel, 15),
              (i) => _buildFirefly(i),
            ),
            AnimatedScale(
              scale: _isPetting ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _isWilted ? "🥀" : _getEmoji(),
                style: const TextStyle(fontSize: 130),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Theme & Base UI ---

  String _getEmoji() => _currentLevel >= 50
      ? "🌳"
      : _currentLevel >= 20
      ? "🌸"
      : _currentLevel >= 10
      ? "🪴"
      : "🌱";

  List<Color> _getThemeGradient() {
    if (_isWilted) return [const Color(0xFF2E1B1B), const Color(0xFF0F0F0F)];
    if (_currentPhase == PomodoroPhase.shortBreak)
      return [const Color(0xFF1B2E3C), const Color(0xFF0F0F0F)];
    if (_currentPhase == PomodoroPhase.longBreak)
      return [const Color(0xFF2E1B2E), const Color(0xFF0F0F0F)];
    return [const Color(0xFF142B1A), const Color(0xFF0F0F0F)];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
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
                  const SizedBox(height: 140),
                  _buildPhaseIndicator(),
                  const SizedBox(height: 20),
                  _buildGardenCore(),
                  const SizedBox(height: 20),
                  _buildTimerDisplay(),
                  const SizedBox(height: 30),
                  _buildStartButton(),
                  const SizedBox(height: 40),
                  _buildStatsCard(),
                ],
              ),
            ),
            _buildTopBar(),
          ],
        ),
      ),
    );
  }

  // --- Support Widgets ---

  Widget _buildPhaseIndicator() {
    String label = _isWilted
        ? "RECOVERING..."
        : (_currentPhase == PomodoroPhase.focus
              ? "DEEP FOCUS ACTIVE"
              : "RECOVERY PHASE");
    Color color = _isWilted
        ? Colors.redAccent
        : (_currentPhase == PomodoroPhase.focus
              ? const Color(0xFF8DAA91)
              : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Text(
      "${(_secondsRemaining ~/ 60)}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
      style: const TextStyle(
        fontSize: 100,
        fontWeight: FontWeight.w100,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _toggleTimer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
        decoration: BoxDecoration(
          color: _isTimerRunning
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFF8DAA91),
          borderRadius: BorderRadius.circular(40),
          border: _isTimerRunning ? Border.all(color: Colors.white24) : null,
        ),
        child: Text(
          _isTimerRunning ? "ABANDON SESSION" : "START MISSION",
          style: TextStyle(
            color: _isTimerRunning ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

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
                    "LVL $_currentLevel",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "STREAK: $_streak",
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _currentExp,
                backgroundColor: Colors.white10,
                color: const Color(0xFF8DAA91),
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirefly(int i) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final t = _animController.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(math.cos(t + i) * 130, math.sin(t + i) * 130),
          child: Container(
            width: 2,
            height: 2,
            decoration: const BoxDecoration(
              color: Color(0xFF8DAA91),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 30,
            right: 30,
            top: 30,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "NEURAL TIMER CONFIG",
                style: TextStyle(
                  color: Color(0xFF8DAA91),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildSlider("Focus Duration", _focusMins, 5, 120, (v) {
                setModalState(() {
                  _focusMins = v.toInt();
                  if (_shortBreakMins > _focusMins)
                    _shortBreakMins = _focusMins;
                  if (_longBreakMins > _focusMins) _longBreakMins = _focusMins;
                });
              }),
              _buildSlider(
                "Short Break",
                _shortBreakMins,
                2,
                120,
                (v) => setModalState(
                  () => _shortBreakMins = v.toInt() > _focusMins
                      ? _focusMins
                      : v.toInt(),
                ),
              ),
              _buildSlider(
                "Long Break",
                _longBreakMins,
                5,
                120,
                (v) => setModalState(
                  () => _longBreakMins = v.toInt() > _focusMins
                      ? _focusMins
                      : v.toInt(),
                ),
              ),
              _buildSlider(
                "Sessions Until Long Break",
                _sessionsUntilLongBreak,
                2,
                10,
                (v) => setModalState(() => _sessionsUntilLongBreak = v.toInt()),
                unit: "",
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('pomodoro_focus', _focusMins);
                  await prefs.setInt('pomodoro_short', _shortBreakMins);
                  await prefs.setInt('pomodoro_long', _longBreakMins);
                  await prefs.setInt('pomodoro_count', _sessionsUntilLongBreak);
                  setState(() {
                    _secondsRemaining = _focusMins * 60;
                    _currentPhase = PomodoroPhase.focus;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8DAA91),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "INITIALIZE CHANGES",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    int val,
    double min,
    double max,
    Function(double) onChanged, {
    String unit = "min",
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              "$val $unit",
              style: const TextStyle(
                color: Color(0xFF8DAA91),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: val.toDouble(),
          min: min,
          max: max,
          activeColor: const Color(0xFF8DAA91),
          inactiveColor: Colors.white10,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showUnlockPopup(int level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2E21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "RANK ASCENDED",
          style: TextStyle(color: Color(0xFF8DAA91), letterSpacing: 2),
        ),
        content: Text(
          "Level $level reached. The garden's bio-rhythm is strengthening.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "PROCEED",
              style: TextStyle(color: Color(0xFF8DAA91)),
            ),
          ),
        ],
      ),
    );
  }
}
