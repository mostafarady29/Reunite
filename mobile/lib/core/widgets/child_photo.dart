import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../utils/image_util.dart';

/// Renders a child's photo: actual image from URL/file/memory if present,
/// or a deterministic branded avatar fallback.
class ChildPhoto extends StatelessWidget {
  const ChildPhoto({
    super.key,
    required this.seed,
    this.radius,
    this.size,
    this.imagePath,
    this.onTap,
    this.borderRadius,
  });

  final String? seed;
  final String? imagePath;
  final double? radius;
  final double? size;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  Widget _buildFallback(Color color, double dim) {
    return Container(
      width: radius != null ? null : dim,
      height: radius != null ? null : dim,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.child_care_rounded,
          color: Colors.white.withValues(alpha: 0.9),
          size: radius != null ? radius! * 0.8 : dim * 0.4,
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, Color color, double dim) {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) {
      return _buildFallback(color, dim);
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: radius != null ? null : dim,
        height: radius != null ? null : dim,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: radius != null ? null : dim,
            height: radius != null ? null : dim,
            color: color.withValues(alpha: 0.15),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(color, dim),
      );
    }

    if (path.startsWith('data:image')) {
      try {
        final comma = path.indexOf(',');
        final base64Str = comma != -1 ? path.substring(comma + 1) : path;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: radius != null ? null : dim,
          height: radius != null ? null : dim,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(color, dim),
        );
      } catch (_) {
        return _buildFallback(color, dim);
      }
    }

    if (!kIsWeb) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: radius != null ? null : dim,
            height: radius != null ? null : dim,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallback(color, dim),
          );
        }
      } catch (_) {}
    }

    return _buildFallback(color, dim);
  }

  @override
  Widget build(BuildContext context) {
    final double dim = size ?? radius ?? 0;
    final Color color = ImageUtil.colorFor(seed ?? 'child');

    final Widget content = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(AppDimens.radiusMd),
      child: _buildImage(context, color, dim),
    );

    final Widget wrapped = onTap == null
        ? content
        : InkWell(onTap: onTap, borderRadius: borderRadius, child: content);

    if (radius == null) return wrapped;

    return SizedBox(
      width: radius,
      height: radius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        child: wrapped,
      ),
    );
  }
}