import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo numérico del formulario de despacho. El valor vive en el bloc: este
/// campo solo muestra [valueText] y avisa lo que se escribe.
///
/// Mientras la persona escribe (el campo tiene el foco) su texto manda; si el
/// valor cambia por fuera (descartar, recargar tras un conflicto) y el campo no
/// tiene el foco, se actualiza.
class DispatchNumberField extends StatefulWidget {
  const DispatchNumberField({
    super.key,
    required this.label,
    required this.valueText,
    required this.onChanged,
    required this.enabled,
    this.errorText,
    this.allowDecimal = false,
  });

  final String label;
  final String valueText;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? errorText;
  final bool allowDecimal;

  @override
  State<DispatchNumberField> createState() => _DispatchNumberFieldState();
}

class _DispatchNumberFieldState extends State<DispatchNumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.valueText,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant DispatchNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && _controller.text != widget.valueText) {
      _controller.text = widget.valueText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.allowDecimal,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(widget.allowDecimal ? r'[0-9.,]' : r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        errorMaxLines: 3,
        isDense: true,
      ),
    );
  }
}
