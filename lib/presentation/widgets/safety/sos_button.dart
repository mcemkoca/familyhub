import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';

class SOSButton extends StatefulWidget {
  final bool active;
  final double progress;
  final VoidCallback onPressIn;
  final VoidCallback onPressOut;
  final VoidCallback onCancel;

  const SOSButton({
    super.key,
    required this.active,
    required this.progress,
    required this.onPressIn,
    required this.onPressOut,
    required this.onCancel,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant SOSButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.active && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        const SizedBox(height: 24),
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow pulse
            if (widget.active)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withAlpha(30),
                      ),
                    ),
                  );
                },
              ),
            // Progress ring
            SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: widget.progress,
                  color: AppColors.error,
                  backgroundColor:
                      AppColors.error.withAlpha(40),
                  strokeWidth: 8,
                ),
              ),
            ),
            // Main button
            GestureDetector(
              onTapDown: (_) {
                if (!widget.active) {
                  HapticFeedback.heavyImpact();
                  widget.onPressIn();
                }
              },
              onTapUp: (_) {
                if (!widget.active) widget.onPressOut();
              },
              onTapCancel: () {
                if (!widget.active) widget.onPressOut();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.active
                        ? const [
                            Color(0xFFDC2626),
                            Color(0xFFEF4444),
                            Color(0xFFF87171),
                          ]
                        : const [
                            Color(0xFFF97316),
                            Color(0xFFEF4444),
                            Color(0xFFDC2626),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withAlpha(100),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sos, color: Colors.white, size: 40),
                    const SizedBox(height: 4),
                    Text(
                      widget.active ? 'SOS' : 'SOS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.active ? 'AKTİF' : 'Basılı Tut',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Cancel button
        if (widget.active)
          ElevatedButton(
            onPressed: widget.onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withAlpha(15),
              foregroundColor: AppColors.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'İptal Et',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          )
        else
          const Text(
            'Acil durumda 3 saniye basılı tutun',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
