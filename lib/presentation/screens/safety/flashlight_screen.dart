import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../services/flashlight_service.dart';

class FlashlightScreen extends StatefulWidget {
  const FlashlightScreen({super.key});

  @override
  State<FlashlightScreen> createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen> {
  bool _isOn = false;
  bool _sosActive = false;
  bool _strobeActive = false;
  int _strobeFreq = 100;

  Future<void> _toggle() async {
    HapticFeedback.lightImpact();
    await FlashlightService.toggle();
    setState(() => _isOn = FlashlightService.isOn);
  }

  Future<void> _toggleSos() async {
    HapticFeedback.mediumImpact();
    if (_sosActive) {
      FlashlightService.stopSos();
    } else {
      FlashlightService.stopStrobe();
      await FlashlightService.startSos();
    }
    setState(() {
      _sosActive = FlashlightService.sosMode;
      _strobeActive = false;
      _isOn = FlashlightService.isOn;
    });
  }

  Future<void> _toggleStrobe() async {
    HapticFeedback.mediumImpact();
    if (_strobeActive) {
      FlashlightService.stopStrobe();
    } else {
      FlashlightService.stopSos();
      await FlashlightService.startStrobe(frequencyMs: _strobeFreq);
    }
    setState(() {
      _strobeActive = FlashlightService.strobeMode;
      _sosActive = false;
    });
  }

  @override
  void dispose() {
    FlashlightService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      appBar: AppBar(
        title: const Text('Fener'),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.dark,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main flashlight button
            GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOn || _sosActive || _strobeActive
                      ? const Color(0xFFFFEB3B).withAlpha(40)
                      : (isDark ? AppColors.darkCard : Colors.white),
                  border: Border.all(
                    color: _isOn || _sosActive || _strobeActive
                        ? const Color(0xFFFFEB3B)
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: 3,
                  ),
                  boxShadow: _isOn || _sosActive || _strobeActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFEB3B).withAlpha(100),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.flashlight_on,
                    size: 80,
                    color: _isOn || _sosActive || _strobeActive
                        ? const Color(0xFFFFEB3B)
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _sosActive
                  ? 'SOS Modu Aktif'
                  : _strobeActive
                      ? 'Strobe Modu Aktif'
                      : _isOn
                          ? 'Fener Açık'
                          : 'Fener Kapalı',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dokun: Aç/Kapat  |  SOS butonu: Morse kodu',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
              ),
            ),
            const SizedBox(height: 32),
            // Mode buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withAlpha(20)
                        : Colors.black.withAlpha(5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ModeButton(
                          icon: Icons.flashlight_on,
                          label: 'Standart',
                          active: _isOn && !_sosActive && !_strobeActive,
                          onTap: () async {
                            FlashlightService.stopSos();
                            FlashlightService.stopStrobe();
                            await FlashlightService.turnOn();
                            setState(() {
                              _isOn = true;
                              _sosActive = false;
                              _strobeActive = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ModeButton(
                          icon: Icons.sos,
                          label: 'SOS',
                          active: _sosActive,
                          color: AppColors.error,
                          onTap: _toggleSos,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ModeButton(
                          icon: Icons.bolt,
                          label: 'Strobe',
                          active: _strobeActive,
                          color: AppColors.warning,
                          onTap: _toggleStrobe,
                        ),
                      ),
                    ],
                  ),
                  if (_strobeActive) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Frekans: ${_strobeFreq}ms',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: _strobeFreq.toDouble(),
                      min: 50,
                      max: 500,
                      divisions: 9,
                      label: '$_strobeFreq ms',
                      onChanged: (v) {
                        setState(() => _strobeFreq = v.round());
                        if (_strobeActive) {
                          FlashlightService.startStrobe(frequencyMs: _strobeFreq);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Emergency SOS big button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _toggleSos,
                icon: const Icon(Icons.warning_amber_rounded),
                label: Text(_sosActive ? 'SOS Durdur' : 'ACİL SOS BAŞLAT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sosActive ? AppColors.error : const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.active,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? AppColors.cobalt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withAlpha(isDark ? 40 : 25)
              : (isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? activeColor.withAlpha(80) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? activeColor : AppColors.slate),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? activeColor : AppColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
