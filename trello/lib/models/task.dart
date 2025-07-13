class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime? deadline;
  final String status;
  final int boardId;
  final int? assignedUserId;
  final int createdBy; // Хто створив завдання
  final bool originallyUnassigned;
  final DateTime createdAt;

  Task({
    this.id,
    required this.title,
    required this.description,
    this.deadline,
    required this.status,
    required this.boardId,
    this.assignedUserId,
    required this.createdBy,
    this.originallyUnassigned = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'board_id': boardId,
      'assigned_user_id': assignedUserId,
      'created_by': createdBy,
      'originally_unassigned': originallyUnassigned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      status: map['status'],
      boardId: map['board_id'],
      assignedUserId: map['assigned_user_id'],
      createdBy: map['created_by'],
      originallyUnassigned: (map['originally_unassigned'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? deadline,
    String? status,
    int? boardId,
    int? assignedUserId,
    int? createdBy,
    bool? originallyUnassigned,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      boardId: boardId ?? this.boardId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      createdBy: createdBy ?? this.createdBy,
      originallyUnassigned: originallyUnassigned ?? this.originallyUnassigned,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}