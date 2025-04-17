import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';

class FlashcardWidget extends StatelessWidget {
  final Flashcard card;
  final bool showDetails;

  const FlashcardWidget({
    super.key,
    required this.card,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  card.kanjiImageUrl,
                  height: 220,
                  width: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                ),
              ),
              const SizedBox(height: 16),
              if (showDetails) ...[
                Text("Onyomi: ${card.onyomi}", style: Theme.of(context).textTheme.bodyLarge),
                Text("Kunyomi: ${card.kunyomi}", style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 10),
                Text("Example: ${card.exampleUsage}", textAlign: TextAlign.center),
              ] else ...[
                const Text(
                  "Tap to reveal details",
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
