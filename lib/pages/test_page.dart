import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/api_service.dart';
import './test_results_page.dart';

class TestPage extends StatefulWidget {
  final List<Flashcard> flashcards;

  const TestPage({
    super.key,
    required this.flashcards,
  });

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late List<Flashcard> _testQueue;
  int _currentIndex = 0;
  bool _answerVisible = false;
  double _progress = 0.0;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _currentTestResults = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  void _initializeTest() {
    _testQueue = List.from(widget.flashcards);
    setState(() {
      _isLoading = false;
      _updateProgress();
    });
  }

  void _showAnswer() {
    setState(() {
      _answerVisible = true;
    });
  }

  void _nextQuestion(String rating) async {
    final currentCard = _testQueue[_currentIndex];
    await SupabaseService.updateCardSrs(currentCard.id, rating);

    _currentTestResults.add({
      'flashcard_id': currentCard.id,
      'rating': rating,
    });

    if (rating == 'forgot') {
      _testQueue.add(currentCard);
    }

    if (_currentIndex >= _testQueue.length - 1) {
      _finishAndSaveChanges();
    } else {
      setState(() {
        _currentIndex++;
        _answerVisible = false;
        _updateProgress();
      });
    }
  }

  Future<void> _finishAndSaveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await SupabaseService.saveTestResults(_currentTestResults);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TestResultsPage(
              testResults: _currentTestResults,
              testedFlashcards: _testQueue,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not save results. $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _updateProgress() {
    if (_testQueue.isEmpty) {
      _progress = 0.0;
      return;
    }
    setState(() {
      _progress = (_currentIndex) / (_testQueue.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSaving) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          title: const Text('Saving Results'),
          backgroundColor: Colors.deepPurple,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Analyzing your results...'),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            title: const Text('Review Session'),
            backgroundColor: Colors.deepPurple),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentFlashcard = _testQueue[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        title: const Text('Review Session'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.deepPurple.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              '${_currentIndex + 1} / ${_testQueue.length}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildKanjiCard(currentFlashcard),
                  const Spacer(),
                ],
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildKanjiCard(Flashcard card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              card.kanjiImageUrl, // Reverted to non-nullable
              height: 220,
              width: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 100, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 30),
          AnimatedOpacity(
            opacity: _answerVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _answerVisible
                ? Column(
                    children: [
                      Text('Onyomi: ${card.onyomi}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Kunyomi: ${card.kunyomi}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Example: ${card.exampleUsage}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ],
                  )
                : const SizedBox(height: 70),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (!_answerVisible)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Show Answer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        if (_answerVisible)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRatingButton(
                  'Forgot', Colors.red, () => _nextQuestion('forgot')),
              _buildRatingButton(
                  'Hard', Colors.orange, () => _nextQuestion('hard')),
              _buildRatingButton(
                  'Good', Colors.blue, () => _nextQuestion('good')),
              _buildRatingButton(
                  'Easy', Colors.green, () => _nextQuestion('easy')),
            ],
          ),
      ],
    );
  }

  Widget _buildRatingButton(String text, Color color, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.white)),
        ),
      ),
    );
  }
}
