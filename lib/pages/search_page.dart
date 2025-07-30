import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/api_service.dart';
import 'add_edit_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Flashcard> allFlashcards = [];
  List<Flashcard> filteredFlashcards = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
    _controller.addListener(_filterFlashcards);
  }

  void _loadFlashcards() async {
    // This uses the correct function that includes status and tag info
    final cards = await SupabaseService.getFlashcardsWithStatus();
    if(mounted) {
      setState(() {
        allFlashcards = cards;
        filteredFlashcards = cards;
      });
    }
  }

  void _filterFlashcards() {
    final query = _controller.text.toLowerCase();
    setState(() {
      filteredFlashcards = allFlashcards.where((card) {
        // Reverted to only search the main text fields
        return card.onyomi.toLowerCase().contains(query) ||
            card.kunyomi.toLowerCase().contains(query) ||
            card.exampleUsage.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _deleteCard(String id) async {
    // Added confirmation dialog for consistency
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flashcard?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final cardToDelete = allFlashcards.firstWhere((card) => card.id == id);
      await SupabaseService.deleteImageByUrl(cardToDelete.kanjiImageUrl);
      await SupabaseService.deleteFlashcard(id);
      _loadFlashcards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Flashcards')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Search by onyomi, kunyomi or example",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: filteredFlashcards.isEmpty
                ? const Center(child: Text("No matching results",style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),)
                : ListView.builder(
              itemCount: filteredFlashcards.length,
              itemBuilder: (context, index) {
                final card = filteredFlashcards[index];
                return ListTile(
                  leading: Image.network(card.kanjiImageUrl, width: 50), // Reverted to simple Image
                  title: Text("${card.onyomi} / ${card.kunyomi}"),
                  subtitle: Text(card.exampleUsage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddEditPage(card: card)),
                    );
                    _loadFlashcards();
                  },
                  onLongPress: () => _deleteCard(card.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
