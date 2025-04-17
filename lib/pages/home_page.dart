import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/api_service.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/logout_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Flashcard> flashcards = [];
  int currentIndex = 0;
  bool showDetails = false;

  @override
  void initState() {
    super.initState();
    loadFlashcards();
  }

  void loadFlashcards() async {
    final cards = await SupabaseService.getUserFlashcards();
    setState(() {
      flashcards = cards;
      currentIndex = 0;
      showDetails = false;
    });
  }

  void nextCard() {
    if (currentIndex < flashcards.length - 1) {
      setState(() {
        currentIndex++;
        showDetails = false;
      });
    }
  }

  void previousCard() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        showDetails = false;
      });
    }
  }

  void toggleDetails() {
    setState(() {
      showDetails = !showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (flashcards.isEmpty) {
      return Scaffold(
      appBar: AppBar(title: const Text("MochiMind"),
        actions: const [
          LogoutButton(),
        ],
      ),
        body: const Center(child: Text("No flashcards found",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ));
    }

    final card = flashcards[currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text("Flashcard Swipe"),
        actions: const [
          LogoutButton(),
        ],
      ),
      body: GestureDetector(
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
                card: card,
                showDetails: showDetails,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            ],
          ),
        ),
      ),
    );
  }
}