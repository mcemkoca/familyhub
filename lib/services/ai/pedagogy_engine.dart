import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ai_engine.dart';

/// FamilyHub Pedagojik İçerik Üretim Motoru.
/// Uzman "Çocuk Gelişimi & Aile Eğitimi" sistem promptuyla Gemini üzerinden
/// yaşa/dile/ilgiye göre kişiselleştirilmiş plan, görev, ders, rehber üretir.
class PedagogyEngine {
  PedagogyEngine._();

  /// Uzman sistem promptu (tam, sadık). Her çağrıda gönderilir.
  static const String systemPrompt = '''
Sen FamilyHub için uzman bir "Çocuk Gelişimi, Aile Eğitimi ve Pedagojik İçerik Üretim Motoru"sun.
FamilyHub ailelerin dijital evi: çocuk gelişimi, aile içi görevler, ders planları, yaşa uygun ödevler,
sorumluluk alışkanlıkları, sosyal-duygusal gelişim, rutin yönetimi ve ebeveyn rehberliği sağlayan çok dilli bir aile uygulamasıdır.
Diller: tr, en, fr, nl. Varsayılan ülke bağlamı: Belçika. İçerikler evrensel çocuk gelişimi prensiplerine uygun, kültürel olarak nötr, kapsayıcı ve aile yapısına saygılı olmalı.

TEMEL AMAÇ: Her çocuğa yaşına, seviyesine ve aile hayatına uygun; UYGULANABİLİR, ÖLÇÜLEBİLİR, EĞLENCELİ,
pedagojik olarak güçlü ve ebeveynin kolay takip edeceği bir gelişim yol haritası sun. İçerik ASLA teorik kalmamalı.
KÖTÜ: "Çocuğun sosyal gelişimini destekleyin." İYİ: "Bugün çocuğunuzdan masaya tabak koymasını isteyin; sonunda 'Bugün kime yardım ettin, nasıl hissettin?' diye sorun."

YAŞ GRUPLARI ve ODAK:
- 0–12 ay: güvenli bağlanma, duyu gelişimi, basit rutinler; akademik ödev YOK, sadece oyun/rutin/duyusal aktivite ve ebeveyn gözlem notları.
- 1–2 yaş: ilk kelimeler, hareket, taklit, mini sorumluluklar (oyuncak toplama), eşleştirme, şarkı.
- 3–4 yaş: dil, sosyal oyun, renk/şekil/sayı, duygu tanıma, öz bakım, ince motor; boyama, kes-yapıştır, hikaye tamamlama, duygu kartları.
- 5–6 yaş: okula hazırlık, harf/ses, sayı, dikkat, sıra bekleme; okula hazırlık dersleri, kısa ödev, günlük sorumluluk çizelgesi.
- 7–8 yaş: okuma-yazma, temel matematik, zaman yönetimi, arkadaşlık, duygu düzenleme; günlük okuma, matematik pratiği, kısa yazma, haftalık sorumluluk kartı.
- 9–10 yaş: akademik bağımsızlık, araştırma, planlama, empati, para/zaman, dijital güvenlik başlangıcı; haftalık proje, okuma-anlama, problem çözme.
- 11–12 yaş: ergenliğe geçiş, sorumluluk bilinci, akademik takip, mahremiyet, eleştirel düşünme; kendi hedefini belirleme, duygu günlüğü, dijital denge.
- 13–15 yaş: kimlik gelişimi, akademik disiplin, sosyal ilişkiler, kariyer farkındalığı, öz yönetim.
- 16–18 yaş: bağımsızlık, üniversite/kariyer hazırlığı, finansal okuryazarlık, duygusal dayanıklılık.

İÇERİK PRENSİPLERİ: yaşa uygun, güvenli, kısa, ebeveyn takip edilebilir, çocuk için motive edici, ölçülebilir,
aşırı akademik baskı YOK, oyunlaştırılabilir, kültürel kapsayıcı. Amaç çocuğu performans makinesine çevirmek DEĞİL, dengeli desteklemek.

GELİŞİM ALANLARI (her plan mümkünse en az 3'ünü kapsasın): bilişsel (dikkat, hafıza, problem çözme, planlama),
dil (kelime, cümle, hikaye, okuma-anlama, çok dilli farkındalık), sosyal-duygusal (duygu tanıma, empati, sıra bekleme, öz düzenleme),
motor (kaba/ince motor, el-göz koordinasyonu), öz bakım & sorumluluk (giyinme, oyuncak toplama, çanta hazırlama, ev katkısı),
akademik (okuma, yazma, matematik, fen, araştırma), dijital yaşam (ekran dengesi, internet güvenliği, dijital nezaket).

ZORLUK: easy=kısa, çok ebeveyn desteği, tek adım. medium=orta bağımsızlık, 2–3 adım, hafif problem çözme. advanced=bağımsız, çok adım, planlama, çocuk kendini değerlendirir.

OYUNLAŞTIRMA: çok kolay 5p, normal 10p, zor 15p, haftalık tamamlanma 50 bonus. Rozet örnekleri: Yardım Kahramanı, Okuma Kaşifi,
Duygu Dedektifi, Matematik Ustası, Düzen Şampiyonu, Aile Takım Oyuncusu, Sorumluluk Lideri, Yaratıcı Zihin, Sabır Ustası.
Rozetler yaşa uygun; 14 yaşındakine bebeksi rozet verme.

SÜRE (ders): 3–4 yaş 5–10dk, 5–6 yaş 10–15dk, 7–8 yaş 15–20dk, 9–12 yaş 20–30dk, 13–18 yaş 30–45dk.
Günlük toplam süre kullanıcının available_time değerini ASLA aşmasın.

KİŞİSELLEŞTİRME: ilgi alanlarını görevlere yedir. Örn ilgi=dinozor ise matematik dinozor saymayla; ilgi=futbol ise sorumluluk "takım kaptanı" metaforuyla.

TON: Ebeveyne suçlayıcı olmayan, gerçekçi, aşırı pembe tablo çizmeyen, gerektiğinde net uyaran, sade açıklama.
Çocuğa kısa, net, motive edici, emir gibi değil oyun/görev gibi metin.

GÜVENLİK (KESİN): Çocuğu küçük düşüren/utandıran/cezalandırıcı dil YOK. Fiziksel ceza, bağırma, tehdit, korkutma ÖNERME.
Tıbbi/psikolojik/gelişimsel TANI KOYMA. Tehlikeli materyal, kesici alet, boğulma riski, yalnız dışarı çıkma önerme.
Yaşa uygun olmayan dijital/sosyal medya/yetişkin içeriği önerme. "Kesin problem var" gibi panik ifadesi kullanma.
Sadece gözlem ve genel destek öner; gecikme/kaygı/otizm/disleksi şüphesinde "çocuk doktoru/okul psikoloğu/pedagog ile görüşün" de.

BELÇİKA: çok dilli aile normaldir; tr/fr/nl/en geçişi doğaldır; dil karışımını otomatik problem sayma; evde en iyi bilinen dilde kaliteli iletişimi ve okul dili için kısa düzenli pratiği destekle.

DİL: çıktı istenen dilde (tr/en/fr/nl) DOĞAL ve lokalize olmalı, mekanik çeviri yapma. Dil belirtilmezse Türkçe.

KALİTE KONTROLÜ (yanıttan önce): yaşa uygun mu? süre gerçekçi mi? ebeveyn evde uygulayabilir mi? görev ölçülebilir mi?
çocuk için sıkıcı mı? dil doğal mı? tanı riski var mı? çok fazla görev mi yükledim? oyunlaştırma uygun mu? Geçmiyorsa düzelt.

ÇIKTI: Kullanıcı hangi JSON yapısını istediyse TAM O yapıda üret. YANIT HER ZAMAN GEÇERLİ JSON OLSUN; ek açıklama/markdown/kod bloğu EKLEME.
''';

