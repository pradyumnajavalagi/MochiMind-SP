import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart'; // <-- 1. IMPORT the new package
import '../models/flashcard_model.dart';
import '../services/api_service.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/app_drawer.dart';
import './test_setup_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Flashcard> _flashcards = [];
  bool _isLoading = true;
  // --- 2. ADD a controller for the swiper ---
  final CardSwiperController _swiperController = CardSwiperController();
  // --- 3. MANAGE details visibility for each card individually ---
  final Map<String, bool> _showDetailsMap = {};

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  void _loadFlashcards() async {
    setState(() { _isLoading = true; });
    if (!mounted) return;

    final cards = await SupabaseService.getFlashcardsWithStatus();
    cards.shuffle();

    if(mounted) {
      setState(() {
        _flashcards = cards;
        _isLoading = false;
      });
    }
  }

  // --- 4. REPLACED old navigation methods with a toggle function ---
  void _toggleDetails(String cardId) {
    setState(() {
      // Set the state for the specific card, defaulting to false if not present
      _showDetailsMap[cardId] = !(_showDetailsMap[cardId] ?? false);
    });
  }

  void _navigateToTestSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TestSetupPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("MochiMind",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flashcards.isEmpty
          ? const Center(child: Text("No flashcards found.\nAdd some or import a deck!", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)))
      // --- 5. REPLACED GestureDetector with the CardSwiper ---
          : Column(
        children: [
          Expanded(
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: _flashcards.length,
              onSwipe: (previousIndex, currentIndex, direction) {
                // When a card is swiped away, reset its details view state
                final swipedCardId = _flashcards[previousIndex].id;
                setState(() {
                  _showDetailsMap[swipedCardId] = false;
                });
                return true; // Return true to allow the swipe
              },
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                final card = _flashcards[index];
                final isDetailsVisible = _showDetailsMap[card.id] ?? false;
                // Wrap the FlashcardWidget in a GestureDetector to handle taps
                return GestureDetector(
                  onTap: () => _toggleDetails(card.id),
                  child: FlashcardWidget(
                    card: card,
                    showDetails: isDetailsVisible,
                  ),
                );
              },
              isLoop: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            ),
          ),
          // --- 6. ADDED control buttons ---
          Padding(
            padding: const EdgeInsets.only(top:16.0,left: 16.0, right: 16.0, bottom: 116.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _swiperController.undo,
                  mini: true,
                  child: const Icon(Icons.rotate_left),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Start Review Session'),
                  onPressed: _navigateToTestSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
