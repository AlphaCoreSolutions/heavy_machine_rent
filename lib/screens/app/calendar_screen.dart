import 'package:flutter/material.dart';
import 'package:ajjara/foundation/localization/l10n_extensions.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:ajjara/core/api/api_handler.dart' as api;
import 'package:ajjara/core/models/admin/request.dart';
import 'package:ajjara/core/models/equipment/equipment.dart';
import 'package:ajjara/foundation/widgets/calendar_event_tile.dart';
import 'package:ajjara/screens/request_screens/request_details_screen.dart';

class RequestCalendarScreen extends StatefulWidget {
  final int vendorId;

  const RequestCalendarScreen({super.key, required this.vendorId});

  @override
  State<RequestCalendarScreen> createState() => _RequestCalendarScreenState();
}

enum DayPosition { start, middle, end, single, none }

class _RequestCalendarScreenState extends State<RequestCalendarScreen> {
  late final ValueNotifier<List<RequestModel>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTimeRange? _filterRange;
  Equipment? _selectedEquipment;
  List<RequestModel> _allRequests = [];

  final Map<DateTime, List<RequestModel>> _eventsMap = {};
  final Map<int, Color> _requestColors = {};

  @override
  void initState() {
    super.initState();
    _selectedEvents = ValueNotifier([]);
    _fetchRequests();
  }

  DayPosition getDayPosition(DateTime day, RequestModel request) {
    final from = DateTime.tryParse(request.fromDate ?? '');
    final to = DateTime.tryParse(request.toDate ?? '');
    if (from == null || to == null) return DayPosition.none;

    final d = _normalizeDate(day);
    final f = _normalizeDate(from);
    final t = _normalizeDate(to);

    if (d == f && d == t) return DayPosition.single;
    if (d == f) return DayPosition.start;
    if (d == t) return DayPosition.end;
    if (d.isAfter(f) && d.isBefore(t)) return DayPosition.middle;
    return DayPosition.none;
  }

  Future<void> _fetchRequests() async {
    final query =
        'select * from requests where vendorId = ${widget.vendorId} and statusId = 37';
    final requests = await api.Api.advanceSearchRequests(query);

    setState(() {
      _allRequests = requests;
      _generateEventsMap();
    });
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void _generateEventsMap() {
    _eventsMap.clear();
    _requestColors.clear();
    final availableColors = [
      Colors.green,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.purple,
    ];

    int colorIndex = 0;

    for (var request in _allRequests) {
      final from = DateTime.tryParse(request.fromDate ?? '');
      final to = DateTime.tryParse(request.toDate ?? '');

      if (from == null || to == null) continue;

      _requestColors[request.requestId ?? colorIndex] =
          availableColors[colorIndex % availableColors.length];
      colorIndex++;

      final days = to.difference(from).inDays + 1;
      for (int i = 0; i < days; i++) {
        final day = _normalizeDate(from.add(Duration(days: i)));

        if (_filterRange != null &&
            (day.isBefore(_normalizeDate(_filterRange!.start)) ||
                day.isAfter(_normalizeDate(_filterRange!.end)))) {
          continue;
        }

        if (_selectedEquipment != null &&
            request.equipmentId != _selectedEquipment!.equipmentId) {
          continue;
        }

        _eventsMap.putIfAbsent(day, () => []).add(request);
      }
    }

    final today = _normalizeDate(_focusedDay);
    _onDaySelected(today, _eventsMap[today] ?? []);
  }

  void _onDaySelected(DateTime selectedDay, List<RequestModel> events) {
    final normalizedDay = _normalizeDate(selectedDay);
    setState(() {
      _selectedDay = normalizedDay;
      _focusedDay = normalizedDay;
    });
    _selectedEvents.value = events;
  }

  Future<void> _selectEquipment() async {
    final equipment = await showModalBottomSheet<Equipment>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const EquipmentFilterBottomSheet(),
    );

    if (equipment != null) {
      setState(() {
        _selectedEquipment = equipment;
        _generateEventsMap();
      });
    }
  }

