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
  late TextEditingController onyomiCtrl, kunyomiCtrl, exampleCtrl;
  String? imageUrl;
  File? pickedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    onyomiCtrl = TextEditingController(text: widget.card?.onyomi ?? '');
    kunyomiCtrl = TextEditingController(text: widget.card?.kunyomi ?? '');
    exampleCtrl = TextEditingController(text: widget.card?.exampleUsage ?? '');
    imageUrl = widget.card?.kanjiImageUrl;
  }

  @override
  void dispose() {
    onyomiCtrl.dispose();
    kunyomiCtrl.dispose();
    exampleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(picked.path)}';

    // 🧹 Delete old image from Supabase if updating
    if (imageUrl != null && widget.card != null) {
      await SupabaseService.deleteImageByUrl(imageUrl!);
    }

    final uploadedUrl = await SupabaseService.uploadImage(file, fileName);

    if (uploadedUrl != null) {
      setState(() {
        imageUrl = uploadedUrl;
        pickedImage = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image")),
      );
    }
  }

  Future<void> _saveFlashcard() async {
    if (!_formKey.currentState!.validate() || imageUrl == null) return;

    final newCard = Flashcard(
      id: widget.card?.id ?? '',
      kanjiImageUrl: imageUrl!,
      onyomi: onyomiCtrl.text,
      kunyomi: kunyomiCtrl.text,
      exampleUsage: exampleCtrl.text,
      userId: widget.card?.userId ?? '',
    );

    try {
      if (widget.card == null) {
        await SupabaseService.createFlashcard(newCard);
      } else {
        await SupabaseService.updateFlashcard(newCard);
      }

      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!(); // ✅ switch to Grid tab
      }

    } catch (e) {
      debugPrint("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong while saving")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card == null ? 'Add Flashcard' : 'Edit Flashcard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              imageUrl != null
                  ? Image.network(imageUrl!, height: 160)
                  :  Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl!, fit: BoxFit.cover),
                )
                    : const Center(
                  child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickAndUploadImage,
                icon: const Icon(Icons.upload),
                label: const Text("Upload Kanji Image"),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: onyomiCtrl,
                decoration: const InputDecoration(labelText: 'Onyomi'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: kunyomiCtrl,
                decoration: const InputDecoration(labelText: 'Kunyomi'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: exampleCtrl,
                decoration: const InputDecoration(labelText: 'Example Usage'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  await _saveFlashcard();
                  setState(() => _saving = false);
                },
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
