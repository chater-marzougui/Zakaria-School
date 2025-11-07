import 'package:flutter/material.dart';
import '../helpers/validators.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;

class EditCandidateDialog extends StatefulWidget {
  final structs.Candidate candidate;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const EditCandidateDialog({super.key,
    required this.candidate,
    required this.onSave,
  });

  @override
  State<EditCandidateDialog> createState() => _EditCandidateDialogState();
}

class _EditCandidateDialogState extends State<EditCandidateDialog> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController cinController;
  late final TextEditingController instructorController;

  late bool theoryPassed;
  late String selectedStatus;

  final formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers in initState
    nameController = TextEditingController(text: widget.candidate.name);
    phoneController = TextEditingController(text: widget.candidate.phone);
    cinController = TextEditingController(text: widget.candidate.cin);
    instructorController = TextEditingController(text: widget.candidate.assignedInstructorId);

    theoryPassed = widget.candidate.theoryPassed;
    selectedStatus = widget.candidate.status;
  }

  @override
  void dispose() {
    // Dispose controllers when the dialog widget is disposed
    nameController.dispose();
    phoneController.dispose();
    cinController.dispose();
    instructorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(t.editCandidate),
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
                  labelText: t.cin,
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: t.cinExample,
                ),
                keyboardType: TextInputType.number,
                maxLength: 8,
                validator: (value) => Validators.validateCIN(
                  value,
                  errorMessage: t.cinInvalid,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: instructorController,
                decoration: InputDecoration(
                  labelText: t.assignedInstructor,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('statusDropdown'),
                initialValue: selectedStatus,
                decoration: InputDecoration(
                  labelText: t.status,
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 'active', child: Text(t.active)),
                  DropdownMenuItem(value: 'inactive', child: Text(t.inactive)),
                  DropdownMenuItem(value: 'graduated', child: Text(t.graduated)),
                ],
                onChanged: _isSaving ? null : (value) {
                  if (value != null) {
                    setState(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(t.theoryPassed),
                value: theoryPassed,
                onChanged: _isSaving ? null : (value) {
                  setState(() {
                    theoryPassed = value;
                  });
                },
                secondary: const Icon(Icons.school),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancelEditCandidateButton'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          key: const Key('saveCandidateButton'),
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
      await widget.onSave({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'cin': cinController.text.trim(),
        'assigned_instructor_id': instructorController.text.trim(),
        'status': selectedStatus,
        'theory_passed': theoryPassed,
      });

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