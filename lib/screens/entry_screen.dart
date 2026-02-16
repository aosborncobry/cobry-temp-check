import 'package:flutter/material.dart';
import 'login_screen.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cobry's primary blue color
    const Color cobryBlue = Color(0xFF00529B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- LOGO IS ADDED HERE ---
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Image.asset(
                  'assets/cobry_logo.png',
                  height: 80, // Adjust height as needed
                ),
              ),
              // --------------------------
              
              const Text(
                "Welcome",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: cobryBlue,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please select your role to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),
              
              // Staff Button
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cobryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen(userType: 'staff')),
                    );
                  },
                  child: const Text("I Cobry Staff", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
              
              // Client Button
              SizedBox(
                height: 60,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cobryBlue,
                    side: const BorderSide(color: cobryBlue, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen(userType: 'client')),
                    );
                  },
                  child: const Text("I am a Cobry Client", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}