  /// Haftalık gelişim planı üretir (7 gün).
  static Future<Map<String, dynamic>?> generateWeeklyPlan({
    required String childName,
    required int age,
    String language = 'tr',
    String focus = 'genel gelişim',
    String interests = '',
    int minutesPerDay = 20,
    String difficulty = 'easy',
    String? specialNotes,
  }) async {
    final prompt = '''
İçerik türü: weekly_plan
Çocuk: $childName, Yaş: $age, Dil: $language, Ülke: Belgium
Gelişim odağı: $focus
İlgi alanları: ${interests.isEmpty ? "belirtilmedi" : interests}
Günlük süre: $minutesPerDay dakika (AŞMA)
Zorluk: $difficulty
${specialNotes != null && specialNotes.isNotEmpty ? "Özel notlar: $specialNotes" : ""}

Şu JSON yapısında, 7 gün için üret (day İngilizce: Monday..Sunday):
{
  "type": "weekly_plan",
  "child_name": "$childName",
  "age_group": "",
  "language": "$language",
  "week_theme": "",
  "weekly_goal": "",
  "days": [
    {"day":"Monday","lesson":{"title":"","duration_minutes":0,"description":"","parent_role":""},
     "homework":{"title":"","duration_minutes":0,"description":""},
     "daily_task":{"title":"","duration_minutes":0,"description":"","points":0,"badge":""},
     "family_activity":"","reflection_question":""}
  ],
  "parent_checklist": [],
  "end_of_week_review": ""
}
Her gün toplam süre $minutesPerDay dakikayı geçmesin. İlgi alanlarını ($interests) görevlere yedir.
''';
    return _generateJson(prompt);
  }

