import 'package:driver_app/shared/presentation/failure_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dispatch_formatters.dart';
import '../../domain/entity/dispatch_change_entity.dart';
import '../bloc/dispatch_history_cubit.dart';

/// Quién cambió la configuración del despacho, cuándo, y cómo estaba antes y
/// después. Lo ve cualquier administrador.
class DispatchHistoryScreen extends StatelessWidget {
  const DispatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => mainServiceLocator<DispatchHistoryCubit>()..load(),
      child: const DispatchHistoryView(),
    );
  }
}

class DispatchHistoryView extends StatelessWidget {
  const DispatchHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dispatchHistoryTitle)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.appColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<DispatchHistoryCubit, DispatchHistoryState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.errorCode != null && state.changes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.failureText(state.errorCode!)),
                      TextButton.icon(
                        onPressed: () => context.read<DispatchHistoryCubit>().load(),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                );
              }
              if (state.loaded && state.changes.isEmpty) {
                return Center(child: Text(l10n.dispatchHistoryEmpty));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  for (final change in state.changes) ...[
                    _ChangeTile(change: change),
                    const SizedBox(height: 10),
                  ],
                  if (state.errorCode != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        context.failureText(state.errorCode!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (state.hasMore)
                    Center(
                      child:
                          state.isLoadingMore
                              ? const CircularProgressIndicator()
                              : TextButton(
                                onPressed:
                                    () =>
                                        context
                                            .read<DispatchHistoryCubit>()
                                            .loadMore(),
                                child: Text(l10n.dispatchHistoryLoadMore),
                              ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChangeTile extends StatelessWidget {
  const _ChangeTile({required this.change});

  final DispatchChangeEntity change;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    final title = switch (change.type) {
      DispatchChangeType.config => l10n.dispatchHistoryConfigChange,
      DispatchChangeType.adminsCanEdit =>
        change.after.adminsCanEdit
            ? l10n.dispatchHistoryAdminEditingOn
            : l10n.dispatchHistoryAdminEditingOff,
    };
    final author =
        change.changedByName.isEmpty
            ? l10n.dispatchHistoryUnknownAuthor
            : change.changedByName;
    final date =
        change.changedAt == null
            ? ''
            : DateFormat.yMMMd(locale).add_Hm().format(change.changedAt!);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Theme(
        // Sin las líneas divisorias que ExpansionTile dibuja por defecto.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('$author · $date'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SnapshotBlock(
              label: l10n.dispatchHistoryBefore,
              snapshot: change.before,
              type: change.type,
            ),
            const SizedBox(height: 12),
            _SnapshotBlock(
              label: l10n.dispatchHistoryAfter,
              snapshot: change.after,
              type: change.type,
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotBlock extends StatelessWidget {
  const _SnapshotBlock({
    required this.label,
    required this.snapshot,
    required this.type,
  });

  final String label;
  final DispatchSnapshotEntity snapshot;
  final DispatchChangeType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        if (type == DispatchChangeType.adminsCanEdit)
          Text(
            l10n.dispatchHistoryAdminEditingLine(
              snapshot.adminsCanEdit ? l10n.commonYes : l10n.commonNo,
            ),
          )
        else ...[
          for (var i = 0; i < snapshot.rings.length; i++)
            Text(
              l10n.dispatchHistoryRingLine(
                i + 1,
                formatKm(meters: snapshot.rings[i].radiusMeters),
                snapshot.rings[i].waitSeconds,
                snapshot.rings[i].maxDrivers,
              ),
            ),
          Text(
            l10n.dispatchHistoryFreshnessLine(snapshot.locationMaxAgeSeconds),
          ),
        ],
      ],
    );
  }
}
