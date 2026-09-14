import 'package:flutter/material.dart';

class AppAlert {
  /// Shows a sleek, floating alert pill comfortably above the mini player or bottom nav.
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 2),
    bool isFullScreen = false,
  }) {
    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: isFullScreen ? 28.0 : 88.0,
            left: 20.0,
            right: 20.0,
          ),
          backgroundColor: const Color(0xFF161618),
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isError
                  ? Colors.redAccent.withValues(alpha: 0.6)
                  : (isSuccess
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.18)),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: duration,
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isError ? Colors.redAccent : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ] else if (isSuccess) ...[
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
              ] else if (isError) ...[
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('AppAlert error: $e');
    }
  }
}
