import 'package:flutter/material.dart';

class SynapseErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;

  const SynapseErrorScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1710),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🍃", style: TextStyle(fontSize: 60)),
              const SizedBox(height: 24),
              const Text(
                "A DISTURBANCE IN THE GARDEN",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Synapse encountered a small growth error. Let's refresh the environment.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8DAA91),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // This restarts the app flow to the splash screen
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text(
                  "REPLANT (RESTART)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
