import 'package:flutter/material.dart';

/// Sağlık makalesi modeli + 4 dilde (tr/nl/fr/en) statik içerik.
/// İçerik bilgilendirme amaçlıdır (teşhis koymaz). Çeviriler elle, kalite
/// gözetilerek hazırlanmıştır — naif makine çevirisi değildir.
class HealthArticle {
  final String id;
  final String category;
  final String categoryLabel;
  final Color categoryColor;
  final String title;
  final String summary;
  final String emoji;
  final String imageUrl;
  final String dateLabel;
  final List<String> body;
  const HealthArticle({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.categoryColor,
    required this.title,
    required this.summary,
    required this.emoji,
    required this.imageUrl,
    required this.dateLabel,
    required this.body,
  });
}

/// Aktif dile göre statik makale listesini döndürür (fallback: en → tr).
List<HealthArticle> healthArticlesFor(String lang) {
  switch (lang) {
    case 'nl':
      return _articlesNl;
    case 'fr':
      return _articlesFr;
    case 'en':
      return _articlesEn;
    case 'tr':
      return _articlesTr;
    default:
      return _articlesEn;
  }
}

// Ortak görsel URL'leri (dile bağlı değil).
const _imgImmunity =
    'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=500&q=60';
const _imgFever =
    'https://images.unsplash.com/photo-1584515933487-779824d29309?w=500&q=60';
const _imgMenstrual =
    'https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b?w=500&q=60';
const _imgVitaminD =
    'https://images.unsplash.com/photo-1550572017-edd951b55104?w=500&q=60';
const _imgSleep =
    'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=500&q=60';
const _imgNutrition =
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&q=60';

const _cGreen = Color(0xFF22C55E);
const _cBlue = Color(0xFF3B82F6);
const _cPink = Color(0xFFEC4899);
const _cAmber = Color(0xFFF59E0B);
const _cPurple = Color(0xFF8B5CF6);
const _cTeal = Color(0xFF14B8A6);

