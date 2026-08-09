import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/presentation/component/custom_button.dart';
import 'onboarding_step_header.dart';
import 'onboarding_text_field.dart';
import 'profile_avatar_picker.dart';

// Número de celular ecuatoriano válido: 9 dígitos después del +593,
// siempre empezando en 9 (equivalente al 09XXXXXXXX nacional).
final RegExp ecuadorMobileRegex = RegExp(r'^9\d{8}$');

class DriverPersonalForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final File? localImage;
  final String? networkImageUrl;
  final bool isPickingImage;
  final VoidCallback onPickImage;
  final VoidCallback onNext;

  const DriverPersonalForm({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.emailController,
    required this.localImage,
    required this.networkImageUrl,
    required this.isPickingImage,
    required this.onPickImage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OnboardingStepHeader(
              step: 1,
              totalSteps: 2,
              title: 'Tus datos',
              subtitle: 'Cuéntanos quién eres para poder verificarte.',
            ),
            const SizedBox(height: 28),
            Center(
              child: ProfileAvatarPicker(
                localImage: localImage,
                networkImageUrl: networkImageUrl,
                isLoading: isPickingImage,
                onTap: onPickImage,
              ),
            ),
            const SizedBox(height: 32),
            OnboardingTextField(
              label: 'Nombres',
              controller: firstNameController,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tus nombres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            OnboardingTextField(
              label: 'Apellidos',
              controller: lastNameController,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tus apellidos';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            OnboardingTextField(
              label: 'Correo electrónico',
              controller: emailController,
              enabled: false,
            ),
            const SizedBox(height: 16),
            OnboardingTextField(
              label: 'Número de celular',
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              hintText: '9XXXXXXXX',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              prefix: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  '+593',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              validator: (value) {
                final digits = value?.trim() ?? '';
                if (digits.isEmpty) {
                  return 'Ingresa tu número de celular';
                }
                if (!ecuadorMobileRegex.hasMatch(digits)) {
                  return 'Número de celular ecuatoriano inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            CustomButton(
              textButton: 'Siguiente',
              backgroundColor: const Color(0xFFE94560),
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
