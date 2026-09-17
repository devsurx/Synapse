import 'package:flutter/material.dart';

/// Minimal story card (1080x1920) for sharing focus progress.
/// Quiet by design: flat ink background, one hero numeral, no boxes,
/// glows, rules or decorations. Easy on the eye at story size.
///
/// NOTE: every TextStyle below sets `decoration: TextDecoration.none`
/// explicitly. The card is painted inside an OverlayEntry whose ambient
/// DefaultTextStyle was observed (on-device) to carry an underline —
/// without the explicit `none`, every line renders underlined.
///
/// Pure widget: painted offscreen via RepaintBoundary, saved as PNG,
//  and shared through the system share sheet.
class FocusStoryCard extends StatelessWidget {
  final int level;
  final int expPercent;
  final int focusMinutes;
  final int streak;
  final DateTime date;

  const FocusStoryCard({
    super.key,
    required this.level,
    required this.expPercent,
    required this.focusMinutes,
    required this.streak,
    required this.date,
  });

  static const Color _ink = Color(0xFF0B0F0C);
  static const Color _paper = Color(0xFFEDEFEA);
  static const Color _sage = Color(0xFF8DAA91);
  static const Color _faint = Color(0xFF9AA39B);

  // Shared guard for the overlay-ambient underline described above.
  static const TextStyle _noLine = TextStyle(
    decoration: TextDecoration.none,
  );

  String get _plant {
    if (level >= 50) return "🌳";
    if (level >= 20) return "🌸";
    if (level >= 10) return "🪴";
    return "🌱";
  }

  String get _focusValue {
    if (focusMinutes < 60) return "$focusMinutes";
    final h = focusMinutes ~/ 60;
    final m = focusMinutes % 60;
    return m == 0 ? "${h}h" : "${h}h ${m}m";
  }

  String get _focusUnit => focusMinutes < 60 ? "MINUTES" : "FOCUSED";

  String get _dateLabel {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: _noLine,
      child: Container(
        width: 1080,
        height: 1920,
        color: _ink,
        child: Stack(
          children: [
            // One soft breath of color, barely there
            Positioned(
              top: -260,
              left: 140,
              child: Container(
                width: 800,
                height: 800,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _sage.withOpacity(0.10),
                      blurRadius: 240,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 110),
              child: Column(
                children: [
                  const SizedBox(height: 190),
                  const Text(
                    "SYNAPSE",
                    style: TextStyle(
                      color: _paper,
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 20,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _dateLabel,
                    style: const TextStyle(
                      color: _faint,
                      fontSize: 27,
                      letterSpacing: 8,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const Spacer(flex: 3),
                  Text(
                    _plant,
                    style: const TextStyle(
                      fontSize: 168,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 56),
                  const Text(
                    "LEVEL",
                    style: TextStyle(
                      color: _sage,
                      fontSize: 30,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    "$level",
                    style: const TextStyle(
                      color: _paper,
                      fontSize: 300,
                      fontWeight: FontWeight.w100,
                      height: 1.05,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 110),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _quietStat(_focusValue, _focusUnit),
                      _quietStat("$streak", "DAY STREAK"),
                      _quietStat("$expPercent%", "TO NEXT LEVEL"),
                    ],
                  ),
                  const Spacer(flex: 4),
                  const Text(
                    "grow your mind",
                    style: TextStyle(
                      color: _faint,
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quietStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _paper,
              fontSize: 68,
              fontWeight: FontWeight.w600,
              height: 1.1,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _faint,
              fontSize: 22,
              letterSpacing: 4,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