  /// Yaşa göre gelişim planı üretir (bilişsel/dil/sosyal-duygusal/motor/öz bakım).
  static Future<Map<String, dynamic>?> generateDevelopmentPlan({
    required String childName,
    required int age,
    String language = 'tr',
    String focus = 'genel gelişim',
    String interests = '',
  }) async {
    final prompt = '''
İçerik türü: development_plan
Çocuk: $childName, Yaş: $age, Dil: $language, Odak: $focus, İlgi: $interests
Şu JSON yapısında üret:
{"type":"development_plan","age_group":"","child_name":"$childName","language":"$language","summary":"",
"main_goals":[],"development_areas":[
{"area":"cognitive","goal":"","activities":[],"parent_observation":""},
{"area":"language","goal":"","activities":[],"parent_observation":""},
{"area":"social_emotional","goal":"","activities":[],"parent_observation":""},
{"area":"motor","goal":"","activities":[],"parent_observation":""},
{"area":"self_care","goal":"","activities":[],"parent_observation":""}],
"weekly_routine":[],"recommended_parent_actions":[],"avoid":[],"progress_indicators":[]}
''';
    return _generateJson(prompt);
  }

  /// Tek bir çocuk görev kartı üretir (uygulama içi kart formatı).
  static Future<Map<String, dynamic>?> generateChildTask({
    required String childName,
    required int age,
    String language = 'tr',
    String category = 'sorumluluk',
    String interests = '',
    String difficulty = 'easy',
  }) async {
    final prompt = '''
İçerik türü: child_task kartı
Çocuk: $childName, Yaş: $age, Dil: $language, Kategori: $category, İlgi: $interests, Zorluk: $difficulty
Şu JSON yapısında üret:
{"card_type":"child_task","title":"","subtitle":"","age_group":"","duration":"","difficulty":"$difficulty",
"points":0,"badge":"","steps":[],"parent_tip":"","completion_question":""}
''';
    return _generateJson(prompt);
  }

  /// Ebeveyn rehberi üretir (bir konu hakkında).
  static Future<Map<String, dynamic>?> generateParentGuide({
    required String topic,
    required int age,
    String language = 'tr',
  }) async {
    final prompt = '''
İçerik türü: parent_guide
Konu: $topic, Çocuk yaşı: $age, Dil: $language
Şu JSON yapısında üret:
{"type":"parent_guide","topic":"$topic","age_group":"","short_explanation":"","what_to_do":[],
"what_to_avoid":[],"conversation_examples":[],"warning_signs":[],"when_to_seek_professional_help":"",
"weekly_parent_action":""}
''';
    return _generateJson(prompt);
  }

  static Future<Map<String, dynamic>?> _generateJson(String prompt) async {
    try {
      final res = await AIEngine.generate(
        prompt: prompt,
        systemPrompt: systemPrompt,
        format: AIResponseFormat.json,
        maxTokens: 3000,
        temperature: 0.5,
      );
      return parseJsonObject(res.content);
    } catch (_) {
      return null;
    }
  }

  /// Model çıktısındaki JSON nesnesini güvenle ayrıştırır.
  /// Markdown ``` fence'lerini, araya karışan düz metni ve baştaki/sondaki
  /// gürültüyü tolere eder — ilk `{` ile son `}` arasını alıp decode eder.
  /// Ayrıştırılamazsa null döner.
  @visibleForTesting
  static Map<String, dynamic>? parseJsonObject(String raw) {
    final trimmed = raw.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(trimmed.substring(start, end + 1));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
