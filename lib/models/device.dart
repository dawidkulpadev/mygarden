enum DeviceType {
  lightController,      // sterowanie światłem
  airSensor,            // parametry powietrza
  soilMoistureSensor,   // wilgotność gleby
}

class Device {
  final String id;           // np. id hardware'u / MAC / UUID
  final String name;         // nazwa przyjazna: "Czujnik salon okno"
  final DeviceType type;

  // na razie tylko proste powiązania identyfikatorami:
  final String? sectionId;   // dla światła i powietrza
  final String? plantId;     // dla wilgotności gleby

  Device({
    required this.id,
    required this.name,
    required this.type,
    this.sectionId,
    this.plantId,
  });

  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? sectionId,
    String? plantId,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      sectionId: sectionId ?? this.sectionId,
      plantId: plantId ?? this.plantId,
    );
  }
}