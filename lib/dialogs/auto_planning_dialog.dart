
// Separate StatefulWidget for the auto planning dialog
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import '../widgets/widgets.dart';

class AutoPlanningDialog extends StatefulWidget {
  final structs.Candidate candidate;
  final ThemeData theme;
  final AppLocalizations t;
  final Future<void> Function(double) onPlan;

  const AutoPlanningDialog({super.key,
    required this.candidate,
    required this.theme,
    required this.t,
    required this.onPlan,
  });

  @override
  State<AutoPlanningDialog> createState() => _AutoPlanningDialogState();
}

class _AutoPlanningDialogState extends State<AutoPlanningDialog> {
  late final TextEditingController hoursController;
  bool _isPlanning = false;

  @override
  void initState() {
    super.initState();
    hoursController = TextEditingController();
  }

  @override
  void dispose() {
    hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome, color: widget.theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.t.autoSessionPlanning,
              style: widget.theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.t.howManyHoursToSchedule(widget.candidate.name),
            style: widget.theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: hoursController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.t.hoursToSchedule,
              prefixIcon: Icon(Icons.access_time),
              suffixText: widget.t.hours,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: widget.t.exampleHours,
            ),
            autofocus: true,
            enabled: !_isPlanning,
          ),
          const SizedBox(height: 8),
          Text(
            widget.t.systemWillFitSessions,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: widget.theme.textTheme.bodySmall?.color?.withAlpha(150),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isPlanning ? null : () => Navigator.pop(context),
          child: Text(widget.t.cancel),
        ),
        ElevatedButton(
          onPressed: _isPlanning ? null : _handlePlan,
          child: _isPlanning
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(widget.t.planSessions),
        ),
      ],
    );
  }

  Future<void> _handlePlan() async {
    final hoursText = hoursController.text.trim();
    final hours = double.tryParse(hoursText);

    if (hours == null || hours <= 0) {
      showCustomSnackBar(
        context,
        widget.t.pleaseEnterValidHours,
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isPlanning = true;
    });

    try {
      Navigator.pop(context);
      await widget.onPlan(hours);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlanning = false;
        });
      }
    }
  }
}