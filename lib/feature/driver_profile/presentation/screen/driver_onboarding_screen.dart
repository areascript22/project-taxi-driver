import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../../../shared/feature/session/presentation/bloc/session/session_bloc.dart';
import '../bloc/driver_onboarding_bloc.dart';
import '../component/driver_personal_form.dart';
import '../component/image_source_sheet.dart';
import '../component/vehicle_info_form.dart';

class DriverOnboardingScreen extends StatelessWidget {
  final UserEntity user;

  const DriverOnboardingScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              mainServiceLocator<DriverOnboardingBloc>()
                ..add(DriverOnboardingStarted(user)),
      child: DriverOnboardingView(user: user),
    );
  }
}

class DriverOnboardingView extends StatefulWidget {
  final UserEntity user;

  const DriverOnboardingView({super.key, required this.user});

  @override
  State<DriverOnboardingView> createState() => _DriverOnboardingViewState();
}

class _DriverOnboardingViewState extends State<DriverOnboardingView> {
  final _pageController = PageController();
  final _personalFormKey = GlobalKey<FormState>();
  final _vehicleFormKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  final _phoneController = TextEditingController();

  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _registrationNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final nameParts = (widget.user.displayName ?? '').trim().split(' ');
    _firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts.first : '',
    );
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await ImageSourceSheet.show(context);
    if (source == null || !mounted) return;
    context.read<DriverOnboardingBloc>().add(DriverOnboardingImagePicked(source));
  }

  void _goToVehicleStep() {
    if (_personalFormKey.currentState?.validate() != true) return;
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPersonalStep() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _submit() {
    if (_vehicleFormKey.currentState?.validate() != true) return;

    context.read<DriverOnboardingBloc>().add(
      DriverOnboardingSubmitted(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: '+593${_phoneController.text.trim()}',
        plate: _plateController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        color: _colorController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_pageController.hasClients && (_pageController.page ?? 0) > 0) {
          _goToPersonalStep();
        }
      },
      child: Scaffold(
        body: BlocConsumer<DriverOnboardingBloc, DriverOnboardingState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
            if (state.registrationSuccess) {
              context.goNamed(sessionRoute.name);
            }
          },
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: context.appColors.backgroundGradient,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          DriverPersonalForm(
                            formKey: _personalFormKey,
                            firstNameController: _firstNameController,
                            lastNameController: _lastNameController,
                            emailController: _emailController,
                            phoneController: _phoneController,
                            localImage: state.profileImage,
                            networkImageUrl: widget.user.photoUrl,
                            isPickingImage: state.isPickingImage,
                            onPickImage: _pickImage,
                            onNext: _goToVehicleStep,
                          ),
                          VehicleInfoForm(
                            formKey: _vehicleFormKey,
                            plateController: _plateController,
                            brandController: _brandController,
                            modelController: _modelController,
                            yearController: _yearController,
                            colorController: _colorController,
                            registrationNumberController:
                                _registrationNumberController,
                            isSubmitting: state.isSubmitting,
                            onBack: _goToPersonalStep,
                            onSubmit: _submit,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<SessionBloc>().add(SessionLogoutRequested());
                        context.goNamed(signInRoute.name);
                      },
                      child: Text(
                        '¿No eres tú? Cerrar sesión',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
