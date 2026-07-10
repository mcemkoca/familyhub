import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../domain/entities.dart';
import '../../../repositories/task_repository.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class AddTaskScreen extends StatefulWidget {
  final String childId;
  final String familyId;
  const AddTaskScreen({
    super.key,
    required this.childId,
    required this.familyId,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
  DateTime? _dueDate;
  bool _isLoading = false;
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  final List<({String label, String value, Color color})> _priorities = [
    (label: 'Düşük', value: 'low', color: Colors.green),
    (label: 'Orta', value: 'medium', color: Colors.orange),
    (label: 'Yüksek', value: 'high', color: Colors.red),
  ];

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showError('Görev başlığı gerekli');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = TaskRepository();
      await repo.createTask(
        Task(
          id: '',
          title: title,
          description: _descCtrl.text.trim(),
          assignedTo: widget.childId,
          priority: _priority,
          dueDate: _dueDate,
        ),
        widget.familyId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).gorevEklendi),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Görev eklenemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onError: (e) => _showError('Ses tanıma hatası: $e'),
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );

    if (!available) {
      _showError('Mikrofon izni verilmemiş');
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      localeId: 'tr_TR',
      onResult: (result) {
        setState(() {
          _titleCtrl.text = result.recognizedWords;
        });
      },
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context).yeniGorev),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Ekle',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(AppLocalizations.of(context).taskTitle,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).ornOdayiTopla,
                      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Açıklama
            const Text(
              'Açıklama (isteğe bağlı)',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).gorevHakkindaDetaylar,
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Öncelik
            Text(AppLocalizations.of(context).priority,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _priorities
                  .map(
                    (p) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _priority = p.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _priority == p.value
                                  ? p.color.withAlpha(30)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _priority == p.value
                                    ? p.color
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: p.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p.label,
                                  style: TextStyle(
                                    color: _priority == p.value
                                        ? p.color
                                        : const Color(0xFF9CA3AF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Son Tarih
            const Text(
              'Son Tarih (isteğe bağlı)',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF3B82F6),
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _dueDate = d);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate == null
                          ? 'Son tarih seç'
                          : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                      style: TextStyle(
                        color: _dueDate == null
                            ? const Color(0xFF6B7280)
                            : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF6B7280),
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Ana Buton
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(AppLocalizations.of(context).gorevEkle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
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