// ── Türkçe ──
const _articlesTr = <HealthArticle>[
  HealthArticle(
    id: 'immunity',
    category: 'aile',
    categoryLabel: 'Bağışıklık',
    categoryColor: _cGreen,
    emoji: '🥗',
    imageUrl: _imgImmunity,
    dateLabel: 'Bugün',
    title: 'Bağışıklık Sistemini Güçlendiren 10 Alışkanlık',
    summary: 'Günlük yaşamda uygulayabileceğiniz basit ama etkili yöntemler.',
    body: [
      'Bağışıklık sistemi, vücudun hastalıklara karşı ilk savunma hattıdır. Güçlü bir bağışıklık için günlük alışkanlıklar büyük fark yaratır.',
      '1) Renkli sebze ve meyve tüketin (C ve A vitamini).\n2) Günde 7-8 saat düzenli uyuyun.\n3) Düzenli fiziksel aktivite yapın.\n4) Yeterli su için.\n5) Stresi yönetin (nefes, mola).',
      '6) İşlenmiş şekeri azaltın.\n7) El hijyenine dikkat edin.\n8) Güneşten D vitamini alın.\n9) Probiyotik gıdalar tüketin.\n10) Sigara ve alkolden kaçının.',
      'Not: Bu içerik bilgilendirme amaçlıdır. Sağlık sorunlarında bir hekime danışın.',
    ],
  ),
  HealthArticle(
    id: 'child_fever',
    category: 'cocuk',
    categoryLabel: 'Çocuk Sağlığı',
    categoryColor: _cBlue,
    emoji: '🤒',
    imageUrl: _imgFever,
    dateLabel: 'Dün',
    title: 'Çocuklarda Ateş: Ne Zaman Endişelenmeli?',
    summary: 'Ateşin nedenleri, doğru ölçüm yöntemi ve ne zaman doktora.',
    body: [
      'Ateş, vücudun enfeksiyonla savaştığının bir işaretidir ve çoğu zaman zararsızdır. Önemli olan çocuğun genel durumunu izlemektir.',
      'Doğru ölçüm: Küçük çocuklarda koltuk altı veya kulaktan güvenilir termometre ile ölçün. 38°C üzeri ateş olarak kabul edilir.',
      'Doktora başvurun: 3 aydan küçük bebekte herhangi bir ateş, 39°C üzeri düşmeyen ateş, nefes güçlüğü, döküntü, aşırı halsizlik veya havale durumunda VAKIT KAYBETMEYİN.',
      'Bu içerik bilgilendirme amaçlıdır; teşhis koymaz. Endişe durumunda çocuk doktoruna danışın.',
    ],
  ),
  HealthArticle(
    id: 'menstrual',
    category: 'kadin',
    categoryLabel: 'Kadın Sağlığı',
    categoryColor: _cPink,
    emoji: '🌸',
    imageUrl: _imgMenstrual,
    dateLabel: '3 gün önce',
    title: 'Adet Döngüsü Hakkında Bilmeniz Gerekenler',
    summary:
        'Adet döngüsünün aşamaları, belirtiler ve dikkat edilmesi gerekenler.',
    body: [
      'Adet döngüsü ortalama 28 gündür ancak 21-35 gün arası normaldir. Döngü dört evreden oluşur: adet, foliküler, yumurtlama ve luteal.',
      'Yumurtlama genellikle döngünün 14. günü civarında olur ve en doğurgan dönemdir. Bu dönemi takip etmek planlama için faydalıdır.',
      'Düzensizlik, aşırı ağrı veya çok yoğun kanama varsa bir kadın hastalıkları uzmanına danışın.',
      'Bu içerik bilgilendirme amaçlıdır ve tıbbi tavsiye yerine geçmez.',
    ],
  ),
  HealthArticle(
    id: 'vitamin_d',
    category: 'aile',
    categoryLabel: 'Beslenme',
    categoryColor: _cAmber,
    emoji: '☀️',
    imageUrl: _imgVitaminD,
    dateLabel: '3 gün önce',
    title: 'D Vitamini Eksikliği Belirtileri',
    summary: 'Vücudunuzun D vitamini eksikliği sinyallerini nasıl anlarsınız?',
    body: [
      'D vitamini kemik sağlığı, bağışıklık ve kas fonksiyonu için gereklidir. Eksikliği yaygındır, özellikle güneşe az maruz kalanlarda.',
      'Belirtiler: sürekli yorgunluk, kemik/kas ağrısı, sık hastalanma, saç dökülmesi ve moral düşüklüğü olabilir.',
      'Öneriler: güneşten (günde 15-20 dk), yağlı balık, yumurta sarısı ve takviyelerden alınabilir. Takviyeden önce hekime danışın.',
      'Bu içerik bilgilendirme amaçlıdır. Kan testi ve tedavi için hekiminize başvurun.',
    ],
  ),
  HealthArticle(
    id: 'sleep',
    category: 'aile',
    categoryLabel: 'Uyku',
    categoryColor: _cPurple,
    emoji: '🌙',
    imageUrl: _imgSleep,
    dateLabel: '4 gün önce',
    title: 'Kaliteli Uyku İçin 7 İpucu',
    summary: 'Daha iyi uyumak ve dinç uyanmak için pratik öneriler.',
    body: [
      'Kaliteli uyku, fiziksel ve zihinsel sağlığın temelidir. Yetişkinler için günde 7-9 saat önerilir.',
      '1) Her gün aynı saatte yatıp kalkın.\n2) Yatmadan 1 saat önce ekranları bırakın.\n3) Odayı karanlık ve serin tutun.\n4) Akşam kafeini azaltın.',
      '5) Yatmadan ağır yemekten kaçının.\n6) Gün içinde hareketli olun.\n7) Rahatlatıcı bir rutin oluşturun (kitap, nefes).',
      'Uyku sorunları sürüyorsa bir uzmana danışın.',
    ],
  ),
  HealthArticle(
    id: 'child_nutrition',
    category: 'cocuk',
    categoryLabel: 'Çocuk Beslenmesi',
    categoryColor: _cTeal,
    emoji: '🍎',
    imageUrl: _imgNutrition,
    dateLabel: '5 gün önce',
    title: 'Çocuklarda Sağlıklı Beslenme Alışkanlıkları',
    summary: 'Seçici yiyen çocuklar için pratik ve dengeli beslenme önerileri.',
    body: [
      'Çocuklukta kazanılan beslenme alışkanlıkları ömür boyu sürer. Renkli ve çeşitli bir tabak sunmak önemlidir.',
      'Öneriler: öğünleri birlikte yiyin, yeni yiyecekleri baskı yapmadan tekrar tekrar sunun, şekerli atıştırmalıkları sınırlayın.',
      'Çocuğu yemeğe zorlamak ters etki yapabilir; örnek olun ve sabırlı olun.',
      'Büyüme/beslenme endişesinde çocuk doktoruna danışın.',
    ],
  ),
];

