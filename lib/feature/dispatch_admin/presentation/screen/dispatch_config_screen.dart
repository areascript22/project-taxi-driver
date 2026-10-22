import 'package:driver_app/shared/presentation/component/app_toast.dart';
import 'package:driver_app/shared/presentation/failure_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dispatch_config_rules.dart';
import '../../domain/entity/dispatch_config_entity.dart';
import '../bloc/dispatch_config_bloc.dart';
import '../component/dispatch_confirm_dialogs.dart';
import '../component/dispatch_number_field.dart';
import '../component/dispatch_ring_card.dart';

/// Configuración del despacho: cómo se busca un conductor para una carrera
/// (anillos de búsqueda y frescura de la ubicación).
///
/// Cualquier administrador la ve. Quién puede cambiarla lo dice el servidor
/// (`canEdit`): el superuser siempre; un administrador solo si el superuser
/// encendió "los administradores pueden editar". El interruptor solo lo ve y lo
/// mueve el superuser.
class DispatchConfigScreen extends StatelessWidget {
  const DispatchConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              mainServiceLocator<DispatchConfigBloc>()
                ..add(DispatchConfigLoadRequested()),
      child: const DispatchConfigView(),
    );
  }
}

class DispatchConfigView extends StatelessWidget {
  const DispatchConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dispatchTitle),
        actions: [
          IconButton(
            tooltip: l10n.dispatchHistoryOpenTooltip,
            icon: const Icon(Icons.history),
            onPressed: () => context.pushNamed(dispatchHistoryRoute.name),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.appColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: MultiBlocListener(
            listeners: [
              BlocListener<DispatchConfigBloc, DispatchConfigState>(
                listenWhen:
                    (previous, current) =>
                        current.errorCode != null &&
                        current.errorSerial != previous.errorSerial,
                listener:
                    (context, state) => AppToast.error(
                      context,
                      message: context.failureText(state.errorCode!),
                    ),
              ),
              BlocListener<DispatchConfigBloc, DispatchConfigState>(
                listenWhen:
                    (previous, current) =>
                        current.notice != null &&
                        current.noticeSerial != previous.noticeSerial,
                listener: (context, state) {
                  final message = switch (state.notice!) {
                    DispatchConfigNotice.saved => l10n.dispatchSavedToast,
                    DispatchConfigNotice.adminEditingEnabled =>
                      l10n.dispatchAdminEditingEnabledToast,
                    DispatchConfigNotice.adminEditingDisabled =>
                      l10n.dispatchAdminEditingDisabledToast,
                  };
                  AppToast.success(context, message: message);
                },
              ),
            ],
            child: BlocBuilder<DispatchConfigBloc, DispatchConfigState>(
              builder: (context, state) {
                final config = state.config;
                if (config == null) {
                  return _LoadingOrRetry(isLoading: state.isLoading);
                }
                return Column(
                  children: [
                    Expanded(child: _Content(state: state, config: config)),
                    if (config.canEdit) _BottomBar(state: state),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingOrRetry extends StatelessWidget {
  const _LoadingOrRetry({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: TextButton.icon(
        onPressed:
            () => context.read<DispatchConfigBloc>().add(
              DispatchConfigLoadRequested(),
            ),
        icon: const Icon(Icons.refresh),
        label: Text(AppLocalizations.of(context).commonRetry),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.config});

  final DispatchConfigState state;
  final DispatchConfigEntity config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<DispatchConfigBloc>();
    final validation = state.validation!;
    final canEdit = config.canEdit;
    final colorScheme = Theme.of(context).colorScheme;

    String draftIssueText(DispatchDraftIssue issue) {
      return switch (issue) {
        DispatchDraftIssue.noRings => l10n.dispatchIssueNoRings,
        DispatchDraftIssue.tooManyRings => l10n.dispatchIssueTooManyRings(
          config.limits.maxRings,
        ),
        DispatchDraftIssue.totalWaitTooLong => l10n.dispatchIssueTotalWait(
          config.limits.maxTotalWaitSeconds,
        ),
        DispatchDraftIssue.locationAgeOutOfRange =>
          l10n.dispatchIssueLocationAge(
            config.limits.minLocationMaxAgeSeconds,
            config.limits.maxLocationMaxAgeSeconds,
          ),
      };
    }

    final ringsIssues = [
      DispatchDraftIssue.noRings,
      DispatchDraftIssue.tooManyRings,
      DispatchDraftIssue.totalWaitTooLong,
    ].where(validation.draftIssues.contains).map(draftIssueText).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (!canEdit) ...[
          _Banner(text: l10n.dispatchReadOnlyBanner),
          const SizedBox(height: 16),
        ],
        _SummaryCard(state: state, config: config),
        if (config.canChangeAdminEditing) ...[
          const SizedBox(height: 16),
          _AdminEditingCard(state: state, config: config),
        ],
        const SizedBox(height: 24),
        Text(
          l10n.dispatchRingsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.dispatchRingsHint,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < state.draftRings.length; i++) ...[
          DispatchRingCard(
            number: i + 1,
            ring: state.draftRings[i],
            issues: validation.ringIssues[i] ?? const {},
            limits: config.limits,
            canEdit: canEdit && !state.isSaving,
            canRemove: state.draftRings.length > 1,
            onChanged:
                (ring) =>
                    bloc.add(DispatchRingChanged(index: i, ring: ring)),
            onRemove: () => bloc.add(DispatchRingRemoved(index: i)),
          ),
          const SizedBox(height: 12),
        ],
        for (final text in ringsIssues)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              text,
              style: TextStyle(color: colorScheme.error, fontSize: 13),
            ),
          ),
        if (canEdit &&
            state.draftRings.length < config.limits.maxRings)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed:
                  state.isSaving ? null : () => bloc.add(DispatchRingAdded()),
              icon: const Icon(Icons.add),
              label: Text(l10n.dispatchAddRing),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          l10n.dispatchLocationTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.dispatchLocationHint,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        DispatchNumberField(
          label: l10n.dispatchLocationMaxAgeLabel,
          valueText: '${state.draftLocationMaxAgeSeconds}',
          enabled: canEdit && !state.isSaving,
          errorText:
              validation.draftIssues.contains(
                    DispatchDraftIssue.locationAgeOutOfRange,
                  )
                  ? draftIssueText(DispatchDraftIssue.locationAgeOutOfRange)
                  : null,
          onChanged:
              (text) => bloc.add(
                DispatchLocationMaxAgeChanged(
                  seconds: int.tryParse(text.trim()) ?? 0,
                ),
              ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.appColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 20, color: context.appColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state, required this.config});

  final DispatchConfigState state;
  final DispatchConfigEntity config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    final String lastEdit;
    if (config.updatedAt == null) {
      lastEdit = l10n.dispatchSummaryNeverEdited;
    } else {
      final date = DateFormat.yMMMd(locale).add_Hm().format(config.updatedAt!);
      final name =
          config.updatedByName.isEmpty
              ? l10n.dispatchHistoryUnknownAuthor
              : config.updatedByName;
      lastEdit = l10n.dispatchSummaryLastEdit(name, date);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dispatchSummaryTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          // Lo que se ve en el resumen sigue al borrador: al mover un número
          // se ve al instante cuánto dura la búsqueda.
          Text(l10n.dispatchSummaryRings(state.draftRings.length)),
          Text(l10n.dispatchSummarySearch(state.draftTotalWaitSeconds)),
          if (!state.isDirty)
            Text(l10n.dispatchSummaryExpiry(config.requestExpirySeconds)),
          const SizedBox(height: 8),
          Text(
            lastEdit,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminEditingCard extends StatelessWidget {
  const _AdminEditingCard({required this.state, required this.config});

  final DispatchConfigState state;
  final DispatchConfigEntity config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: SwitchListTile(
        value: config.adminsCanEdit,
        onChanged:
            state.isTogglingAdminEditing
                ? null
                : (enabled) async {
                  final bloc = context.read<DispatchConfigBloc>();
                  final confirmed = await AdminEditingDialog.show(
                    context,
                    enabling: enabled,
                  );
                  if (confirmed == true) {
                    bloc.add(DispatchAdminEditingToggled(enabled: enabled));
                  }
                },
        title: Text(l10n.dispatchAdminEditingTitle),
        subtitle: Text(l10n.dispatchAdminEditingSubtitle),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state});

  final DispatchConfigState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final bloc = context.read<DispatchConfigBloc>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed:
                  state.isDirty && !state.isSaving
                      ? () {
                        FocusScope.of(context).unfocus();
                        bloc.add(DispatchDraftDiscarded());
                      }
                      : null,
              child: Text(l10n.dispatchDiscard),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  state.canSave
                      ? () async {
                        FocusScope.of(context).unfocus();
                        final confirmed = await SaveDispatchConfigDialog.show(
                          context,
                        );
                        if (confirmed == true) {
                          bloc.add(DispatchSaveRequested());
                        }
                      }
                      : null,
              child:
                  state.isSaving
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(l10n.dispatchSave),
            ),
          ),
        ],
      ),
    );
  }
}
