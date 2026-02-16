import 'package:flutter/material.dart';
import 'login_screen.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with actual Cobry Blue hex if known (e.g., 0xFF003366)
    const Color cobryPrimary = Color(0xFF00529B); 

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder
              const FlutterLogo(size: 80), // Replace with Image.asset('assets/cobry_logo.png')
              const SizedBox(height: 20),
              const Text(
                "Temp Check",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "How are we doing today?",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 60),

              // Button 1: Client Path
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cobryPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen(userType: 'client')),
                  ),
                  child: const Text("I am a Client", style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 20),

              // Button 2: Staff Path
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: cobryPrimary, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen(userType: 'staff')),
                  ),
                  child: const Text(
                    "I am Cobry Staff",
                    style: TextStyle(fontSize: 18, color: cobryPrimary),
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