// ── Nederlands ──
const _articlesNl = <HealthArticle>[
  HealthArticle(
    id: 'immunity',
    category: 'aile',
    categoryLabel: 'Immuniteit',
    categoryColor: _cGreen,
    emoji: '🥗',
    imageUrl: _imgImmunity,
    dateLabel: 'Vandaag',
    title: '10 gewoonten die je immuunsysteem versterken',
    summary: 'Eenvoudige maar effectieve tips voor elke dag.',
    body: [
      'Het immuunsysteem is de eerste verdedigingslinie van het lichaam tegen ziekten. Dagelijkse gewoonten maken een groot verschil voor een sterke afweer.',
      '1) Eet kleurrijke groenten en fruit (vitamine C en A).\n2) Slaap 7-8 uur per nacht.\n3) Beweeg regelmatig.\n4) Drink voldoende water.\n5) Beheer stress (ademhaling, pauzes).',
      '6) Beperk bewerkte suiker.\n7) Let op handhygiëne.\n8) Haal vitamine D uit zonlicht.\n9) Eet probiotische voeding.\n10) Vermijd roken en alcohol.',
      'Let op: deze inhoud is louter informatief. Raadpleeg bij gezondheidsklachten een arts.',
    ],
  ),
  HealthArticle(
    id: 'child_fever',
    category: 'cocuk',
    categoryLabel: 'Kindergezondheid',
    categoryColor: _cBlue,
    emoji: '🤒',
    imageUrl: _imgFever,
    dateLabel: 'Gisteren',
    title: 'Koorts bij kinderen: wanneer maak je je zorgen?',
    summary: 'Oorzaken van koorts, correct meten en wanneer naar de dokter.',
    body: [
      'Koorts is een teken dat het lichaam een infectie bestrijdt en is meestal onschadelijk. Het belangrijkste is de algemene toestand van het kind in de gaten te houden.',
      'Correct meten: meet bij jonge kinderen onder de oksel of in het oor met een betrouwbare thermometer. Vanaf 38 °C spreken we van koorts.',
      'Raadpleeg een arts: WACHT NIET bij koorts bij een baby jonger dan 3 maanden, koorts boven 39 °C die niet zakt, ademhalingsmoeilijkheden, huiduitslag, extreme slapte of stuipen.',
      'Deze inhoud is informatief en stelt geen diagnose. Raadpleeg bij twijfel de kinderarts.',
    ],
  ),
  HealthArticle(
    id: 'menstrual',
    category: 'kadin',
    categoryLabel: 'Vrouwengezondheid',
    categoryColor: _cPink,
    emoji: '🌸',
    imageUrl: _imgMenstrual,
    dateLabel: '3 dagen geleden',
    title: 'Wat je moet weten over de menstruatiecyclus',
    summary: 'De fasen van de cyclus, symptomen en aandachtspunten.',
    body: [
      'De menstruatiecyclus duurt gemiddeld 28 dagen, maar 21-35 dagen is normaal. De cyclus bestaat uit vier fasen: menstruatie, folliculair, ovulatie en luteaal.',
      'De eisprong vindt meestal rond dag 14 plaats en is de meest vruchtbare periode. Deze periode volgen is nuttig voor planning.',
      'Raadpleeg een gynaecoloog bij onregelmatigheid, hevige pijn of zeer zwaar bloedverlies.',
      'Deze inhoud is informatief en vervangt geen medisch advies.',
    ],
  ),
  HealthArticle(
    id: 'vitamin_d',
    category: 'aile',
    categoryLabel: 'Voeding',
    categoryColor: _cAmber,
    emoji: '☀️',
    imageUrl: _imgVitaminD,
    dateLabel: '3 dagen geleden',
    title: 'Tekenen van een vitamine D-tekort',
    summary: 'Hoe herken je de signalen van een vitamine D-tekort?',
    body: [
      'Vitamine D is essentieel voor botten, immuniteit en spierfunctie. Een tekort komt vaak voor, vooral bij weinig blootstelling aan zon.',
      'Symptomen: aanhoudende vermoeidheid, bot-/spierpijn, vaak ziek zijn, haaruitval en een sombere stemming.',
      'Aanbevelingen: uit zonlicht (15-20 min per dag), vette vis, eigeel en supplementen. Raadpleeg een arts voor je supplementen neemt.',
      'Deze inhoud is informatief. Raadpleeg je arts voor een bloedtest en behandeling.',
    ],
  ),
  HealthArticle(
    id: 'sleep',
    category: 'aile',
    categoryLabel: 'Slaap',
    categoryColor: _cPurple,
    emoji: '🌙',
    imageUrl: _imgSleep,
    dateLabel: '4 dagen geleden',
    title: '7 tips voor een goede nachtrust',
    summary:
        'Praktische tips om beter te slapen en uitgerust wakker te worden.',
    body: [
      'Een goede nachtrust is de basis van je fysieke en mentale gezondheid. Voor volwassenen worden 7-9 uur per nacht aanbevolen.',
      '1) Ga elke dag op hetzelfde uur slapen en op.\n2) Leg schermen 1 uur voor het slapen weg.\n3) Houd de kamer donker en koel.\n4) Beperk cafeïne \'s avonds.',
      '5) Vermijd zware maaltijden voor het slapen.\n6) Beweeg overdag.\n7) Bouw een rustgevende routine op (lezen, ademhaling).',
      'Raadpleeg een specialist als de slaapproblemen aanhouden.',
    ],
  ),
  HealthArticle(
    id: 'child_nutrition',
    category: 'cocuk',
    categoryLabel: 'Kindervoeding',
    categoryColor: _cTeal,
    emoji: '🍎',
    imageUrl: _imgNutrition,
    dateLabel: '5 dagen geleden',
    title: 'Gezonde eetgewoonten bij kinderen',
    summary: 'Praktische, evenwichtige tips voor kieskeurige eters.',
    body: [
      'Eetgewoonten die je in de kindertijd aanleert, blijven een leven lang. Een kleurrijk en gevarieerd bord aanbieden is belangrijk.',
      'Tips: eet samen, bied nieuwe voeding zonder druk herhaaldelijk aan en beperk suikerrijke snacks.',
      'Een kind dwingen om te eten kan averechts werken; geef het goede voorbeeld en wees geduldig.',
      'Raadpleeg de kinderarts bij zorgen over groei of voeding.',
    ],
  ),
];

