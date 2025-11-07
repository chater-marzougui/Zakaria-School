import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/structs.dart' as structs;
import 'availability_widgets/availability_state.dart';
import 'availability_widgets/availability_header.dart';
import 'availability_widgets/time_column.dart';
import 'availability_widgets/day_column.dart';

/// Main availability calendar tab widget
class AvailabilityCalendarTab extends StatefulWidget {
  final structs.Candidate candidate;

  const AvailabilityCalendarTab({
    super.key,
    required this.candidate,
  });

  @override
  State<AvailabilityCalendarTab> createState() =>
      _AvailabilityCalendarTabState();
}

class _AvailabilityCalendarTabState extends State<AvailabilityCalendarTab> {
  late AvailabilityState _availabilityState;
  double _zoomLevel = 1.2;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  // Drag state for creating new slots
  String? _dragDayKey;
  double? _dragStartY;
  double? _dragCurrentY;

  // Drag state for moving existing slots
  String? _movingSlotDayKey;
  structs.TimeSlot? _movingSlot;
  Offset? _movingSlotOffset;

  // Keys for each day grid
  final Map<String, GlobalKey> _dayGridKeys = {};

  final List<String> _dayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    _availabilityState = AvailabilityState(
      candidateId: widget.candidate.id,
      initialAvailability: widget.candidate.availability,
    );
    _availabilityState.addListener(_onStateChanged);

    // Initialize keys for each day column
    for (var dayKey in _dayKeys) {
      _dayGridKeys[dayKey] = GlobalKey();
    }

