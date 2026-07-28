/// Gizlilik tercihleri — modül bazlı AI veri izinleri + consent kaydı.
/// KURAL: sağlık/finans/çocuk/konum gibi HASSAS veriler VARSAYILAN KAPALIDIR
/// (minimum erişim). Gizlilik yalnızca UI değil — AI context builder buna uyar.
library;

/// AI'nın erişebileceği veri modülleri (izin anahtarı).
enum PrivacyModule {
  calendar,
  tasks,
  shopping,
  kitchen,
  health, // hassas
  finance, // hassas
  child, // hassas
  location, // hassas
}

/// Hassas modüller — varsayılan KAPALI, açık onay gerektirir.
const _sensitiveModules = {
  PrivacyModule.health,
  PrivacyModule.finance,
  PrivacyModule.child,
  PrivacyModule.location,
};

class PrivacyPreferences {
  final bool analyticsEnabled;
  final bool personalizationEnabled;
  final Set<PrivacyModule> aiAllowedModules;
  final int consentVersion;
  final DateTime? consentedAt;

  const PrivacyPreferences({
    this.analyticsEnabled = true,
    this.personalizationEnabled = true,
    this.aiAllowedModules = const {
      // Hassas olmayan modüller varsayılan açık.
      PrivacyModule.calendar,
      PrivacyModule.tasks,
      PrivacyModule.shopping,
      PrivacyModule.kitchen,
    },
    this.consentVersion = 1,
    this.consentedAt,
  });

  /// Güncel consent şeması sürümü — değişince yeniden onay istenebilir.
  static const currentConsentVersion = 1;

  /// AI bu modülün verisini kullanabilir mi?
  bool aiAllows(PrivacyModule m) => aiAllowedModules.contains(m);

  static bool isSensitive(PrivacyModule m) => _sensitiveModules.contains(m);

  PrivacyPreferences toggleModule(PrivacyModule m, bool allow) {
    final set = {...aiAllowedModules};
    if (allow) {
      set.add(m);
    } else {
      set.remove(m);
    }
    return copyWith(aiAllowedModules: set, consentedAt: DateTime.now());
  }

  PrivacyPreferences copyWith({
    bool? analyticsEnabled,
    bool? personalizationEnabled,
    Set<PrivacyModule>? aiAllowedModules,
    int? consentVersion,
    DateTime? consentedAt,
  }) =>
      PrivacyPreferences(
        analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
        personalizationEnabled:
            personalizationEnabled ?? this.personalizationEnabled,
        aiAllowedModules: aiAllowedModules ?? this.aiAllowedModules,
        consentVersion: consentVersion ?? this.consentVersion,
        consentedAt: consentedAt ?? this.consentedAt,
      );

  Map<String, dynamic> toJson() => {
        'analyticsEnabled': analyticsEnabled,
        'personalizationEnabled': personalizationEnabled,
        'aiAllowedModules': aiAllowedModules.map((m) => m.name).toList(),
        'consentVersion': consentVersion,
        'consentedAt': consentedAt?.toIso8601String(),
      };

  factory PrivacyPreferences.fromJson(Map<String, dynamic> json) {
    final mods = (json['aiAllowedModules'] as List?)
            ?.map((e) => PrivacyModule.values
                .firstWhere((m) => m.name == e, orElse: () => PrivacyModule.tasks))
            .toSet() ??
        const {
          PrivacyModule.calendar,
          PrivacyModule.tasks,
          PrivacyModule.shopping,
          PrivacyModule.kitchen,
        };
    return PrivacyPreferences(
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? true,
      personalizationEnabled: json['personalizationEnabled'] as bool? ?? true,
      aiAllowedModules: mods,
      consentVersion: json['consentVersion'] as int? ?? 1,
      consentedAt: json['consentedAt'] != null
          ? DateTime.tryParse(json['consentedAt'] as String)
          : null,
    );
  }
}
