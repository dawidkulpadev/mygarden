import 'light_settings.dart';

enum DeviceType {
  lightController,
  airSensor,
  soilMoistureSensor,
}

class Device {
  final String id;
  final String name;
  final DeviceType type;

  final String? sectionId;
  final String? plantId;

  final LightSettings? lightSettings;

  Device({
    required this.id,
    required this.name,
    required this.type,
    this.sectionId,
    this.plantId,
    this.lightSettings,
  });

  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? sectionId,
    String? plantId,
    LightSettings? lightSettings,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      sectionId: sectionId ?? this.sectionId,
      plantId: plantId ?? this.plantId,
      lightSettings: lightSettings ?? this.lightSettings,
    );
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    late DeviceType type;
    switch (typeStr) {
      case 'lightController':
        type = DeviceType.lightController;
        break;
      case 'airSensor':
        type = DeviceType.airSensor;
        break;
      case 'soilMoistureSensor':
        type = DeviceType.soilMoistureSensor;
        break;
      default:
        type = DeviceType.airSensor;
    }

    LightSettings? lightSettings;
    if (type == DeviceType.lightController &&
        json['light_start_time'] != null &&
        json['light_end_time'] != null) {
      lightSettings = LightSettings.fromJson(json);
    }

    return Device(
      id: json['id'].toString(),
      name: json['name'] as String,
      type: type,
      sectionId:
          json['section_id'] != null ? json['section_id'].toString() : null,
      plantId:
          json['plant_id'] != null ? json['plant_id'].toString() : null,
      lightSettings: lightSettings,
    );
  }
}
