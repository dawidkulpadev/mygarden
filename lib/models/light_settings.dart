import 'package:flutter/material.dart';



class LightSettings {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Duration sunriseDuration;
  final Duration sunsetDuration;
  final double maxPowerPercent;

  const LightSettings({
    required this.startTime,
    required this.endTime,
    required this.sunriseDuration,
    required this.sunsetDuration,
    required this.maxPowerPercent,
  });

  LightSettings copyWith({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Duration? sunriseDuration,
    Duration? sunsetDuration,
    double? maxPowerPercent,
  }) {
    return LightSettings(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sunriseDuration: sunriseDuration ?? this.sunriseDuration,
      sunsetDuration: sunsetDuration ?? this.sunsetDuration,
      maxPowerPercent: maxPowerPercent ?? this.maxPowerPercent,
    );
  }

  factory LightSettings.fromJson(Map<String, dynamic> json) {
    TimeOfDay parseTime(String s) {
      final parts = s.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return TimeOfDay(hour: h, minute: m);
    }

    return LightSettings(
      startTime: parseTime(json['light_start_time'] as String),
      endTime: parseTime(json['light_end_time'] as String),
      sunriseDuration:
          Duration(minutes: (json['light_sunrise_minutes'] ?? 0) as int),
      sunsetDuration:
          Duration(minutes: (json['light_sunset_minutes'] ?? 0) as int),
      maxPowerPercent:
          (json['light_max_power'] as num?)?.toDouble() ?? 100.0,
    );
  }
}