// ── Français ──
const _articlesFr = <HealthArticle>[
  HealthArticle(
    id: 'immunity',
    category: 'aile',
    categoryLabel: 'Immunité',
    categoryColor: _cGreen,
    emoji: '🥗',
    imageUrl: _imgImmunity,
    dateLabel: 'Aujourd\'hui',
    title: '10 habitudes qui renforcent le système immunitaire',
    summary: 'Des méthodes simples mais efficaces pour le quotidien.',
    body: [
      'Le système immunitaire est la première ligne de défense du corps contre les maladies. Des habitudes quotidiennes font une grande différence pour une bonne immunité.',
      '1) Mangez des fruits et légumes colorés (vitamines C et A).\n2) Dormez 7 à 8 heures par nuit.\n3) Pratiquez une activité physique régulière.\n4) Buvez suffisamment d\'eau.\n5) Gérez le stress (respiration, pauses).',
      '6) Réduisez le sucre transformé.\n7) Soignez l\'hygiène des mains.\n8) Prenez de la vitamine D au soleil.\n9) Consommez des aliments probiotiques.\n10) Évitez le tabac et l\'alcool.',
      'Remarque : ce contenu est informatif. En cas de problème de santé, consultez un médecin.',
    ],
  ),
  HealthArticle(
    id: 'child_fever',
    category: 'cocuk',
    categoryLabel: 'Santé de l\'enfant',
    categoryColor: _cBlue,
    emoji: '🤒',
    imageUrl: _imgFever,
    dateLabel: 'Hier',
    title: 'Fièvre chez l\'enfant : quand s\'inquiéter ?',
    summary: 'Causes de la fièvre, mesure correcte et quand consulter.',
    body: [
      'La fièvre est un signe que le corps combat une infection et elle est le plus souvent bénigne. L\'essentiel est de surveiller l\'état général de l\'enfant.',
      'Mesure correcte : chez le jeune enfant, mesurez sous l\'aisselle ou dans l\'oreille avec un thermomètre fiable. On parle de fièvre au-delà de 38 °C.',
      'Consultez un médecin : NE TARDEZ PAS en cas de fièvre chez un bébé de moins de 3 mois, de fièvre supérieure à 39 °C qui ne baisse pas, de difficultés respiratoires, d\'éruption cutanée, de grande faiblesse ou de convulsions.',
      'Ce contenu est informatif et ne pose pas de diagnostic. En cas de doute, consultez le pédiatre.',
    ],
  ),
  HealthArticle(
    id: 'menstrual',
    category: 'kadin',
    categoryLabel: 'Santé de la femme',
    categoryColor: _cPink,
    emoji: '🌸',
    imageUrl: _imgMenstrual,
    dateLabel: 'Il y a 3 jours',
    title: 'Ce qu\'il faut savoir sur le cycle menstruel',
    summary: 'Les phases du cycle, les symptômes et les points d\'attention.',
    body: [
      'Le cycle menstruel dure en moyenne 28 jours, mais 21 à 35 jours est normal. Le cycle comporte quatre phases : menstruation, folliculaire, ovulation et lutéale.',
      'L\'ovulation a généralement lieu vers le 14e jour du cycle et correspond à la période la plus fertile. Suivre cette période est utile pour la planification.',
      'Consultez un gynécologue en cas d\'irrégularité, de douleurs intenses ou de saignements très abondants.',
      'Ce contenu est informatif et ne remplace pas un avis médical.',
    ],
  ),
  HealthArticle(
    id: 'vitamin_d',
    category: 'aile',
    categoryLabel: 'Nutrition',
    categoryColor: _cAmber,
    emoji: '☀️',
    imageUrl: _imgVitaminD,
    dateLabel: 'Il y a 3 jours',
    title: 'Signes d\'une carence en vitamine D',
    summary: 'Comment reconnaître les signaux d\'une carence en vitamine D ?',
    body: [
      'La vitamine D est essentielle à la santé des os, à l\'immunité et à la fonction musculaire. La carence est fréquente, surtout en cas de faible exposition au soleil.',
      'Symptômes : fatigue persistante, douleurs osseuses/musculaires, infections fréquentes, chute de cheveux et baisse de moral.',
      'Recommandations : soleil (15-20 min par jour), poissons gras, jaune d\'œuf et compléments. Consultez un médecin avant toute supplémentation.',
      'Ce contenu est informatif. Consultez votre médecin pour une analyse de sang et un traitement.',
    ],
  ),
  HealthArticle(
    id: 'sleep',
    category: 'aile',
    categoryLabel: 'Sommeil',
    categoryColor: _cPurple,
    emoji: '🌙',
    imageUrl: _imgSleep,
    dateLabel: 'Il y a 4 jours',
    title: '7 conseils pour un sommeil de qualité',
    summary: 'Des conseils pratiques pour mieux dormir et se réveiller reposé.',
    body: [
      'Un sommeil de qualité est le fondement de la santé physique et mentale. On recommande 7 à 9 heures par nuit pour les adultes.',
      '1) Couchez-vous et levez-vous à la même heure.\n2) Éteignez les écrans 1 heure avant de dormir.\n3) Gardez la chambre sombre et fraîche.\n4) Réduisez la caféine le soir.',
      '5) Évitez les repas lourds avant de dormir.\n6) Bougez pendant la journée.\n7) Instaurez une routine apaisante (lecture, respiration).',
      'Consultez un spécialiste si les troubles du sommeil persistent.',
    ],
  ),
  HealthArticle(
    id: 'child_nutrition',
    category: 'cocuk',
    categoryLabel: 'Nutrition enfant',
    categoryColor: _cTeal,
    emoji: '🍎',
    imageUrl: _imgNutrition,
    dateLabel: 'Il y a 5 jours',
    title: 'De bonnes habitudes alimentaires chez l\'enfant',
    summary:
        'Des conseils pratiques et équilibrés pour les enfants difficiles.',
    body: [
      'Les habitudes alimentaires acquises dans l\'enfance durent toute la vie. Proposer une assiette colorée et variée est important.',
      'Conseils : mangez ensemble, proposez à nouveau les nouveaux aliments sans forcer et limitez les collations sucrées.',
      'Forcer un enfant à manger peut être contre-productif ; montrez l\'exemple et soyez patient.',
      'En cas d\'inquiétude sur la croissance ou l\'alimentation, consultez le pédiatre.',
    ],
  ),
];

