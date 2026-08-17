import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_version_details/app_version_details.dart';

class AppVersionWidget extends StatefulWidget {
  final TextStyle? textStyle;

  const AppVersionWidget({super.key, this.textStyle});

  @override
  State<AppVersionWidget> createState() => _AppVersionWidgetState();
}

class _AppVersionWidgetState extends State<AppVersionWidget> {
  String _appVersion = 'Cargando...';
  final _appVersionDetailsPlugin = AppVersionDetails();

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    String version;
    try {
      version =
          await _appVersionDetailsPlugin.getVersion() ??
          'Versión no disponible';
    } on PlatformException {
      version = 'Error al obtener la versión';
    }

    if (!mounted) return;

    setState(() {
      _appVersion = version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Versión: $_appVersion',
      style:
          widget.textStyle ??
          TextStyle(color: Theme.of(context).colorScheme.onSurface),
    );
  }
}
