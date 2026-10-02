import 'package:flutter/material.dart';

// Diálogo genérico para pedirle al admin un motivo obligatorio -- usado
// tanto para rechazar como para bloquear a un conductor (ver
// driver_detail_screen.dart). El motivo que se escriba acá se le muestra
// directamente al conductor en la app, así que el campo pide redactarlo
// pensando en eso.
class ReasonInputDialog extends StatefulWidget {
  final String title;
  final String description;
  final String confirmLabel;

  const ReasonInputDialog({
    super.key,
    required this.title,
    required this.description,
    required this.confirmLabel,
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String description,
    required String confirmLabel,
  }) {
    return showDialog<String>(
      context: context,
      builder:
          (_) => ReasonInputDialog(
            title: title,
            description: description,
            confirmLabel: confirmLabel,
          ),
    );
  }

  @override
  State<ReasonInputDialog> createState() => _ReasonInputDialogState();
}

class _ReasonInputDialogState extends State<ReasonInputDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'Este campo es obligatorio');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Escribe el motivo...',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.confirmLabel,
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