// ── English ──
const _articlesEn = <HealthArticle>[
  HealthArticle(
    id: 'immunity',
    category: 'aile',
    categoryLabel: 'Immunity',
    categoryColor: _cGreen,
    emoji: '🥗',
    imageUrl: _imgImmunity,
    dateLabel: 'Today',
    title: '10 Habits That Strengthen Your Immune System',
    summary: 'Simple yet effective methods you can apply every day.',
    body: [
      'The immune system is the body\'s first line of defence against illness. Daily habits make a big difference to a strong immune system.',
      '1) Eat colourful fruit and vegetables (vitamins C and A).\n2) Sleep 7-8 hours a night.\n3) Exercise regularly.\n4) Drink enough water.\n5) Manage stress (breathing, breaks).',
      '6) Cut back on processed sugar.\n7) Mind your hand hygiene.\n8) Get vitamin D from sunlight.\n9) Eat probiotic foods.\n10) Avoid smoking and alcohol.',
      'Note: this content is informational only. Consult a doctor for any health concerns.',
    ],
  ),
  HealthArticle(
    id: 'child_fever',
    category: 'cocuk',
    categoryLabel: 'Child Health',
    categoryColor: _cBlue,
    emoji: '🤒',
    imageUrl: _imgFever,
    dateLabel: 'Yesterday',
    title: 'Fever in Children: When to Worry?',
    summary:
        'Causes of fever, how to measure it correctly and when to see a doctor.',
    body: [
      'Fever is a sign that the body is fighting an infection and is usually harmless. What matters most is monitoring the child\'s general condition.',
      'Correct measurement: in young children, measure under the arm or in the ear with a reliable thermometer. Above 38 °C is considered a fever.',
      'See a doctor: DO NOT DELAY with any fever in a baby under 3 months, a fever above 39 °C that won\'t come down, breathing difficulty, a rash, extreme weakness or convulsions.',
      'This content is informational and does not diagnose. If worried, consult a paediatrician.',
    ],
  ),
  HealthArticle(
    id: 'menstrual',
    category: 'kadin',
    categoryLabel: 'Women\'s Health',
    categoryColor: _cPink,
    emoji: '🌸',
    imageUrl: _imgMenstrual,
    dateLabel: '3 days ago',
    title: 'What You Need to Know About the Menstrual Cycle',
    summary: 'The phases of the cycle, symptoms and things to watch for.',
    body: [
      'The menstrual cycle averages 28 days, but 21-35 days is normal. The cycle has four phases: menstruation, follicular, ovulation and luteal.',
      'Ovulation usually occurs around day 14 of the cycle and is the most fertile period. Tracking this window is useful for planning.',
      'See a gynaecologist if you have irregularity, severe pain or very heavy bleeding.',
      'This content is informational and does not replace medical advice.',
    ],
  ),
  HealthArticle(
    id: 'vitamin_d',
    category: 'aile',
    categoryLabel: 'Nutrition',
    categoryColor: _cAmber,
    emoji: '☀️',
    imageUrl: _imgVitaminD,
    dateLabel: '3 days ago',
    title: 'Signs of Vitamin D Deficiency',
    summary: 'How to recognise the signals of a vitamin D deficiency.',
    body: [
      'Vitamin D is essential for bone health, immunity and muscle function. Deficiency is common, especially with little sun exposure.',
      'Symptoms: constant tiredness, bone/muscle pain, getting ill often, hair loss and low mood.',
      'Recommendations: from sunlight (15-20 min a day), oily fish, egg yolk and supplements. Consult a doctor before taking supplements.',
      'This content is informational. See your doctor for a blood test and treatment.',
    ],
  ),
  HealthArticle(
    id: 'sleep',
    category: 'aile',
    categoryLabel: 'Sleep',
    categoryColor: _cPurple,
    emoji: '🌙',
    imageUrl: _imgSleep,
    dateLabel: '4 days ago',
    title: '7 Tips for Quality Sleep',
    summary: 'Practical tips to sleep better and wake up refreshed.',
    body: [
      'Quality sleep is the foundation of physical and mental health. Adults are advised to get 7-9 hours a night.',
      '1) Go to bed and get up at the same time daily.\n2) Put screens away 1 hour before bed.\n3) Keep the room dark and cool.\n4) Reduce caffeine in the evening.',
      '5) Avoid heavy meals before bed.\n6) Stay active during the day.\n7) Build a calming routine (reading, breathing).',
      'If sleep problems persist, consult a specialist.',
    ],
  ),
  HealthArticle(
    id: 'child_nutrition',
    category: 'cocuk',
    categoryLabel: 'Child Nutrition',
    categoryColor: _cTeal,
    emoji: '🍎',
    imageUrl: _imgNutrition,
    dateLabel: '5 days ago',
    title: 'Healthy Eating Habits in Children',
    summary: 'Practical, balanced nutrition tips for picky eaters.',
    body: [
      'Eating habits built in childhood last a lifetime. Offering a colourful and varied plate is important.',
      'Tips: eat together, offer new foods again and again without pressure, and limit sugary snacks.',
      'Forcing a child to eat can backfire; set an example and be patient.',
      'If you are worried about growth or nutrition, consult a paediatrician.',
    ],
  ),
];
