class StudyNote {
  final int? id;
  final int? userId;
  final String title;
  final String? description;
  final String? content;
  final String? dateCreated;

  const StudyNote({
    this.id,
    this.userId,
    required this.title,
    this.description,
    this.content,
    this.dateCreated,
  });

  factory StudyNote.fromMap(Map<String, dynamic> map) {
    return StudyNote(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      title: (map['title'] ?? '').toString(),
      description: map['description']?.toString(),
      content: map['content']?.toString(),
      dateCreated: map['dateCreated']?.toString(),
    );
  }

  DateTime? get createdAt {
    if (dateCreated == null || dateCreated!.isEmpty) {
      return null;
    }
    return DateTime.tryParse(dateCreated!);
  }

  StudyNote copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? content,
    String? dateCreated,
  }) {
    return StudyNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }
}
