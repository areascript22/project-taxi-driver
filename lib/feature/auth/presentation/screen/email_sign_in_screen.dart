import 'package:driver_app/l10n/app_localizations.dart';
import 'package:driver_app/shared/presentation/component/app_toast.dart';
import 'package:driver_app/shared/presentation/failure_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/email_verification_dialog.dart';

class EmailSignInScreen extends StatelessWidget {
  const EmailSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => mainServiceLocator<AuthBloc>(),
      child: const EmailSignInView(),
    );
  }
}

class EmailSignInView extends StatefulWidget {
  const EmailSignInView({super.key});

  @override
  State<EmailSignInView> createState() => _EmailSignInViewState();
}

class _EmailSignInViewState extends State<EmailSignInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthSignInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
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
        if (state is AuthEmailNotVerified) {
          EmailVerificationDialog.show(context, email: state.email);
        }
        if (state is AuthAuthenticated) {
          context.goNamed(sessionRoute.name);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AuthPageScaffold(
          title: l10n.emailSignInTitle,
          subtitle: l10n.emailSignInSubtitle,
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed:
                    isLoading
                        ? null
                        : () => context.pushNamed(
                          passwordResetRoute.name,
                          extra: _emailController.text.trim(),
                        ),
                child: Text(l10n.signInForgotPassword),
              ),
            ),
            const SizedBox(height: 8),
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
                        l10n.signInEmailButton,
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
                  l10n.signInNoAccount,
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                ),
                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () => context.pushNamed(
                            signUpRoute.name,
                            extra: _emailController.text.trim(),
                          ),
                  child: Text(l10n.signInCreateOne),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
