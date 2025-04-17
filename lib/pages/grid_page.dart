import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/api_service.dart';
import '../widgets/logout_button.dart';
import 'add_edit_page.dart';

class GridPage extends StatefulWidget {
  const GridPage({super.key});

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  List<Flashcard> flashcards = [];

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    final cards = await SupabaseService.getUserFlashcards();
    setState(() {
      flashcards = cards;
    });
  }

  Future<void> _deleteFlashcard(String id) async {
    await SupabaseService.deleteFlashcard(id);
    _loadFlashcards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Flashcards'),
      actions: const [
        LogoutButton(),
      ],),
      body: flashcards.isEmpty
          ? const Center(child: Text("No flashcards found",style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),)
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: flashcards.length,
        itemBuilder: (context, index) {
          final card = flashcards[index];
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditPage(card: card)),
              );
              _loadFlashcards();
            },
            onLongPress: () => _deleteFlashcard(card.id),
            child: Card(
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(card.kanjiImageUrl, height: 80, fit: BoxFit.contain),
                  const SizedBox(height: 8),
                  Text(card.onyomi, style: card.onyomi.contains("*")?const TextStyle(fontWeight: FontWeight.bold): const TextStyle(fontWeight: FontWeight.normal)),
                  Text(card.kunyomi, style: card.kunyomi.contains("*")?const TextStyle(fontWeight: FontWeight.bold): const TextStyle(fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
