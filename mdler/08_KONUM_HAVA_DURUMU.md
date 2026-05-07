# KONUM & HAVA DURUMU
## 4 Konum Tabanli Sorun | Hedef: GPS ile Otomatik

---

## 38. Hava Durumu — Cihaz Konumuna Gore

**Sorun:** Liste sehir secimi. Yeni: Cihaz GPS konumuna gore otomatik.

### pubspec.yaml
```yaml
dependencies:
  geolocator: ^13.0.0
  geocoding: ^3.0.0
  http: ^1.2.0
```

### lib/features/weather/services/location_weather_service.dart
```dart
class LocationWeatherService {
  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;

  Future<WeatherData> getCurrentLocationWeather() async {
    // 1. Konum izni kontrolu
    LocationPermission permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Konum izni reddedildi');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException('Konum izni kalici reddedildi. Ayarlardan acin.');
    }

    // 2. GPS konum al
    final Position position = await _geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 3. Reverse geocoding — sehir adi
    final placemarks = await placemarkFromCoordinates(
      position.latitude, 
      position.longitude,
    );
    final city = placemarks.first.locality ?? 'Bilinmiyor';
    final country = placemarks.first.country ?? '';

    // 4. OpenWeather API cagrisi
    final response = await http.get(Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?'
      'lat=${position.latitude}&lon=${position.longitude}'
      '&appid=${Env.openWeatherApiKey}&units=metric&lang=tr'
    ));

    if (response.statusCode != 200) {
      throw WeatherException('Hava durumu alinamadi');
    }

    final data = jsonDecode(response.body);
    return WeatherData.fromJson(data, city: city, country: country);
  }

  /// Arka planda periyodik guncelleme
  void scheduleBackgroundUpdate() {
    Workmanager().registerPeriodicTask(
      'weather-update',
      'fetchWeather',
      frequency: const Duration(hours: 3),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
```

### lib/features/weather/screens/weather_screen.dart — YENI
```dart
class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final LocationWeatherService _weatherService = LocationWeatherService();
  WeatherData? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final weather = await _weatherService.getCurrentLocationWeather();
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
        });
      }
    } on LocationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Beklenmeyen hata: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadWeather,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: true,
              flexibleSpace: FlexibleSpaceBar(
                title: _weather != null 
                    ? Text('${_weather!.city}, ${_weather!.country}')
                    : const Text('Hava Durumu'),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark 
                          ? [const Color(0xFF1e3a5f), const Color(0xFF0f172a)]
                          : [const Color(0xFF60a5fa), const Color(0xFF3b82f6)],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: _buildErrorState(isDark),
              )
            else if (_weather != null)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildCurrentWeather(isDark),
                    const SizedBox(height: 24),
                    _buildForecast(isDark),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeather(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.surfaceDarkElevated : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getWeatherIcon(_weather!.condition),
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weather!.temperature.round()}°C',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    _weather!.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail('Nem', '${_weather!.humidity}%', Icons.water_drop),
              _buildWeatherDetail('Ruzgar', '${_weather!.windSpeed} km/s', Icons.air),
              _buildWeatherDetail('Hissedilen', '${_weather!.feelsLike.round()}°', Icons.thermostat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textTertiaryDark)),
      ],
    );
  }

  Widget _buildForecast(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '5 Gunluk Tahmin',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        ..._weather!.forecast.map((day) => _buildForecastDay(day, isDark)),
      ],
    );
  }

  Widget _buildForecastDay(ForecastDay day, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.surfaceDarkElevated : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day.dayName, style: const TextStyle(fontWeight: FontWeight.w500)),
          Icon(_getWeatherIcon(day.condition), color: AppColors.primary),
          Text('${day.minTemp.round()}° / ${day.maxTemp.round()}°'),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: AppColors.textTertiaryDark),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadWeather,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Geolocator.openAppSettings(),
            child: const Text('Konum Ayarlarini Ac'),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return Icons.wb_sunny;
      case 'clouds': return Icons.wb_cloudy;
      case 'rain': return Icons.water_drop;
      case 'snow': return Icons.ac_unit;
      case 'thunderstorm': return Icons.flash_on;
      default: return Icons.wb_sunny;
    }
  }
}
```

