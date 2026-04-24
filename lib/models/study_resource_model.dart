class StudyResource {
  final int? id;
  final int? userId;
  String fileName;
  final String? localPath;
  final String category;
  final String? content;
  final String? dateAdded;

  StudyResource({
    this.id,
    this.userId,
    required this.fileName,
    this.localPath,
    required this.category,
    this.content,
    this.dateAdded,
  });

  factory StudyResource.fromMap(Map<String, dynamic> map) {
    return StudyResource(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      fileName: (map['fileName'] ?? 'Untitled').toString(),
      localPath: map['localPath']?.toString(),
      category: (map['category'] ?? '').toString(),
      content: map['content']?.toString(),
      dateAdded: map['dateAdded']?.toString(),
    );
  }

  DateTime? get addedAt {
    if (dateAdded == null || dateAdded!.isEmpty) {
      return null;
    }
    return DateTime.tryParse(dateAdded!);
  }

  StudyResource copyWith({
    int? id,
    int? userId,
    String? fileName,
    String? localPath,
    String? category,
    String? content,
    String? dateAdded,
  }) {
    return StudyResource(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      category: category ?? this.category,
      content: content ?? this.content,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'localPath': localPath,
      'category': category,
      'content': content,
      'dateAdded': dateAdded,
    };
  }
}
