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
  List<Flashcard> _allFlashcards = [];
  List<Flashcard> _filteredFlashcards = [];
  List<Tag> _allTags = [];

  // --- 1. UPDATED: Use Sets for multi-selection ---
  final Set<String> _selectedStatuses = {};
  final Set<String> _selectedTags = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    final results = await Future.wait([
      SupabaseService.getFlashcardsWithStatus(),
      SupabaseService.getTagsForUser(),
    ]);

    if (mounted) {
      setState(() {
        _allFlashcards = results[0] as List<Flashcard>;
        _allTags = results[1] as List<Tag>;
        _filterCards(); // Apply initial filter
        _isLoading = false;
      });
    }
  }

  // --- 2. UPDATED: Advanced filtering logic ---
  void _filterCards() {
    setState(() {
      if (_selectedStatuses.isEmpty && _selectedTags.isEmpty) {
        // If no filters are selected, show all cards
        _filteredFlashcards = _allFlashcards;
        return;
      }

      _filteredFlashcards = _allFlashcards.where((card) {
        // Status check: card's status must be in the selected set
        final statusMatch = _selectedStatuses.isEmpty ||
            (_selectedStatuses.contains(card.status?.toLowerCase()));

        // Tag check: card must have at least one of the selected tags
        final tagMatch = _selectedTags.isEmpty ||
            card.tags.any((tag) => _selectedTags.contains(tag.name));

        // A card must match both active filters (AND logic)
        return statusMatch && tagMatch;
      }).toList();
    });
  }

  // --- 3. UPDATED: Handle multi-selection toggling ---
  void _onStatusSelected(String status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
    _filterCards();
  }

  void _onTagSelected(String tagName) {
    setState(() {
      if (_selectedTags.contains(tagName)) {
        _selectedTags.remove(tagName);
      } else {
        _selectedTags.add(tagName);
      }
    });
    _filterCards();
  }


  // --- THIS FUNCTION IS NOW CORRECTED ---
  Future<void> _deleteFlashcard(Flashcard card) async {
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
      // First, delete the image from storage using its URL.
      await SupabaseService.deleteImageByUrl(card.kanjiImageUrl);
      // Then, delete the flashcard record from the database using its ID (a String).
      await SupabaseService.deleteFlashcard(card.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Flashcards'),
        actions: const [LogoutButton()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFlashcards.isEmpty
                ? const Center(
              child: Text(
                'No flashcards match your filters.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _filteredFlashcards.length,
              itemBuilder: (context, index) {
                final card = _filteredFlashcards[index];
                return _buildGridCard(card);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final statusCategories = ['Forgot', 'Hard', 'Good', 'Easy'];
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Filter by Status", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildFilterChips(statusCategories, _selectedStatuses, _onStatusSelected),
          const SizedBox(height: 16),
          const Text("Filter by Tag", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _allTags.isEmpty
              ? const Text("No tags created yet.", style: TextStyle(color: Colors.grey))
              : _buildFilterChips(_allTags.map((t) => t.name).toList(), _selectedTags, _onTagSelected),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<String> filters, Set<String> selectedSet, Function(String) onSelected) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedSet.contains(filter);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip( // <-- 4. Use FilterChip for multi-select
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => onSelected(filter),
              selectedColor: Colors.deepPurple,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridCard(Flashcard card) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditPage(card: card)),
        );
        _loadData();
      },
      onLongPress: () => _deleteFlashcard(card),
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(card.kanjiImageUrl, height: 80, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    card.onyomi,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    card.kunyomi,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (card.status != null)
              Positioned(
                top: 0,
                right: 0,
                child: Banner(
                  message: card.status!.toUpperCase(),
                  location: BannerLocation.topEnd,
                  color: _getStatusColor(card.status),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'forgot': return Colors.red;
      case 'hard': return Colors.orange;
      case 'good': return Colors.blue;
      case 'easy': return Colors.green;
      default: return Colors.grey;
    }
  }
}
