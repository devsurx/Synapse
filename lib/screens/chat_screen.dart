import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends StatefulWidget {
  final String? studyContext;
  const ChatScreen({super.key, this.studyContext});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  late final GenerativeModel _model;

  // STT State
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: 'AIzaSyCAnahv3xdlsl5Gc4lrxYYoCyR74tke2NI',
    );
    _loadChatHistory();
  }

  // --- VOICE LOGIC ---

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('STT Status: $status'),
        onError: (errorNotification) => print('STT Error: $errorNotification'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // --- PERSISTENCE LOGIC ---

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedChat = prefs.getString('chat_history');
    if (savedChat != null) {
      setState(() {
        _messages = List<Map<String, String>>.from(
          (jsonDecode(savedChat) as List).map(
            (item) => Map<String, String>.from(item),
          ),
        );
      });
    } else {
      setState(() {
        _messages = [
          {
            "role": "ai",
            "content": "I'm ready. You can type or tap the mic to speak!",
          },
        ];
      });
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', jsonEncode(_messages));
  }

  Future<void> _clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    setState(() {
      _messages = [
        {"role": "ai", "content": "History cleared. How can I help?"},
      ];
    });
  }

  // --- CHAT LOGIC ---

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
      _isListening = false; // Stop listening if voice was active
      _controller.clear();
    });
    _speech.stop();

    try {
      String prompt =
          """
YOU ARE A STRICT STUDY TUTOR. 
YOUR SOURCE MATERIAL IS LIMITED TO THIS TEXT: ${widget.studyContext}

If the user asks something NOT in the text, say: "That isn't in your notes, but I can help with [related topic from notes]."
USER QUESTION: $text
""";
      if (widget.studyContext != null && widget.studyContext!.isNotEmpty) {
        prompt = "Context: ${widget.studyContext}\n\nStudent Question: $text";
      }

      final response = await _model.generateContent([Content.text(prompt)]);

      setState(() {
        _messages.add({
          "role": "ai",
          "content": response.text ?? "I'm having trouble processing that.",
        });
        _isLoading = false;
      });
      _saveChatHistory();
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "ai",
          "content": "Error: Check your API key or connection.",
        });
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "AI TUTOR",
          style: TextStyle(
            letterSpacing: 4,
            fontSize: 12,
            color: Colors.white24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.white24,
            ),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final isUser = _messages[i]["role"] == "user";
                return _buildBubble(isUser, _messages[i]["content"]!);
              },
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 1,
              backgroundColor: Colors.transparent,
              color: Color(0xFF8DAA91),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: isKeyboardOpen ? 10 : 110,
            ),
            child: _buildInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.redAccent : Colors.white54,
                  ),
                  onPressed: _listen,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? "Listening..."
                          : "Ask your tutor...",
                      hintStyle: const TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          backgroundColor: const Color(0xFF8DAA91),
          child: IconButton(
            onPressed: _handleSend,
            icon: const Icon(Icons.arrow_upward, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // --- UI BUBBLES ---
  void _confirmClear() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Clear Chat?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _clearChat();
              Navigator.pop(context);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF8DAA91)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : null,
            bottomLeft: !isUser ? const Radius.circular(0) : null,
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
      ),
    );
  }
}
