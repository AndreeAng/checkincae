import 'worksite.dart';
import 'user.dart';

class Checkin {
  final int id;
  final String type;
  final DateTime occurredAt;
  final double latitude;
  final double longitude;
  final String activity;
  final String photoUrl;
  final WorkSite? workSite;
  final User? user;

  Checkin({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.latitude,
    required this.longitude,
    required this.activity,
    required this.photoUrl,
    this.workSite,
    this.user,
  });

  factory Checkin.fromJson(Map<String, dynamic> json) {
    return Checkin(
      id: json['id'] as int,
      type: json['type'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      activity: json['activity'] as String,
      photoUrl: json['photoUrl'] as String,
      workSite: json['workSite'] == null
          ? null
          : WorkSite.fromJson(json['workSite'] as Map<String, dynamic>),
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
