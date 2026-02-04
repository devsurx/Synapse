import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../services/pdf_service.dart';
import 'flashcard_screen.dart';
import 'Eli5LabScreen.dart';
import '../garden.dart';
import '../main.dart';

// --- 1. LEVEL UP OVERLAY ---
class LevelUpOverlay extends StatelessWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: InkWell(
          onTap: onDismiss,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: const Text("🌟", style: TextStyle(fontSize: 120)),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  "NEW LEVEL REACHED",
                  style: TextStyle(
                    color: Color(0xFF8DAA91),
                    letterSpacing: 5,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "LEVEL $newLevel",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text(
                    "TAP TO CONTINUE",
                    style: TextStyle(
                      color: Colors.white54,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 2. HOME PAGE ---
class HomePage extends StatefulWidget {
  final String userName;
  final Function(String) onPdfUploaded;

  const HomePage({
    super.key,
    required this.userName,
    required this.onPdfUploaded,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isExtracting = false;
  bool _showLevelUp = false;
  List<String> _todos = [];
  String? _fileName;
  List<double> _weeklyPoints = [2, 5, 8, 4, 9, 6, 3];

  // Synced Garden Stats
  int _gardenLevel = 1;
  double _gardenExp = 0.0;

  late Timer _timeTimer;
  String _currentTime = "";
  String _greeting = "";

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timeTimer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour;
    setState(() {
      _currentTime = DateFormat('h:mm a').format(now);
      if (hour < 12) {
        _greeting = "GOOD MORNING";
      } else if (hour < 17) {
        _greeting = "GOOD AFTERNOON";
      } else {
        _greeting = "GOOD EVENING";
      }
    });
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todos = prefs.getStringList('todos') ?? [];
      _fileName = prefs.getString('current_file_name');
      _gardenLevel = prefs.getInt('garden_level') ?? 1;
      _gardenExp = prefs.getDouble('garden_exp') ?? 0.0;
      List<String>? savedPoints = prefs.getStringList('weekly_points');
      if (savedPoints != null) {
        _weeklyPoints = savedPoints.map((e) => double.parse(e)).toList();
      }
    });
  }

  // Unified EXP method used by Todos and PDF uploads
  Future<void> _addExp(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    int todayIndex = DateTime.now().weekday - 1;

    double newExp = _gardenExp + amount;
    int newLevel = _gardenLevel;

    if (newExp >= 1.0) {
      newExp = newExp - 1.0;
      newLevel++;
      setState(() => _showLevelUp = true);
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _weeklyPoints[todayIndex] += (amount * 10);
      _gardenExp = newExp;
      _gardenLevel = newLevel;
    });

    await prefs.setStringList(
      'weekly_points',
      _weeklyPoints.map((e) => e.toString()).toList(),
    );
    await prefs.setInt('garden_level', _gardenLevel);
    await prefs.setDouble('garden_exp', _gardenExp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildTopBar(),
                  const SizedBox(height: 20),
                  // Clickable Garden Status
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GardenScreen(),
                        ),
                      );
                      _loadAllData(); // Refresh when returning
                    },
                    child: _buildGardenStatus(),
                  ),
                  const SizedBox(height: 30),
                  _buildBentoHero(),
                  const SizedBox(height: 16),
                  _buildFeatureRow(),
                  const SizedBox(height: 32),
                  _buildGlassCard(
                    title: "WEEKLY MOMENTUM",
                    child: _buildChart(),
                  ),
                  const SizedBox(height: 32),
                  _buildGlassCard(
                    title: "DAILY MISSIONS",
                    child: Column(
                      children: [
                        _buildTodoInput(),
                        const SizedBox(height: 16),
                        _buildTodoList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          if (_showLevelUp)
            LevelUpOverlay(
              newLevel: _gardenLevel,
              onDismiss: () => setState(() => _showLevelUp = false),
            ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    color: Color(0xFF8DAA91),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "•  $_currentTime",
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.userName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _showLogoutDialog,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.white24,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGardenStatus() {
    return _glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          const Text("🌱", style: TextStyle(fontSize: 24)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "GARDEN LEVEL $_gardenLevel",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "${(_gardenExp * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _gardenExp,
                  backgroundColor: Colors.white10,
                  color: const Color(0xFF8DAA91),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildBentoHero() {
    return _glassContainer(
      height: 140,
      gradient: LinearGradient(
        colors: [
          const Color(0xFF8DAA91).withOpacity(0.4),
          const Color(0xFF8DAA91).withOpacity(0.05),
        ],
      ),
      onTap: _pickFile,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isExtracting ? Icons.sync : Icons.auto_awesome,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            _fileName ?? "Upload PDF to Study",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const Text(
            "AI Analysis for Quizzes & Flashcards",
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow() {
    return Row(
      children: [
        Expanded(
          child: _featureButton(
            "FLASHCARDS",
            Icons.style_rounded,
            const Color(0xFFD4A373),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FlashcardScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _featureButton(
            "ELI5 LAB",
            Icons.biotech_rounded,
            const Color(0xFF8DAA91),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Eli5LabScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return _glassContainer(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoInput() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      onSubmitted: (v) {
        if (v.isNotEmpty) {
          setState(() => _todos.add(v));
          _saveTodos();
        }
      },
      decoration: InputDecoration(
        hintText: "Add mission...",
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: const Icon(Icons.add, color: Color(0xFF8DAA91)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTodoList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _todos.length,
      itemBuilder: (context, i) => Dismissible(
        key: Key(_todos[i] + i.toString()),
        onDismissed: (_) {
          setState(() => _todos.removeAt(i));
          _addExp(0.15); // Completing a todo gives 15% progress
          _saveTodos();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.circle_outlined,
                size: 20,
                color: Colors.white24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _todos[i],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('todos', _todos);
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _isExtracting = true);
      String text = await PdfService.extractText(result.files.single.path!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_pdf_text', text);
      await prefs.setString('current_file_name', result.files.single.name);
      widget.onPdfUploaded(text);
      setState(() {
        _fileName = result.files.single.name;
        _isExtracting = false;
      });
      _addExp(0.3); // Uploading a PDF gives 30% progress
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Logout?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.white24),
            ),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "LOGOUT",
              style: TextStyle(color: Color(0xFF8DAA91)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassContainer({
    required Widget child,
    double? height,
    EdgeInsets? padding,
    VoidCallback? onTap,
    Gradient? gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: height,
            width: double.infinity,
            padding: padding ?? const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              gradient: gradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            letterSpacing: 2,
            fontSize: 10,
            color: Colors.white30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _glassContainer(child: child, padding: const EdgeInsets.all(20)),
      ],
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 15,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) => Text(
                  ['M', 'T', 'W', 'T', 'F', 'S', 'S'][v.toInt()],
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            7,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _weeklyPoints[i],
                  color: i == DateTime.now().weekday - 1
                      ? const Color(0xFF8DAA91)
                      : Colors.white10,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
