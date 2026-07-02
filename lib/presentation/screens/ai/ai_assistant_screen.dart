import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../services/ai/local_ai_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final List<_ChatEntry> _messages = [];
  bool _thinking = false;
  final _rng = Random();

  // Quick prompt chips
  static const _quickPrompts = [
    '🍽️ Akşam yemeği için tarif öner',
    '📅 Bu hafta ne pişireyim?',
    '💊 Aile sağlığı nasıl?',
    '🏠 Ev işleri nasıl dağıtılmalı?',
    '📱 Aboneliklerimi gözden geçir',
    '🎯 Çocuk gelişimi önerisi',
    '💰 Tasarruf ipuçları',
    '🛒 Alışveriş listesi öner',
  ];

  @override
  void initState() {
    super.initState();
    _addWelcome();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addWelcome() {
    _messages.add(_ChatEntry(
      isAI: true,
      text: 'Merhaba! Ben FamilyHub AI asistanınım. 👋\n\n'
          'Size yemek tarifleri, sağlık takibi, ev işleri, bütçe yönetimi ve daha fazlası hakkında yardımcı olabilirim.\n\n'
          'Ne konuşmak istersiniz?',
      time: DateTime.now(),
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(_ChatEntry(isAI: false, text: text.trim(), time: DateTime.now()));
      _thinking = true;
      _textController.clear();
    });

    _scrollToBottom();

    // Simulate AI thinking delay
    await Future.delayed(Duration(milliseconds: 600 + _rng.nextInt(800)));

    final response = await _generateResponse(text.trim());

    if (mounted) {
      setState(() {
        _thinking = false;
        _messages.add(_ChatEntry(isAI: true, text: response, time: DateTime.now()));
      });
      _scrollToBottom();
    }
  }

  Future<String> _generateResponse(String input) async {
    final lower = input.toLowerCase();

    // Recipe suggestions
    if (lower.contains('tarif') || lower.contains('yemek') || lower.contains('pişir') || lower.contains('akşam')) {
      final localAI = LocalAIService();
      final plan = await localAI.generateWeeklyPlan();
      final today = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][DateTime.now().weekday - 1];
      final recipe = plan[today];
      if (recipe != null) {
        final title = recipe['title'] ?? 'Lezzetli bir yemek';
        final time = recipe['cook_time'] ?? recipe['prep_time'] ?? 30;
        final ingredients = (recipe['ingredients'] as List?)?.take(5)
            .map((i) => '• ${i['name']} — ${i['amount']} ${i['unit']}')
            .join('\n') ?? '';
        return '🍽️ **$title** öneriyorum!\n\n'
            '⏱️ Pişirme süresi: $time dakika\n\n'
            '**Malzemeler:**\n$ingredients\n\n'
            'Mutfak ekranından tarifin tamamını görebilirsiniz. Afiyet olsun! 😊';
      }
      return _recipeFallback();
    }

    // Weekly meal plan
    if (lower.contains('hafta') && (lower.contains('yemek') || lower.contains('tarif') || lower.contains('plan'))) {
      final localAI = LocalAIService();
      final plan = await localAI.generateWeeklyPlan();
      final buffer = StringBuffer('📅 **Haftalık Yemek Planınız:**\n\n');
      for (final entry in plan.entries) {
        buffer.writeln('${entry.key}: ${entry.value['title'] ?? '-'}');
      }
      buffer.writeln('\nMutfak ekranında tariflerin detaylarına ulaşabilirsiniz!');
      return buffer.toString();
    }

    // Health advice
    if (lower.contains('sağlık') || lower.contains('ilaç') || lower.contains('vitamin') || lower.contains('doktor')) {
      return '💊 **Aile Sağlığı Önerileri:**\n\n'
          '• Günlük ilaçları sabah kahvaltıdan sonra alın\n'
          '• Vitamin takviyelerini doktor önerisiyle kullanın\n'
          '• Randevularınızı Sağlık ekranında takip edin\n'
          '• Çocukların aşı takvimini düzenli kontrol edin\n\n'
          'Sağlık ekranında her aile üyesi için ayrı takip yapabilirsiniz! 🏥';
    }

    // Home chores
    if (lower.contains('ev') || lower.contains('görev') || lower.contains('iş') || lower.contains('temizlik')) {
      final chores = ['Bulaşık', 'Çamaşır', 'Ütü', 'Süpürme', 'Silme', 'Banyo', 'Mutfak', 'Çöp'];
      chores.shuffle(_rng);
      final today = chores.take(3).join(', ');
      return '🏠 **Ev İşi Önerisi:**\n\n'
          'Bugün için önerilen görevler:\n'
          '• ${today.split(', ').join('\n• ')}\n\n'
          '💡 Görev rotasyonu için Akıllı Rotasyon ekranını kullanın. '
          'Aile üyeleri arasında adil dağılım yapılır!\n\n'
          '🏆 Haftalık liderboard ile motivasyonu yüksek tutun.';
    }

    // Budget & subscriptions
    if (lower.contains('bütçe') || lower.contains('para') || lower.contains('harcama') || lower.contains('tasarruf')) {
      return '💰 **Bütçe & Tasarruf Önerileri:**\n\n'
          '• Aylık aboneliklerinizi gözden geçirin — gereksiz olanları iptal edin\n'
          '• Market alışverişinizi listeyle yapın, spontan alım yapmayın\n'
          '• Enerji faturalarını azaltmak için gece saatlerini kullanın\n'
          '• Bütçe ekranında kategori bazlı harcamalarınızı takip edin\n\n'
          '📱 Abonelik ekranında hangi servislere ne kadar ödediğinizi görün!';
    }

    // Subscriptions
    if (lower.contains('abonelik') || lower.contains('netflix') || lower.contains('spotify')) {
      return '📱 **Abonelik Yönetimi:**\n\n'
          'Ortalama bir Türk ailesi aylık 300-800₺ abonelik öder!\n\n'
          '💡 Tasarruf İpuçları:\n'
          '• Kullanmadığınız platformları askıya alın\n'
          '• Aile planlarını tercih edin\n'
          '• Yıllık planlar aylık %20-40 daha ucuz\n\n'
          'Abonelik ekranında tüm harcamalarınızı bir arada görün!';
    }

    // Child development
    if (lower.contains('çocuk') || lower.contains('gelişim') || lower.contains('okul') || lower.contains('ödev')) {
      return '🌱 **Çocuk Gelişimi:**\n\n'
          '• WHO/AAP önerilerine göre gelişim takibi yapın\n'
          '• Ödev takibini düzenli tutun, küçük ödüller verin\n'
          '• Okul performansını haftalık gözden geçirin\n'
          '• Boy/kilo takibini Gelişim ekranına kaydedin\n\n'
          '📚 Eğitim ekranında yaşa uygun aktiviteler bulabilirsiniz!';
    }

    // Shopping list
    if (lower.contains('alışveriş') || lower.contains('market') || lower.contains('liste')) {
      final items = ['Domates', 'Soğan', 'Yumurta', 'Ekmek', 'Süt', 'Peynir', 'Tavuk', 'Makarna'];
      items.shuffle(_rng);
      return '🛒 **Temel Alışveriş Listesi:**\n\n'
          '${items.take(6).map((i) => '• $i').join('\n')}\n\n'
          '💡 Alışveriş listesi ekranında tüm aile üyeleri aynı anda ürün ekleyebilir!';
    }

    // Greetings
    if (lower.contains('merhaba') || lower.contains('selam') || lower.contains('nasılsın')) {
      return 'Merhaba! 👋 Bugün size nasıl yardımcı olabilirim?\n\n'
          '🍽️ Yemek tarifi arıyor musunuz?\n'
          '🏠 Ev işleri için yardım mı istiyorsunuz?\n'
          '💊 Sağlık takibi konusunda destek mi?\n'
          '💰 Bütçe önerileri mi?\n\n'
          'Yukarıdaki konulardan birini seçebilir veya başka bir şey sorabilirsiniz!';
    }

    // Generic daily suggestions
    final hour = DateTime.now().hour;
    if (hour < 10) {
      return '☀️ **Günaydın!**\n\n'
          'Bugün için önerilerim:\n'
          '• Kahvaltıyı atlamayın — en önemli öğün!\n'
          '• Çocukların okul çantasını kontrol edin\n'
          '• Bugünkü görevleri gözden geçirin\n\n'
          'Size nasıl yardımcı olabilirim?';
    } else if (hour < 18) {
      return '🌤️ **İyi Günler!**\n\n'
          'Öğleden sonra önerileri:\n'
          '• Öğle yemeğini kaçırmayın\n'
          '• Alışveriş listesini güncelleyin\n'
          '• Akşam yemeği için hazırlık yapın\n\n'
          'Başka nasıl yardımcı olabilirim?';
    } else {
      return '🌙 **İyi Akşamlar!**\n\n'
          'Akşam önerileri:\n'
          '• Akşam yemeği için tarif önerileri alın\n'
          '• Yarının planını hazırlayın\n'
          '• Aile ile birlikte zaman geçirin\n\n'
          'Ne konuşmak istersiniz?';
    }
  }

  String _recipeFallback() {
    final recipes = [
      ('🍲 Mercimek Çorbası', '30 dk', 'Kırmızı mercimek, soğan, havuç, tereyağı, kimyon'),
      ('🥘 Kuru Fasulye', '60 dk', 'Kuru fasulye, domates salçası, soğan, et'),
      ('🍳 Menemen', '15 dk', 'Yumurta, domates, biber, zeytinyağı'),
      ('🫕 İmam Bayıldı', '45 dk', 'Patlıcan, soğan, domates, zeytinyağı'),
      ('🍖 Köfte', '30 dk', 'Kıyma, soğan, galeta unu, baharatlar'),
    ];
    final r = recipes[_rng.nextInt(recipes.length)];
    return '${r.$1}\n\n⏱️ Süre: ${r.$2}\n🥗 Malzemeler: ${r.$3}\n\nMutfak ekranında detaylı tarife bakabilirsiniz!';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FamilyHub AI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
                Text(
                  'Akıllı Aile Asistanı',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcome();
              });
            },
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Yeni Sohbet',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) {
                  return _ThinkingBubble(isDark: isDark);
                }
                final entry = _messages[i];
                return _MessageBubble(entry: entry, isDark: isDark);
              },
            ),
          ),

          // Quick prompts (show only at first or when input is empty)
          if (_messages.length <= 2)
            _QuickPromptsRow(
              prompts: _quickPrompts,
              isDark: isDark,
              onSelect: _sendMessage,
            ),

          // Input bar
          _InputBar(
            controller: _textController,
            focusNode: _focusNode,
            isDark: isDark,
            onSend: () => _sendMessage(_textController.text),
          ),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatEntry entry;
  final bool isDark;
  const _MessageBubble({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: entry.isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (entry.isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: entry.isAI
                    ? (isDark ? AppColors.darkCard : Colors.white)
                    : const Color(0xFF667EEA),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: entry.isAI ? Radius.zero : const Radius.circular(16),
                  bottomRight: entry.isAI ? const Radius.circular(16) : Radius.zero,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                entry.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: entry.isAI
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.dark)
                      : Colors.white,
                ),
              ),
            ),
          ),
          if (!entry.isAI) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Thinking Bubble ─────────────────────────────────────────────────────────
class _ThinkingBubble extends StatefulWidget {
  final bool isDark;
  const _ThinkingBubble({required this.isDark});

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.psychology, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                width: 7, height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(
                    (_anim.value - (i * 0.15)).clamp(0.2, 1.0),
                  ),
                  shape: BoxShape.circle,
                ),
              )),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Quick Prompts ────────────────────────────────────────────────────────────
class _QuickPromptsRow extends StatelessWidget {
  final List<String> prompts;
  final bool isDark;
  final ValueChanged<String> onSelect;
  const _QuickPromptsRow({required this.prompts, required this.isDark, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onSelect(prompts[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF667EEA).withAlpha(80),
              ),
            ),
            child: Text(
              prompts[i],
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.focusNode, required this.isDark, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Bir şey sorun...',
                hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.slate),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────
class _ChatEntry {
  final bool isAI;
  final String text;
  final DateTime time;
  _ChatEntry({required this.isAI, required this.text, required this.time});
}
