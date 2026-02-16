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
  static const Color charcoalGrey = Color(0xFF424242);

  List<FlSpot> _clientSpots = [];
  List<FlSpot> _staffSpots = [];

  Future<Map<String, double>> _fetchData() async {
    double avgClientHappiness = 0;
    double avgStaffSatisfaction = 0;

    // Define the 24-hour window
    final DateTime now = DateTime.now();
    final DateTime twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    final Timestamp startTime = Timestamp.fromDate(twentyFourHoursAgo);

    try {
      // 1. Fetch Client Data from last 24hrs
      final clientQuery = await _db
          .collection('feedback_clients')
          .where('timestamp', isGreaterThanOrEqualTo: startTime)
          .orderBy('timestamp', descending: true)
          .get();

      if (clientQuery.docs.isNotEmpty) {
        double totalScore = 0;
        _clientSpots = clientQuery.docs.map((doc) {
          final d = doc.data();
          double score = ((d['support'] + d['quality'] + d['speed']) / 30) * 100;
          totalScore += score;
          return FlSpot(d['timestamp'].millisecondsSinceEpoch.toDouble(), score);
        }).toList();
        
        avgClientHappiness = totalScore / clientQuery.docs.length;
        _clientSpots.sort((a, b) => a.x.compareTo(b.x));
      }

      // 2. Fetch Staff Data from last 24hrs
      final staffQuery = await _db
          .collection('feedback_staff')
          .where('timestamp', isGreaterThanOrEqualTo: startTime)
          .orderBy('timestamp', descending: true)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        double totalScore = 0;
        _staffSpots = staffQuery.docs.map((doc) {
          final d = doc.data();
          double score = (d['feeling_score'] / 10) * 100;
          totalScore += score;
          return FlSpot(d['timestamp'].millisecondsSinceEpoch.toDouble(), score);
        }).toList();

        avgStaffSatisfaction = totalScore / staffQuery.docs.length;
        _staffSpots.sort((a, b) => a.x.compareTo(b.x));
      }
    } catch (e) {
      debugPrint("Error fetching results: $e");
    }

    return {'client': avgClientHappiness, 'staff': avgStaffSatisfaction};
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
                
                Row(
                  children: [
                    Expanded(child: _buildKPICard("Avg. Client Happiness | Last 24hrs", scores['client']!)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildKPICard("Avg. Staff Satisfaction | Last 24hrs", scores['staff']!)),
                  ],
                ),
                
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Sentiment Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cobryBlue)),
                ),
                const SizedBox(height: 20),
                
                SizedBox(height: 250, child: _buildAreaChart()),
                
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem("Staff", cobryBlue),
                    const SizedBox(width: 25),
                    _buildLegendItem("Clients", cobryGreen),
                  ],
                ),

                const SizedBox(height: 40),
                
                // Looker Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: null, 
                    icon: const Icon(Icons.analytics_outlined, size: 20, color: Colors.white70),
                    label: const Text("Explore in Looker (coming soon)", style: TextStyle(color: Colors.white70)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: charcoalGrey,
                      disabledBackgroundColor: charcoalGrey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),

                // Done Button
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
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
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
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: (percentage == 0) ? 0 : percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade100,
                  color: statusColor,
                ),
              ),
              Text(percentage == 0 ? "N/A" : "${percentage.round()}%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaChart() {
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
                  child: Text(DateFormat('HH:mm').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text("${value.toInt()}%", style: const TextStyle(fontSize: 10)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _clientSpots, 
            isCurved: true, 
            color: cobryGreen, 
            barWidth: 4, 
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: cobryGreen.withOpacity(0.1)),
          ),
          LineChartBarData(
            spots: _staffSpots, 
            isCurved: true, 
            color: cobryBlue, 
            barWidth: 4, 
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: cobryBlue.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}