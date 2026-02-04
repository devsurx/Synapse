import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

// Import your new screen files
import 'screens/home_page.dart';
import 'screens/plan_screen.dart';
import 'screens/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyCoachApp());
}

class StudyCoachApp extends StatelessWidget {
  const StudyCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8DAA91),
          secondary: Color(0xFFD4A373),
        ),
      ),
      // App starts here
      home: const SplashScreen(),
    );
  }
}

// --- FEATURE: ANIMATED SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // 1. Wait for 2 seconds to show the logo
    await Future.delayed(const Duration(seconds: 2));

    // 2. Check if user is logged in
    final prefs = await SharedPreferences.getInstance();
    final String? userName = prefs.getString('user_name');

    if (!mounted) return;

    // 3. Navigate based on result
    if (userName != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CozyAuraBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A simple, cozy logo icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8DAA91).withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  size: 80,
                  color: Color(0xFF8DAA91),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "STUDY COZY",
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w300,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _saveUser() async {
    if (_nameController.text.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text.trim());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CozyAuraBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome,",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                "What is your name?",
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Enter name...",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _saveUser,
                  child: const Text("Get Started"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MAIN NAVIGATION HOLDER ---
class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  String _userName = "friend";

  // This holds the text extracted from the PDF globally for the session
  String? _currentStudyContext;

  Future<void> _saveData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _loadPersistentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentStudyContext = prefs.getString('saved_pdf_text');
      // You can also load chat history or plans here
    });
  }

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadPersistentData(); // Load everything when app starts
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('user_name') ?? "friend");
  }

  @override
  Widget build(BuildContext context) {
    // Detects if the keyboard is open
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Prevents navbar from jumping up with keyboard
      body: Stack(
        children: [
          // 1. The Screen Content
          // Inside MainNavigationHolder in main.dart
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: [
              HomeScreen(
                userName: _userName,
                onPdfUploaded: (text) =>
                    setState(() => _currentStudyContext = text),
              ),
              // Update this line:
              PlanScreen(studyContext: _currentStudyContext),
              ChatScreen(studyContext: _currentStudyContext),
            ],
          ),

          // 2. The Floating Island Navbar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: 20,
            right: 20,
            // Hides the navbar by moving it 100px off-screen when keyboard is up
            bottom: isKeyboardVisible ? -100 : 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        0,
                        Icons.home_filled,
                        Icons.home_outlined,
                        "Home",
                      ),
                      _buildNavItem(
                        1,
                        Icons.calendar_month,
                        Icons.calendar_month_outlined,
                        "Plan",
                      ),
                      _buildNavItem(
                        2,
                        Icons.chat_bubble_rounded,
                        Icons.chat_bubble_outline,
                        "Tutor",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8DAA91).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? const Color(0xFF8DAA91) : Colors.white38,
              size: 24,
            ),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8DAA91),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- GLOBAL BACKGROUND ---
class CozyAuraBackground extends StatelessWidget {
  final Widget child;
  const CozyAuraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8DAA91).withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4A373).withOpacity(0.06),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(color: Colors.transparent),
          ),
        ),
        child,
      ],
    );
  }
}
