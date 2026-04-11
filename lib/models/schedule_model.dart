class Schedule {
  final int? id;
  final String subject;
  final String days;
  final String startTime;
  final String endTime;
  final String room;
  final String professor;

  Schedule({
    this.id,
    required this.subject,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.professor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'professor': professor,
      'days': days,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      subject: map['subject'],
      days: map['days'] ?? '',
      startTime: map['startTime'],
      endTime: map['endTime'],
      room: map['room'],
      professor: map['professor'],
    );
  }
}
