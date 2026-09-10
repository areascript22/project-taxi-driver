import 'package:flutter/material.dart';

// Se muestra en el body de IncomingRequestScreen en vez de OfflineNotice
// cuando el conductor rechazó el diálogo nativo de "ignorar optimización de
// batería" -- sin ese permiso no dejamos encender el toggle (ver
// ForegroundServiceBloc), así que hay que darle una salida clara para
// reintentarlo o ir directo a Ajustes.
class BatteryOptimizationDeniedBanner extends StatelessWidget {
  final VoidCallback onRetryTapped;
  final VoidCallback onOpenSettingsTapped;

  const BatteryOptimizationDeniedBanner({
    super.key,
    required this.onRetryTapped,
    required this.onOpenSettingsTapped,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.battery_alert_rounded,
                color: colorScheme.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No puedes recibir carreras todavía',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Necesitas excluir a TaxiGo Conductor de la optimización de '
              'batería para que tu ubicación no se pierda durante un viaje.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetryTapped,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onOpenSettingsTapped,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Abrir ajustes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
