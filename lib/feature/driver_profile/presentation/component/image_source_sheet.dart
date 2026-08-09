import 'package:flutter/material.dart';
import '../../../../shared/image_picker/service/profile_image_picker_service.dart';

class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({super.key});

  static Future<ProfileImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ProfileImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImageSourceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Foto de perfil',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.photo_camera_outlined,
              label: 'Tomar foto',
              onTap: () => Navigator.of(context).pop(ProfileImageSource.camera),
            ),
            _OptionTile(
              icon: Icons.photo_library_outlined,
              label: 'Elegir de galería',
              onTap: () => Navigator.of(context).pop(ProfileImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE94560).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFE94560), size: 22),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
    );
  }
}
