import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class RecoverPasswordDialog extends StatefulWidget {
  final Future<void> Function(String email) onRecoverPassword;

  const RecoverPasswordDialog({
    super.key,
    required this.onRecoverPassword,
  });

  @override
  State<RecoverPasswordDialog> createState() => _RecoverPasswordDialogState();
}

class _RecoverPasswordDialogState extends State<RecoverPasswordDialog> {
  late final TextEditingController emailController;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
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
            Text(t.enterYourEmailToRecoverYourPassword),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: t.email,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleRecoverPassword,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.recoverPassword),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRecoverPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onRecoverPassword(email);

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
