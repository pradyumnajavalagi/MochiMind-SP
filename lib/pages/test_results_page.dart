import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/api_service.dart';

// A simple data class to hold the results of the test.
class TestSummary {
  final int forgotCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final int totalQuestions;
  final double score;

  TestSummary({
    required this.forgotCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
  })  : totalQuestions = forgotCount + hardCount + goodCount + easyCount,
        score = (forgotCount + hardCount + goodCount + easyCount) > 0
            ? (easyCount * 1.0 + goodCount * 0.75 + hardCount * 0.25) /
            (forgotCount + hardCount + goodCount + easyCount) * 100
            : 0.0;
}

class TestResultsPage extends StatefulWidget {
  final List<Map<String, dynamic>> testResults;
  final List<Flashcard> testedFlashcards;

  const TestResultsPage({
    super.key,
    required this.testResults,
    required this.testedFlashcards,
  });

  @override
  State<TestResultsPage> createState() => _TestResultsPageState();
}

class _TestResultsPageState extends State<TestResultsPage> {
  late TestSummary _summary;
  String _aiFeedback = '';
  bool _isFetchingFeedback = true;

  @override
  void initState() {
    super.initState();
    _summary = _calculateSummary();
    _fetchAiFeedback();
  }

  Future<void> _fetchAiFeedback() async {
    final resultsWithKanji = widget.testResults.map((result) {
      final card = widget.testedFlashcards.firstWhere(
            (c) => c.id == result['flashcard_id'],
        // Reverted to the simpler Flashcard constructor for the fallback
        orElse: () => Flashcard(
          id: '',
          userId: '',
          kanjiImageUrl: '', // Only has image URL
          onyomi: '',
          kunyomi: '',
          exampleUsage: '',
          srsLevel: 0,
          nextReviewAt: DateTime.now(),
        ),
      );
      if (card.id.isEmpty) return null;

      // Reverted to only parse the character from the placeholder URL
      final kanjiChar = Uri.parse(card.kanjiImageUrl).queryParameters['text'] ?? '?';
      return {
        ...result,
        'kanjiChar': kanjiChar,
      };
    }).whereType<Map<String, dynamic>>().toList();

    final feedback = await SupabaseService.getAiFeedback(resultsWithKanji);
    if (mounted) {
      setState(() {
        _aiFeedback = feedback;
        _isFetchingFeedback = false;
      });
    }
  }

  TestSummary _calculateSummary() {
    int forgot = 0, hard = 0, good = 0, easy = 0;
    for (var result in widget.testResults) {
      switch (result['rating']) {
        case 'forgot':
          forgot++;
          break;
        case 'hard':
          hard++;
          break;
        case 'good':
          good++;
          break;
        case 'easy':
          easy++;
          break;
      }
    }
    return TestSummary(
        forgotCount: forgot,
        hardCount: hard,
        goodCount: good,
        easyCount: easy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Test Results',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Here's your breakdown:",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800)),
            const SizedBox(height: 24),
            _buildScoreCard(_summary),
            const SizedBox(height: 24),
            _buildDonutChart(_summary),
            const SizedBox(height: 24),
            _buildAiFeedbackCard(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.home_outlined, color: Colors.white, size: 24),
          label: const Text(
            'Return to Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAiFeedbackCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text("AI Feedback",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (_isFetchingFeedback)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(width: 16),
                      Text("Analyzing your results..."),
                    ],
                  ),
                ),
              )
            else
              Text(
                _aiFeedback,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(TestSummary summary) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  '${summary.score.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                ),
                const SizedBox(height: 4),
                const Text('Your Score',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            Column(
              children: [
                Text(
                  '${summary.totalQuestions}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                ),
                const SizedBox(height: 4),
                const Text('Total Cards',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart(TestSummary summary) {
    if (summary.totalQuestions == 0) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text("No data for chart.")),
        ),
      );
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Performance Breakdown",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  startDegreeOffset: -90,
                  sections: [
                    if (summary.forgotCount > 0)
                      PieChartSectionData(
                          color: Colors.red,
                          value: summary.forgotCount.toDouble(),
                          title: '${summary.forgotCount}',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    if (summary.hardCount > 0)
                      PieChartSectionData(
                          color: Colors.orange,
                          value: summary.hardCount.toDouble(),
                          title: '${summary.hardCount}',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    if (summary.goodCount > 0)
                      PieChartSectionData(
                          color: Colors.blue,
                          value: summary.goodCount.toDouble(),
                          title: '${summary.goodCount}',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    if (summary.easyCount > 0)
                      PieChartSectionData(
                          color: Colors.green,
                          value: summary.easyCount.toDouble(),
                          title: '${summary.easyCount}',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.red, 'Forgot'),
                _buildLegendItem(Colors.orange, 'Hard'),
                _buildLegendItem(Colors.blue, 'Good'),
                _buildLegendItem(Colors.green, 'Easy'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
