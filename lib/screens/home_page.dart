import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';

// Internal App Imports
import '../services/pdf_service.dart';
import 'flashcard_screen.dart';
import 'Eli5LabScreen.dart';

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

// --- 1. SETTINGS SCREEN ---
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            glassBox(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _apiController,
                obscureText: _isObscured,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: "GEMINI_API_CORE",
                  labelStyle: const TextStyle(
                    color: Color(0xFF8DAA91),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white24,
                    ),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8DAA91),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                "INITIALIZE SAVE",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. UPDATED GLOBAL SYNC PORTAL ---
class GlobalSyncPortal extends StatefulWidget {
  final Function(String, String) onPdfUploaded; // Updated to include filename
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  glassBox(
                    padding: const EdgeInsets.all(40),
                    child: const Icon(
                      Icons.hub_outlined,
                      size: 60,
                      color: Color(0xFF8DAA91),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "ESTABLISHING NEURAL LINK",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Upload PDF to sync across all labs",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 40),
                  glassBox(
                    onTap: _syncPdf,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    child: const Text(
                      "START SYNC",
                      style: TextStyle(
                        color: Color(0xFF8DAA91),
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

// --- 3. VIEW COPY PORTAL & RESULT SCREEN ---
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

// --- 4. REVAMPED HOME PAGE WITH PDF STATUS ---
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

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todos = prefs.getStringList('todos') ?? [];
      _gardenLevel = prefs.getInt('garden_level') ?? 1;
      _gardenExp = prefs.getDouble('garden_exp') ?? 0.0;
      _activePdfName = prefs.getString('active_pdf_name');
      List<String>? savedPoints = prefs.getStringList('weekly_points');
      if (savedPoints != null)
        _weeklyPoints = savedPoints.map((e) => double.parse(e)).toList();
    });
  }

  void _handleSyncUpload(String text, String fileName) async {
    final prefs = await SharedPreferences.getInstance();

    // Save the filename for the UI
    await prefs.setString('active_pdf_name', fileName);

    // CRITICAL: Save the actual extracted text for the Flashcard Screen
    await prefs.setString('global_synced_pdf', text);

    setState(() {
      _activePdfName = fileName;
    });

    // Keep your existing callback if needed
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

                  // --- ACTIVE PDF STATUS ---
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
                          // Pass our updated handler here
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
                  _sectionHeader("NEURAL MOMENTUM"),
                  const SizedBox(height: 16),
                  glassBox(
                    padding: const EdgeInsets.all(24),
                    child: _buildChart(),
                  ),

                  const SizedBox(height: 32),
                  _sectionHeader("DAILY MISSIONS"),
                  const SizedBox(height: 16),
                  glassBox(
                    padding: const EdgeInsets.all(16),
                    child: _buildTodoList(),
                  ),

                  const SizedBox(height: 100),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ACTIVE NEURAL SOURCE",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 8,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _activePdfName!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white24, size: 16),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('active_pdf_name');
              await prefs.remove('global_synced_pdf'); // Add this line
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
        glassBox(
          padding: const EdgeInsets.all(10),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
          child: const Icon(
            Icons.settings_input_component_rounded,
            color: Colors.white70,
            size: 20,
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
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              height: 6,
              width: (MediaQuery.of(context).size.width - 48) * _gardenExp,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8DAA91).withOpacity(0.4),
                    blurRadius: 10,
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFF8DAA91), Color(0xFFA3C4BC)],
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _portalTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return glassBox(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 100,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 15,
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            7,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _weeklyPoints[i],
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8DAA91), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  width: 12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodoList() {
    return Column(
      children: [
        TextField(
          onSubmitted: (v) {
            if (v.isNotEmpty) {
              setState(() => _todos.add(v));
              _addExp(0.05);
            }
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            hintText: "ADD MISSION...",
            hintStyle: TextStyle(
              color: Colors.white24,
              letterSpacing: 2,
              fontSize: 10,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.add, color: Color(0xFF8DAA91), size: 18),
          ),
        ),
        ..._todos.map(
          (e) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              e,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            leading: const Icon(
              Icons.radio_button_off_rounded,
              color: Colors.white10,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

// --- LEVEL UP OVERLAY ---
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black54,
        child: InkWell(
          onTap: onDismiss,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "EVOLUTION COMPLETE",
                  style: TextStyle(
                    color: Color(0xFF8DAA91),
                    letterSpacing: 5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "LVL $newLevel",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  "TAP TO CONTINUE",
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 2,
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
