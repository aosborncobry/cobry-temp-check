import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'entry_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Color cobryBlue = Color(0xFF00529B);
  static const Color cobryGreen = Color(0xFF39B54A); 
  static const Color cobryOrange = Color(0xFFFF8C00);
  static const Color cobryRed = Color(0xFFE53935);

  List<FlSpot> _clientSpots = [];
  List<FlSpot> _staffSpots = [];
  double _minX = 0;
  double _maxX = 0;
  bool _showHourly = true;

  Future<Map<String, double>> _fetchData() async {
    double clientLatest = 0;
    double staffLatest = 0;

    try {
      // 1. Fetch Client Data
      final clientQuery = await _db
          .collection('feedback_clients')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      if (clientQuery.docs.isNotEmpty) {
        final lastDoc = clientQuery.docs.first.data();
        clientLatest = ((lastDoc['support'] + lastDoc['quality'] + lastDoc['speed']) / 30) * 100;

        _clientSpots = clientQuery.docs
          .where((doc) => doc.data()['timestamp'] != null)
          .map((doc) {
            final d = doc.data();
            double score = ((d['support'] + d['quality'] + d['speed']) / 30) * 100;
            return FlSpot(d['timestamp'].millisecondsSinceEpoch.toDouble(), score);
          }).toList();
        
        // CRITICAL FIX: Sort chronologically to prevent line loops
        _clientSpots.sort((a, b) => a.x.compareTo(b.x));
      }

      // 2. Fetch Staff Data
      final staffQuery = await _db
          .collection('feedback_staff')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        final lastDoc = staffQuery.docs.first.data();
        staffLatest = (lastDoc['feeling_score'] / 10) * 100;

        _staffSpots = staffQuery.docs
          .where((doc) => doc.data()['timestamp'] != null)
          .map((doc) {
            final d = doc.data();
            return FlSpot(d['timestamp'].millisecondsSinceEpoch.toDouble(), (d['feeling_score'] / 10) * 100);
          }).toList();
        
        // CRITICAL FIX: Sort chronologically to prevent line loops
        _staffSpots.sort((a, b) => a.x.compareTo(b.x));
      }

      // Set X-axis bounds
      List<FlSpot> all = [..._clientSpots, ..._staffSpots];
      if (all.isNotEmpty) {
        all.sort((a, b) => a.x.compareTo(b.x));
        _minX = all.first.x;
        _maxX = all.last.x;
        if ((_maxX - _minX) > 86400000) _showHourly = false;
      }
    } catch (e) {
      debugPrint("Error fetching results: $e");
    }

    return {'client': clientLatest, 'staff': staffLatest};
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return cobryGreen;
    if (score > 50) return cobryOrange;
    return cobryRed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Cobry Pulse Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: cobryBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: cobryBlue));
          }

          final scores = snapshot.data ?? {'client': 0.0, 'staff': 0.0};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Image.asset('assets/cobry_logo.png', height: 50),
                const SizedBox(height: 30),
                
                // KPI Cards
                Row(
                  children: [
                    Expanded(child: _buildKPICard("Client Happiness", scores['client']!)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildKPICard("Staff Sentiment", scores['staff']!)),
                  ],
                ),
                
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Performance Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cobryBlue)),
                ),
                const SizedBox(height: 20),
                
                // The Fixed Chart
                SizedBox(height: 250, child: _buildChart()),
                
                // Legend
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem("Staff", cobryBlue),
                    const SizedBox(width: 20),
                    _buildLegendItem("Clients", cobryGreen),
                  ],
                ),

                const SizedBox(height: 40),
                
                // Looker Placeholder
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: null, 
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text("Explore in Looker (coming soon)"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),

                // Finish Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cobryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const EntryScreen()), (r) => false);
                    },
                    child: const Text("Done & Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildKPICard(String title, double percentage) {
    Color statusColor = _getScoreColor(percentage);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade100,
                  color: statusColor,
                ),
              ),
              Text("${percentage.round()}%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_showHourly ? DateFormat('HH:mm').format(date) : DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _clientSpots, 
            isCurved: true, 
            curveSmoothness: 0.35, // Balanced smoothness
            color: cobryGreen, 
            barWidth: 4, 
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: cobryGreen.withOpacity(0.05)),
          ),
          LineChartBarData(
            spots: _staffSpots, 
            isCurved: true, 
            curveSmoothness: 0.35,
            color: cobryBlue, 
            barWidth: 4, 
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: cobryBlue.withOpacity(0.05)),
          ),
        ],
      ),
    );
  }
}