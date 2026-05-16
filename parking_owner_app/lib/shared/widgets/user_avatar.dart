import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? profileImageUrl;
  final double size;

  const UserAvatar({
    super.key,
    required this.name,
    this.profileImageUrl,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final imageUrl = profileImageUrl?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null || imageUrl.isEmpty
          ? _InitialAvatar(name: name, accent: accent, size: size)
          : CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => _InitialAvatar(
                name: name,
                accent: accent.withValues(alpha: 0.55),
                size: size,
              ),
              errorWidget: (context, url, error) =>
                  _InitialAvatar(name: name, accent: accent, size: size),
            ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;
  final Color accent;
  final double size;

  const _InitialAvatar({
    required this.name,
    required this.accent,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    return Center(
      child: Text(
        trimmed.isNotEmpty ? trimmed.substring(0, 1) : '?',
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}
