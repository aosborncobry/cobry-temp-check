import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'results_screen.dart';

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

  double _feelingScore = 5;
  final TextEditingController _commentController = TextEditingController();
  List<String> _availableClients = [];
  final Map<String, bool> _selectedClients = {};
  final Map<String, Map<String, double>> _clientProjectRatings = {};

  double _supportRating = 5;
  double _qualityRating = 5;
  double _speedRating = 5;

  @override
  void initState() {
    super.initState();
    _initialiseApp();
  }

  Future<void> _initialiseApp() async {
    await _loadUserRole();
    await _fetchClientsFromFirestore(); 
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchClientsFromFirestore() async {
    try {
      final snapshot = await _db.collection('clients').get();
      final clients = snapshot.docs.map((doc) => doc.id).toList(); 
      if (mounted) {
        setState(() {
          _availableClients = clients;
          for (var client in clients) {
            _selectedClients[client] = false;
            _clientProjectRatings[client] = {'speed': 5.0, 'quality': 5.0, 'satisfaction': 5.0};
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching clients: $e");
    }
  }

  Future<void> _loadUserRole() async {
    if (_user?.email == null) return;
    final cleanEmail = _user!.email!.trim().toLowerCase();
    try {
      DocumentSnapshot doc = await _db.collection('approved_users').doc(cleanEmail).get();
      if (!doc.exists) {
        final query = await _db.collection('approved_users').where('email', isEqualTo: cleanEmail).limit(1).get();
        if (query.docs.isNotEmpty) doc = query.docs.first;
      }
      if (mounted) {
        _userRole = (doc.exists && doc.data() != null) 
            ? (doc.data() as Map<String, dynamic>)['role']?.toString().toLowerCase() 
            : 'client';
      }
    } catch (e) {
      if (mounted) _userRole = 'client';
    }
  }

  Future<void> _submitFeedback() async {
    setState(() => _isLoading = true);
    final collection = (_userRole == 'staff') ? 'feedback_staff' : 'feedback_clients';
    Map<String, dynamic> data = {'email': _user?.email, 'timestamp': FieldValue.serverTimestamp()};

    if (_userRole == 'staff') {
      data['feeling_score'] = _feelingScore;
      data['comments'] = _commentController.text;
      Map<String, dynamic> projectFeedback = {};
      _selectedClients.forEach((client, isSelected) {
        if (isSelected) projectFeedback[client] = _clientProjectRatings[client];
      });
      data['project_performance'] = projectFeedback;
    } else {
      data['support'] = _supportRating; data['quality'] = _qualityRating; data['speed'] = _speedRating;
    }

    try {
      await _db.collection(collection).add(data);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const ResultsScreen()));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cobryBlue = Color(0xFF00529B);
    const Color cobryBg = Color(0xFFF4F9FF);

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: cobryBg,
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/cobry_logo.png', height: 40),
                const SizedBox(height: 40),
                Text(
                  _userRole == 'staff' ? "Staff Sentiment" : "Client Feedback",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: cobryBlue),
                ),
                const SizedBox(height: 10),
                Text("Logged in as ${_user?.email}", style: const TextStyle(color: Colors.blueGrey)),
                const SizedBox(height: 40),
                
                if (_userRole == 'staff') ..._buildStaffForm(cobryBlue) else ..._buildClientForm(cobryBlue),
                
                const SizedBox(height: 40),
                const Text("Additional Comments", style: TextStyle(fontWeight: FontWeight.bold, color: cobryBlue)),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController, 
                  maxLines: 3, 
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  )
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
                    onPressed: _submitFeedback, 
                    child: const Text("Submit Feedback", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStaffForm(Color color) {
    return [
      Text("How are you feeling about work lately?", 
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Slider(value: _feelingScore, min: 1, max: 10, divisions: 9, activeColor: color, onChanged: (v) => setState(() => _feelingScore = v)),
      const SizedBox(height: 40),
      Text("Which clients are you working with?", 
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 20),
      ..._availableClients.map((client) {
        bool isSelected = _selectedClients[client] ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              CheckboxListTile(
                title: Text(client, style: const TextStyle(fontWeight: FontWeight.bold)),
                value: isSelected,
                activeColor: color,
                onChanged: (bool? value) => setState(() => _selectedClients[client] = value ?? false),
              ),
              if (isSelected) 
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildNestedSlider(client, "I think the quality of responses to this client would currently score:", "quality", color),
                      _buildNestedSlider(client, "I think my speed to acknowledge and respond to this client currently scores:", "speed", color),
                      _buildNestedSlider(client, "I think this client's satisfaction is about:", "satisfaction", color),
                    ],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    ];
  }

  List<Widget> _buildClientForm(Color color) {
    return [
      _buildRatingSlider("Support Experience", _supportRating, (v) => setState(() => _supportRating = v), color),
      _buildRatingSlider("Quality of Work", _qualityRating, (v) => setState(() => _qualityRating = v), color),
      _buildRatingSlider("Speed of Delivery", _speedRating, (v) => setState(() => _speedRating = v), color),
    ];
  }

  Widget _buildNestedSlider(String client, String label, String key, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        Slider(
          value: _clientProjectRatings[client]![key]!,
          min: 1, max: 10, divisions: 9,
          activeColor: color,
          onChanged: (v) => setState(() => _clientProjectRatings[client]![key] = v),
        ),
      ],
    );
  }

  Widget _buildRatingSlider(String label, double value, ValueChanged<double> onChanged, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: value, min: 1, max: 10, divisions: 9, activeColor: color, onChanged: onChanged),
        ],
      ),
    );
  }
}