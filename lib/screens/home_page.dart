import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart'; // Required for TapGestureRecognizer

// Internal App Imports
import '../services/pdf_service.dart';
import 'flashcard_screen.dart';
import 'Eli5LabScreen.dart';
import 'feynman_labscreen.dart';
import 'test_screen.dart';

class NeuralExpBar extends StatefulWidget {
  final double exp;
  final int level;
  final bool isSyncing;

  const NeuralExpBar({
    super.key,
    required this.exp,
    required this.level,
    this.isSyncing = false,
  });

  @override
  State<NeuralExpBar> createState() => _NeuralExpBarState();
}

class _NeuralExpBarState extends State<NeuralExpBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "NEURAL LEVEL ${widget.level}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "${(widget.exp * 100).toInt()}% SYNCED",
                  style: TextStyle(
                    color: const Color(0xFF8DAA91),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: widget.isSyncing
                        ? [
                            Shadow(
                              color: const Color(
                                0xFF8DAA91,
                              ).withOpacity(_glowController.value),
                              blurRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(height: 4, color: Colors.white.withOpacity(0.05)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: 4,
                    width: MediaQuery.of(context).size.width * widget.exp,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8DAA91),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8DAA91).withOpacity(
                            widget.isSyncing ? _glowController.value : 0.3,
                          ),
                          blurRadius: widget.isSyncing ? 12 : 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- NEW IMMERSIVE WRAPPER ---
class ImmersiveWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  const ImmersiveWrapper({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080A),
      appBar: title != null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                title!,
                style: const TextStyle(
                  letterSpacing: 3,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: _blurOrb(300, const Color(0xFF8DAA91).withOpacity(0.12)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _blurOrb(250, const Color(0xFFD4A373).withOpacity(0.08)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blurOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: Container(),
      ),
    );
  }
}

// --- UNIVERSAL GLASS CONTAINER ---
Widget glassBox({
  required Widget child,
  EdgeInsets? padding,
  VoidCallback? onTap,
  double blur = 15,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    ),
  );
}

// --- SPACED REPETITION TIMER COMPONENT ---
class SpacedRepetitionTimer extends StatefulWidget {
  const SpacedRepetitionTimer({super.key});

  @override
  State<SpacedRepetitionTimer> createState() => _SpacedRepetitionTimerState();
}

class _SpacedRepetitionTimerState extends State<SpacedRepetitionTimer> {
  Timer? _timer;
  Duration _timeLeft = const Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "NEXT REVIEW CYCLE",
              style: TextStyle(
                color: Color(0xFFD4A373),
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatDuration(_timeLeft),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 1 - (_timeLeft.inSeconds / (24 * 3600)),
          backgroundColor: Colors.white.withOpacity(0.05),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4A373)),
          minHeight: 2,
        ),
      ],
    );
  }
}