    // Reload data from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _availabilityState.reloadFromFirestore();
    });
  }

  @override
  void dispose() {
    _availabilityState.removeListener(_onStateChanged);
    _availabilityState.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    if (!_availabilityState.hasChanges) return true;

    final t = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(t.unsavedChanges),
        content: Text(t.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(t.discard),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(t.save),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _saveChanges();
      return true;
    } else if (result == 'discard') {
      return true;
    }
    return false;
  }

  Future<void> _saveChanges() async {
    final t = AppLocalizations.of(context)!;
    try {
      await _availabilityState.saveChanges();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.changesSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.error(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_availabilityState.hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Column(
        children: [
          AvailabilityHeader(
            hasChanges: _availabilityState.hasChanges,
            onSave: _saveChanges,
          ),
          const AvailabilityInstructions(),
          Expanded(
            child: Stack(
              children: [
                _buildCalendarGrid(theme),
                _buildZoomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: () {
              setState(() {
                _zoomLevel = (_zoomLevel * 1.2).clamp(0.5, 3.0);
              });
            },
            tooltip: 'Zoom In',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: () {
              setState(() {
                _zoomLevel = (_zoomLevel / 1.2).clamp(0.5, 3.0);
              });
            },
            tooltip: 'Zoom Out',
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final hourHeight = 60.0 * _zoomLevel;
    final quarterHeight = hourHeight / 4;
    final hours = List.generate(13, (index) => 8 + index);
    const baseMinutes = 8 * 60;
    final totalHeight = hours.length * hourHeight;

    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          _zoomLevel = (_zoomLevel * details.scale).clamp(0.5, 3.0);
        });
      },
      child: SingleChildScrollView(
        controller: _verticalController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 70 + (7 * 120.0),
            height: 80 + totalHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TimeColumn(
                  hours: hours,
                  hourHeight: hourHeight,
                  quarterHeight: quarterHeight,
                ),
                ...List.generate(7, (dayIndex) {
                  final dayKey = _dayKeys[dayIndex];
                  final daySlots =
                      _availabilityState.availability[dayKey] ?? [];

                  return DayColumn(
                    dayKey: dayKey,
                    gridKey: _dayGridKeys[dayKey]!,
                    hours: hours,
                    hourHeight: hourHeight,
                    quarterHeight: quarterHeight,
                    baseMinutes: baseMinutes,
                    totalHeight: totalHeight,
                    daySlots: daySlots,
                    dragDayKey: _dragDayKey,
                    dragStartY: _dragStartY,
                    dragCurrentY: _dragCurrentY,
                    movingSlotDayKey: _movingSlotDayKey,
                    movingSlot: _movingSlot,
                    movingSlotOffset: _movingSlotOffset,
                    onLongPressStart: (details) =>
                        _handleDayLongPressStart(dayKey, details, totalHeight),
                    onLongPressMoveUpdate: (details) =>
                        _handleDayLongPressMoveUpdate(
                            dayKey, details, totalHeight),
                    onLongPressEnd: (details) => _handleDayLongPressEnd(
                        dayKey, hourHeight, baseMinutes, totalHeight),
                    onRemoveSlot: (slot) =>
                        _availabilityState.removeTimeSlot(dayKey, slot),
                    onSlotLongPressStart: (slot, details) =>
                        _handleSlotLongPressStart(
                            dayKey, slot, hourHeight, baseMinutes),
                    onSlotLongPressMoveUpdate: (slot, details) =>
                        _handleSlotLongPressMoveUpdate(
                            dayKey, details, totalHeight),
                    onSlotLongPressEnd: (slot, details) =>
                        _handleSlotLongPressEnd(
                            dayKey, slot, hourHeight, baseMinutes),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Handlers for creating new slots
  void _handleDayLongPressStart(
      String dayKey, LongPressStartDetails details, double totalHeight) {
    if (_movingSlot != null) return;

    final renderObject =
        _dayGridKeys[dayKey]?.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final gridBox = renderObject;

    final localPosition = gridBox.globalToLocal(details.globalPosition);

    setState(() {
      _dragDayKey = dayKey;
      _dragStartY = localPosition.dy.clamp(0.0, totalHeight);
      _dragCurrentY = _dragStartY;
    });
  }

  void _handleDayLongPressMoveUpdate(
      String dayKey, LongPressMoveUpdateDetails details, double totalHeight) {
    if (_dragDayKey == dayKey && _dragStartY != null && _movingSlot == null) {
      final renderObject =
          _dayGridKeys[dayKey]?.currentContext?.findRenderObject();
      if (renderObject is! RenderBox) return;
      final gridBox = renderObject;

      final localPosition = gridBox.globalToLocal(details.globalPosition);

      setState(() {
        _dragCurrentY = localPosition.dy.clamp(0.0, totalHeight);
      });
    }
  }

  void _handleDayLongPressEnd(String dayKey, double hourHeight,
      int baseMinutes, double totalHeight) {
    if (_dragDayKey == dayKey &&
        _dragStartY != null &&
        _dragCurrentY != null &&
        _movingSlot == null) {
      final startY = _dragStartY!.clamp(0.0, totalHeight);
      final endY = _dragCurrentY!.clamp(0.0, totalHeight);

      final startMinutes = _availabilityState
          .snapToQuarterHour(baseMinutes + ((startY / hourHeight) * 60).round());
      final endMinutes = _availabilityState
          .snapToQuarterHour(baseMinutes + ((endY / hourHeight) * 60).round());

      if ((endMinutes - startMinutes).abs() >= 15) {
        final actualStart =
            startMinutes < endMinutes ? startMinutes : endMinutes;
        final actualEnd = startMinutes < endMinutes ? endMinutes : startMinutes;

        _availabilityState.addTimeSlot(
          dayKey,
          _minutesToTimeString(actualStart),
          _minutesToTimeString(actualEnd),
        );
      }

      setState(() {
        _dragDayKey = null;
        _dragStartY = null;
        _dragCurrentY = null;
      });
    }
  }

  // Handlers for moving existing slots
  void _handleSlotLongPressStart(
      String dayKey, structs.TimeSlot slot, double hourHeight, int baseMinutes) {
    setState(() {
      _movingSlotDayKey = dayKey;
      _movingSlot = slot;
      final startMinutes = _timeStringToMinutes(slot.startTime);
      final topPosition = ((startMinutes - baseMinutes) / 60) * hourHeight;
      _movingSlotOffset = Offset(0, topPosition);
    });
  }

  void _handleSlotLongPressMoveUpdate(
      String dayKey, LongPressMoveUpdateDetails details, double totalHeight) {
    if (_movingSlot != null && _movingSlotDayKey == dayKey) {
      final renderObject =
          _dayGridKeys[dayKey]?.currentContext?.findRenderObject();
      if (renderObject is! RenderBox) return;
      final gridBox = renderObject;

      final localPosition = gridBox.globalToLocal(details.globalPosition);

      setState(() {
        _movingSlotOffset = Offset(0, localPosition.dy.clamp(0.0, totalHeight));
      });
    }
  }

  void _handleSlotLongPressEnd(String dayKey, structs.TimeSlot slot,
      double hourHeight, int baseMinutes) {
    if (_movingSlot != null &&
        _movingSlotDayKey == dayKey &&
        _movingSlotOffset != null) {
      final newY = _movingSlotOffset!.dy;
      final newStartMinutes = _availabilityState
          .snapToQuarterHour(baseMinutes + ((newY / hourHeight) * 60).round());

      _availabilityState.moveTimeSlot(dayKey, _movingSlot!, dayKey, newStartMinutes);
    }

    setState(() {
      _movingSlot = null;
      _movingSlotDayKey = null;
      _movingSlotOffset = null;
    });
  }

  String _minutesToTimeString(int minutes) {
    final hours = (minutes ~/ 60).clamp(0, 23);
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  int _timeStringToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
