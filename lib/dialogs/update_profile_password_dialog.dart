import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class UpdateProfilePasswordDialog extends StatefulWidget {
  final Future<void> Function(String password) onConfirm;

  const UpdateProfilePasswordDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<UpdateProfilePasswordDialog> createState() =>
      _UpdateProfilePasswordDialogState();
}

class _UpdateProfilePasswordDialogState
    extends State<UpdateProfilePasswordDialog> {
  late final TextEditingController passwordController;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(t.typeYourPasswordToApplyChanges),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleConfirm,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.applyChanges),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    final password = passwordController.text.trim();

    if (password.isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onConfirm(password);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      rethrow;
    }
  }
}
