import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Confirma aplicar la configuración del despacho: avisa que vale para las
/// solicitudes nuevas y no toca las búsquedas en curso.
class SaveDispatchConfigDialog extends StatelessWidget {
  const SaveDispatchConfigDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const SaveDispatchConfigDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.dispatchSaveConfirmTitle),
      content: Text(l10n.dispatchSaveConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.dispatchSaveConfirmAction),
        ),
      ],
    );
  }
}

/// Confirma encender o apagar "los administradores pueden editar" (solo lo ve
/// el superuser). Cambia quién puede tocar la operación, así que no es de un
/// solo toque.
class AdminEditingDialog extends StatelessWidget {
  const AdminEditingDialog({super.key, required this.enabling});

  /// true = se va a encender; false = se va a apagar.
  final bool enabling;

  static Future<bool?> show(BuildContext context, {required bool enabling}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AdminEditingDialog(enabling: enabling),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        enabling ? l10n.dispatchAdminEditingOnTitle : l10n.dispatchAdminEditingOffTitle,
      ),
      content: Text(
        enabling ? l10n.dispatchAdminEditingOnBody : l10n.dispatchAdminEditingOffBody,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.dispatchSaveConfirmAction),
        ),
      ],
    );
  }
}
