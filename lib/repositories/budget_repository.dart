import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';

class BudgetRepository with RepositoryErrorHandler {
  static final BudgetRepository _instance = BudgetRepository._internal();
  factory BudgetRepository() => _instance;
  BudgetRepository._internal();
  final _client = SupabaseConfig.client;

  Future<String?> _getFamilyId() async {
    return handleRepositoryCall(() async {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final profile = await _client
          .from('profiles')
          .select('family_id')
          .eq('id', user.id)
          .maybeSingle();
      return profile?['family_id'] as String?;
    }, '_getFamilyId');
  }

  Future<List<Transaction>> getTransactions() async {
    String? familyId;
    try {
      familyId = await _getFamilyId();
    } catch (_) {
      familyId = null;
    }
    // Aile/oturum yoksa yerel (Hive) kayıtları döndür — çevrimdışı çalışsın.
    if (familyId == null) return HiveService.getTransactions();

    try {
      final response = await _client
          .from('budget_entries')
          .select('*')
          .eq('family_id', familyId)
          .order('date', ascending: false);
      final cloud = (response as List)
          .map((e) => _transactionFromJson(e as Map<String, dynamic>))
          .toList();
      // Yerel-only (senkronlanmamış) kayıtları da koru.
      final locals = HiveService.getTransactions()
          .where((t) => t.id.startsWith('local_'))
          .toList();
      final merged = [...locals, ...cloud];
      await HiveService.saveTransactions(merged);
      return merged;
    } catch (e) {
      debugPrint('getTransactions cloud failed, using local: $e');
      return HiveService.getTransactions();
    }
  }

  Future<Transaction> createTransaction({
    required double amount, // gelir + , gider -
    required String category,
    String? description,
    String? receiptUrl,
  }) async {
    final userId = AuthService.currentUserId;
    String? familyId;
    try {
      familyId = await _getFamilyId();
    } catch (_) {
      familyId = null;
    }

    Future<Transaction> saveLocal() async {
      final tx = Transaction(
        id: 'local_${const Uuid().v4()}',
        amount: amount.abs(),
        currency: 'EUR',
        type: amount >= 0 ? TransactionType.income : TransactionType.expense,
        category: category,
        description: description,
        createdBy: userId ?? '',
        createdAt: DateTime.now(),
        attachments: receiptUrl != null ? [receiptUrl] : const [],
      );
      final all = HiveService.getTransactions();
      await HiveService.saveTransactions([tx, ...all]);
      return tx;
    }

    if (familyId == null) return saveLocal();

    try {
      final response = await _client
          .from('budget_entries')
          .insert({
            'family_id': familyId,
            'created_by': userId,
            'amount': amount,
            'currency': 'EUR',
            'category': category,
            'description': description,
            'receipt_url': receiptUrl,
            'paid_by': userId,
            'date': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final created = _transactionFromJson(response);
      final all = HiveService.getTransactions();
      await HiveService.saveTransactions([created, ...all]);
      return created;
    } catch (e) {
      debugPrint('createTransaction cloud failed, saving local: $e');
      return saveLocal();
    }
  }

  Future<void> deleteTransaction(String id) async {
    // Her durumda yerel kayıttan da düş.
    Future<void> removeLocal() async {
      final all = HiveService.getTransactions();
      await HiveService.saveTransactions(
          all.where((t) => t.id != id).toList());
    }

    if (id.startsWith('local_')) {
      await removeLocal();
      return;
    }
    try {
      await _client.from('budget_entries').delete().eq('id', id);
    } catch (e) {
      debugPrint('deleteTransaction cloud failed: $e');
    }
    await removeLocal();
  }

  Future<Budget> getCurrentBudget() async {
    return handleRepositoryCall(() async {
      final familyId = await _getFamilyId();
      if (familyId == null) {
        return const Budget(
          id: '',
          totalAmount: 0,
          spentAmount: 0,
          periodStart: null,
          periodEnd: null,
        );
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final response = await _client
          .from('budget_entries')
          .select('amount')
          .eq('family_id', familyId)
          .gte('date', startOfMonth.toIso8601String())
          .lte('date', endOfMonth.toIso8601String());

      final entries = response as List;
      final totalIncome = entries
          .where((e) => ((e as Map<String, dynamic>)['amount'] as num) > 0)
          .fold<double>(0, (s, e) => s + ((e as Map<String, dynamic>)['amount'] as num).toDouble());
      final totalExpense = entries
          .where((e) => ((e as Map<String, dynamic>)['amount'] as num) < 0)
          .fold<double>(0, (s, e) => s + ((e as Map<String, dynamic>)['amount'] as num).toDouble().abs());

      // Default monthly budget: total income or 2500 EUR
      final budgetLimit = totalIncome > 0 ? totalIncome * 1.2 : 10000;

      return Budget(
        id: '${now.year}-${now.month}',
        totalAmount: budgetLimit.toDouble(),
        spentAmount: totalExpense.toDouble(),
        currency: 'EUR',
        periodStart: startOfMonth,
        periodEnd: endOfMonth,
      );
    }, 'getCurrentBudget');
  }

  Stream<List<Transaction>> watchTransactions() {
    try {
      return _client
          .from('budget_entries')
          .stream(primaryKey: ['id'])
          .map((data) => data.map((e) => _transactionFromJson(e)).toList());
    } catch (e) {
      debugPrint('BudgetRepository.watchTransactions error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watchTransactions]: $e'));
    }
  }

  Transaction _transactionFromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num).toDouble();
    return Transaction(
      id: json['id'] as String,
      amount: amount.abs(),
      currency: json['currency'] as String? ?? 'EUR',
      type: amount >= 0 ? TransactionType.income : TransactionType.expense,
      category: json['category'] as String? ?? 'Genel',
      description: json['description'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      attachments: json['receipt_url'] != null
          ? [json['receipt_url'] as String]
          : const [],
    );
  }
}
