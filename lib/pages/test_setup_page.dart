import 'package:flutter/material.dart';
import 'dart:math';
import '../models/flashcard_model.dart';
import '../services/api_service.dart';
import './test_page.dart';

class TestSetupPage extends StatefulWidget {
  const TestSetupPage({super.key});

  @override
  State<TestSetupPage> createState() => _TestSetupPageState();
}

class _TestSetupPageState extends State<TestSetupPage> {
  List<Flashcard> _reviewCards = [];
  List<Tag> _allTags = [];
  final Set<Tag> _selectedTags = {};
  bool _isLoading = true;
  int _selectedCardCount = 0;
  int _maxCards = 0;
  // --- THIS IS THE CHANGE ---
  final int _minCards = 5; // Changed from 1 to 5

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() { _isLoading = true; });
    final tags = await SupabaseService.getTagsForUser();
    if (mounted) {
      setState(() { _allTags = tags; });
    }
    await _loadReviewCards();
  }

  Future<void> _loadReviewCards() async {
    setState(() { _isLoading = true; });
    final selectedTagIds = _selectedTags.map((t) => t.id).toList();
    final cards = await SupabaseService.getReviewCards(tagIds: selectedTagIds);
    if (mounted) {
      setState(() {
        _reviewCards = cards;
        _maxCards = _reviewCards.length;
        // Clamp the selected count between the new min and the max available
        _selectedCardCount = min(10, _maxCards).clamp(_minCards, _maxCards);
        _isLoading = false;
      });
    }
  }

  void _onTagSelected(Tag tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    _loadReviewCards();
  }

  void _changeCount(int delta) {
    setState(() {
      _selectedCardCount = (_selectedCardCount + delta).clamp(_minCards, _maxCards);
    });
  }

  void _setCount(int count) {
    setState(() {
      _selectedCardCount = count.clamp(_minCards, _maxCards);
    });
  }

  void _startTest() {
    final testDeck = List<Flashcard>.from(_reviewCards)..shuffle();
    final selectedDeck = testDeck.sublist(0, _selectedCardCount);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestPage(flashcards: selectedDeck),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canStartTest = _reviewCards.length >= _minCards;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        title: const Text('Review Session'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading && _reviewCards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildTagFilterSection(),
            const Divider(height: 30),
            if (!canStartTest)
              _buildNotEnoughCardsMessage()
            else
              _buildTestSetupSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTagFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Filter by Tags (Optional)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_allTags.isEmpty)
          const Text("No tags created yet.", style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _allTags.map((tag) {
              return FilterChip(
                label: Text(tag.name),
                selected: _selectedTags.contains(tag),
                onSelected: (_) => _onTagSelected(tag),
                selectedColor: Colors.deepPurple,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: _selectedTags.contains(tag) ? Colors.white : Colors.black,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTestSetupSection() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You have $_maxCards cards due for review.',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'How many cards to test?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.deepPurple, size: 40),
                onPressed: _selectedCardCount > _minCards ? () => _changeCount(-1) : null,
              ),
              const SizedBox(width: 20),
              Text('$_selectedCardCount', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.deepPurple, size: 40),
                onPressed: _selectedCardCount < _maxCards ? () => _changeCount(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Min: $_minCards, Max: $_maxCards', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 40),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildPresetButton(10),
              _buildPresetButton(20),
              _buildPresetButton(50),
              _buildPresetButton(_maxCards, label: 'All'),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
              label: const Text('Start Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
              onPressed: _selectedCardCount >= _minCards ? _startTest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotEnoughCardsMessage() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_reviewCards.isEmpty ? Icons.check_circle_outline : Icons.info_outline, color: _reviewCards.isEmpty ? Colors.green : Colors.blue, size: 80),
          const SizedBox(height: 20),
          Text(
            _reviewCards.isEmpty ? "You're all caught up!" : "Almost there!",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _reviewCards.isEmpty
                ? (_selectedTags.isEmpty ? "There are no cards due for review right now. Great job!" : "No cards with the selected tags are due for review.")
                : "You have ${_reviewCards.length} card(s) due, but you need at least $_minCards to start a review session.",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(int count, {String? label}) {
    final bool isEnabled = count >= _minCards && count <= _maxCards;
    return ElevatedButton(
      onPressed: isEnabled ? () => _setCount(count) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedCardCount == count ? Colors.deepPurple : Colors.grey.shade300,
        foregroundColor: _selectedCardCount == count ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label ?? '$count'),
    );
  }
}
