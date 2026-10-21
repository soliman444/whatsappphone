import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme.dart';

class ReceiptTicks extends StatelessWidget {
  const ReceiptTicks({
    super.key,
    required this.status,
    this.isGroup = false,
    this.size = 16,
    this.onDark = false,
  });

  final String status;
  final bool isGroup;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final read = !isGroup && Receipt.isRead(status);
    final color = status == 'failed'
        ? Colors.red
        : read
        ? (onDark ? const Color(0xFFE8A87C) : AppColors.accent)
        : (onDark ? const Color(0xFFD5DCE8) : const Color(0xFF7A8494));
    return Icon(_icon, size: size, color: color);
  }

  IconData get _icon {
    switch (status) {
      case 'pending':
      case 'pending_local':
      case 'sending':
        return Icons.schedule;
      case 'failed':
        return Icons.error_outline;
      case 'delivered':
      case 'read':
      case 'played':
        return Icons.done_all;
      default:
        return Icons.done;
    }
  }
}
