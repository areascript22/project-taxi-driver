import 'package:driver_app/shared/presentation/component/app_version.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => mainServiceLocator<AuthBloc>(),
      child: const SignInView(),
    );
  }
}

class SignInView extends StatelessWidget {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.appColors.backgroundGradient,
              ),
            ),
          ),
          SafeArea(
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }

                if (state is AuthAuthenticated) {
                  context.goNamed(sessionRoute.name);
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: onSurface.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_taxi_rounded,
                          size: 72,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'TaxiGo',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conductor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: onSurface.withValues(alpha: 0.6),
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Inicia sesión para comenzar a conducir',
                        style: TextStyle(
                          fontSize: 14,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : () {
                                    context.read<AuthBloc>().add(
                                      AuthSignInWithGoogle(),
                                    );
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              isLoading
                                  ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Continuar con Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      AppVersionWidget(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
