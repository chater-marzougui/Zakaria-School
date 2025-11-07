import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import '../widgets/widgets.dart';

class PaymentConfirmationDialog extends StatefulWidget {
  final structs.Session session;
  final bool markAsPaid;

  const PaymentConfirmationDialog({
    super.key,
    required this.session,
    required this.markAsPaid,
  });

  @override
  State<PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState
    extends State<PaymentConfirmationDialog> {
  late final TextEditingController amountController;
  late final TextEditingController noteController;
  late DateTime selectedDate;

  final formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers in initState
    amountController = TextEditingController(
      text: widget.session.paymentAmount > 0
          ? widget.session.paymentAmount.toString()
          : '',
    );
    noteController = TextEditingController(text: widget.session.paymentNote);
    selectedDate = widget.session.paymentDate ?? DateTime.now();
  }

  @override
  void dispose() {
    // Dispose controllers when the dialog widget is disposed
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.markAsPaid ? Icons.check_circle : Icons.cancel,
            color: widget.markAsPaid ? Colors.green : theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.markAsPaid ? t.markAsPaid : t.markAsUnpaid,
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.confirmPaymentStatusChange),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(widget.session.date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.session.durationInHours.toStringAsFixed(1)} ${t.hours}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.markAsPaid) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Payment Amount
              TextField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: t.paymentAmount,
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'TND',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Payment Date
              InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: t.paymentDate,
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Payment Note
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: t.noteOptional,
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: t.examplePaymentNote,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.markAsPaid
                ? Colors.green
                : theme.colorScheme.error,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(t.confirm),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final t = AppLocalizations.of(context)!;
      final updateData = <String, dynamic>{
        'payment_status': widget.markAsPaid ? 'paid' : 'unpaid',
      };

      if (widget.markAsPaid) {
        // Parse amount
        final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
        updateData['payment_amount'] = amount;
        updateData['payment_date'] = Timestamp.fromDate(selectedDate);
        updateData['payment_note'] = noteController.text.trim();
      } else {
        // Clear payment data when marking as unpaid
        updateData['payment_amount'] = 0.0;
        updateData['payment_date'] = null;
        updateData['payment_note'] = '';
      }

      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.session.id)
          .update(updateData);

      if (!mounted) return;

      Navigator.pop(context);

      showCustomSnackBar(
        context,
        widget.markAsPaid ? t.paymentMarkedAsPaid : t.paymentMarkedAsUnpaid,
        type: SnackBarType.success,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        final t = AppLocalizations.of(context)!;
        showCustomSnackBar(
          context,
          '${t.error}: $e',
          type: SnackBarType.error,
        );
      }
    }
  }
}
