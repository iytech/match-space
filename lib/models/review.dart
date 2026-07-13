class Review {
  final String id;
  final String propertyId;
  final String authorId;
  final String? authorName;
  final String? authorAvatar;
  final int rating; // 1..5
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.propertyId,
    required this.authorId,
    this.authorName,
    this.authorAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> m) => Review(
        id: m['id'].toString(),
        propertyId: m['property_id'].toString(),
        authorId: m['author_id'] as String,
        authorName: (m['profiles']?['full_name']) as String?,
        authorAvatar: (m['profiles']?['avatar_url']) as String?,
        rating: (m['rating'] ?? 5) as int,
        comment: (m['comment'] ?? '') as String,
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}
