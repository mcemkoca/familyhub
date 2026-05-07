import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/constants.dart';

class HubFAB extends StatefulWidget {
  final VoidCallback? onPress;
  const HubFAB({super.key, this.onPress});

  @override
  State<HubFAB> createState() => _HubFABState();
}

class _HubFABState extends State<HubFAB> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnim;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _rotateAnim = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _handlePress() {
    HapticFeedback.mediumImpact();
    if (_menuOpen) {
      _controller.reverse();
    } else {
      _controller.forward().then((_) => _controller.reverse());
    }
    setState(() => _menuOpen = !_menuOpen);
    widget.onPress?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_controller.value * 0.08),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse ring
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cobalt.withAlpha(50), width: 2),
                    ),
                  ),
                  // FAB
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.fabGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.cobalt, blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    ),
                    child: Center(
                      child: RotationTransition(
                        turns: _rotateAnim,
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
