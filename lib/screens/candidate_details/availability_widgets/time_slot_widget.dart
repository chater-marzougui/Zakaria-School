import 'package:flutter/material.dart';
import '../../../models/structs.dart' as structs;

/// Widget for displaying a time slot block
class TimeSlotWidget extends StatelessWidget {
  final structs.TimeSlot slot;
  final String dayKey;
  final double height;
  final VoidCallback onRemove;
  final Function(LongPressStartDetails) onLongPressStart;
  final Function(LongPressMoveUpdateDetails) onLongPressMoveUpdate;
  final Function(LongPressEndDetails) onLongPressEnd;

  const TimeSlotWidget({
    super.key,
    required this.slot,
    required this.dayKey,
    required this.height,
    required this.onRemove,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
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
                onTap: onRemove,
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
}

/// Widget for the moving slot overlay
class MovingSlotWidget extends StatelessWidget {
  final structs.TimeSlot slot;
  final double height;

  const MovingSlotWidget({
    super.key,
    required this.slot,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
}

/// Widget for the drag indicator when creating new slots
class DragIndicator extends StatelessWidget {
  final double top;
  final double height;

  const DragIndicator({
    super.key,
    required this.top,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      child: Container(
        height: height,
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
    );
  }
}
