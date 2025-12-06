import 'dart:math';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/plant.dart';
import '../services/api_client.dart';
import 'light_device_screen.dart';
import 'soil_moisture_history_screen.dart';



class RoomDetailScreen extends StatefulWidget {
  final int roomId;
  final String roomName;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}



class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _api = ApiClient();

  bool _loading = true;
  String? _error;
  List<SectionData> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sections = await _api.fetchRoomDetails(widget.roomId);
      if (!mounted) return;
      setState(() {
        _sections = sections;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }


  Future<void> _renameDevice(Device device) async {
    final controller = TextEditingController(text: device.name);
    final formKey = GlobalKey<FormState>();
    String? error;

    await showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Zmień nazwę urządzenia'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nazwa urządzenia',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Podaj nazwę';
                }
                return null;
              },
            ),
          ),
          actions: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: Text(
                  error!,
                  style: TextStyle(color: cs.error),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await _api.updateDeviceName(
                    deviceId: device.id,
                    newName: controller.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _loadDetails();
                  }
                } catch (e) {
                  error = e.toString();
                  (context as Element).markNeedsBuild();
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _openLightDevice(Device device) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LightDeviceScreen(device: device),
      ),
    );
    _loadDetails();
  }

  Future<void> _deleteDevice(Device device) async {
    try {
      await _api.deleteDevice(device.id);
      _loadDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się usunąć urządzenia: $e')),
      );
    }
  }



  Future<void> _showAddSectionDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nowa sekcja'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nazwa sekcji',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Podaj nazwę sekcji';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await _api.createSection(widget.roomId, controller.text.trim());
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _loadDetails();
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Błąd dodawania sekcji: $e')),
                  );
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPlantDialog(SectionData sectionData) async {
    final nameController = TextEditingController();
    final speciesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nowa roślina w sekcji "${sectionData.section.name}"'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa rośliny',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj nazwę rośliny';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: speciesController,
                  decoration: const InputDecoration(
                    labelText: 'Gatunek (opcjonalnie)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await _api.createPlant(
                    sectionId: int.parse(sectionData.section.id),
                    name: nameController.text.trim(),
                    species: speciesController.text.trim().isEmpty
                        ? null
                        : speciesController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _loadDetails();
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Błąd dodawania rośliny: $e')),
                  );
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddDeviceSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _AddDeviceSheet(
          sections: _sections,
          onDeviceCreated: () {
            Navigator.of(context).pop();
            _loadDetails();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          IconButton(
            onPressed: _showAddSectionDialog,
            tooltip: 'Dodaj sekcję',
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sections.isEmpty ? null : _showAddDeviceSheet,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj urządzenie'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Błąd: $_error'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _loadDetails,
                        child: const Text('Spróbuj ponownie'),
                      ),
                    ],
                  ),
                )
              : _sections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Brak sekcji w tym pokoju'),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _showAddSectionDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Dodaj pierwszą sekcję'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sections.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final sectionData = _sections[index];
                        final section = sectionData.section;
                        final plantsWithSensors = sectionData.plants;
                        final sectionDevices = sectionData.devices;
                        final sectionPlants = plantsWithSensors
                            .map((e) => e.plant)
                            .toList();

                        return Card(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(
                                      16, 0, 16, 16),
                              leading: CircleAvatar(
                                backgroundColor:
                                    cs.secondaryContainer,
                                child: Icon(
                                  Icons.layers_outlined,
                                  color: cs.onSecondaryContainer,
                                ),
                              ),
                              title: Text(
                                section.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              subtitle: Text(
                                '${sectionPlants.length} roślin • ${sectionDevices.length} urządzeń',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                              ),
                              children: [
                                const SizedBox(height: 8),
                                // ===== ROŚLINY =====
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rośliny',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _showAddPlantDialog(
                                              sectionData),
                                      icon: const Icon(
                                          Icons.add_circle_outline),
                                      label: const Text('Dodaj roślinę'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (plantsWithSensors.isNotEmpty)
                                  Column(
                                    children: [
                                      for (final ps
                                          in plantsWithSensors)
                                        _PlantRow(
                                          plant: ps.plant,
                                          sensor: ps.moistureSensor,
                                          onDeleteSensor:
                                              ps.moistureSensor == null
                                                  ? null
                                                  : () => _deleteDevice(
                                                      ps.moistureSensor!),
                                        ),
                                    ],
                                  )
                                else
                                  Text(
                                    'Brak roślin w tej sekcji',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                // Urządzenia w sekcji
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Urządzenia sekcji',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (sectionDevices.isNotEmpty)
                                  Column(
                                    children: [
                                      for (final device
                                          in sectionDevices)
                                        if (device.type ==
                                            DeviceType
                                                .lightController)
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .only(
                                                    bottom:
                                                        8.0),
                                            child:
                                                _LightDeviceCard(
                                                  device: device,
                                                  onSettingsTap: () => _openLightDevice(device),
                                                  onDelete: () => _deleteDevice(device),
                                                  onRename: () => _renameDevice(device),
                                                ),
                                          )
                                        else if (device.type ==
                                            DeviceType.airSensor)
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .only(
                                                    bottom:
                                                        8.0),
                                            child:
                                                _AirDeviceCard(
                                                  device: device,
                                                  onDelete: () => _deleteDevice(device),
                                                  onRename: () => _renameDevice(device),
                                                ),
                                          )
                                        else
                                          ListTile(
                                            contentPadding:
                                                EdgeInsets.zero,
                                            leading:
                                                const Icon(Icons
                                                    .sensors),
                                            title:
                                                Text(device.name),
                                            trailing: IconButton(
                                              icon: const Icon(
                                                  Icons.delete),
                                              onPressed: () =>
                                                  _deleteDevice(
                                                      device),
                                            ),
                                          ),
                                    ],
                                  )
                                else
                                  Text(
                                    'Brak urządzeń przypisanych do sekcji',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}




class _AddDeviceSheet extends StatefulWidget {
  final List<SectionData> sections;
  final VoidCallback onDeviceCreated;

  const _AddDeviceSheet({
    required this.sections,
    required this.onDeviceCreated,
  });

  @override
  State<_AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends State<_AddDeviceSheet> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  DeviceType _type = DeviceType.lightController;
  SectionData? _selectedSection;
  PlantWithSensor? _selectedPlant;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.sections.isNotEmpty) {
      _selectedSection = widget.sections.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSection == null) {
      setState(() {
        _error = 'Wybierz sekcję';
      });
      return;
    }

    if (_type == DeviceType.soilMoistureSensor &&
        (_selectedPlant == null)) {
      setState(() {
        _error = 'Dla czujnika wilgotności wybierz roślinę';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.createDevice(
        name: _nameController.text.trim(),
        type: _type,
        sectionId:
            _type == DeviceType.soilMoistureSensor ? null : int.parse(_selectedSection!.section.id),
        plantId: _type == DeviceType.soilMoistureSensor
            ? int.parse(_selectedPlant!.plant.id)
            : null,
      );

      widget.onDeviceCreated();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sectionPlants =
        _selectedSection?.plants ?? const <PlantWithSensor>[];

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dodaj urządzenie',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // typ
                  DropdownButtonFormField<DeviceType>(
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: 'Typ urządzenia',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: DeviceType.lightController,
                        child: Text('Sterownik światła'),
                      ),
                      DropdownMenuItem(
                        value: DeviceType.airSensor,
                        child: Text('Czujnik powietrza'),
                      ),
                      DropdownMenuItem(
                        value: DeviceType.soilMoistureSensor,
                        child: Text('Czujnik wilgotności gleby'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _type = v ?? DeviceType.lightController;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa urządzenia',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Podaj nazwę urządzenia';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
             
                  DropdownButtonFormField<SectionData>(
                    value: _selectedSection,
                    decoration: const InputDecoration(
                      labelText: 'Sekcja',
                    ),
                    items: [
                      for (final s in widget.sections)
                        DropdownMenuItem(
                          value: s,
                          child: Text(s.section.name),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedSection = v;
                        _selectedPlant = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  if (_type == DeviceType.soilMoistureSensor)
                    DropdownButtonFormField<PlantWithSensor>(
                      value: _selectedPlant,
                      decoration: const InputDecoration(
                        labelText: 'Roślina',
                      ),
                      items: [
                        for (final ps in sectionPlants)
                          DropdownMenuItem(
                            value: ps,
                            child: Text(ps.plant.name),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedPlant = v;
                        });
                      },
                    ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Zapisz'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _PlantRow extends StatelessWidget {
  final Plant plant;
  final Device? sensor;
  final VoidCallback? onDeleteSensor;

  const _PlantRow({
    required this.plant,
    required this.sensor,
    this.onDeleteSensor,
  });

  int _stableStringHash(String s) {
    var hash = 0;
    for (final codeUnit in s.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  double? _fakeMoistureForSensor(Device? sensor) {
    if (sensor == null) return null;
    final seed = _stableStringHash(sensor.id);
    final rand = Random(seed);
    final value = 30 + rand.nextDouble() * 50; // 30–80 %
    return double.parse(value.toStringAsFixed(0));
  }

  void _openHistory(BuildContext context) {
    if (sensor == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SoilMoistureHistoryScreen(
          sensor: sensor!,
          plant: plant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final moisture = _fakeMoistureForSensor(sensor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(Icons.local_florist, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              plant.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: sensor != null ? () => _openHistory(context) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 4.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.opacity_outlined,
                    size: 18,
                    color:
                        sensor != null ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sensor != null
                        ? '${moisture?.toStringAsFixed(0)} %'
                        : 'brak czujnika',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: sensor != null
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (sensor != null && onDeleteSensor != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Usuń czujnik',
              onPressed: onDeleteSensor,
            ),
        ],
      ),
    );
  }
}


class _AirReading {
  final double temperatureC;
  final double humidity;
  final int co2ppm;

  _AirReading({
    required this.temperatureC,
    required this.humidity,
    required this.co2ppm,
  });
}

class _AirDeviceCard extends StatelessWidget {
   final Device device;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _AirDeviceCard({
    required this.device,
    required this.onDelete,
    required this.onRename,
  });

  int _stringHash(String s) {
    var hash = 0;
    for (final codeUnit in s.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  _AirReading _fakeReadingForDevice(Device device) {
    final seed = _stringHash(device.id);
    final rand = Random(seed);

    final temp = 18 + rand.nextDouble() * 8;
    final hum = 40 + rand.nextDouble() * 30;
    final co2 = 400 + rand.nextInt(800);

    return _AirReading(
      temperatureC: double.parse(temp.toStringAsFixed(1)),
      humidity: double.parse(hum.toStringAsFixed(0)),
      co2ppm: co2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reading = _fakeReadingForDevice(device);

    return Card(
      elevation: 0,
      color: cs.surfaceVariant.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.air,
                    color: cs.onPrimaryContainer,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    device.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Zmień nazwę',
                  onPressed: onRename,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Usuń urządzenie',
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _IconInfo(
                  icon: Icons.thermostat_outlined,
                  label:
                      '${reading.temperatureC.toStringAsFixed(1)} °C',
                ),
                _IconInfo(
                  icon: Icons.water_drop_outlined,
                  label:
                      '${reading.humidity.toStringAsFixed(0)} %',
                ),
                _IconInfo(
                  icon: Icons.cloud_outlined,
                  label: '${reading.co2ppm} ppm CO₂',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class _LightDeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onSettingsTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _LightDeviceCard({
    required this.device,
    required this.onSettingsTap,
    required this.onDelete,
    required this.onRename,
  });

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = device.lightSettings;

    return Card(
      elevation: 0,
      color: cs.surfaceVariant.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width:
                      32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wb_sunny_outlined,
                    color: cs.onPrimaryContainer,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    device.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: onSettingsTap,
                  icon: const Icon(Icons.settings),
                  tooltip: 'Ustawienia światła',
                ),
                IconButton(
                  onPressed: onRename,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Zmień nazwę',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Usuń urządzenie',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (settings == null)
              Text(
                'Brak skonfigurowanych ustawień',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _IconInfo(
                    icon: Icons.schedule,
                    label:
                        '${_formatTime(settings.startTime)}–${_formatTime(settings.endTime)}',
                  ),
                  _IconInfo(
                    icon: Icons.timelapse,
                    label:
                        'Wschód: ${settings.sunriseDuration.inMinutes} min',
                  ),
                  _IconInfo(
                    icon: Icons.nights_stay_outlined,
                    label:
                        'Zachód: ${settings.sunsetDuration.inMinutes} min',
                  ),
                  _IconInfo(
                    icon: Icons.bolt_outlined,
                    label:
                        'Max ${settings.maxPowerPercent.round()}%',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _IconInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IconInfo({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: cs.primary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
