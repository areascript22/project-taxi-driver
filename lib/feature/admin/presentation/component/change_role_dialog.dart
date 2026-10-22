import 'package:driver_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ChangeRoleDialog extends StatelessWidget {
  final List<String> availableRoles;
  final String Function(String role) roleLabel;

  const ChangeRoleDialog({
    super.key,
    required this.availableRoles,
    required this.roleLabel,
  });

  static Future<String?> show({
    required BuildContext context,
    required List<String> availableRoles,
    required String Function(String role) roleLabel,
  }) {
    return showDialog<String>(
      context: context,
      builder:
          (_) => ChangeRoleDialog(
            availableRoles: availableRoles,
            roleLabel: roleLabel,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.adminChangeRole,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            availableRoles
                .map(
                  (role) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      roleLabel(role),
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    onTap: () => Navigator.of(context).pop(role),
                  ),
                )
                .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.commonCancel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
