import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/presentation/component/custom_button.dart';
import 'onboarding_step_header.dart';
import 'onboarding_text_field.dart';

class VehicleInfoForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController plateController;
  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController yearController;
  final TextEditingController colorController;
  final TextEditingController registrationNumberController;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const VehicleInfoForm({
    super.key,
    required this.formKey,
    required this.plateController,
    required this.brandController,
    required this.modelController,
    required this.yearController,
    required this.colorController,
    required this.registrationNumberController,
    required this.isSubmitting,
    required this.onBack,
    required this.onSubmit,
  });

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentYear = DateTime.now().year;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingStepHeader(
              step: 2,
              totalSteps: 2,
              title: l10n.onboardingVehicleTitle,
              subtitle: l10n.onboardingVehicleSubtitle,
            ),
            const SizedBox(height: 28),
            OnboardingTextField(
              label: l10n.vehiclePlate,
              controller: plateController,
              textCapitalization: TextCapitalization.characters,
              hintText: 'PBX-1234',
              inputFormatters: [UpperCaseTextFormatter()],
              validator: (value) => _required(value, l10n.validationPlate),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OnboardingTextField(
                    label: l10n.vehicleBrand,
                    controller: brandController,
                    textCapitalization: TextCapitalization.words,
                    hintText: 'Toyota',
                    validator: (value) => _required(value, l10n.commonRequired),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OnboardingTextField(
                    label: l10n.vehicleModel,
                    controller: modelController,
                    textCapitalization: TextCapitalization.words,
                    hintText: 'Corolla',
                    validator: (value) => _required(value, l10n.commonRequired),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OnboardingTextField(
                    label: l10n.vehicleYear,
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    hintText: '$currentYear',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      final year = int.tryParse(value?.trim() ?? '');
                      if (year == null) {
                        return l10n.commonRequired;
                      }
                      if (year < 1990 || year > currentYear + 1) {
                        return l10n.validationYearInvalid;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OnboardingTextField(
                    label: l10n.vehicleColor,
                    controller: colorController,
                    textCapitalization: TextCapitalization.words,
                    hintText: l10n.vehicleColorHint,
                    validator: (value) => _required(value, l10n.commonRequired),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OnboardingTextField(
              label: l10n.vehicleRegistrationNumber,
              controller: registrationNumberController,
              textCapitalization: TextCapitalization.characters,
              hintText: 'MAT-4567',
              validator:
                  (value) => _required(value, l10n.validationRegistrationNumber),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.commonBack,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    textButton:
                    isSubmitting ? l10n.onboardingSaving : l10n.onboardingSubmit,
                    backgroundColor: colorScheme.primary,
                    onTap: isSubmitting ? null : onSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
