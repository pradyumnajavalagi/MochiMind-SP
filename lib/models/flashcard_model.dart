class Flashcard {
  final String id;
  final String userId;
  final String kanjiImageUrl;
  final String onyomi;
  final String kunyomi;
  final String exampleUsage;

  Flashcard({
    required this.id,
    required this.userId,
    required this.kanjiImageUrl,
    required this.onyomi,
    required this.kunyomi,
    required this.exampleUsage,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'],
    userId: json['user_id'],
    kanjiImageUrl: json['kanji_image_url'],
    onyomi: json['onyomi'],
    kunyomi: json['kunyomi'],
    exampleUsage: json['example_usage'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'kanji_image_url': kanjiImageUrl,
    'onyomi': onyomi,
    'kunyomi': kunyomi,
    'example_usage': exampleUsage,
    'user_id': userId,
  };
}
