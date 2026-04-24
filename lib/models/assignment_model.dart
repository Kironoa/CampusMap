class Assignment {
  final int? id;
  final int? userId;
  final int? isCompleted;
  final String title;
  final String? subject;
  final String? description;
  final String? deadline;

  const Assignment({
    this.id,
    this.userId,
    this.isCompleted,
    required this.title,
    this.subject,
    this.description,
    this.deadline,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      isCompleted: map['isCompleted'] as int?,
      title: (map['title'] ?? '').toString(),
      subject: map['subject']?.toString(),
      description: map['description']?.toString(),
      deadline: map['deadline']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'isCompleted': isCompleted ?? 0,
      'title': title,
      'subject': subject,
      'description': description,
      'deadline': deadline,
    };
  }

  DateTime? get deadlineDate {
    if (deadline == null || deadline!.isEmpty) {
      return null;
    }
    return DateTime.tryParse(deadline!);
  }

  bool get isDone => isCompleted == 1;

  Assignment copyWith({
    int? id,
    int? userId,
    int? isCompleted,
    String? title,
    String? subject,
    String? description,
    String? deadline,
  }) {
    return Assignment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isCompleted: isCompleted ?? this.isCompleted,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
    );
  }
}
