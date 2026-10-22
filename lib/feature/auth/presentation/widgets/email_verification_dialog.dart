import 'package:driver_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Pide revisar el correo para confirmarlo. Se usa tras registrarse y cuando
/// alguien intenta entrar sin haber verificado todavia.
class EmailVerificationDialog extends StatelessWidget {
  const EmailVerificationDialog({super.key, required this.email});

  final String email;

  static Future<void> show(BuildContext context, {required String email}) {
    return showDialog<void>(
      context: context,
      builder: (_) => EmailVerificationDialog(email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      icon: const Icon(Icons.mark_email_unread_outlined, size: 40),
      title: Text(l10n.emailVerificationTitle),
      content: Text(l10n.emailVerificationBody(email)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.emailVerificationAccept),
        ),
      ],
    );
  }
}
