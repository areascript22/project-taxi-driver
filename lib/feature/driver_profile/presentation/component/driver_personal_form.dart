import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingStepHeader(
              step: 1,
              totalSteps: 2,
              title: l10n.onboardingPersonalTitle,
              subtitle: l10n.onboardingPersonalSubtitle,
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
              label: l10n.fieldFirstName,
              controller: firstNameController,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.validationFirstName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            OnboardingTextField(
              label: l10n.fieldLastName,
              controller: lastNameController,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.validationLastName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            OnboardingTextField(
              label: l10n.commonEmail,
              controller: emailController,
              enabled: false,
            ),
            const SizedBox(height: 16),
            OnboardingTextField(
              label: l10n.fieldMobile,
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
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              validator: (value) {
                final digits = value?.trim() ?? '';
                if (digits.isEmpty) {
                  return l10n.validationMobileRequired;
                }
                if (!ecuadorMobileRegex.hasMatch(digits)) {
                  return l10n.validationMobileInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            CustomButton(
              textButton: l10n.commonNext,
              backgroundColor: colorScheme.primary,
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
