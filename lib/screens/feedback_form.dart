import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'results_screen.dart'; // Ensure you have created this file!

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

  // Client Ratings (Default to middle 5)
  double _supportRating = 5;
  double _qualityRating = 5;
  double _speedRating = 5;
  
  // Staff Sentiment (Default to middle 5)
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
          // We check if doc exists to avoid null errors on data access
          if (doc.exists && doc.data() != null) {
            final data = doc.data() as Map<String, dynamic>;
            _userRole = data['role']?.toString().toLowerCase();
          } else {
             _userRole = 'client';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // If anything fails, default to showing the client form
      debugPrint("Error loading role: $e");
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
      // Save to Firestore
      await _db.collection(collection).add(data);
      
      if (!mounted) return;

      // SUCCESS! Navigate to the Results Dashboard
      // pushReplacement ensures the user can't hit "Back" to resubmit the form
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ResultsScreen()),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting feedback: $e"))
        );
        setState(() => _isLoading = false);
      }
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
        backgroundColor: Colors.white,
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
              const Text("How are you feeling about work lately?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildSliderLabel("Feeling Score", _feelingScore),
              Slider(
                value: _feelingScore, 
                min: 1, 
                max: 10, 
                divisions: 9, 
                label: _feelingScore.round().toString(),
                activeColor: cobryBlue,
                onChanged: (v) => setState(() => _feelingScore = v)
              ),
              const Center(child: Text("1 = Struggling   —   10 = Great")),
            ] else ...[
               const Text("Rate our recent performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 20),
              _buildRatingSlider("Support Experience", _supportRating, (v) => setState(() => _supportRating = v), cobryBlue),
              _buildRatingSlider("Quality of Work", _qualityRating, (v) => setState(() => _qualityRating = v), cobryBlue),
              _buildRatingSlider("Speed of Response", _speedRating, (v) => setState(() => _speedRating = v), cobryBlue),
            ],
            
            const SizedBox(height: 30),
            
            // Optional Comment Box (Available for both)
            TextField(
              controller: _commentController, 
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Any additional comments?", 
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              )
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cobryBlue, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _submitFeedback, 
                child: const Text("Submit Feedback", style: TextStyle(fontSize: 16))
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderLabel(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
          child: Text(value.round().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildRatingSlider(String label, double value, ValueChanged<double> onChanged, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        _buildSliderLabel(label, value),
        Slider(
          value: value, 
          min: 1, 
          max: 10, 
          divisions: 9, 
          label: value.round().toString(), 
          activeColor: color,
          onChanged: onChanged
        ),
      ],
    );
  }
}