import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/structs.dart' as structs;
import 'time_slot_widget.dart';

/// Individual day column in the availability grid
class DayColumn extends StatelessWidget {
  final String dayKey;
  final GlobalKey gridKey;
  final List<int> hours;
  final double hourHeight;
  final double quarterHeight;
  final int baseMinutes;
  final double totalHeight;
  final List<structs.TimeSlot> daySlots;
  final String? dragDayKey;
  final double? dragStartY;
  final double? dragCurrentY;
  final String? movingSlotDayKey;
  final structs.TimeSlot? movingSlot;
  final Offset? movingSlotOffset;
  final Function(LongPressStartDetails) onLongPressStart;
  final Function(LongPressMoveUpdateDetails) onLongPressMoveUpdate;
  final Function(LongPressEndDetails) onLongPressEnd;
  final Function(structs.TimeSlot) onRemoveSlot;
  final Function(structs.TimeSlot, LongPressStartDetails) onSlotLongPressStart;
  final Function(structs.TimeSlot, LongPressMoveUpdateDetails)
      onSlotLongPressMoveUpdate;
  final Function(structs.TimeSlot, LongPressEndDetails) onSlotLongPressEnd;

  const DayColumn({
    super.key,
    required this.dayKey,
    required this.gridKey,
    required this.hours,
    required this.hourHeight,
    required this.quarterHeight,
    required this.baseMinutes,
    required this.totalHeight,
    required this.daySlots,
    required this.dragDayKey,
    required this.dragStartY,
    required this.dragCurrentY,
    required this.movingSlotDayKey,
    required this.movingSlot,
    required this.movingSlotOffset,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    required this.onRemoveSlot,
    required this.onSlotLongPressStart,
    required this.onSlotLongPressMoveUpdate,
    required this.onSlotLongPressEnd,
  });

  String _getDayLabel(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (dayKey) {
      case 'monday':
        return t.monday;
      case 'tuesday':
        return t.tuesday;
      case 'wednesday':
        return t.wednesday;
      case 'thursday':
        return t.thursday;
      case 'friday':
        return t.friday;
      case 'saturday':
        return t.saturday;
      case 'sunday':
        return t.sunday;
      default:
        return dayKey;
    }
  }

  int _timeStringToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayLabel = _getDayLabel(context);

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
            key: gridKey,
            onLongPressStart: onLongPressStart,
            onLongPressMoveUpdate: onLongPressMoveUpdate,
            onLongPressEnd: onLongPressEnd,
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
                          children: List.generate(
                              4,
                              (i) => Container(
                                    height: quarterHeight - 1,
                                    decoration: i < 3
                                        ? BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: theme.dividerColor
                                                    .withAlpha(36),
                                                width: 0.5,
                                              ),
                                            ),
                                          )
                                        : null,
                                  )),
                        ),
                      ),
                    );
                  }),
                  // Existing time slots (exclude the one being moved)
                  ...daySlots
                      .where((slot) =>
                          movingSlot == null ||
                          movingSlotDayKey != dayKey ||
                          slot.startTime != movingSlot!.startTime ||
                          slot.endTime != movingSlot!.endTime)
                      .map((slot) {
                    final startMinutes = _timeStringToMinutes(slot.startTime);
                    final endMinutes = _timeStringToMinutes(slot.endTime);
                    final duration = endMinutes - startMinutes;

                    final topPosition =
                        ((startMinutes - baseMinutes) / 60) * hourHeight;
                    final height = (duration / 60) * hourHeight;

                    return Positioned(
                      top: topPosition.clamp(0.0, totalHeight),
                      left: 4,
                      right: 4,
                      child: TimeSlotWidget(
                        slot: slot,
                        dayKey: dayKey,
                        height: height,
                        onRemove: () => onRemoveSlot(slot),
                        onLongPressStart: (details) =>
                            onSlotLongPressStart(slot, details),
                        onLongPressMoveUpdate: (details) =>
                            onSlotLongPressMoveUpdate(slot, details),
                        onLongPressEnd: (details) =>
                            onSlotLongPressEnd(slot, details),
                      ),
                    );
                  }),
                  // Active drag indicator for creating new slot
                  if (dragDayKey == dayKey &&
                      dragStartY != null &&
                      dragCurrentY != null &&
                      movingSlot == null)
                    DragIndicator(
                      top: (dragStartY! < dragCurrentY!
                              ? dragStartY!
                              : dragCurrentY!)
                          .clamp(0.0, totalHeight),
                      height: (dragCurrentY! - dragStartY!)
                          .abs()
                          .clamp(20.0, totalHeight),
                    ),
                  // Moving slot overlay
                  if (movingSlotDayKey == dayKey &&
                      movingSlot != null &&
                      movingSlotOffset != null)
                    Positioned(
                      top: movingSlotOffset!.dy.clamp(0.0, totalHeight),
                      left: 4,
                      right: 4,
                      child: Opacity(
                        opacity: 0.8,
                        child: MovingSlotWidget(
                          slot: movingSlot!,
                          height: (((_timeStringToMinutes(movingSlot!.endTime) -
                                          _timeStringToMinutes(
                                              movingSlot!.startTime)) /
                                      60) *
                                  hourHeight)
                              .clamp(40.0, double.infinity),
                        ),
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
}
