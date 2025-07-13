class Board {
  final int? id;
  final String title;
  final String description;
  final int ownerId;
  final DateTime createdAt;

  Board({
    this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Board.fromMap(Map<String, dynamic> map) {
    return Board(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      ownerId: map['owner_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Board copyWith({
    int? id,
    String? title,
    String? description,
    int? ownerId,
    DateTime? createdAt,
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}