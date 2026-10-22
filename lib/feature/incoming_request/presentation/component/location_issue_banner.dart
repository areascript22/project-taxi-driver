import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import 'package:driver_app/shared/presentation/failure_text.dart';
import 'package:flutter/material.dart';

// Aviso persistente en la pantalla de peticiones cuando NO hay ubicación
// utilizable: al intentar conectarse, o mientras el conductor está en línea y el
// servicio deja de conseguirla.
//
// Estar "en línea" sin ubicación significa no recibir pedidos (el servidor
// descarta posiciones de más de 45 s), y sin este aviso nada se lo decía al
// conductor. Dice POR QUÉ (GPS o ajustes apagados, permiso, sin señal) y ofrece
// ir a arreglarlo. Desaparece solo cuando la ubicación vuelve.
class LocationIssueBanner extends StatelessWidget {
  const LocationIssueBanner({
    super.key,
    required this.issue,
    required this.onOpenSettingsTapped,
  });

  final FailureCode issue;
  final VoidCallback onOpenSettingsTapped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_off, color: colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.locationIssueTitle,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.failureText(issue),
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenSettingsTapped,
              child: Text(l10n.locationIssueOpenSettings),
            ),
          ),
        ],
      ),
    );
  }
}
