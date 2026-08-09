import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool enabled;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final Widget? prefix;

  const OnboardingTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.enabled = true,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
            prefixIcon: prefix,
            filled: true,
            fillColor:
                enabled
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE94560), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
