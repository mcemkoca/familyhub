import 'package:flutter/material.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  final _expanded = <int>{};

  final _guides = const [
    {
      'icon': Icons.home_outlined,
      'color': 0xFF2563EB,
      'title': 'Hub\'ı Keşfedin',
      'desc': 'Aile aktiviteleri, hava durumu ve hızlı erişim kartları.',
      'steps': [
        'Ana ekranda (Hub) ailenizin günlük özeti görünür.',
        'Sağ üstteki hava durumu chip\'i anlık sıcaklığı gösterir. Konum izni verirseniz yerel hava durumunu çeker.',
        'Aile üyeleri satırında herkesin profil avatarı ve çevrimiçi durumu görünür. Yeni üye eklemek için "+ Ekle" butonuna dokunun.',
        'Görevler, Streak, Takvim ve Bütçe kartlarına dokunarak ilgili ekrana hızlıca gidebilirsiniz.',
        'Alt kısımdaki "Son Aktiviteler" bölümünde ailedeki son hareketleri (görev tamamlama, etkinlik ekleme vb.) görürsünüz.',
      ],
    },
    {
      'icon': Icons.calendar_today_outlined,
      'color': 0xFF10B981,
      'title': 'Etkinlik Oluşturma',
      'desc': 'Takvimde etkinlik ekleyin, hatırlatıcılar ayarlayın.',
      'steps': [
        'Alt menüden "Plan" sekmesine veya Hub\'daki Takvim kartına dokunun.',
        'Sağ alttaki "+" butonuna basarak yeni etkinlik ekleyin.',
        'Etkinlik başlığı, tarih/saat, konum ve açıklama girin.',
        'Kategori seçin (Doğum Günü, Doktor, Tatil, Spor vb.).',
        'Tekrar seçeneği ile haftalık/aylık/yıllık tekrarlayan etkinlikler oluşturabilirsiniz.',
        'Hatırlatıcı ayarlayın: 15 dk, 1 saat, 1 gün önce bildirim alabilirsiniz.',
        'Katılımcıları ekleyerek etkinliği aile üyelerine atayın.',
        'Görünüm modlarını (Ay, Hafta, Gün, Liste) değiştirmek için takvimin üstündeki sekmeleri kullanın.',
      ],
    },
    {
      'icon': Icons.task_alt_outlined,
      'color': 0xFFF59E0B,
      'title': 'Görev Atama',
      'desc': 'Aile üyelerine görev atayın ve ilerlemeyi takip edin.',
      'steps': [
        'Hub\'daki "Görevler" kartına veya merkez menüden "Görevler"\'e gidin.',
        'Yeni görev oluşturmak için "+" butonuna basın.',
        'Görev başlığı, açıklama, son tarih ve öncelik (Düşük/Orta/Yüksek) seçin.',
        'Görevi bir aile üyesine atayın. Atanan kişiye bildirim gider.',
        'Görev tamamlandığında yanındaki kutucuğa dokunarak işaretleyin.',
        'Tamamlanan görevler otomatik olarak "Tamamlandı" bölümüne taşınır.',
        'Streak sistemi sayesinde her gün görev tamamlayarak seri oluşturabilirsiniz.',
      ],
    },
    {
      'icon': Icons.chat_bubble_outline,
      'color': 0xFF8B5CF6,
      'title': 'Sohbet ve Duyurular',
      'desc': 'Grup sohbeti, duyurular ve duygu paylaşımı.',
      'steps': [
        'Alt menüden "Sohbet" sekmesine dokunun.',
        'Aile grubunda metin mesajları, fotoğraflar ve sesli mesajlar gönderebilirsiniz.',
        'Bir mesaja uzun basarak tepki (emoji) ekleyebilir veya yanıtlayabilirsiniz.',
        'Duyuru oluşturmak için mesaj kutusunun yanındaki megafon simgesine dokunun.',
        'Duyurular tüm aile üyelerine yüksek öncelikli bildirim olarak gider.',
        'Duygu paylaşımı yapmak için mesaj kutusundaki kalp simgesine basın; günlük ruh halinizi aileye bildirin.',
        'Önemli mesajları sabitlemek için üzerine uzun basıp "Sabitle" seçeneğini kullanın.',
      ],
    },
    {
      'icon': Icons.shield_outlined,
      'color': 0xFFEF4444,
      'title': 'Güvenlik Özellikleri',
      'desc': 'SOS butonu, konum paylaşımı ve acil durum kartı.',
      'steps': [
        'Alt menüden "Güvenlik" sekmesine dokunun.',
        'SOS butonu: Acil durumda büyük kırmızı butona basarak anında konumunuzu ve acil durum mesajınızı aile üyelerine gönderin.',
        'SOS tetiklendiğinde otomatik olarak 112 (Acil Çağrı) aranır.',
        'Güvenli bölge ayarlayın: Haritada ev, okul veya işaretli alanlar belirleyin. Üye bu alanlara giriş/çıkış yaptığında bildirim alırsınız.',
        'Canlı konum paylaşımı: Aile üyelerinizin anlık konumunu haritada görün.',
        'Acil durum kartı: Her aile üyesinin kan grubu, alerjileri ve acil iletişim bilgilerini saklayın.',
        'Sağlık kartına bilgi eklemek için üye profiline gidin ve "Sağlık Bilgileri" bölümünü düzenleyin.',
      ],
    },
    {
      'icon': Icons.photo_library_outlined,
      'color': 0xFFEC4899,
      'title': 'Anılar ve Albümler',
      'desc': 'Fotoğraf yükleyin, büyüme takibi yapın.',
      'steps': [
        'Alt menüden "Anılar" sekmesine veya Hub menüsünden "Albümler"\'e gidin.',
        'Yeni albüm oluşturmak için "+ Albüm" butonuna basın. Tatil, Doğum Günü, Okul gibi kategoriler seçebilirsiniz.',
        'Albüme fotoğraf eklemek için "Fotoğraf Ekle" butonuna basın. Galeriden veya kameradan seçim yapabilirsiniz.',
        'Fotoğrafa dokunarak büyütün, kaydedin veya paylaşın.',
        'Büyüme takibi: Çocuk üyeleri için boy/kilo verisi girerek gelişim grafiği oluşturun.',
        'Milestone (önemli an) ekleyin: İlk diş, ilk adım, ilk kelime gibi anıları tarihleriyle birlikte kaydedin.',
        'Premium üyeler sınırsız fotoğraf depolama ve 4K video yükleme yapabilir.',
      ],
    },
  ];

  void _toggle(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF0A0A0F);

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: 'Kullanım Kılavuzu',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _guides.length,
        itemBuilder: (context, index) {
          final g = _guides[index];
          final color = Color(g['color'] as int);
          final isOpen = _expanded.contains(index);
          final steps = g['steps'] as List<String>;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _toggle(index),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            g['icon'] as IconData,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g['title'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                g['desc'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: isOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: isDark
                                ? const Color(0x1EFFFFFF)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 16, left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: steps.asMap().entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(40),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${e.key + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: isDark
                                            ? const Color(0xFF6B7280)
                                            : const Color(0xFFE5E7EB).withAlpha(200),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      crossFadeState: isOpen
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