  void _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (range != null) {
      setState(() {
        _filterRange = range;
        _generateEventsMap();
      });
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.requestCalendar),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: context.l10n.filterByEquipment,
            onPressed: _selectEquipment,
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: context.l10n.filterByDate,
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: Column(
          children: [
            TableCalendar<RequestModel>(
              focusedDay: _focusedDay,
              firstDay: DateTime(2020),
              lastDay: DateTime(2035),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) =>
                  isSameDay(_normalizeDate(_selectedDay ?? _focusedDay), day),
              onDaySelected: (selectedDay, _) {
                final key = _normalizeDate(selectedDay);
                _onDaySelected(key, _eventsMap[key] ?? []);
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              eventLoader: (day) => _eventsMap[_normalizeDate(day)] ?? [],
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF12B76A).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF12B76A),
                  shape: BoxShape.circle,
                ), // 👈 Prevents purple background
                outsideDaysVisible: false,
              ),

              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) {
                  final normalizedDay = _normalizeDate(day);
                  final requests = _eventsMap[normalizedDay] ?? [];
                  final isSelected = isSameDay(normalizedDay, _selectedDay);
                  Color? bgColor;
                  BorderRadius? radius;

                  if (requests.isNotEmpty) {
                    final request = requests.first;
                    final color =
                        _requestColors[request.requestId] ??
                        Theme.of(context).colorScheme.primary;
                    bgColor = color.withOpacity(0.4);

                    final isArabic =
                        Directionality.of(context) == TextDirection.rtl;
                    final pos = getDayPosition(day, request);

                    switch (pos) {
                      case DayPosition.single:
                        radius = BorderRadius.circular(20);
                        break;
                      case DayPosition.start:
                        radius = isArabic
                            ? const BorderRadius.horizontal(
                                right: Radius.circular(20),
                                left: Radius.circular(0),
                              )
                            : const BorderRadius.horizontal(
                                left: Radius.circular(20),
                                right: Radius.circular(0),
                              );
                        break;
                      case DayPosition.middle:
                        radius = BorderRadius.zero;
                        break;
                      case DayPosition.end:
                        radius = isArabic
                            ? const BorderRadius.horizontal(
                                right: Radius.circular(0),
                                left: Radius.circular(20),
                              )
                            : const BorderRadius.horizontal(
                                left: Radius.circular(0),
                                right: Radius.circular(20),
                              );
                        break;
                      default:
                        radius = BorderRadius.circular(8);
                    }
                  }

                  // Light green color for selected day
                  final selectedColor = const Color(0xFF12B76A);

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedColor.withOpacity(0.8)
                          : bgColor,
                      borderRadius: radius ?? BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: requests.isNotEmpty
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ValueListenableBuilder<List<RequestModel>>(
                valueListenable: _selectedEvents,
                builder: (_, events, __) {
                  if (events.isEmpty) {
                    return Center(child: Text(context.l10n.noRequests));
                  }
                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (_, index) {
                      final request = events[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RequestDetailsScreen(
                                requestId: request.requestId ?? 0,
                              ),
                            ),
                          );
                        },
                        child: CalendarEventTile(request: request)
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.2, duration: 300.ms),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EquipmentFilterBottomSheet extends StatefulWidget {
  const EquipmentFilterBottomSheet({super.key});

  @override
  State<EquipmentFilterBottomSheet> createState() =>
      _EquipmentFilterBottomSheetState();
}

class _EquipmentFilterBottomSheetState
    extends State<EquipmentFilterBottomSheet> {
  List<Equipment> _equipments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEquipments();
  }

  Future<void> _fetchEquipments() async {
    try {
      const query = 'select * from equipments';
      final results = await api.Api.advanceSearchEquipments(query);
      setState(() {
        _equipments = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load equipments';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Text(
              context.l10n.selectEquipment,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Loading / Error / Empty / List
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text(context.l10n.failedToLoadEquipments))
            else if (_equipments.isEmpty)
              Center(child: Text(context.l10n.noEquipmentFound))
            else
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: _equipments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final equipment = _equipments[index];
                    return ListTile(
                      title: Text(equipment.title),
                      leading: const Icon(Icons.build),
                      onTap: () => Navigator.pop(context, equipment),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(context.l10n.clearFilter),
            ),
          ],
        ),
      ),
    );
  }
}
