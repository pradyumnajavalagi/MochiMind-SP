import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String _userEmail = '';
  int _streak = 0;
  double _deckRetention = 0.0;
  int _totalTested = 0;
  // --- STATE FOR CALENDAR ---
  Map<DateTime, int> _studyDates = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() { _isLoading = true; });

    // Fetch all data in parallel for better performance
    final results = await Future.wait([
      SupabaseService.getUserEmail(),
      SupabaseService.getDeckRetention(),
      SupabaseService.getCurrentStreak(),
      SupabaseService.getStudyDates(), // <-- Fetch the new data
    ]);

    final retentionData = results[1] as Map<String, dynamic>;

    if (mounted) {
      setState(() {
        _userEmail = results[0] as String;
        _deckRetention = retentionData['retention_percent'] ?? 0.0;
        _totalTested = retentionData['total_tested'] ?? 0;
        _streak = results[2] as int;
        _studyDates = results[3] as Map<DateTime, int>; // <-- Store the new data
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProfileData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildStatsCard(),
            const SizedBox(height: 24),
            _buildStreakCalendar(),
            const SizedBox(height: 100),// This will now be the real calendar
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          _userEmail,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Streak', '$_streak Days', Icons.whatshot, Colors.orange),
            _buildStatItem('Retention', '${_deckRetention.toStringAsFixed(1)}%', Icons.memory, Colors.blue),
            _buildStatItem('Tested', '$_totalTested', Icons.checklist, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  // --- UPDATED STREAK CALENDAR WIDGET ---
  Widget _buildStreakCalendar() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Study Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // The actual HeatMapCalendar widget
            HeatMapCalendar(
              datasets: _studyDates,
              colorMode: ColorMode.color,
              colorsets: const {
                1: Colors.green, // Use green for days you've studied
              },
              defaultColor: Colors.grey.shade200,
              textColor: Colors.black,
              showColorTip: false,
              monthFontSize: 16,
              weekFontSize: 12,
              weekTextColor: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
