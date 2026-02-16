import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'entry_screen.dart'; // Ensure this import exists to go back home

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, double>> _fetchKPIScores() async {
    double clientPct = 0;
    double staffPct = 0;

    try {
      // 1. GET LATEST CLIENT SCORE
      // We order by timestamp descending to get the newest one
      final clientQuery = await _db
          .collection('feedback_clients')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (clientQuery.docs.isNotEmpty) {
        final data = clientQuery.docs.first.data();
        // Client score is average of Support, Quality, Speed (Max 30 points total)
        // Adjust field names if yours are different (e.g. 'speed' vs 'response_speed')
        double support = (data['support'] ?? 0).toDouble();
        double quality = (data['quality'] ?? 0).toDouble();
        double speed = (data['speed'] ?? 0).toDouble();
        
        // Calculation: Total Points / Max Points (30) * 100
        clientPct = ((support + quality + speed) / 30) * 100;
      }

      // 2. GET LATEST STAFF SCORE
      final staffQuery = await _db
          .collection('feedback_staff')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        final data = staffQuery.docs.first.data();
        double feeling = (data['feeling_score'] ?? 0).toDouble();
        
        // Calculation: Score / Max (10) * 100
        staffPct = (feeling / 10) * 100;
      }

    } catch (e) {
      debugPrint("Error fetching KPIs: $e");
    }

    return {
      'client': clientPct,
      'staff': staffPct,
    };
  }

  void _finish() async {
    // Sign out and return to the very beginning
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (c) => const EntryScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const cobryBlue = Color(0xFF00529B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Live Pulse"),
        backgroundColor: Colors.white,
        foregroundColor: cobryBlue,
        elevation: 0,
        automaticallyImplyLeading: false, // Hide back button
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _fetchKPIScores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final scores = snapshot.data ?? {'client': 0.0, 'staff': 0.0};

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  "Latest Feedback Scores",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // KPI CARDS ROW
                Row(
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        "Client Happiness", 
                        scores['client']!, 
                        Colors.green
                      )
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildKPICard(
                        "Staff Sentiment", 
                        scores['staff']!, 
                        cobryBlue
                      )
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Done Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cobryBlue,
                      foregroundColor: Colors.white
                    ),
                    onPressed: _finish,
                    child: const Text("Done & Sign Out"),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPICard(String title, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: color,
                ),
              ),
              Text(
                "${percentage.round()}%",
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: color
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}