import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dispatch_config_rules.dart';
import '../../domain/dispatch_formatters.dart';
import '../../domain/entity/dispatch_limits_entity.dart';
import '../../domain/entity/dispatch_ring_entity.dart';
import 'dispatch_number_field.dart';

/// Un anillo del borrador: radio, espera y máximo de conductores. Con
/// [canEdit] en falso los campos quedan de solo lectura.
class DispatchRingCard extends StatelessWidget {
  const DispatchRingCard({
    super.key,
    required this.number,
    required this.ring,
    required this.issues,
    required this.limits,
    required this.canEdit,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  /// Número del anillo (posición + 1).
  final int number;
  final DispatchRingEntity ring;
  final Set<DispatchRingIssue> issues;
  final DispatchLimitsEntity limits;
  final bool canEdit;
  final bool canRemove;
  final ValueChanged<DispatchRingEntity> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    String? radiusError;
    if (issues.contains(DispatchRingIssue.radiusOutOfRange)) {
      radiusError = l10n.dispatchIssueRadiusRange(
        formatKm(meters: limits.minRadiusMeters),
        formatKm(meters: limits.maxRadiusMeters),
      );
    } else if (issues.contains(DispatchRingIssue.radiusNotIncreasing)) {
      radiusError = l10n.dispatchIssueRadiusIncreasing;
    }
    final waitError =
        issues.contains(DispatchRingIssue.waitOutOfRange)
            ? l10n.dispatchIssueWaitRange(
              limits.minWaitSeconds,
              limits.maxWaitSeconds,
            )
            : null;
    final maxDriversError =
        issues.contains(DispatchRingIssue.maxDriversOutOfRange)
            ? l10n.dispatchIssueMaxDriversRange(
              limits.minMaxDrivers,
              limits.maxMaxDrivers,
            )
            : null;

    return Card(
      elevation: 0,
      color: colorScheme.onSurface.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              issues.isEmpty
                  ? colorScheme.onSurface.withValues(alpha: 0.08)
                  : colorScheme.error.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dispatchRingTitle(number),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (canEdit && canRemove)
                  IconButton(
                    tooltip: l10n.dispatchRingRemoveTooltip,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onRemove,
                  ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: DispatchNumberField(
                    label: l10n.dispatchRingRadiusLabel,
                    valueText: formatKm(meters: ring.radiusMeters),
                    allowDecimal: true,
                    enabled: canEdit,
                    errorText: radiusError,
                    onChanged:
                        (text) => onChanged(
                          ring.copyWith(
                            radiusMeters: parseKmToMeters(text: text) ?? 0,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DispatchNumberField(
                    label: l10n.dispatchRingWaitLabel,
                    valueText: '${ring.waitSeconds}',
                    enabled: canEdit,
                    errorText: waitError,
                    onChanged:
                        (text) => onChanged(
                          ring.copyWith(
                            waitSeconds: parseWholeNumber(text: text) ?? 0,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DispatchNumberField(
                    label: l10n.dispatchRingMaxDriversLabel,
                    valueText: '${ring.maxDrivers}',
                    enabled: canEdit,
                    errorText: maxDriversError,
                    onChanged:
                        (text) => onChanged(
                          ring.copyWith(
                            maxDrivers: parseWholeNumber(text: text) ?? 0,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
