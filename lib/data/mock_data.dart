import '../models/room.dart';
import '../models/section.dart';
import '../models/plant.dart';
import '../models/device.dart';

final rooms = <Room>[
  Room(id: 'room1', name: 'Salon'),
  Room(id: 'room2', name: 'Sypialnia'),
];

final sections = <Section>[
  Section(id: 'sec1', name: 'Półka przy oknie wschodnim', roomId: 'room1'),
  Section(id: 'sec2', name: 'Nad fotelem', roomId: 'room1'),
  Section(id: 'sec3', name: 'Przy akwarium', roomId: 'room1'),
  Section(id: 'sec4', name: 'Parapet', roomId: 'room2'),
];

final plants = <Plant>[
  Plant(id: 'plant1', name: 'Monstera deliciosa', sectionId: 'sec1', species: 'Monstera'),
  Plant(id: 'plant2', name: 'Fikus benjamina', sectionId: 'sec1', species: 'Fikus'),
  Plant(id: 'plant3', name: 'Zamiokulkas', sectionId: 'sec2', species: 'Zamioculcas'),
];

final devices = <Device>[
  // Urządzenia w sekcjach (światło / powietrze)
  Device(
    id: 'dev1',
    name: 'Sterownik światła salon półka',
    type: DeviceType.lightController,
    sectionId: 'sec1',
  ),
  Device(
    id: 'dev2',
    name: 'Czujnik powietrza salon',
    type: DeviceType.airSensor,
    sectionId: 'sec1',
  ),
  Device(
    id: 'dev3',
    name: 'Sterownik światła nad fotelem',
    type: DeviceType.lightController,
    sectionId: 'sec2',
  ),

  // Czujniki wilgotności przypięte do roślin
  Device(
    id: 'dev4',
    name: 'Czujnik wilgotności Monstera',
    type: DeviceType.soilMoistureSensor,
    plantId: 'plant1',
  ),
  Device(
    id: 'dev5',
    name: 'Czujnik wilgotności Fikus',
    type: DeviceType.soilMoistureSensor,
    plantId: 'plant2',
  ),
];