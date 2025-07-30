import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/api_service.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/app_drawer.dart'; // <-- 1. IMPORT the new drawer
import './test_setup_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Flashcard> flashcards = [];
  int currentIndex = 0;
  bool showDetails = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFlashcards();
  }

  void loadFlashcards() async {
    setState(() { _isLoading = true; });
    if (!mounted) return;
    final cards = await SupabaseService.getFlashcardsWithStatus();
    cards.shuffle();
    if(mounted) {
      setState(() {
        flashcards = cards;
        flashcards = cards;
        currentIndex = 0;
        showDetails = false;
        _isLoading = false;
      });
    }
  }

  void nextCard() {
    if (flashcards.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex + 1) % flashcards.length;
        showDetails = false;
      });
    }
  }

  void previousCard() {
    if (flashcards.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex - 1 + flashcards.length) % flashcards.length;
        showDetails = false;
      });
    }
  }

  void toggleDetails() {
    setState(() {
      showDetails = !showDetails;
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
        // The LogoutButton is removed from actions, as it's now in the drawer
      ),
      // --- 2. ADD the drawer to the Scaffold ---
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Loading your flashcards..."),
            ],
          ))
          : flashcards.isEmpty
          ? const Center(child: Text("No flashcards found.\nAdd some to get started!", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)))
          : GestureDetector(
        onTap: toggleDetails,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            nextCard();
          } else if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
            previousCard();
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlashcardWidget(
                card: flashcards[currentIndex],
                showDetails: showDetails,
              ),
              const SizedBox(height: 40),
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
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            ],
          ),
        ),
      ),
    );
  }
}
