import 'package:driver_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DeleteDriverConfirmDialog extends StatelessWidget {
  final String driverName;

  const DeleteDriverConfirmDialog({super.key, required this.driverName});

  static Future<bool?> show({
    required BuildContext context,
    required String driverName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteDriverConfirmDialog(driverName: driverName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.adminDeleteDriver,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: Text(
        l10n.adminDeleteDriverBody(driverName),
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.commonCancel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.adminDelete,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}
