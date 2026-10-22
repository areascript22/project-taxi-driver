import 'package:driver_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../util/auth_input_rules.dart';

class AuthEmailField extends StatelessWidget {
  const AuthEmailField({
    super.key,
    required this.controller,
    required this.enabled,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.email],
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: l10n.signInEmailLabel,
        prefixIcon: const Icon(Icons.email_outlined),
      ),
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) return l10n.signInEmailRequired;
        if (!isEmailFormatValid(email: email)) return l10n.signInEmailInvalid;
        return null;
      },
    );
  }
}

/// Campo de contrasena con boton para mostrarla/ocultarla. Con
/// [validateStrength] exige el minimo de Firebase (registro); sin el, solo que
/// no este vacia (login).
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.enabled,
    this.label,
    this.validateStrength = false,
    this.textInputAction = TextInputAction.next,
    this.autofillHint = AutofillHints.password,
    this.onFieldSubmitted,
    this.extraValidator,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? label;
  final bool validateStrength;
  final TextInputAction textInputAction;
  final String autofillHint;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String value)? extraValidator;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      autofillHints: [widget.autofillHint],
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label ?? l10n.signInPasswordLabel,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscure ? l10n.signInShowPassword : l10n.signInHidePassword,
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (value) {
        final password = value ?? '';
        if (password.isEmpty) return l10n.signInPasswordRequired;
        if (widget.validateStrength && password.length < minPasswordLength) {
          return l10n.signUpPasswordTooShort;
        }
        return widget.extraValidator?.call(password);
      },
    );
  }
}
