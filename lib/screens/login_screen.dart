import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final String userType;
  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _linkSent = false;

  Future<void> _sendMagicLink() async {
    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final acs = ActionCodeSettings(
      url: 'https://cobry-temp-check.web.app', // Ensure this matches your Firebase URL
      handleCodeInApp: true,
      iOSBundleId: 'com.cobry.tempCheck',
      androidPackageName: 'com.cobry.tempCheck',
      androidInstallApp: true,
      androidMinimumVersion: '12',
    );

    try {
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: acs,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emailForSignIn', email);

      setState(() {
        _linkSent = true;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Magic link sent! Check your inbox.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const cobryBlue = Color(0xFF00529B);
    const cobryBg = Color(0xFFF4F9FF);

    return Scaffold(
      backgroundColor: cobryBg,
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/cobry_logo.png', height: 50),
              const SizedBox(height: 40),
              Text(
                "${widget.userType[0].toUpperCase()}${widget.userType.substring(1)} Login",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cobryBlue),
              ),
              const SizedBox(height: 10),
              Text(_linkSent 
                ? "Check your email! We've sent a login link to ${_emailController.text}."
                : "Enter your email to receive a secure magic login link."
              ),
              const SizedBox(height: 40),
              if (!_linkSent) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    hintText: "name@cobry.co.uk",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15), 
                      borderSide: BorderSide.none
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cobryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _sendMagicLink,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("Send Magic Link", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                const Center(
                  child: Icon(Icons.mark_email_read_outlined, size: 80, color: cobryBlue),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _linkSent = false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Use a different email"),
                  ),
                ),
              ],
              const SizedBox(height: 25),
              // --- SPAM DISCLAIMER ---
              const Text(
                "Whilst this app is in development your 'magic link' email might go to your junk or spam folder.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Go Back", style: TextStyle(color: cobryBlue)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}