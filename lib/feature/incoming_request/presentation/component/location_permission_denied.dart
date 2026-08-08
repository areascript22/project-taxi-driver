import 'package:flutter/material.dart';

class LocationPermissionDenied extends StatelessWidget {
  final bool isPermanentlyDenied;
  final VoidCallback onEnablePermissionsTapped;

  const LocationPermissionDenied({
    super.key,
    required this.isPermanentlyDenied,
    required this.onEnablePermissionsTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE94560).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: Color(0xFFE94560),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Necesitamos tu ubicación',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPermanentlyDenied
                  ? 'El acceso a tu ubicación está bloqueado. Actívalo desde la configuración del dispositivo para poder ver y aceptar carreras.'
                  : 'Para ver y aceptar las carreras de los pasajeros necesitamos acceso a tu ubicación.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onEnablePermissionsTapped,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isPermanentlyDenied
                      ? 'Abrir configuración'
                      : 'Dar permiso de ubicación',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
