import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/hive_service.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities.dart';
import '../../../services/weather_service.dart';
import '../../../services/location_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/settings/screen_header.dart';
import 'location_picker_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class WeatherSettingsScreen extends ConsumerStatefulWidget {
  const WeatherSettingsScreen({super.key});

  @override
  ConsumerState<WeatherSettingsScreen> createState() =>
      _WeatherSettingsScreenState();
}

class _WeatherSettingsScreenState extends ConsumerState<WeatherSettingsScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  String _selectedCity = 'Brüksel';
  bool _useCelsius = true;
  bool _useCurrentLocation = true;
  bool _isRequestingPermission = false;
  LocationModel? _savedLocation;

  @override
  void initState() {
    super.initState();
    _selectedCity = HiveService.getSetting('weatherCity') ?? 'Brüksel';
    _useCelsius = HiveService.getBoolSetting('weatherCelsius', defaultValue: true);
    _useCurrentLocation = HiveService.getBoolSetting('weatherUseLocation', defaultValue: true);
    _savedLocation = HiveService.getLocation();
  }

  Future<void> _toggleLocation(bool value) async {
    if (!value) {
      setState(() => _useCurrentLocation = false);
      return;
    }

    setState(() => _isRequestingPermission = true);
    final status = await LocationService.checkPermission();
    setState(() => _isRequestingPermission = false);

    if (status == LocationPermissionStatus.granted) {
      setState(() => _useCurrentLocation = true);
      final loc = await LocationService.getCurrentAddress();
      if (loc != null) {
        setState(() => _savedLocation = loc);
        await HiveService.saveLocation(loc);
      }
    } else if (status == LocationPermissionStatus.deniedForever) {
      _showPermissionDialog();
      setState(() => _useCurrentLocation = false);
    } else {
      setState(() => _useCurrentLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).konumIzniVerilmediSehirSecimiVeyaHaritadanKonumSecimiKullanilabilir,
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).konumIzniGerekli),
          ],
        ),
        content: const Text(
          'Mevcut konumunuzu kullanmak için ayarlardan konum iznini manuel olarak etkinleştirmeniz gerekiyor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LocationPickerScreen()));
    if (result == true) {
      setState(() {
        _savedLocation = HiveService.getLocation();
        _useCurrentLocation = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await HiveService.setSetting('weatherCity', _selectedCity);
    await HiveService.setBoolSetting('weatherCelsius', _useCelsius);
    await HiveService.setBoolSetting('weatherUseLocation', _useCurrentLocation);
    await HiveService.saveUseCurrentLocation(_useCurrentLocation);

    ref.invalidate(weatherProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).havaDurumuAyarlariKaydedildi)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).wtTitle,
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Live weather preview
          weatherAsync.when(
            data: (weather) => _WeatherPreviewCard(
              weather: weather,
              useCelsius: _useCelsius,
              locationName: _buildLocationName(),
            ),
            loading: () => _buildPreviewSkeleton(isDark),
            error: (_, _) => _buildPreviewError(isDark),
          ),
          const SizedBox(height: 20),

          // Current location toggle
          _buildSectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF6366F1),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mevcut Konumum',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          Text(
                            'GPS ile otomatik konum belirleme',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isRequestingPermission)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Switch(
                        value: _useCurrentLocation,
                        onChanged: _toggleLocation,
                        activeTrackColor: const Color(0xFF6366F1),
                      ),
                  ],
                ),
                if (_useCurrentLocation && _savedLocation != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place,
                          color: Color(0xFF6366F1),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _savedLocation!.fullAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Map location picker
          _buildSectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).haritadanKonumSec,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context).openstreetmapHaritasindanIstediginizNoktayiSecin,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                if (_savedLocation != null && !_useCurrentLocation)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1).withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place,
                          color: Color(0xFF6366F1),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _savedLocation!.address,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              Text(
                                _savedLocation!.fullAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _openLocationPicker,
                    icon: const Icon(Icons.map, color: Color(0xFF6366F1)),
                    label: Text(AppLocalizations.of(context).haritayiAc,
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Şehir seçimi kaldırıldı — konum cihazdan izinle alınır
          _buildSectionCard(
            isDark: isDark,
            child: const Row(
              children: [
                Icon(Icons.my_location,
                    color: Color(0xFF10B981), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Konum cihazınızdan otomatik alınır. Doğru hava durumu için konum iznini açık tutun.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Temperature unit
          _buildSectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).sicaklikBirimi,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _UnitOption(
                        label: AppLocalizations.of(context).wtCelsius,
                        selected: _useCelsius,
                        onTap: () => setState(() => _useCelsius = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UnitOption(
                        label: AppLocalizations.of(context).wtFahrenheit,
                        selected: !_useCelsius,
                        onTap: () => setState(() => _useCelsius = false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 7-day forecast preview
          if (weatherAsync.hasValue)
            _buildForecastSection(weatherAsync.value!, isDark),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Kaydet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildLocationName() {
    if (_useCurrentLocation && _savedLocation != null) {
      return _savedLocation!.city.isNotEmpty
          ? _savedLocation!.city
          : _savedLocation!.address;
    }
    if (!_useCurrentLocation && _savedLocation != null) {
      return _savedLocation!.address;
    }
    return _selectedCity;
  }

  Widget _buildSectionCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x1EFFFFFF),
        ),
      ),
      child: child,
    );
  }

  Widget _buildPreviewSkeleton(bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildPreviewError(bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x1EFFFFFF),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: Color(0xFF6B7280)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).havaDurumuAlinamadi),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastSection(WeatherData weather, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).gunlukTahmin,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE5E7EB),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: weather.daily.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final day = weather.daily[index];
              final isToday = index == 0;
              final dayName = isToday
                  ? 'Bugün'
                  : DateFormat('EEE', 'tr_TR').format(day.date);

              return Container(
                width: 80,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFF6366F1).withAlpha(20)
                      : (const Color(0xFF13131A)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday
                        ? const Color(0xFF6366F1).withAlpha(60)
                        : (const Color(0x1EFFFFFF)),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF6366F1)
                            : (const Color(0xFF6B7280)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      WeatherService.weatherIconData(day.weatherCode),
                      color: WeatherService.weatherColor(day.weatherCode),
                      size: 26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${day.maxTemp.round()}°',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.minTemp.round()}°',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeatherPreviewCard extends StatelessWidget {
  final WeatherData weather;
  final bool useCelsius;
  final String locationName;

  const _WeatherPreviewCard({
    required this.weather,
    required this.useCelsius,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    final unit = useCelsius ? '°C' : '°F';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WeatherService.weatherColor(weather.weatherCode).withAlpha(220),
            const Color(0xFF6366F1).withAlpha(180),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                WeatherService.weatherIconData(weather.weatherCode),
                color: Colors.white,
                size: 56,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.round()}$unit',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    WeatherService.weatherDescription(weather.weatherCode),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            locationName,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricItem(
                  icon: Icons.thermostat,
                  label: AppLocalizations.of(context).wtFeelsLike,
                  value: '${weather.feelsLike.round()}$unit',
                ),
                _MetricItem(
                  icon: Icons.water_drop,
                  label: AppLocalizations.of(context).wtHumidity,
                  value: '${weather.humidity}%',
                ),
                _MetricItem(
                  icon: Icons.air,
                  label: AppLocalizations.of(context).ruzgar,
                  value: '${weather.windSpeed.round()} km/s',
                ),
                _MetricItem(
                  icon: Icons.speed,
                  label: AppLocalizations.of(context).basinc,
                  value: '${weather.pressure.round()} hPa',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }
}

class _UnitOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                    ? const Color(0xFF6366F1).withAlpha(30)
                    : const Color(0xFF6366F1).withAlpha(15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF6366F1)
                : (const Color(0x1EFFFFFF)),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? const Color(0xFF6366F1)
                  : (const Color(0xFFE5E7EB)),
            ),
          ),
        ),
      ),
    );
  }
}
