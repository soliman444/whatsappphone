import 'package:flutter/material.dart';

import '../../platform/local_fs.dart';
import '../theme.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.path,
    this.isGroup = false,
    this.isChannel = false,
    this.size = 48,
  });

  final String name;
  final String? path;
  final bool isGroup;
  final bool isChannel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    final color = isChannel
        ? const Color(0xFF6B7280)
        : isGroup
        ? AppColors.accent
        : AppColors.ink;
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: color,
        child: localFileExists(path)
            ? localImageFile(path!, fit: BoxFit.cover, width: size, height: size)
            : Center(
                child: Text(
                  initialsFor(name),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.34,
                  ),
                ),
              ),
      ),
    );
  }
}
