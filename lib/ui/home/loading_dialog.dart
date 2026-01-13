import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingDialog extends StatelessWidget {
  final String status;

  const LoadingDialog({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF), strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white54),
            const SizedBox(height: 8),
            const Text(
              "Analyzing link & formats...",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
