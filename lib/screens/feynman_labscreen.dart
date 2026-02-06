import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'home_page.dart'; // Ensure this matches your filename for glassBox/ImmersiveWrapper

class FeynmanLabScreen extends StatefulWidget {
  const FeynmanLabScreen({super.key});

  @override
  State<FeynmanLabScreen> createState() => _FeynmanLabScreenState();
}

class _FeynmanLabScreenState extends State<FeynmanLabScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Engines
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // State Management
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _isMuted = false;
  bool _isSocraticMode = false; // New Socratic Toggle
  bool _sessionEnded = false;
  String? _pdfText;
  ChatSession? _chat;

  @override
  void initState() {
    super.initState();
    _checkNeuralLink();
    _setupTts();
    _initSpeech();
  }

  void _setupTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.1);
    await _tts.setSpeechRate(0.45);
  }

  void _initSpeech() async {
    await _speech.initialize(
      onError: (val) => debugPrint('STT Error: $val'),
      onStatus: (val) => debugPrint('STT Status: $val'),
    );
  }

  Future<void> _checkNeuralLink() async {
    final prefs = await SharedPreferences.getInstance();
    _pdfText = prefs.getString('global_synced_pdf');

    if (_pdfText == null || _pdfText!.trim().isEmpty) {
      _showLockoutDialog();
    } else {
      _initStudentAI();
    }
  }

  void _showLockoutDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AlertDialog(
            backgroundColor: const Color(0xFF0D0D0E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
            ),
            title: const Text(
              "NEURAL LINK REQUIRED",
              style: TextStyle(
                color: Colors.redAccent,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
            content: const Text(
              "Feynman Lab requires source material. Upload a PDF in 'GLOBAL SYNC' first.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "RETURN",
                  style: TextStyle(color: Color(0xFF8DAA91)),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _endSession() async {
    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    // The conversation history is already stored in the 'chat' object.
    // We send a final command to trigger the analysis.
    final response = await _chat!.sendMessage(
      Content.text("""
      TERMINATE SESSION. Perform a Final Audit.
      Compare the User's explanations against the SOURCE MATERIAL.
      
      Output the report in this exact format:
      1. MASTERED: [List topics explained correctly]
      2. KNOWLEDGE GAPS: [List specific facts or sections from the source text that were never mentioned or explained incorrectly]
      3. CRITICAL OMISSION: [The most important thing they missed]
      4. NEXT STEP: [One sentence advice]
    """),
    );

    setState(() {
      _isLoading = false;
      _sessionEnded = true;
    });

    // Inside _endSession after receiving response
    final prefs = await SharedPreferences.getInstance();
    // We save the raw analysis string to a 'recent_gaps' key
    await prefs.setString('neural_audit_latest', response.text ?? "");

    // Optional: Save a timestamp so the user knows how "stale" their knowledge is
    await prefs.setString('last_audit_date', DateTime.now().toIso8601String());

    _showAnalyticsDashboard(response.text ?? "Audit failed to initialize.");
    // 1. Get current weekly points
    List<String> points =
        prefs.getStringList('weekly_points') ??
        ['0', '0', '0', '0', '0', '0', '0'];

    // 2. Identify today (0 for Monday, 6 for Sunday)
    int today = DateTime.now().weekday - 1;

    // 3. Update the value (adding 1.0 momentum point)
    double currentVal = double.parse(points[today]);
    points[today] = (currentVal + 1.5)
        .toString(); // 1.5 is the "intensity" of a Feynman session

    // 4. Save back to disk
    await prefs.setStringList('weekly_points', points);

    // 5. Exit the lab
    Navigator.pop(context);
  }

  void _showAnalyticsDashboard(String analysis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: glassBox(
          padding: const EdgeInsets.all(25),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "NEURAL AUDIT REPORT",
                    style: TextStyle(
                      color: Color(0xFFD4A373),
                      letterSpacing: 4,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      analysis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.8,
                        fontFamily: 'Courier', // Gives it a "technical" feel
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8DAA91),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text(
                    "CLOSE & SYNC DATA",
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
    );
  }

  Future<void> _initStudentAI() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? "";
    if (apiKey.isEmpty) return;

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system("""
        You are acting as a curious student. The user is your teacher.
        SOURCE MATERIAL: $_pdfText
        
        CURRENT MODE: ${_isSocraticMode ? "SOCRATIC" : "STUDENT"}
        
        IF SOCRATIC: Do not explain anything. Only ask deep, probing questions that force the teacher to find the answer in the source text.
        IF STUDENT: Act like a 10-year-old. Ask 'Why?' and 'How?'. Admit when you are confused.
        
        GOAL: Help the teacher find gaps in their knowledge of the SOURCE MATERIAL.
      """),
    );

    _chat = model.startChat();
    _aiResponse("I'm ready to learn. What's the main idea of this document?");
  }

  void _toggleSocratic(bool value) {
    setState(() {
      _isSocraticMode = value;
      _messages.add({
        "role": "ai",
        "text": _isSocraticMode
            ? "[SYSTEM]: SOCRATIC MODE ENGAGED. I will now only ask questions."
            : "[SYSTEM]: STUDENT MODE ENGAGED. I will now listen and learn.",
      });
    });
    _initStudentAI(); // Re-initialize chat with new system instruction
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        HapticFeedback.lightImpact();
        _speech.listen(
          onResult: (val) =>
              setState(() => _controller.text = val.recognizedWords),
          listenMode: stt.ListenMode.dictation,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _sendMessage();
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    String txt = _controller.text;
    setState(() {
      _messages.add({"role": "user", "text": txt});
      _isLoading = true;
    });
    _controller.clear();

    final res = await _chat!.sendMessage(Content.text(txt));
    _aiResponse(res.text ?? "...");
    setState(() => _isLoading = false);

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _aiResponse(String text) {
    setState(() => _messages.add({"role": "ai", "text": text}));
    if (!_isMuted) _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return ImmersiveWrapper(
      title: "FEYNMAN LAB",
      child: Column(
        children: [
          _buildTopControls(),
          _buildAvatar(),
          Expanded(child: _buildChatList()),
          if (_isLoading)
            const LinearProgressIndicator(
              color: Color(0xFF8DAA91),
              backgroundColor: Colors.transparent,
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          glassBox(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Text(
                  "SOCRATIC",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Switch(
                  value: _isSocraticMode,
                  onChanged: _toggleSocratic,
                  activeColor: const Color(0xFFD4A373),
                  inactiveThumbColor: Colors.white24,
                ),
                GestureDetector(
                  onTap: _endSession,
                  child: glassBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: const Text(
                      "END SESSION",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white24,
            ),
            onPressed: () => setState(() => _isMuted = !_isMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _isListening
                  ? Colors.redAccent
                  : const Color(0xFF8DAA91).withOpacity(0.5),
              width: _isListening ? 3 : 1,
            ),
          ),
          child: const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white10,
            child: Icon(Icons.psychology, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isListening
              ? "LISTENING..."
              : (_isSocraticMode ? "SOCRATIC MODE" : "STUDENT READY"),
          style: TextStyle(
            color: _isListening ? Colors.redAccent : Colors.white24,
            fontSize: 8,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        bool isAi = _messages[index]["role"] == "ai";
        return Align(
          alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: glassBox(
              padding: const EdgeInsets.all(14),
              child: Text(
                _messages[index]["text"]!,
                style: TextStyle(
                  color: isAi ? const Color(0xFF8DAA91) : Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: glassBox(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _isListening ? Icons.stop_circle : Icons.mic,
                color: _isListening
                    ? Colors.redAccent
                    : const Color(0xFF8DAA91),
              ),
              onPressed: _toggleListening,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "Teach the concept...",
                  hintStyle: TextStyle(color: Colors.white10),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF8DAA91)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
