import 'package:driver_app/l10n/app_localizations.dart';
import 'package:driver_app/shared/presentation/component/app_toast.dart';
import 'package:driver_app/shared/presentation/failure_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_page_scaffold.dart';

class PasswordResetScreen extends StatelessWidget {
  const PasswordResetScreen({super.key, this.initialEmail = ''});

  /// Correo que la persona ya habia escrito en el login, para no retipearlo.
  final String initialEmail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => mainServiceLocator<AuthBloc>(),
      child: PasswordResetView(initialEmail: initialEmail),
    );
  }
}

class PasswordResetView extends StatefulWidget {
  const PasswordResetView({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthPasswordResetRequested(email: _emailController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          AppToast.error(context, message: context.failureText(state.code));
        }
        if (state is AuthPasswordResetSent) {
          // Toast primero y pop despues: el toast vive en el overlay raiz y
          // sobrevive al cambio de pantalla (CLAUDE.md 2.1).
          AppToast.success(context, message: l10n.resetPasswordSent(state.email));
          context.pop();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AuthPageScaffold(
          title: l10n.resetPasswordTitle,
          subtitle: l10n.resetPasswordSubtitle,
          children: [
            Form(
              key: _formKey,
              child: AuthEmailField(
                controller: _emailController,
                enabled: !isLoading,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        l10n.resetPasswordButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ],
        );
      },
    );
  }
}
