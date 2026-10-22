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
import '../widgets/email_verification_dialog.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key, this.initialEmail = ''});

  /// Correo que la persona ya habia escrito en el login, para no retipearlo.
  final String initialEmail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => mainServiceLocator<AuthBloc>(),
      child: SignUpView(initialEmail: initialEmail),
    );
  }
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.initialEmail);
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthSignUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _onSignUpCompleted({required String email}) async {
    await EmailVerificationDialog.show(context, email: email);
    // De vuelta al login con correo (la pantalla desde la que se llego aqui).
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          AppToast.error(context, message: context.failureText(state.code));
        }
        if (state is AuthSignUpCompleted) {
          _onSignUpCompleted(email: state.email);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AuthPageScaffold(
          title: l10n.signUpTitle,
          subtitle: l10n.signUpSubtitle,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AuthEmailField(
                    controller: _emailController,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  AuthPasswordField(
                    controller: _passwordController,
                    enabled: !isLoading,
                    validateStrength: true,
                    autofillHint: AutofillHints.newPassword,
                  ),
                  const SizedBox(height: 16),
                  AuthPasswordField(
                    controller: _confirmController,
                    enabled: !isLoading,
                    label: l10n.signUpConfirmPasswordLabel,
                    autofillHint: AutofillHints.newPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    extraValidator:
                        (value) =>
                            value == _passwordController.text
                                ? null
                                : l10n.signUpPasswordMismatch,
                  ),
                ],
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
                        l10n.signUpButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.signUpHaveAccount,
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                ),
                TextButton(
                  onPressed: isLoading ? null : () => context.pop(),
                  child: Text(l10n.signUpGoToSignIn),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