---

## 39. Canli Destek — Konum Dahil

**Sorun:** Liste yerine konum alip o konuma gore bilgi iletmeli

### lib/features/support/services/live_support_service.dart
```dart
class LiveSupportService {
  final SupabaseClient _client = SupabaseConfig.safeClient;
  final LocationService _locationService = LocationService();

  Future<SupportSession> initiateLiveSupport() async {
    final user = _client.auth.currentUser;
    if (user == null) throw AuthException('Oturum yok');

    // 1. Konum al
    final Position? position = await _getSafePosition();
    final String locationText = position != null 
        ? '${position.latitude},${position.longitude}'
        : 'Konum alinamadi';

    // 2. Reverse geocoding
    String? address;
    if (position != null) {
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
        );
        final pm = placemarks.first;
        address = '${pm.street}, ${pm.locality}, ${pm.country}';
      } catch (_) {}
    }

    // 3. Supabase Realtime'e session ac
    final session = await _client.from('support_sessions').insert({
      'user_id': user.id,
      'status': 'waiting',
      'location': locationText,
      'address': address,
      'started_at': DateTime.now().toIso8601String(),
      'priority': 'normal',
    }).select().single();

    // 4. Realtime subscription baslat
    _subscribeToAgentMessages(session['id']);

    return SupportSession.fromJson(session);
  }

  Future<Position?> _getSafePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      return null;
    }
  }

  void _subscribeToAgentMessages(String sessionId) {
    _client
        .channel('support:$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            // Yeni mesaj bildirimi
          },
        )
        .subscribe();
  }
}
```

### Supabase Schema
```sql
CREATE TABLE IF NOT EXISTS support_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    agent_id UUID,
    status VARCHAR(20) DEFAULT 'waiting',
    location TEXT,
    address TEXT,
    messages JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS support_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES support_sessions(id),
    sender_id UUID REFERENCES auth.users(id),
    content TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE support_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own support sessions" ON support_sessions
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users send messages" ON support_messages
FOR INSERT WITH CHECK (
    session_id IN (SELECT id FROM support_sessions WHERE user_id = auth.uid())
);
```

---

## 40. Safe Zones — Default Konum Duzeltme

**Sorun:** Default konum Frankfurt, Almanya

### lib/features/safety/screens/safe_zones_step.dart
```dart
class SafeZonesStep extends StatefulWidget {
  @override
  _SafeZonesStepState createState() => _SafeZonesStepState();
}

class _SafeZonesStepState extends State<SafeZonesStep> {
  LatLng _currentPosition = const LatLng(41.0082, 28.9784); // Istanbul, Turkiye

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Fallback: Istanbul
      setState(() {
        _currentPosition = const LatLng(41.0082, 28.9784);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) {
          // Harita olusturuldu
        },
        circles: {
          Circle(
            circleId: const CircleId('safe_zone'),
            center: _currentPosition,
            radius: 500, // 500m
            fillColor: Colors.green.withOpacity(0.2),
            strokeColor: Colors.green,
            strokeWidth: 2,
          ),
        },
      ),
    );
  }
}
```

---

## Kontrol Listesi

- [ ] Hava durumu GPS konumuna gore calisiyor
- [ ] Reverse geocoding sehir adi donuyor
- [ ] Pull-to-refresh ile manuel guncelleme
- [ ] Konum izni reddedilirse ayarlara yonlendirme
- [ ] Canli destek konum dahil calisiyor
- [ ] Safe zones default konum Istanbul/Turkiye
- [ ] Background weather update 3 saatte bir
- [ ] 5 gunluk tahmin gosteriliyor

---
**Versiyon:** 1.0 | **Dosya:** 8/10 | **Hedef:** GPS ile Otomatik
