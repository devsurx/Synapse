import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';

import '../services/pdf_service.dart';
import 'quiz_screen.dart';
import 'flashcard_screen.dart';
import 'Eli5LabScreen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'onboarding_screen.dart';

class SubtleAdWidget extends StatefulWidget {
  const SubtleAdWidget({super.key});

  @override
  State<SubtleAdWidget> createState() => _SubtleAdWidgetState();
}

class _SubtleAdWidgetState extends State<SubtleAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-3940256099942544/2247696110', // Test ID
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("Ad failed to load: $error");
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 72,
      alignment: Alignment.center,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

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
  List<String> _todos = [];
  String? _fileName;
  List<double> _weeklyPoints = [2, 5, 8, 4, 9, 6, 3];

  int _gardenLevel = 1;
  double _gardenExp = 0.3;

  @override
  void initState() {
    super.initState();
    _loadAllData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildGardenStatus(),
              const SizedBox(height: 30),
              _buildBentoHero(), // Now full width without timer
              const SizedBox(height: 16),
              _buildFeatureRow(),
              const SizedBox(height: 32),
              _buildGlassCard(title: "WEEKLY MOMENTUM", child: _buildChart()),
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
                Text(
                  "GARDEN LEVEL $_gardenLevel",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: _gardenExp,
                  backgroundColor: Colors.white10,
                  color: const Color(0xFF8DAA91),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          const Text(
            "1,240 Studying Now",
            style: TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow() {
    return Row(
      children: [
        Expanded(
          child: _glassContainer(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FlashcardScreen()),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.style_rounded, size: 18, color: Color(0xFFD4A373)),
                SizedBox(width: 8),
                Text(
                  "FLASHCARDS",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _glassContainer(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Eli5LabScreen()),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.biotech_rounded, size: 18, color: Color(0xFF8DAA91)),
                SizedBox(width: 8),
                Text(
                  "ELI5 LAB",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "GOOD MORNING",
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white24),
          onPressed: () => _showLogoutDialog(),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to log out? Your garden progress will be saved.",
          style: TextStyle(color: Colors.white70),
        ),
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
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                  (route) => false,
                );
              }
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

  Widget _buildBentoHero() {
    return _glassContainer(
      height: 140,
      gradient: LinearGradient(
        colors: [
          const Color(0xFF8DAA91).withOpacity(0.5),
          const Color(0xFF8DAA91).withOpacity(0.1),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            "AI analyzes your document for Quizzes & Flashcards",
            style: TextStyle(fontSize: 11, color: Colors.white70),
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
                getTitlesWidget: (v, m) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][v.toInt()],
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
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

  Widget _buildTodoInput() {
    return TextField(
      onSubmitted: (v) {
        if (v.isNotEmpty) {
          setState(() => _todos.add(v));
          _saveTodos();
        }
      },
      decoration: InputDecoration(
        hintText: "Add mission...",
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

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('todos', _todos);
  }

  Widget _buildTodoList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _todos.length + (_todos.isNotEmpty ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == 1 && _todos.isNotEmpty) return const SubtleAdWidget();
        final todoIndex = (i > 1) ? i - 1 : i;
        if (todoIndex < _todos.length) return _buildTodoTile(todoIndex);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTodoTile(int index) {
    return Dismissible(
      key: Key(_todos[index] + index.toString()),
      onDismissed: (direction) async {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _todos.removeAt(index);
          _gardenExp += 0.1;
          if (_gardenExp >= 1.0) {
            _gardenExp = 0.0;
            _gardenLevel++;
          }
        });
        await prefs.setStringList('todos', _todos);
        await prefs.setInt('garden_level', _gardenLevel);
        await prefs.setDouble('garden_exp', _gardenExp);
        HapticFeedback.lightImpact();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.circle_outlined,
              size: 20,
              color: const Color(0xFF8DAA91).withOpacity(0.5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _todos[index],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const Icon(Icons.chevron_left, size: 14, color: Colors.white10),
          ],
        ),
      ),
    );
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
    }
  }
}
