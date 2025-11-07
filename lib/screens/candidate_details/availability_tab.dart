import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../models/structs.dart' as structs;

class AvailabilityCalendarTab extends StatefulWidget {
  final structs.Candidate candidate;

  const AvailabilityCalendarTab({
    super.key,
    required this.candidate,
  });

  @override
  State<AvailabilityCalendarTab> createState() => _AvailabilityCalendarTabState();
}

class _AvailabilityCalendarTabState extends State<AvailabilityCalendarTab> {
  double _zoomLevel = 1.2;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  // Modified availability (local state)
  late Map<String, List<structs.TimeSlot>> _workingAvailability;
  bool _hasChanges = false;

  // Drag state for creating new slots
  String? _dragDayKey;
  double? _dragStartY;
  double? _dragCurrentY;

  // Drag state for moving existing slots
  String? _movingSlotDayKey;
  structs.TimeSlot? _movingSlot;
  Offset? _movingSlotOffset;

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
    _workingAvailability = _deepCopyAvailability(widget.candidate.availability);
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Map<String, List<structs.TimeSlot>> _deepCopyAvailability(
      Map<String, List<structs.TimeSlot>> original) {
    final copy = <String, List<structs.TimeSlot>>{};
    original.forEach((key, value) {
      copy[key] = value.map((slot) => structs.TimeSlot(
        startTime: slot.startTime,
        endTime: slot.endTime,
      )).toList();
    });
    return copy;
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

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
      // Convert to Map for Firestore
      Map<String, dynamic> availabilityMap = {};
      _workingAvailability.forEach((day, slots) {
        availabilityMap[day] = slots.map((slot) => slot.toMap()).toList();
      });

      await FirebaseFirestore.instance
          .collection('candidates')
          .doc(widget.candidate.id)
          .update({'availability': availabilityMap});

      setState(() {
        _hasChanges = false;
      });

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

  // Snap minutes to 15-minute intervals
  int _snapToQuarterHour(int minutes) {
    return (minutes / 15).round() * 15;
  }

  // Merge overlapping or touching slots
  void _mergeSlots(String dayKey, int startMinutes, int endMinutes) {
    final slots = _workingAvailability[dayKey] ?? [];
    final toRemove = <structs.TimeSlot>[];
    int mergedStart = startMinutes;
    int mergedEnd = endMinutes;

    for (var slot in slots) {
      final slotStart = _timeStringToMinutes(slot.startTime);
      final slotEnd = _timeStringToMinutes(slot.endTime);

      // Check if slots overlap or touch (no gap between them)
      if (mergedStart <= slotEnd && mergedEnd >= slotStart) {
        mergedStart = mergedStart < slotStart ? mergedStart : slotStart;
        mergedEnd = mergedEnd > slotEnd ? mergedEnd : slotEnd;
        toRemove.add(slot);
      }
    }

    // Remove old slots
    for (var slot in toRemove) {
      _workingAvailability[dayKey]?.removeWhere(
            (s) => s.startTime == slot.startTime && s.endTime == slot.endTime,
      );
    }

    // Add merged slot
    if (!_workingAvailability.containsKey(dayKey)) {
      _workingAvailability[dayKey] = [];
    }
    _workingAvailability[dayKey]!.add(
      structs.TimeSlot(
        startTime: _minutesToTimeString(mergedStart),
        endTime: _minutesToTimeString(mergedEnd),
      ),
    );
  }

  void _addTimeSlot(String dayKey, String startTime, String endTime) {
    final startMinutes = _timeStringToMinutes(startTime);
    final endMinutes = _timeStringToMinutes(endTime);

    setState(() {
      _mergeSlots(dayKey, startMinutes, endMinutes);
      _hasChanges = true;
    });
  }

  void _removeTimeSlot(String dayKey, structs.TimeSlot slot) {
    setState(() {
      _workingAvailability[dayKey]?.removeWhere(
            (s) => s.startTime == slot.startTime && s.endTime == slot.endTime,
      );
      if (_workingAvailability[dayKey]?.isEmpty ?? false) {
        _workingAvailability.remove(dayKey);
      }
      _hasChanges = true;
    });
  }

  void _moveTimeSlot(String fromDayKey, structs.TimeSlot slot, String toDayKey, int newStartMinutes) {
    final startMinutes = _timeStringToMinutes(slot.startTime);
    final endMinutes = _timeStringToMinutes(slot.endTime);
    final duration = endMinutes - startMinutes;
    final newEndMinutes = newStartMinutes + duration;

    // Ensure the slot stays within bounds
    if (newStartMinutes < 8 * 60 || newEndMinutes > 20 * 60) {
      return;
    }

    setState(() {
      // Remove from old location
      _workingAvailability[fromDayKey]?.removeWhere(
            (s) => s.startTime == slot.startTime && s.endTime == slot.endTime,
      );
      if (_workingAvailability[fromDayKey]?.isEmpty ?? false) {
        _workingAvailability.remove(fromDayKey);
      }

      // Add to new location (with merging)
      _mergeSlots(toDayKey, newStartMinutes, newEndMinutes);
      _hasChanges = true;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Column(
        children: [
          // Header with save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      t.weeklyAvailability,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_hasChanges)
                  ElevatedButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.save),
                    label: Text(t.save),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.primaryContainer.withAlpha(100),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.availabilityInstructions,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          // Calendar grid with zoom controls
          Expanded(
            child: Stack(
              children: [
                _buildCalendarGrid(theme, t),
                // Zoom controls (bottom right)
                Positioned(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme, AppLocalizations t) {
    final hourHeight = 60.0 * _zoomLevel;
    final quarterHeight = hourHeight / 4; // Height for 15-minute intervals
    final hours = List.generate(13, (index) => 8 + index); // 8 AM to 8 PM
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
                // Time column
                _buildTimeColumn(hours, hourHeight, quarterHeight, theme),

                // Day columns
                ...List.generate(7, (dayIndex) {
                  final dayKey = _dayKeys[dayIndex];

                  return _buildDayColumn(
                    dayKey,
                    hours,
                    hourHeight,
                    quarterHeight,
                    baseMinutes,
                    totalHeight,
                    theme,
                    t,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn(List<int> hours, double hourHeight, double quarterHeight, ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 80,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Text(
              t.time,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Hour labels with quarter-hour marks
          ...hours.map((hour) {
            return Container(
              height: hourHeight,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withAlpha(72),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Hour label
                  Container(
                    height: hourHeight - 2,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayColumn(
      String dayKey,
      List<int> hours,
      double hourHeight,
      double quarterHeight,
      int baseMinutes,
      double totalHeight,
      ThemeData theme,
      AppLocalizations t,
      ) {
    final daySlots = _workingAvailability[dayKey] ?? [];
    final dayLabel = _getDayLabel(dayKey, t);
    final yOffset = 200.0;

    return Container(
      width: 120,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Day header
          Container(
            height: 80,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Center(
              child: Text(
                dayLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Day grid with slots
          GestureDetector(
            onLongPressStart: (details) {
              if (_movingSlot != null) return; // Don't create if moving

              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);

              setState(() {
                _dragDayKey = dayKey;
                _dragStartY = localPosition.dy - yOffset;
                _dragCurrentY = _dragStartY;
              });
            },
            onLongPressMoveUpdate: (details) {
              if (_dragDayKey == dayKey && _dragStartY != null && _movingSlot == null) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);

                setState(() {
                  _dragCurrentY = (localPosition.dy - yOffset).clamp(0.0, totalHeight);
                });
              }
            },
            onLongPressEnd: (details) {
              if (_dragDayKey == dayKey && _dragStartY != null && _dragCurrentY != null && _movingSlot == null) {
                final startY = _dragStartY!.clamp(0.0, totalHeight);
                final endY = _dragCurrentY!.clamp(0.0, totalHeight);

                final startMinutes = _snapToQuarterHour(baseMinutes + ((startY / hourHeight) * 60).round());
                final endMinutes = _snapToQuarterHour(baseMinutes + ((endY / hourHeight) * 60).round());

                if ((endMinutes - startMinutes).abs() >= 15) {
                  final actualStart = startMinutes < endMinutes ? startMinutes : endMinutes;
                  final actualEnd = startMinutes < endMinutes ? endMinutes : startMinutes;

                  _addTimeSlot(
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
            },
            child: SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  // Hour dividers with quarter-hour marks
                  ...hours.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Positioned(
                      top: index * hourHeight,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: hourHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.dividerColor.withAlpha(72),
                            ),
                          ),
                        ),
                        child: Column(
                          children: List.generate(4, (i) => Container(
                            height: quarterHeight - 1,
                            decoration: i < 3 ? BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: theme.dividerColor.withAlpha(36),
                                  width: 0.5,
                                ),
                              ),
                            ) : null,
                          )),
                        ),
                      ),
                    );
                  }),

                  // Existing time slots (exclude the one being moved)
                  ...daySlots.where((slot) =>
                  _movingSlot == null ||
                      _movingSlotDayKey != dayKey ||
                      slot.startTime != _movingSlot!.startTime ||
                      slot.endTime != _movingSlot!.endTime
                  ).map((slot) {
                    final startMinutes = _timeStringToMinutes(slot.startTime);
                    final endMinutes = _timeStringToMinutes(slot.endTime);
                    final duration = endMinutes - startMinutes;

                    final topPosition = ((startMinutes - baseMinutes) / 60) * hourHeight;
                    final height = (duration / 60) * hourHeight;

                    return Positioned(
                      top: topPosition.clamp(0.0, totalHeight),
                      left: 4,
                      right: 4,
                      child: _buildTimeSlotBlock(slot, dayKey, height, hourHeight, baseMinutes, totalHeight, theme, yOffset),
                    );
                  }),

                  // Active drag indicator for creating new slot
                  if (_dragDayKey == dayKey && _dragStartY != null && _dragCurrentY != null && _movingSlot == null)
                    Positioned(
                      top: (_dragStartY! < _dragCurrentY!
                          ? _dragStartY!
                          : _dragCurrentY!).clamp(0.0, totalHeight),
                      left: 4,
                      right: 4,
                      child: Container(
                        height: (_dragCurrentY! - _dragStartY!).abs().clamp(20.0, totalHeight),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(100),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.access_time,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),

                  // Moving slot overlay
                  if (_movingSlotDayKey == dayKey && _movingSlot != null && _movingSlotOffset != null)
                    Positioned(
                      top: _movingSlotOffset!.dy,
                      left: 4,
                      right: 4,
                      child: Opacity(
                        opacity: 0.8,
                        child: _buildMovingSlotBlock(_movingSlot!, hourHeight, baseMinutes, theme),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotBlock(
      structs.TimeSlot slot,
      String dayKey,
      double height,
      double hourHeight,
      int baseMinutes,
      double totalHeight,
      ThemeData theme,
      double yOffset,
      ) {
    return GestureDetector(
      onLongPressStart: (details) {
        setState(() {
          _movingSlotDayKey = dayKey;
          _movingSlot = slot;
          _movingSlotOffset = Offset(0, details.localPosition.dy);
        });
      },
      onLongPressMoveUpdate: (details) {
        if (_movingSlot != null && _movingSlotDayKey == dayKey) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);

          setState(() {
            _movingSlotOffset = Offset(0, (localPosition.dy - yOffset).clamp(0.0, totalHeight));
          });
        }
      },
      onLongPressEnd: (details) {
        if (_movingSlot != null && _movingSlotDayKey == dayKey && _movingSlotOffset != null) {
          final newY = _movingSlotOffset!.dy;
          final newStartMinutes = _snapToQuarterHour(baseMinutes + ((newY / hourHeight) * 60).round());

          _moveTimeSlot(dayKey, _movingSlot!, dayKey, newStartMinutes);
        }

        setState(() {
          _movingSlot = null;
          _movingSlotDayKey = null;
          _movingSlotOffset = null;
        });
      },
      child: Container(
        height: height.clamp(40.0, double.infinity),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slot.startTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    slot.endTime,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeTimeSlot(dayKey, slot),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: theme.colorScheme.onError,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovingSlotBlock(
      structs.TimeSlot slot,
      double hourHeight,
      int baseMinutes,
      ThemeData theme,
      ) {
    final startMinutes = _timeStringToMinutes(slot.startTime);
    final endMinutes = _timeStringToMinutes(slot.endTime);
    final duration = endMinutes - startMinutes;
    final height = (duration / 60) * hourHeight;

    return Container(
      height: height.clamp(40.0, double.infinity),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.drag_indicator,
              size: 16,
              color: theme.colorScheme.onSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              slot.startTime,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondary,
              ),
            ),
            Text(
              slot.endTime,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayLabel(String dayKey, AppLocalizations t) {
    switch (dayKey) {
      case 'monday': return t.monday;
      case 'tuesday': return t.tuesday;
      case 'wednesday': return t.wednesday;
      case 'thursday': return t.thursday;
      case 'friday': return t.friday;
      case 'saturday': return t.saturday;
      case 'sunday': return t.sunday;
      default: return dayKey;
    }
  }
}