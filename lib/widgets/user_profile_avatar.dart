import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final String? gender;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserProfileAvatar({
    super.key,
    this.imagePath,
    this.gender,
    this.radius = 40,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarChild = _buildAvatarChild();

    Widget avatarCore = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0F766E).withValues(alpha: 0.15),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: avatarChild,
      ),
    );

    if (showEditBadge || onTap != null) {
      avatarCore = Stack(
        children: [
          avatarCore,
          if (showEditBadge)
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: avatarCore,
      );
    }

    return avatarCore;
  }

  Widget _buildAvatarChild() {
    final defaultEmoji = (gender == 'أنثى') ? '👩' : '👨';

    if (imagePath == null || imagePath!.trim().isEmpty) {
      return Center(
        child: Text(
          defaultEmoji,
          style: TextStyle(fontSize: radius * 0.95),
        ),
      );
    }

    final path = imagePath!.trim();

    // Preset emoji avatar
    if (path.startsWith('emoji:')) {
      final emoji = path.substring(6);
      return Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: radius * 0.95),
        ),
      );
    }

    // Base64 image string (Web or inline data)
    if (path.startsWith('data:image') || path.startsWith('base64:')) {
      try {
        final cleanStr = path.contains(',') ? path.split(',').last : path.replaceFirst('base64:', '');
        final bytes = base64Decode(cleanStr);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(defaultEmoji, style: TextStyle(fontSize: radius * 0.95)),
          ),
        );
      } catch (_) {
        return Center(
          child: Text(defaultEmoji, style: TextStyle(fontSize: radius * 0.95)),
        );
      }
    }

    // Local file path
    if (!kIsWeb) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(defaultEmoji, style: TextStyle(fontSize: radius * 0.95)),
            ),
          );
        }
      } catch (_) {}
    }

    return Center(
      child: Text(defaultEmoji, style: TextStyle(fontSize: radius * 0.95)),
    );
  }
}
