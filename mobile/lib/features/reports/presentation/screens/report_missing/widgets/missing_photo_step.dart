import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../../../core/widgets/widgets.dart';
import 'section_card.dart';
import 'secondary_btn.dart';

/// Photo capture step with real ImagePicker support and live preview.
class MissingPhotoStep extends StatelessWidget {
  const MissingPhotoStep({
    super.key,
    required this.photoSeed,
    required this.onPhotoChanged,
  });
  final String? photoSeed;
  final ValueChanged<String?> onPhotoChanged;

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final mime = picked.mimeType ?? 'image/jpeg';
        final base64String = 'data:$mime;base64,${base64Encode(bytes)}';
        onPhotoChanged(base64String);
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoSeed != null && photoSeed!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MissingSectionCard(
          icon: Icons.camera_alt_rounded,
          color: AppColors.primary,
          title: context.tr('report.photo'),
          subtitle: context.tr('report.photoHint'),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _pickPhoto(context, ImageSource.gallery),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: context.palette.surfaceAlt.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: !hasPhoto
                          ? context.palette.border
                          : AppColors.primary.withValues(alpha: 0.3),
                      width: !hasPhoto ? 1 : 1.5,
                    ),
                  ),
                  child: !hasPhoto
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.10),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.add_a_photo_rounded,
                                    size: 28, color: AppColors.primary)),
                            const SizedBox(height: 12),
                            Text('Tap to add photo',
                                style: context.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Clear face photo helps identification',
                                style: context.textTheme.bodySmall?.copyWith(
                                    color: context.palette.textSecondary)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ChildPhoto(
                                seed: photoSeed,
                                imagePath: photoSeed,
                                size: 200,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Material(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => onPhotoChanged(null),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.close_rounded,
                                          size: 18, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: MissingSecondaryBtn(
                      icon: Icons.camera_alt_outlined,
                      label: context.tr('report.takePhoto'),
                      onTap: () => _pickPhoto(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MissingSecondaryBtn(
                      icon: Icons.photo_library_outlined,
                      label: context.tr('report.gallery'),
                      outlined: true,
                      onTap: () => _pickPhoto(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.14))),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Photo added — you can change it anytime',
                            style: context.textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600))),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
