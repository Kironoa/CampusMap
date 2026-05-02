enum Wing { left, right, center }

enum Row { top, bottom }

class IndoorRoom {
  final String id;
  final String name;
  final Wing wing;
  final Row row;
  final String? description;

  const IndoorRoom({
    required this.id,
    required this.name,
    required this.wing,
    required this.row,
    this.description,
  });

  String get wingName => wing.name[0].toUpperCase() + wing.name.substring(1);
  String get rowName => row.name[0].toUpperCase() + row.name.substring(1);
}
