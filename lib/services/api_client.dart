import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/room.dart';
import '../models/section.dart';
import '../models/plant.dart';
import '../models/device.dart';

class ApiClient {
  static const String baseUrl = 'https://dawidkulpa.pl/sggw/mygarden';

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<int> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/login');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['userId'] as int;
    } else if (resp.statusCode == 401) {
      throw Exception('Nieprawidłowy email lub hasło');
    } else {
      throw Exception('Błąd logowania: ${resp.statusCode}');
    }
  }

  Future<Device> updateDeviceName({
    required String deviceId,
    required String newName,
  }) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId');
    final resp = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': newName}),
    );

    if (resp.statusCode != 200) {
      throw Exception(
          'Nie udało się zmienić nazwy urządzenia (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Device.fromJson(data);
  }

  Future<List<Room>> fetchRooms(int userId) async {
    final uri = Uri.parse('$baseUrl/rooms?userId=$userId');
    final resp = await _client.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Nie udało się pobrać pokoi (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as List<dynamic>;
    return data
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SectionData>> fetchRoomDetails(int roomId) async {
    final uri = Uri.parse('$baseUrl/rooms/$roomId/full');
    final resp = await _client.get(uri);

    if (resp.statusCode != 200) {
      throw Exception(
          'Nie udało się pobrać szczegółów pokoju (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final sectionsJson = (data['sections'] as List<dynamic>? ?? []);

    return sectionsJson
        .map((e) => SectionData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

   Future<Room> createRoom(int userId, String name) async {
    final uri = Uri.parse('$baseUrl/rooms');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'name': name}),
    );

    if (resp.statusCode != 201) {
      throw Exception('Nie udało się dodać pokoju (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Room.fromJson(data);
  }

  Future<Section> createSection(int roomId, String name) async {
    final uri = Uri.parse('$baseUrl/sections');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'roomId': roomId, 'name': name}),
    );

    if (resp.statusCode != 201) {
      throw Exception('Nie udało się dodać sekcji (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Section(
      id: data['id'].toString(),
      name: data['name'] as String,
      roomId: roomId.toString(),
    );
  }

  Future<Plant> createPlant({
    required int sectionId,
    required String name,
    String? species,
  }) async {
    final uri = Uri.parse('$baseUrl/plants');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sectionId': sectionId,
        'name': name,
        'species': species,
      }),
    );

    if (resp.statusCode != 201) {
      throw Exception('Nie udało się dodać rośliny (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Plant.fromJson(data);
  }

  Future<Device> createDevice({
    required String name,
    required DeviceType type,
    int? sectionId,
    int? plantId,
  }) async {
    String typeStr;
    switch (type) {
      case DeviceType.lightController:
        typeStr = 'lightController';
        break;
      case DeviceType.airSensor:
        typeStr = 'airSensor';
        break;
      case DeviceType.soilMoistureSensor:
        typeStr = 'soilMoistureSensor';
        break;
    }

    final uri = Uri.parse('$baseUrl/devices');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'type': typeStr,
        'sectionId': sectionId,
        'plantId': plantId,
      }),
    );

    if (resp.statusCode != 201) {
      throw Exception('Nie udało się dodać urządzenia (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Device.fromJson(data);
  }

  Future<void> deleteDevice(String deviceId) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId');
    final resp = await _client.delete(uri);
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw Exception('Nie udało się usunąć urządzenia (${resp.statusCode})');
    }
  }
}


class SectionData {
  final Section section;
  final List<PlantWithSensor> plants;
  final List<Device> devices;

  SectionData({
    required this.section,
    required this.plants,
    required this.devices,
  });

  factory SectionData.fromJson(Map<String, dynamic> json) {
    final section = Section(
      id: json['id'].toString(),
      name: json['name'] as String,
      roomId: '',
    );

    final plantsJson = json['plants'] as List<dynamic>? ?? [];
    final devicesJson = json['devices'] as List<dynamic>? ?? [];

    final plantsWithSensors = plantsJson.map((p) {
      final map = p as Map<String, dynamic>;
      final plant = Plant.fromJson(map);
      Device? sensor;
      if (map['moistureSensor'] != null) {
        sensor =
            Device.fromJson(map['moistureSensor'] as Map<String, dynamic>);
      }
      return PlantWithSensor(plant: plant, moistureSensor: sensor);
    }).toList();

    final sectionDevices = devicesJson
        .map((d) => Device.fromJson(d as Map<String, dynamic>))
        .toList();

    return SectionData(
      section: section,
      plants: plantsWithSensors,
      devices: sectionDevices,
    );
  }
}

class PlantWithSensor {
  final Plant plant;
  final Device? moistureSensor;

  PlantWithSensor({
    required this.plant,
    required this.moistureSensor,
  });
}
