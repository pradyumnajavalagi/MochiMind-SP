import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flashcard_model.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;
  static final _storage = _client.storage.from('kanji-uploads');

  // 🔐 Auth check
  static String get _userId => _client.auth.currentUser?.id ?? '';

  // 📤 Upload Image
  static Future<String?> uploadImage(File file, String fileName) async {
    try {
      final filePath = 'kanji/$fileName';
      await _storage.upload(filePath, file);
      final publicUrl = _storage.getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // 🧹 Delete Image from URL
  static Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final path = extractPathFromUrl(imageUrl);
      await _storage.remove([path]);
    } catch (e) {
      debugPrint("Image delete error: $e");
    }
  }

  // 📦 Extract relative file path from public URL
  static String extractPathFromUrl(String url) {
    final parts = Uri.parse(url).pathSegments;
    final startIndex = parts.indexOf('kanji-uploads');
    return parts.sublist(startIndex + 1).join('/');
  }

  // ➕ Create Flashcard
  static Future<void> createFlashcard(Flashcard card) async {
    await _client.from('flashcards').insert({
      'kanji_image_url': card.kanjiImageUrl,
      'onyomi': card.onyomi,
      'kunyomi': card.kunyomi,
      'example_usage': card.exampleUsage,
      'user_id': _userId,
    });
  }

  // 🧾 Fetch Flashcards
  static Future<List<Flashcard>> getUserFlashcards() async {
    final res = await _client
        .from('flashcards')
        .select()
        .eq('user_id', _userId)
        .order('created_at');

    return res.map((json) => Flashcard.fromJson(json)).toList();
  }

  // ✏️ Update Flashcard
  static Future<void> updateFlashcard(Flashcard card) async {
    await _client.from('flashcards').update({
      'kanji_image_url': card.kanjiImageUrl,
      'onyomi': card.onyomi,
      'kunyomi': card.kunyomi,
      'example_usage': card.exampleUsage,
    }).eq('id', card.id);
  }

  // 🗑 Delete Flashcard
  static Future<void> deleteFlashcard(String id) async {
    await _client.from('flashcards').delete().eq('id', id);
  }
}
