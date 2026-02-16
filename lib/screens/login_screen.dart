import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String userType; // 'client' or 'staff'

  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Please enter an email address", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Check if whitelisted AND matches userType (client vs staff)
      bool isAllowed = await _auth.isEmailWhitelisted(email, widget.userType);
      
      if (isAllowed) {
        // 2. SAVE EMAIL LOCALLY
        // This is critical for the PWA/Web link to complete the sign-in
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('emailForSignIn', email);

        // 3. Send the Passwordless link
        await _auth.sendLoginLink(email);
        
        if (!mounted) return;
        _showSnackBar("Success! Check your inbox for the login link.");
      } else {
        if (!mounted) return;
        _showSnackBar("Email not recognized as ${widget.userType}. Contact support.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF00529B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.userType == 'staff' ? "Staff Login" : "Client Portal";
    const Color cobryBlue = Color(0xFF00529B);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: cobryBlue)),
              const SizedBox(height: 10),
              const Text("To keep things secure and simple, we'll email you a magic login link."),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Work Email Address",
                  hintText: "email@example.com",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cobryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Send Magic Link", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}