// --- SETTINGS SCREEN ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiController = TextEditingController();
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
      () => _apiController.text = prefs.getString('gemini_api_key') ?? "",
    );
  }

  Future<void> _saveKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiController.text.trim());
    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImmersiveWrapper(
      title: "SYSTEM CONFIG",
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- API INPUT SECTION ---
            const Text(
              "AUTHENTICATION TOKEN",
              style: TextStyle(
                color: Color(0xFF8DAA91),
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            glassBox(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _apiController,
                obscureText: _isObscured,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: "PASTE KEY HERE...",
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.1),
                    fontSize: 13,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF8DAA91).withOpacity(0.5),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- DOCUMENTATION SECTION ---
            const Text(
              "PROCURING ACCESS",
              style: TextStyle(
                color: Colors.white30,
                fontSize: 9,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            glassBox(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _instructionStep("01", "Navigate to "),
                  // Clickable Link Logic
                  _linkStep("aistudio.google.com"),
                  const SizedBox(height: 16),
                  _instructionStep(
                    "02",
                    "Sign in with a standard Google Account",
                  ),
                  _instructionStep(
                    "03",
                    "Select 'Get API Key' from the sidebar",
                  ),
                  _instructionStep("04", "Generate a new project key"),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(color: Colors.white10, thickness: 1),
                  ),

                  // AGE REQUIREMENT WARNING
                  Row(
                    children: [
                      const Icon(
                        Icons.privacy_tip_outlined,
                        color: Colors.orangeAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "LEGAL: USER MUST BE 18+ TO OPERATE GEMINI API",
                          style: TextStyle(
                            color: Colors.orangeAccent.withOpacity(0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // --- INITIALIZE BUTTON ---
            ElevatedButton(
              onPressed: _saveKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8DAA91),
                minimumSize: const Size(double.infinity, 64),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "INITIALIZE SAVE",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _instructionStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$num.",
            style: const TextStyle(
              color: Color(0xFF8DAA91),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkStep(String url) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, top: 2),
      child: GestureDetector(
        onTap: () async {
          final Uri uri = Uri.parse("https://$url");
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Text(
          url,
          style: const TextStyle(
            color: Color(0xFF8DAA91),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

// --- GLOBAL SYNC PORTAL ---
class GlobalSyncPortal extends StatefulWidget {
  final Function(String, String) onPdfUploaded;
  final Function(double) onExpGain;
  const GlobalSyncPortal({
    super.key,
    required this.onPdfUploaded,
    required this.onExpGain,
  });

  @override
  State<GlobalSyncPortal> createState() => _GlobalSyncPortalState();
}

class _GlobalSyncPortalState extends State<GlobalSyncPortal> {
  bool _loading = false;

  Future<void> _syncPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _loading = true);
      try {
        String path = result.files.single.path!;
        String fileName = result.files.single.name;
        String text = await PdfService.extractText(path);

        widget.onPdfUploaded(text, fileName);
        widget.onExpGain(0.4);

        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImmersiveWrapper(
      title: "GLOBAL SYNC",
      child: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Color(0xFF8DAA91))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- SYNC HUB ICON ---
                    glassBox(
                      padding: const EdgeInsets.all(40),
                      child: const Icon(
                        Icons.hub_outlined,
                        size: 80, // Made bigger
                        color: Color(0xFF8DAA91),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- STATUS TEXT ---
                    const Text(
                      "ESTABLISHING NEURAL LINK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18, // Increased size
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Upload PDF to sync across all labs",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // --- ACTION BUTTON ---
                    glassBox(
                      onTap: _syncPdf,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 80,
                        vertical: 22,
                      ),
                      child: const Text(
                        "INITIALIZE SYNC",
                        style: TextStyle(
                          color: Color(0xFF8DAA91),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// Helper for standard steps with bigger text
Widget _syncStep(String num, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Row(
      children: [
        Text(
          num,
          style: const TextStyle(
            color: Color(0xFF8DAA91),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

// Helper for the Clickable Link
Widget _syncLinkStep(String num, String text, String url) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          num,
          style: const TextStyle(
            color: Color(0xFF8DAA91),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14, // Slightly bigger for better readability
                height: 1.5,
              ),
              children: [
                TextSpan(text: text),
                TextSpan(
                  text: url,
                  style: const TextStyle(
                    color: Color(0xFF8DAA91),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final Uri uri = Uri.parse("https://$url");
                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      } catch (e) {
                        debugPrint("Could not launch $url: $e");
                      }
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// --- VIEW COPY PORTAL & RESULT SCREEN ---
class ViewCopyPortal extends StatefulWidget {
  const ViewCopyPortal({super.key});
  @override
  State<ViewCopyPortal> createState() => _ViewCopyPortalState();
}

class _ViewCopyPortalState extends State<ViewCopyPortal> {
  bool _loading = false;

  Future<void> _pickAndView() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _loading = true);
      String text = await PdfService.extractText(result.files.single.path!);
      setState(() => _loading = false);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultViewScreen(
              text: text,
              fileName: result.files.single.name,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImmersiveWrapper(
      title: "SANDBOX VIEW",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.document_scanner_outlined,
              size: 60,
              color: Colors.white24,
            ),
            const SizedBox(height: 20),
            const Text(
              "LOCAL EXTRACTION",
              style: TextStyle(color: Colors.white54, letterSpacing: 2),
            ),
            const SizedBox(height: 40),
            _loading
                ? const CircularProgressIndicator()
                : glassBox(
                    onTap: _pickAndView,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    child: const Text(
                      "SELECT PDF",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class ResultViewScreen extends StatelessWidget {
  final String text;
  final String fileName;
  const ResultViewScreen({
    super.key,
    required this.text,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return ImmersiveWrapper(
      title: fileName.toUpperCase(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: glassBox(
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            text,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// --- HOME PAGE ---
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
  bool _showLevelUp = false;
  List<String> _todos = [];
  List<double> _weeklyPoints = [2, 5, 8, 4, 9, 6, 3];
  int _gardenLevel = 1;
  double _gardenExp = 0.0;
  String? _activePdfName;
  bool _isSyncingExp = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Adds a mission and saves it to local storage
  Future<void> _addMission(String task) async {
    if (task.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todos.add(task.trim());
    });

    await prefs.setStringList('todos', _todos);
    HapticFeedback.lightImpact();
  }

  void _showAddObjectiveModal() {
    final TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: glassBox(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "INITIALIZE OBJECTIVE",
                style: TextStyle(
                  color: Color(0xFF8DAA91),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter mission details...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  border: InputBorder.none,
                ),
                onSubmitted: (val) => _saveNewObjective(val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _saveNewObjective(controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8DAA91),
                ),
                child: const Text(
                  "CONFIRM",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveNewObjective(String title) async {
    if (title.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todos.add(title);
    });
    await prefs.setStringList('todos', _todos);

    Navigator.pop(context);
    HapticFeedback.lightImpact();
  }

  Future<void> _completeMission(int index) async {
    // 1. Trigger the syncing animation
    setState(() => _isSyncingExp = true);

    // 2. Add the reward
    await _addExp(0.08);

    // 3. Update the list and save
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todos.removeAt(index);
    });
    await prefs.setStringList('todos', _todos);

    // FIXED: Correct HapticFeedback call
    await HapticFeedback.mediumImpact();

    // 4. Reset glow effect
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSyncingExp = false);
    });
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // FIXED: Proper null handling and data parsing
    setState(() {
      _todos = prefs.getStringList('todos') ?? [];
      _gardenLevel = prefs.getInt('garden_level') ?? 1;
      _gardenExp = prefs.getDouble('garden_exp') ?? 0.0;
      _activePdfName = prefs.getString('active_pdf_name');

      List<String>? savedPoints = prefs.getStringList('weekly_points');
      if (savedPoints != null) {
        // FIXED: tryParse to prevent crashes on bad data
        _weeklyPoints = savedPoints
            .map((e) => double.tryParse(e) ?? 0.0)
            .toList();
      } else {
        // Initialize with empty week if data doesn't exist
        _weeklyPoints = List.filled(7, 0.0);
      }
    });
  }

  void _handleSyncUpload(String text, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_pdf_name', fileName);
    await prefs.setString('global_synced_pdf', text);

    setState(() {
      _activePdfName = fileName;
    });

    widget.onPdfUploaded(text);
    debugPrint("GLOBAL SYNC COMPLETE: Saved ${text.length} characters.");
  }

  Future<void> _addExp(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    int todayIndex = DateTime.now().weekday - 1;
    double newExp = _gardenExp + amount;
    int newLevel = _gardenLevel;

    if (newExp >= 1.0) {
      newExp -= 1.0;
      newLevel++;
      setState(() => _showLevelUp = true);
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _weeklyPoints[todayIndex] = (_weeklyPoints[todayIndex] + (amount * 10))
          .clamp(0, 15);
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

  // --- NEW NEURAL AUDIT HELPERS ---
  Future<String?> _getLatestAudit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('neural_audit_latest');
  }

  Future<void> _recordMomentumPoint(double intensity) async {
    final prefs = await SharedPreferences.getInstance();

    // Get the current day of the week (0 = Monday, 6 = Sunday)
    int todayIndex = DateTime.now().weekday - 1;

    setState(() {
      // Increment today's score based on the session intensity
      _weeklyPoints[todayIndex] += intensity;

      // Optional: Also give some EXP for the session
      _addExp(intensity * 0.05);
    });

    // Persist the updated list
    await prefs.setStringList(
      'weekly_points',
      _weeklyPoints.map((e) => e.toString()).toList(),
    );
  }

  Widget _buildChart() {
    // Check if there's any data. If all are 0.0, show the flatline state.
    bool hasData = _weeklyPoints.any((value) => value > 0);

    if (!hasData) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            "NEURAL FLATLINE: NO SESSIONS RECORDED",
            style: TextStyle(
              color: Colors.white10,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Calculate the highest point to ensure the chart scales perfectly
    double maxPoint = _weeklyPoints.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: 0,
          // Dynamic scaling: Always 1 unit higher than your best session
          maxY: maxPoint + 1.0,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _weeklyPoints.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.4,
              color: const Color(0xFFD4A373),
              barWidth: 4,
              isStrokeCapRound: true,
              // Draw dots so you can see exactly where the data points are
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: const Color(0xFFD4A373),
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFD4A373).withOpacity(0.2),
                    const Color(0xFFD4A373).withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullAuditModal(BuildContext context, String fullText) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Audit",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.5),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: glassBox(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "DETAILED NEURAL AUDIT",
                            style: TextStyle(
                              color: Color(0xFFD4A373),
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white38,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 30),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            fullText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.8,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8DAA91),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "ACKNOWLEDGED",
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildNeuralDebtCard(BuildContext context, String auditText) {
    return glassBox(
      onTap: () => _showFullAuditModal(context, auditText),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_alt,
                color: Color(0xFFD4A373),
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "LATEST BRAIN GAP",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "Tap to review missing concepts",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            auditText.split('\n').take(3).join('\n'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ImmersiveWrapper(
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildTopBar(),
                  const SizedBox(height: 30),
                  _buildNeonExpBar(),

                  if (_activePdfName != null) ...[
                    const SizedBox(height: 24),
                    _buildActivePdfCard(),
                  ],

                  const SizedBox(height: 40),
                  _sectionHeader("COGNITIVE LAB"),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _bentoTile(
                          "ELI5",
                          Icons.bolt,
                          const Color(0xFF8DAA91),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Eli5LabScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _bentoTile(
                          "FLASHCARDS",
                          Icons.layers,
                          const Color(0xFFD4A373),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FlashcardScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _portalTile(
                    "ASSESSMENT LAB",
                    _activePdfName != null
                        ? "Generate 10-question exam from source"
                        : "Upload a document to unlock testing",
                    Icons.quiz_rounded,
                    _activePdfName != null
                        ? const Color(0xFF918DAA)
                        : Colors.white10,
                    () {
                      if (_activePdfName != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TestScreen(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Sync a PDF to initialize Testing Core",
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 32),
                  _sectionHeader("NEURAL ARCHIVE"),
                  const SizedBox(height: 16),

                  FutureBuilder<String?>(
                    future: _getLatestAudit(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data != null &&
                          snapshot.data!.isNotEmpty) {
                        return _buildNeuralDebtCard(context, snapshot.data!);
                      }
                      return _portalTile(
                        "NO RECENT AUDITS",
                        "Complete a Feynman session to generate data",
                        Icons.history_edu,
                        Colors.white10,
                        () {},
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  _sectionHeader("DATA INGESTION"),
                  const SizedBox(height: 16),
                  _portalTile(
                    "UPLOAD PDF",
                    "Updates Core Labs",
                    Icons.sync_alt_rounded,
                    const Color(0xFF8DAA91),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GlobalSyncPortal(
                          onPdfUploaded: _handleSyncUpload,
                          onExpGain: _addExp,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _portalTile(
                    "PDF TO TEXT",
                    "Extract Only",
                    Icons.security_rounded,
                    Colors.white24,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewCopyPortal(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _sectionHeader("STUDY TECHNIQUES"),
                  const SizedBox(height: 16),

                  if (_activePdfName != null) ...[
                    glassBox(
                      padding: const EdgeInsets.all(20),
                      child: const SpacedRepetitionTimer(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _portalTile(
                    "FEYNMAN LAB",
                    "Teach a curious student to master the topic",
                    Icons.record_voice_over_rounded,
                    const Color(0xFFA3C4BC),
                    () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FeynmanLabScreen(),
                          ),
                        ).then(
                          (_) => _loadAllData(),
                        ), // Re-syncs the chart when you return
                  ),

                  const SizedBox(height: 32),
                  _sectionHeader("NEURAL MOMENTUM"),
                  const SizedBox(height: 16),
                  glassBox(
                    padding: const EdgeInsets.all(24),
                    child: _buildChart(),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionHeader("DAILY MISSIONS"),
                      IconButton(
                        // This calls the modal function we defined earlier
                        onPressed: _showAddObjectiveModal,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF8DAA91),
                          size: 20,
                        ),
                        tooltip: 'Add New Mission',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // This is where your list of missions lives
                  glassBox(
                    padding: const EdgeInsets.all(16),
                    child: _buildTodoList(),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            if (_showLevelUp)
              LevelUpOverlay(
                newLevel: _gardenLevel,
                onDismiss: () => setState(() => _showLevelUp = false),
              ),
          ],
        ),
      ),
    );
  }

  // NOTE: Assuming _buildChart(), _buildTodoList(), _buildActivePdfCard(), _sectionHeader(), _buildTopBar(),
  // _buildNeonExpBar(), _bentoTile(), _portalTile() and LevelUpOverlay are defined below or in your 1.2k code.
  // I have included standard versions here to ensure the code compiles.

  Widget _buildTodoList() {
    if (_todos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            "NO ACTIVE OBJECTIVES",
            style: TextStyle(
              color: Colors.white10,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _todos.asMap().entries.map((entry) {
        int idx = entry.key;
        String mission = entry.value;

        return Dismissible(
          key: Key('$mission$idx'),
          direction: DismissDirection.startToEnd,
          // Trigger the reward logic on swipe
          onDismissed: (direction) => _completeMission(idx),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF8DAA91).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Color(0xFF8DAA91), size: 18),
                SizedBox(width: 10),
                Text(
                  "CLAIMING EXP...",
                  style: TextStyle(
                    color: Color(0xFF8DAA91),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            leading: const Icon(
              Icons.gps_fixed,
              color: Color(0xFF8DAA91),
              size: 16,
            ),
            title: Text(
              mission.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            subtitle: const Text(
              "SWIPE RIGHT TO FINALIZE",
              style: TextStyle(color: Colors.white24, fontSize: 8),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white10,
              size: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivePdfCard() {
    return glassBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF8DAA91),
              boxShadow: [BoxShadow(color: Color(0xFF8DAA91), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _activePdfName!.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white24, size: 16),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('active_pdf_name');
              setState(() => _activePdfName = null);
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withOpacity(0.3),
        fontSize: 10,
        letterSpacing: 4,
        fontWeight: FontWeight.w900,
      ),
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
              "OPERATOR",
              style: TextStyle(
                color: Color(0xFF8DAA91),
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.userName.toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(
            Icons.settings_input_component_rounded,
            color: Colors.white70,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildNeonExpBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "LEVEL $_gardenLevel",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${(_gardenExp * 100).toInt()}% SYNCED",
              style: const TextStyle(
                color: Color(0xFF8DAA91),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _gardenExp,
          backgroundColor: Colors.white10,
          valueColor: const AlwaysStoppedAnimation(Color(0xFF8DAA91)),
        ),
      ],
    );
  }

  Widget _bentoTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return glassBox(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _portalTile(
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return glassBox(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
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

// Placeholder for your LevelUpOverlay
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
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Text(
            "LEVEL UP: $newLevel",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
