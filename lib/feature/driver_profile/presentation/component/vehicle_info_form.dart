import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final currentYear = DateTime.now().year;

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
              title: 'Tu vehículo',
              subtitle: 'Estos datos serán revisados por nuestro equipo.',
            ),
            const SizedBox(height: 28),
            OnboardingTextField(
              label: 'Placa',
              controller: plateController,
              textCapitalization: TextCapitalization.characters,
              hintText: 'PBX-1234',
              inputFormatters: [UpperCaseTextFormatter()],
              validator: (value) => _required(value, 'Ingresa la placa'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OnboardingTextField(
                    label: 'Marca',
                    controller: brandController,
                    textCapitalization: TextCapitalization.words,
                    hintText: 'Toyota',
                    validator: (value) => _required(value, 'Requerido'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OnboardingTextField(
                    label: 'Modelo',
                    controller: modelController,
                    textCapitalization: TextCapitalization.words,
                    hintText: 'Corolla',
                    validator: (value) => _required(value, 'Requerido'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OnboardingTextField(
                    label: 'Año',
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
                        return 'Requerido';
                      }
                      if (year < 1990 || year > currentYear + 1) {
                        return 'Año inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OnboardingTextField(
                    label: 'Color',
                    controller: colorController,
                    textCapitalization: TextCapitalization.words,
                    hintText: 'Blanco',
                    validator: (value) => _required(value, 'Requerido'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OnboardingTextField(
              label: 'Número de matrícula',
              controller: registrationNumberController,
              textCapitalization: TextCapitalization.characters,
              hintText: 'MAT-4567',
              validator: (value) => _required(value, 'Ingresa el número de matrícula'),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Atrás',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    textButton: isSubmitting ? 'Guardando...' : 'Registrarme',
                    backgroundColor: const Color(0xFFE94560),
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
