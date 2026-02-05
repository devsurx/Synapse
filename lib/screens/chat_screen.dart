import 'dart:convert';
import 'dart:ui';
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
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  GenerativeModel? _model;

  // STT State
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  // --- LOGIC (UNTOUCHED) ---
  Future<void> _initChat() async {
    await _setupModel();
    await _loadChatHistory();
  }

  Future<void> _setupModel() async {
    final prefs = await SharedPreferences.getInstance();
    final String apiKey = prefs.getString('gemini_api_key') ?? "";
    if (apiKey.isEmpty) {
      _showErrorBubble("API Key not found. Please set it up in settings.");
      return;
    }
    setState(() {
      _model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) =>
              setState(() => _controller.text = val.recognizedWords),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedChat = prefs.getString('chat_history');
    setState(() {
      if (savedChat != null) {
        _messages = List<Map<String, String>>.from(
          (jsonDecode(savedChat) as List).map(
            (item) => Map<String, String>.from(item),
          ),
        );
      } else {
        _messages = [
          {
            "role": "ai",
            "content":
                "Neural link established. How can I assist your study session?",
          },
        ];
      }
    });
    _scrollToBottom();
  }

  Future<void> _saveChatHistory() async =>
      (await SharedPreferences.getInstance()).setString(
        'chat_history',
        jsonEncode(_messages),
      );

  Future<void> _clearChat() async {
    (await SharedPreferences.getInstance()).remove('chat_history');
    setState(
      () => _messages = [
        {"role": "ai", "content": "Memory purged. Ready for a new session."},
      ],
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorBubble(String message) {
    setState(
      () =>
          _messages.add({"role": "ai", "content": message, "isError": "true"}),
    );
    _scrollToBottom();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    if (_model == null) {
      await _setupModel();
      if (_model == null) return;
    }

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
      _isListening = false;
      _controller.clear();
    });
    _speech.stop();
    _scrollToBottom();
    _saveChatHistory();

    try {
      String prompt = text;
      if (widget.studyContext != null && widget.studyContext!.isNotEmpty) {
        prompt =
            "YOU ARE A STRICT STUDY TUTOR. SOURCE: ${widget.studyContext}\n\nUSER QUESTION: $text";
      }
      final response = await _model!.generateContent([Content.text(prompt)]);
      setState(() {
        _messages.add({
          "role": "ai",
          "content": response.text ?? "Processing error.",
        });
        _isLoading = false;
      });
      _saveChatHistory();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "ai",
          "content": "System overload. Please retry.",
          "isError": "true",
        });
        _isLoading = false;
      });
      _saveChatHistory();
      _scrollToBottom();
    }
  }

  // --- REVAMPED UI ---

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF121212).withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: const Text(
            "Clear History?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "This will permanently erase the current conversation cache.",
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
              onPressed: () {
                _clearChat();
                Navigator.pop(context);
              },
              child: const Text(
                "PURGE",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Text(
                "NEXUS TUTOR",
                style: TextStyle(
                  letterSpacing: 4,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.auto_delete_outlined,
              color: Colors.white.withOpacity(0.2),
            ),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final isUser = _messages[i]["role"] == "user";
                    final isError = _messages[i]["isError"] == "true";
                    return _buildBubble(
                      isUser,
                      _messages[i]["content"]!,
                      isError,
                    );
                  },
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: const Color(0xFF8DAA91).withOpacity(0.5),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  15,
                  20,
                  isKeyboardOpen ? 20 : 110,
                ),
                child: _buildInput(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _isListening ? Colors.redAccent : Colors.white38,
                  ),
                  onPressed: _listen,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _handleSend(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: _isListening
                        ? "Listening to audio..."
                        : "Query the system...",
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _handleSend,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8DAA91),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8DAA91).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(bool isUser, String text, bool isError) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF8DAA91), Color(0xFF6A8A6E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser
              ? null
              : (isError
                    ? Colors.redAccent.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isError
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
            color: isUser
                ? Colors.black.withOpacity(0.8)
                : (isError ? Colors.redAccent : Colors.white.withOpacity(0.9)),
          ),
        ),
      ),
    );
  }
}
