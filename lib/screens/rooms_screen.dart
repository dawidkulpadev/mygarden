import 'package:flutter/material.dart';

import '../data/mock_data.dart' show plants, sections; // tymczasowo do zliczania
import '../models/room.dart';
import '../services/api_client.dart';
import 'login_screen.dart';
import 'room_detail_screen.dart';

class RoomsScreen extends StatefulWidget {
  final int userId; // <- teraz przechowujemy userId

  const RoomsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _api = ApiClient();

  bool _loading = true;
  String? _error;
  List<Room> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rooms = await _api.fetchRooms(widget.userId);
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
      });
    } catch (e) {
      if (!mounted) return;
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

  void _openRoom(BuildContext context, Room room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomDetailScreen(
          roomId: int.parse(room.id),
          roomName: room.name,
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje pokoje'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Wyloguj',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Błąd: $_error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _loadRooms,
                          child: const Text('Spróbuj ponownie'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final room = _rooms[index];

                      // Tymczasowo liczby z mock_data – później też wyciągniemy z backendu
                      final secCount =
                          sections.where((s) => s.roomId == room.id).length;
                      final roomSectionIds = sections
                          .where((s) => s.roomId == room.id)
                          .map((s) => s.id)
                          .toSet();
                      final plantsCount = plants
                          .where((p) => roomSectionIds.contains(p.sectionId))
                          .length;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openRoom(context, room),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.meeting_room_outlined,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$secCount sekcje • $plantsCount rośliny',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Dodawanie pokoju jeszcze niezaimplementowane 🙂'),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Dodaj pokój'),
      ),
    );
  }
}
