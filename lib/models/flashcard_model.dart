// Class to represent a single tag
class Tag {
  final String id;
  final String name;

  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
    id: json['id'],
    name: json['name'],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}


class Flashcard {
  final String id;
  final String userId;
  final String kanjiImageUrl; // <-- Reverted to non-nullable
  final String onyomi;
  final String kunyomi;
  final String exampleUsage;
  final String? status;
  final int srsLevel;
  final DateTime nextReviewAt;
  List<Tag> tags;

  Flashcard({
    required this.id,
    required this.userId,
    required this.kanjiImageUrl, // <-- Reverted to required
    required this.onyomi,
    required this.kunyomi,
    required this.exampleUsage,
    this.status,
    required this.srsLevel,
    required this.nextReviewAt,
    this.tags = const [],
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    var tagsFromJson = json['tags'] as List<dynamic>?;
    List<Tag> tagsList = tagsFromJson?.map((tagJson) => Tag.fromJson(tagJson)).toList() ?? [];

    return Flashcard(
      id: json['id'],
      userId: json['user_id'],
      kanjiImageUrl: json['kanji_image_url'], // <-- Assumes non-nullable
      onyomi: json['onyomi'],
      kunyomi: json['kunyomi'],
      exampleUsage: json['example_usage'] ?? '',
      status: json['status'],
      srsLevel: json['srs_level'] ?? 0,
      nextReviewAt: DateTime.parse(json['next_review_at']),
      tags: tagsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'kanji_image_url': kanjiImageUrl,
    'onyomi': onyomi,
    'kunyomi': kunyomi,
    'example_usage': exampleUsage,
    'user_id': userId,
  };
}
