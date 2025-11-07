import 'package:flutter/material.dart';
import '../helpers/validators.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;

class AddCandidateDialog extends StatefulWidget {
  final Future<void> Function(structs.Candidate) onSave;

  const AddCandidateDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<AddCandidateDialog> createState() => _AddCandidateDialogState();
}

class _AddCandidateDialogState extends State<AddCandidateDialog> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController cinController;

  final formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers in initState
    nameController = TextEditingController();
    phoneController = TextEditingController();
    cinController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers when the dialog widget is disposed
    nameController.dispose();
    phoneController.dispose();
    cinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(t.addCandidate),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t.candidateName,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t.nameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: t.candidatePhone,
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => Validators.validatePhone(
                  value,
                  errorMessage: value == null || value.trim().isEmpty
                      ? t.pleaseEnterLabel(t.phoneNumber)
                      : t.phoneNumberInvalid,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: cinController,
                decoration: InputDecoration(
                  labelText: t.candidateCin,
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: '${t.cinExample} (${t.optional})',
                ),
                keyboardType: TextInputType.number,
                maxLength: 8,
                validator: (value) => Validators.validateCIN(
                  value,
                  errorMessage: t.cinInvalid,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.save),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final candidate = structs.Candidate(
        id: '',
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        cin: cinController.text.trim(),
        startDate: DateTime.now(),
      );

      await widget.onSave(candidate);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
      rethrow;
    }
  }
}
