import 'package:mobile_app/helper/time_helper.dart';

class Schedule {
  final int? id;
  final int? userId;
  final String subject;
  final String days;
  final String startTime;
  final String endTime;
  final String room;
  final String professor;

  Schedule({
    this.id,
    this.userId,
    required this.subject,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.professor,
  });

  String get displayStartTime => TimeHelper.formatTimeForDisplay(startTime);
  String get displayEndTime => TimeHelper.formatTimeForDisplay(endTime);

  int get startMinutes => TimeHelper.convertToMinutes(startTime);
  int get endMinutes => TimeHelper.convertToMinutes(endTime);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
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
      userId: map['userId'],
      subject: map['subject'],
      days: map['days'] ?? '',
      startTime: map['startTime'],
      endTime: map['endTime'],
      room: map['room'],
      professor: map['professor'],
    );
  }

  Schedule copyWith({
    int? id,
    int? userId,
    String? subject,
    String? days,
    String? startTime,
    String? endTime,
    String? room,
    String? professor,
  }) {
    return Schedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      days: days ?? this.days,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      professor: professor ?? this.professor,
    );
  }
}
