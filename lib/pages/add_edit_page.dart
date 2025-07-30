import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../models/flashcard_model.dart';
import '../services/api_service.dart';

class AddEditPage extends StatefulWidget {
  final Flashcard? card;
  final VoidCallback? onSaved;
  const AddEditPage({super.key, this.card, this.onSaved});

  @override
  State<AddEditPage> createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController onyomiCtrl, kunyomiCtrl, exampleCtrl, tagCtrl;
  String? imageUrl;
  bool _saving = false;

  List<Tag> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    onyomiCtrl = TextEditingController(text: widget.card?.onyomi ?? '');
    kunyomiCtrl = TextEditingController(text: widget.card?.kunyomi ?? '');
    exampleCtrl = TextEditingController(text: widget.card?.exampleUsage ?? '');
    tagCtrl = TextEditingController();
    imageUrl = widget.card?.kanjiImageUrl;
    _selectedTags = List.from(widget.card?.tags ?? []);
  }

  @override
  void dispose() {
    onyomiCtrl.dispose();
    kunyomiCtrl.dispose();
    exampleCtrl.dispose();
    tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(picked.path)}';

    if (imageUrl != null && widget.card != null) {
      await SupabaseService.deleteImageByUrl(imageUrl!);
    }

    final uploadedUrl = await SupabaseService.uploadImage(file, fileName);

    if (uploadedUrl != null) {
      setState(() {
        imageUrl = uploadedUrl;
      });
    } else {
      if(mounted) _showError("Failed to upload image");
    }
  }

  void _addTag() async {
    final tagName = tagCtrl.text;
    if (tagName.isEmpty) return;
    if (_selectedTags.any((t) => t.name.toLowerCase() == tagName.toLowerCase())) {
      tagCtrl.clear();
      return;
    }
    final newTag = await SupabaseService.createTagIfNotExists(tagName);
    setState(() {
      _selectedTags.add(newTag);
      tagCtrl.clear();
    });
  }

  void _removeTag(Tag tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  Future<void> _saveFlashcard() async {
    if (!_formKey.currentState!.validate() || imageUrl == null) {
      _showError("Please fill all required fields and upload an image.");
      return;
    }

    setState(() => _saving = true);

    try {
      Flashcard savedCard;
      final cardData = Flashcard(
        id: widget.card?.id ?? '',
        kanjiImageUrl: imageUrl!,
        onyomi: onyomiCtrl.text,
        kunyomi: kunyomiCtrl.text,
        exampleUsage: exampleCtrl.text,
        userId: widget.card?.userId ?? '',
        srsLevel: widget.card?.srsLevel ?? 0,
        nextReviewAt: widget.card?.nextReviewAt ?? DateTime.now(),
        tags: _selectedTags,
      );

      if (widget.card == null) {
        savedCard = await SupabaseService.createFlashcard(cardData);
      } else {
        await SupabaseService.updateFlashcard(cardData);
        savedCard = cardData;
      }

      await SupabaseService.setFlashcardTags(savedCard.id, _selectedTags);

      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint("Save error: $e");
      _showError("Something went wrong while saving");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteFlashcard() async {
    if (widget.card == null) return;

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
      try {
        // --- THIS IS THE FIX ---
        // The service function expects the card's ID (a String), not the whole object.
        await SupabaseService.deleteFlashcard(widget.card!.id);
        if (mounted) {
          if (widget.onSaved != null) {
            widget.onSaved!(); // Go back to grid and refresh
          } else {
            Navigator.of(context).pop(); // Just go back
          }
        }
      } catch (e) {
        _showError("Failed to delete card.");
      }
    }
  }


  void _showError(String message) {
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card == null ? 'Add Flashcard' : 'Edit Flashcard'),
        actions: [
          if (widget.card != null) // Only show delete button when editing
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteFlashcard,
              tooltip: 'Delete Flashcard',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                child: imageUrl != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl!, fit: BoxFit.cover))
                    : const Center(child: Icon(Icons.image_outlined, size: 40, color: Colors.grey)),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(onPressed: _pickAndUploadImage, icon: const Icon(Icons.upload), label: const Text("Upload Kanji Image")),
              const SizedBox(height: 20),
              TextFormField(controller: onyomiCtrl, decoration: const InputDecoration(labelText: 'Onyomi'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              TextFormField(controller: kunyomiCtrl, decoration: const InputDecoration(labelText: 'Kunyomi'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              TextFormField(controller: exampleCtrl, decoration: const InputDecoration(labelText: 'Example Usage')),
              const SizedBox(height: 20),
              _buildTagsSection(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _saveFlashcard,
                child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _selectedTags.map((tag) {
            return Chip(
              label: Text(tag.name),
              onDeleted: () => _removeTag(tag),
              deleteIcon: const Icon(Icons.cancel, size: 18),
              backgroundColor: Colors.deepPurple.withOpacity(0.1),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: tagCtrl,
                decoration: const InputDecoration(
                  labelText: 'Add a tag (e.g., N3, Soumatome)',
                ),
                onFieldSubmitted: (_) => _addTag(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.deepPurple),
              onPressed: _addTag,
            ),
          ],
        ),
      ],
    );
  }
}
