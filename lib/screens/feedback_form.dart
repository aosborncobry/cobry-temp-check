import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  
  String? _userRole;
  bool _isLoading = true;

  // Client Ratings
  double _supportRating = 5;
  double _qualityRating = 5;
  double _speedRating = 5;
  
  // Staff Sentiment
  double _feelingScore = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  // ROBUST ROLE LOOKUP (Matches AuthService logic)
  Future<void> _loadUserRole() async {
    if (_user?.email == null) return;

    final cleanEmail = _user!.email!.trim().toLowerCase();
    
    try {
      // 1. Try finding by Document ID first
      DocumentSnapshot doc = await _db.collection('approved_users').doc(cleanEmail).get();

      // 2. If not found, try finding by 'email' field (The Safety Net)
      if (!doc.exists) {
        final query = await _db
            .collection('approved_users')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();
        
        if (query.docs.isNotEmpty) {
          doc = query.docs.first;
        }
      }

      if (mounted) {
        setState(() {
          // If we found the doc, get the role. If not, default to 'client' safely.
          _userRole = doc.exists ? doc.get('role') : 'client'; 
          _isLoading = false;
        });
      }
    } catch (e) {
      // If anything fails, default to showing the client form
      if (mounted) {
        setState(() {
          _userRole = 'client';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    setState(() => _isLoading = true);
    
    // Determine collection based on the loaded role
    final collection = (_userRole == 'staff') ? 'feedback_staff' : 'feedback_clients';
    
    // Build the data packet
    final data = (_userRole == 'staff') 
      ? {
          'email': _user?.email,
          'feeling_score': _feelingScore,
          'comments': _commentController.text,
          'timestamp': FieldValue.serverTimestamp(),
        }
      : {
          'email': _user?.email,
          'support': _supportRating,
          'quality': _qualityRating,
          'speed': _speedRating,
          'timestamp': FieldValue.serverTimestamp(),
        };

    try {
      await _db.collection(collection).add(data);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback Sent!"))
      );
      
      // Sign out and go back to home
      await FirebaseAuth.instance.signOut();
      // Optional: Navigate back or force reload if needed
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"))
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cobryBlue = Color(0xFF00529B);

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cobry Temp Check"), 
        foregroundColor: cobryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Logged in as ${_user?.email}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            // DYNAMIC UI SWITCHER
            if (_userRole == 'staff') ...[
              const Text("How are you feeling about work lately?", style: TextStyle(fontSize: 18)),
              Slider(value: _feelingScore, min: 1, max: 10, divisions: 9, label: _feelingScore.round().toString(), onChanged: (v) => setState(() => _feelingScore = v)),
            ] else ...[
              _buildRatingSlider("Support", _supportRating, (v) => setState(() => _supportRating = v)),
              _buildRatingSlider("Quality", _qualityRating, (v) => setState(() => _qualityRating = v)),
              _buildRatingSlider("Response Speed", _speedRating, (v) => setState(() => _speedRating = v)),
            ],
            
            const SizedBox(height: 20),
            TextField(
              controller: _commentController, 
              decoration: const InputDecoration(
                labelText: "Any additional comments?", 
                border: OutlineInputBorder()
              )
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: cobryBlue, foregroundColor: Colors.white),
                onPressed: _submitFeedback, 
                child: const Text("Submit Feedback")
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(value: value, min: 1, max: 10, divisions: 9, label: value.round().toString(), onChanged: onChanged),
        const SizedBox(height: 10),
      ],
    );
  }
}