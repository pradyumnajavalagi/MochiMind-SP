import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flashcard_model.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;
  static final _storage = _client.storage.from('kanji-uploads');

  // --- ✨ DEFINITIVE AUTHENTICATION FUNCTIONS ✨ ---

  static Future<void> signInWithGoogle() async {
    const webClientId = '268423175595-ff01ti9odt3ej7jceac2g97p2ek43r4i.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign-in was canceled.');
    }
    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw const AuthException('No Access Token found.');
    }
    if (idToken == null) {
      throw const AuthException('No ID Token found.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  static Future<void> signInWithOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  static Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://login-callback/'
    );
  }

  static Future<void> updateUserPassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }


  // --- ALL OTHER EXISTING FUNCTIONS ---

  static String get _userId => _client.auth.currentUser?.id ?? '';

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

  static Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final path = extractPathFromUrl(imageUrl);
      await _storage.remove([path]);
    } catch (e) {
      debugPrint("Image delete error: $e");
    }
  }

  static String extractPathFromUrl(String url) {
    final parts = Uri.parse(url).pathSegments;
    final startIndex = parts.indexOf('kanji-uploads');
    return parts.sublist(startIndex + 1).join('/');
  }

  static Future<Flashcard> createFlashcard(Flashcard card) async {
    final response = await _client.from('flashcards').insert({
      'kanji_image_url': card.kanjiImageUrl,
      'onyomi': card.onyomi,
      'kunyomi': card.kunyomi,
      'example_usage': card.exampleUsage,
      'user_id': _userId,
    }).select().single();

    return Flashcard.fromJson(response);
  }

  static Future<void> updateFlashcard(Flashcard card) async {
    await _client.from('flashcards').update({
      'kanji_image_url': card.kanjiImageUrl,
      'onyomi': card.onyomi,
      'kunyomi': card.kunyomi,
      'example_usage': card.exampleUsage,
    }).eq('id', card.id);
  }

  static Future<void> deleteFlashcard(String id) async {
    await _client.from('flashcards').delete().eq('id', id);
  }

  static Future<void> saveTestResults(List<Map<String, dynamic>> results) async {
    final userId = _userId;
    if (userId.isEmpty) return;
    final resultsWithUser = results.map((res) => {...res, 'user_id': userId}).toList();
    try {
      await _client.from('test_results').insert(resultsWithUser);
    } catch (e) {
      debugPrint('Error saving test results: $e');
      rethrow;
    }
  }

  static Future<String> getAiFeedback(List<Map<String, dynamic>> resultsWithKanji) async {
    try {
      final response = await _client.functions.invoke(
        'get-ai-feedback',
        body: {'testResults': resultsWithKanji},
      );
      if (response.data != null && response.data['feedback'] != null) {
        return response.data['feedback'];
      } else if (response.data != null && response.data['error'] != null) {
        return "AI Error: ${response.data['error']}";
      } else {
        return "Could not get feedback at this time.";
      }
    } catch (e) {
      debugPrint('Error invoking AI feedback function: $e');
      return "An error occurred while fetching AI feedback.";
    }
  }

  static Future<List<Flashcard>> getFlashcardsWithStatus() async {
    final flashcardsRes = await _client
        .from('flashcards')
        .select('*, tags(*)')
        .eq('user_id', _userId)
        .order('created_at');

    final statusesRes = await _client.from('flashcard_status').select();
    final statusMap = {for (var s in statusesRes) s['flashcard_id']: s['rating']};

    return flashcardsRes.map((json) {
      final cardId = json['id'];
      json['status'] = statusMap[cardId];
      return Flashcard.fromJson(json);
    }).toList();
  }

  static Future<String> getUserEmail() async {
    return _client.auth.currentUser?.email ?? 'No email found';
  }

  static Future<int> getCurrentStreak() async {
    try {
      final streak = await _client.rpc('calculate_streak');
      return streak as int;
    } catch (e) {
      debugPrint('Error fetching streak: $e');
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getDeckRetention() async {
    try {
      final res = await _client.from('deck_retention_stats').select().single();
      final total = res['total_tested'] as int;
      final retained = res['retained_cards'] as int;
      final percent = total > 0 ? (retained / total) * 100 : 0.0;
      return {'retention_percent': percent, 'total_tested': total};
    } catch (e) {
      debugPrint('Error fetching retention: $e');
      return {'retention_percent': 0.0, 'total_tested': 0};
    }
  }

  static Future<void> updateCardSrs(String cardId, String rating) async {
    try {
      await _client.rpc('update_srs_data', params: {
        'card_id_in': cardId,
        'rating_in': rating,
      });
    } catch (e) {
      debugPrint('Error updating SRS data for card $cardId: $e');
    }
  }

  static Future<List<Tag>> getTagsForUser() async {
    final res = await _client.from('tags').select().eq('user_id', _userId);
    return res.map((json) => Tag.fromJson(json)).toList();
  }

  static Future<Tag> createTagIfNotExists(String name) async {
    final trimmedName = name.trim().toLowerCase();
    final existing = await _client
        .from('tags')
        .select()
        .eq('user_id', _userId)
        .eq('name', trimmedName)
        .maybeSingle();

    if (existing != null) {
      return Tag.fromJson(existing);
    }

    final newTag = await _client
        .from('tags')
        .insert({'name': trimmedName, 'user_id': _userId})
        .select()
        .single();
    return Tag.fromJson(newTag);
  }

  static Future<void> setFlashcardTags(String flashcardId, List<Tag> newTags) async {
    final currentTagLinks = await _client
        .from('flashcard_tags')
        .select('tag_id')
        .eq('flashcard_id', flashcardId);
    final currentTagIds = currentTagLinks.map((e) => e['tag_id'] as String).toSet();
    final newTagIds = newTags.map((t) => t.id).toSet();

    final tagsToAdd = newTagIds.difference(currentTagIds);
    final tagsToRemove = currentTagIds.difference(newTagIds);

    if (tagsToRemove.isNotEmpty) {
      await _client
          .from('flashcard_tags')
          .delete()
          .eq('flashcard_id', flashcardId)
          .filter('tag_id', 'in', tagsToRemove.toList());
    }
    if (tagsToAdd.isNotEmpty) {
      final newLinks = tagsToAdd.map((tagId) => {
        'flashcard_id': flashcardId,
        'tag_id': tagId,
      }).toList();
      await _client.from('flashcard_tags').insert(newLinks);
    }
  }

  static Future<List<Flashcard>> getReviewCards({List<String> tagIds = const []}) async {
    try {
      final res = await _client.rpc('get_review_cards_by_tags', params: {
        'tag_ids_in': tagIds,
      });
      return (res as List<dynamic>).map((json) => Flashcard.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching review cards by tags: $e');
      return [];
    }
  }

  static Future<Map<DateTime, int>> getStudyDates() async {
    try {
      final res = await _client.rpc('get_study_dates');
      final dates = (res as List<dynamic>).map((dateStr) => DateTime.parse(dateStr as String)).toList();
      return { for (var date in dates) date: 1 };
    } catch (e) {
      debugPrint('Error fetching study dates: $e');
      return {};
    }
  }
}
