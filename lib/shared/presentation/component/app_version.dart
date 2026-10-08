import 'package:app_version_details/app_version_details.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// El estado guarda qué pasó al consultar la versión, no el texto a mostrar.
// Antes `_appVersion` arrancaba en 'Cargando...' y se sobreescribía con
// 'Versión no disponible' / 'Error al obtener la versión', o sea que el copy de
// UI vivía dentro del estado y no había forma de localizarlo: el texto ya
// estaba resuelto antes de tener un BuildContext.
enum _VersionStatus { loading, loaded, unavailable, error }

class AppVersionWidget extends StatefulWidget {
  final TextStyle? textStyle;

  const AppVersionWidget({super.key, this.textStyle});

  @override
  State<AppVersionWidget> createState() => _AppVersionWidgetState();
}

class _AppVersionWidgetState extends State<AppVersionWidget> {
  _VersionStatus _status = _VersionStatus.loading;
  String? _version;
  final _appVersionDetailsPlugin = AppVersionDetails();

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    _VersionStatus status;
    String? version;
    try {
      version = await _appVersionDetailsPlugin.getVersion();
      status =
          version == null ? _VersionStatus.unavailable : _VersionStatus.loaded;
    } on PlatformException {
      status = _VersionStatus.error;
    }

    if (!mounted) return;

    setState(() {
      _status = status;
      _version = version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final text = switch (_status) {
      _VersionStatus.loading => l10n.appVersionLoading,
      _VersionStatus.loaded => l10n.appVersionLabel(_version!),
      _VersionStatus.unavailable => l10n.appVersionUnavailable,
      _VersionStatus.error => l10n.appVersionError,
    };

    return Text(
      text,
      style:
          widget.textStyle ??
          TextStyle(color: Theme.of(context).colorScheme.onSurface),
    );
  }
}
