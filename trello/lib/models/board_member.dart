import 'user_role.dart';

class BoardMember {
  final int? id;
  final int boardId;
  final int userId;
  final UserRole role;
  final DateTime addedAt;

  BoardMember({
    this.id,
    required this.boardId,
    required this.userId,
    required this.role,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'board_id': boardId,
      'user_id': userId,
      'role': role.name,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory BoardMember.fromMap(Map<String, dynamic> map) {
    return BoardMember(
      id: map['id'],
      boardId: map['board_id'],
      userId: map['user_id'],
      role: UserRole.values.firstWhere((r) => r.name == map['role']),
      addedAt: DateTime.parse(map['added_at']),
    );
  }

  BoardMember copyWith({
    int? id,
    int? boardId,
    int? userId,
    UserRole? role,
    DateTime? addedAt,
  }) {
    return BoardMember(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}