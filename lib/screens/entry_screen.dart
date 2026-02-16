import 'package:flutter/material.dart';
import 'login_screen.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cobryBlue = Color(0xFF00529B);
    const Color cobryBg = Color(0xFFF4F9FF);

    return Scaffold(
      backgroundColor: cobryBg,
      body: Align(
        alignment: Alignment.topCenter, // Centers the column horizontally
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800), // Gemini-style width constraint
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned like Gemini
              children: [
                // --- LOGO ---
                Image.asset(
                  'assets/cobry_logo.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 60),

                // --- MAIN TITLE ---
                const Text(
                  "Cobry Temperature Checks",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: cobryBlue,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 32),

                // --- MANIFESTO TEXT (Left Aligned) ---
                const Text(
                  "At Cobry, we know that world-class delivery only happens when the people behind it are firing on all cylinders. This \"temperature check\" is a vital part of our Continuous Improvement cycle, helping us keep our standards sky-high and catch any friction before it becomes a headache.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1A202C),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Whether you’re part of the team or a partner, your honest pulse-check ensures we stay sharp, efficient, and—most importantly—constantly evolving. It only takes a second, but it’s how we make sure our work (and our relationships) stay at their absolute best.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF4A5568),
                    height: 1.6,
                  ),
                ),
                
                const SizedBox(height: 60),

                // --- BUTTONS: Grouped for easy access ---
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cobryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen(userType: 'staff')),
                            );
                          },
                          child: const Text(
                            "I am a Cobry employee",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cobryBlue,
                            side: const BorderSide(color: cobryBlue, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen(userType: 'client')),
                            );
                          },
                          child: const Text(
                            "I am a Cobry Client",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100), // Bottom breathing room
              ],
            ),
          ),
        ),
      ),
    );
  }
}