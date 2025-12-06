import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/device.dart';
import '../models/light_settings.dart';

class LightDeviceScreen extends StatefulWidget {
  final Device device;

  const LightDeviceScreen({super.key, required this.device});

  @override
  State<LightDeviceScreen> createState() => _LightDeviceScreenState();
}

class _LightDeviceScreenState extends State<LightDeviceScreen> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  double _sunriseMinutes = 30;
  double _sunsetMinutes = 30;
  double _maxPower = 80;

  @override
  void initState() {
    super.initState();
    final settings = widget.device.lightSettings;
    _startTime = settings?.startTime ?? const TimeOfDay(hour: 8, minute: 0);
    _endTime = settings?.endTime ?? const TimeOfDay(hour: 20, minute: 0);
    _sunriseMinutes = (settings?.sunriseDuration.inMinutes ?? 30).toDouble();
    _sunsetMinutes = (settings?.sunsetDuration.inMinutes ?? 30).toDouble();
    _maxPower = settings?.maxPowerPercent ?? 80;
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickStartTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (result != null) {
      setState(() => _startTime = result);
    }
  }

  Future<void> _pickEndTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (result != null) {
      setState(() => _endTime = result);
    }
  }

  void _save() {
    final newSettings = LightSettings(
      startTime: _startTime,
      endTime: _endTime,
      sunriseDuration: Duration(minutes: _sunriseMinutes.round()),
      sunsetDuration: Duration(minutes: _sunsetMinutes.round()),
      maxPowerPercent: _maxPower.roundToDouble(),
    );

    final updatedDevice = widget.device.copyWith(lightSettings: newSettings);

    final index = devices.indexWhere((d) => d.id == widget.device.id);
    if (index != -1) {
      devices[index] = updatedDevice;
    }

    Navigator.of(context).pop();
  }

  Future<void> _deleteDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń urządzenie'),
        content: const Text('Czy na pewno chcesz usunąć to urządzenie?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    devices.removeWhere((d) => d.id == widget.device.id);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Usuń urządzenie',
            onPressed: _deleteDevice,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Czasy świecenia',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickStartTime,
                            icon: const Icon(Icons.play_arrow),
                            label: Text('Początek: ${_formatTime(_startTime)}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickEndTime,
                            icon: const Icon(Icons.stop),
                            label: Text('Koniec: ${_formatTime(_endTime)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Światło będzie włączone między tymi godzinami.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wschód i zachód',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Czas trwania wschodu [min]',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      min: 0,
                      max: 120,
                      divisions: 12,
                      label: _sunriseMinutes.round().toString(),
                      value: _sunriseMinutes,
                      onChanged: (v) => setState(() => _sunriseMinutes = v),
                    ),
                    Text('${_sunriseMinutes.round()} min'),
                    const SizedBox(height: 16),
                    Text(
                      'Czas trwania zachodu [min]',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      min: 0,
                      max: 120,
                      divisions: 12,
                      label: _sunsetMinutes.round().toString(),
                      value: _sunsetMinutes,
                      onChanged: (v) => setState(() => _sunsetMinutes = v),
                    ),
                    Text('${_sunsetMinutes.round()} min'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maksymalna moc',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      min: 10,
                      max: 100,
                      divisions: 18,
                      label: _maxPower.round().toString(),
                      value: _maxPower,
                      onChanged: (v) => setState(() => _maxPower = v),
                    ),
                    Text(
                      '${_maxPower.round()} %',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'To maksymalna jasność do której urządzenie będzie dochodzić w ciągu dnia',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
  }
}
