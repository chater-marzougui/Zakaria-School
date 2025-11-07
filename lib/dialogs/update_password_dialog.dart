import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class UpdatePasswordDialog extends StatefulWidget {
  final Future<void> Function(String oldPassword, String newPassword)
      onUpdatePassword;
  final VoidCallback onForgotPassword;

  const UpdatePasswordDialog({
    super.key,
    required this.onUpdatePassword,
    required this.onForgotPassword,
  });

  @override
  State<UpdatePasswordDialog> createState() => _UpdatePasswordDialogState();
}

class _UpdatePasswordDialogState extends State<UpdatePasswordDialog> {
  late final TextEditingController passwordController;
  late final TextEditingController newPasswordController;
  late final TextEditingController confirmPasswordController;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
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
            Text(
              t.typeYourOldPasswordAndTheNewOneToApplyChanges,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t.oldPassword,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t.newPassword,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t.confirmPassword,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_clock),
              ),
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleUpdatePassword,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.applyChanges),
            ),
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onForgotPassword();
                    },
              child: Text(t.forgotPassword),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdatePassword() async {
    final t = AppLocalizations.of(context)!;
    final oldPassword = passwordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validate the passwords
    if (newPassword != confirmPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.passwordsDoNotMatch)),
        );
      }
      return;
    }

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onUpdatePassword(oldPassword, newPassword);

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
