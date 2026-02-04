import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:audioplayers/audioplayers.dart'; // For Sounds
import '../services/pdf_service.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final Function(String) onPdfUploaded;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.onPdfUploaded,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Persistence & PDF State
  bool _isExtracting = false;
  List<String> _todos = [];
  String? _fileName;
  final TextEditingController _todoController = TextEditingController();
  final DateFormat _timeFormat = DateFormat('hh:mm a');

  // Pomodoro Timer State
  int _secondsLeft = 1500; // 25 Minutes
  Timer? _timer;
  bool _isTimerRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _todoController.dispose();
    super.dispose();
  }

  // --- LOGIC: PERSISTENCE ---
  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todos = prefs.getStringList('todos') ?? [];
      _fileName = prefs.getString('current_file_name');
      String? savedText = prefs.getString('saved_pdf_text');
      if (savedText != null) widget.onPdfUploaded(savedText);
    });
  }

  Future<void> _resetEverything() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _todos = [];
      _fileName = null;
      _secondsLeft = 1500;
      _isTimerRunning = false;
    });
    widget.onPdfUploaded("");

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All data wiped. Starting fresh."),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }

  // --- LOGIC: POMODORO (WITH AUDIO & HAPTICS) ---
  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      _startPomodoro();
    }
  }

  void _startPomodoro() async {
    HapticFeedback.lightImpact();
    try {
      await _audioPlayer.play(AssetSource('sounds/start_click.mp3'));
    } catch (e) {
      debugPrint("Audio play error: $e");
    }

    setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        _handleTimerComplete();
      }
    });
  }

  void _handleTimerComplete() async {
    HapticFeedback.vibrate();
    try {
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (e) {
      debugPrint("Audio play error: $e");
    }

    setState(() {
      _isTimerRunning = false;
      _secondsLeft = 1500;
    });

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Time's Up! ☕",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text("Great focus. Take a break!"),
        actions: [
          TextButton(
            onPressed: () {
              _audioPlayer.stop();
              Navigator.pop(context);
            },
            child: const Text(
              "Got it",
              style: TextStyle(color: Color(0xFF8DAA91)),
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC: PDF UPLOAD ---
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _isExtracting = true);
      String name = result.files.single.name;
      String text = await PdfService.extractText(result.files.single.path!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_pdf_text', text);
      await prefs.setString('current_file_name', name);

      widget.onPdfUploaded(text);
      setState(() {
        _fileName = name;
        _isExtracting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 30),
            _buildBentoGrid(),
            const SizedBox(height: 32),
            _buildProgressChart(),
            const SizedBox(height: 40),
            const Text(
              "DAILY TARGETS",
              style: TextStyle(
                letterSpacing: 2,
                fontSize: 12,
                color: Colors.white24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTodoInput(),
            const SizedBox(height: 16),
            _buildTodoList(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_getGreeting()}, ${widget.userName}.",
              style: const TextStyle(color: Colors.white38, fontSize: 16),
            ),
            const Text(
              "Your Space",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white24),
              onPressed: _showResetConfirmation,
            ),
            _buildClockPill(),
          ],
        ),
      ],
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Reset All Data?"),
        content: const Text("This will wipe all PDFs and plans."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _resetEverything();
              Navigator.pop(context);
            },
            child: const Text(
              "Reset",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockPill() {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _timeFormat.format(snapshot.data ?? DateTime.now()),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8DAA91),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBentoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _buildPdfTile()),
            const SizedBox(width: 16),
            Expanded(child: _buildTimerTile()),
          ],
        ),
        const SizedBox(height: 16),
        _buildQuizTile(),
      ],
    );
  }

  Widget _buildPdfTile() {
    return GestureDetector(
      onTap: _pickFile,
      child: _bentoBox(
        color: const Color(0xFF8DAA91),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isExtracting ? Icons.sync : Icons.cloud_upload_outlined,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _fileName ?? "Upload PDF",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerTile() {
    return GestureDetector(
      onTap: _toggleTimer,
      child: _bentoBox(
        color: Colors.white.withOpacity(0.05),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _isTimerRunning ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: CircularPercentIndicator(
                radius: 40.0,
                lineWidth: 4.0,
                percent: _secondsLeft / 1500,
                center: Text(
                  "${(_secondsLeft ~/ 60)}m",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isTimerRunning
                        ? const Color(0xFF8DAA91)
                        : Colors.white,
                  ),
                ),
                progressColor: const Color(0xFF8DAA91),
                backgroundColor: Colors.white10,
                circularStrokeCap: CircularStrokeCap.round,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuizTile() {
    return GestureDetector(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final savedText = prefs.getString('saved_pdf_text');
        if (savedText != null && savedText.isNotEmpty) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(studyContext: savedText),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Upload PDF first!")));
        }
      },
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Color(0xFF8DAA91)),
                SizedBox(width: 12),
                Text(
                  "Test Knowledge",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "WEEKLY ACTIVITY",
          style: TextStyle(
            letterSpacing: 2,
            fontSize: 12,
            color: Colors.white24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 10,
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                7,
                (i) => _makeBar(i, [5.0, 8.0, 4.0, 9.0, 7.0, 6.0, 3.0][i]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF8DAA91),
          width: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTodoInput() {
    return TextField(
      controller: _todoController,
      onSubmitted: (val) async {
        if (val.isEmpty) return;
        final prefs = await SharedPreferences.getInstance();
        setState(() => _todos.add(val));
        await prefs.setStringList('todos', _todos);
        _todoController.clear();
      },
      decoration: InputDecoration(
        hintText: "Add a task...",
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.add, color: Color(0xFF8DAA91)),
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
        onDismissed: (_) async {
          final prefs = await SharedPreferences.getInstance();
          setState(() => _todos.removeAt(i));
          await prefs.setStringList('todos', _todos);
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
                Icons.radio_button_off,
                size: 20,
                color: Colors.white24,
              ),
              const SizedBox(width: 16),
              Text(_todos[i], style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bentoBox({required Color color, required Widget child}) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }
}
