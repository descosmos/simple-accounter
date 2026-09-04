import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'seed.dart';
import 'utils.dart';

/// 全局账本数据中心。
///
/// 所有页面共享同一实例,变更通过 [ChangeNotifier] 广播;
/// 每次变更后立即落盘(单 JSON 文件,原子写入)。
final ledgerStore = LedgerStore();

class PeriodSummary {
  const PeriodSummary(this.expenseCents, this.incomeCents);
  final int expenseCents;
  final int incomeCents;
  int get balanceCents => incomeCents - expenseCents;
}

class LedgerStore extends ChangeNotifier {
  bool loaded = false;

  final List<Book> books = [];
  final List<Txn> _txns = [];
  final List<Category> _customCategories = [];
  String _currentBookId = '';

  int _idCounter = 0;
  String _genId(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  // ---------- 读取 ----------

  Book get currentBook {
    if (books.isEmpty) {
      throw StateError('store not loaded');
    }
    return books.firstWhere(
      (b) => b.id == _currentBookId,
      orElse: () => books.first,
    );
  }

  String get currentBookId => currentBook.id;

  List<Txn> get txns => List.unmodifiable(_txns);

  List<Category> categoriesOf(TxnType type) => [
    ...seedCategories.where((c) => c.type == type),
    ..._customCategories.where((c) => c.type == type),
  ];

  Category categoryOf(String key) {
    for (final c in seedCategories) {
      if (c.key == key) return c;
    }
    for (final c in _customCategories) {
      if (c.key == key) return c;
    }
    return seedCategories.firstWhere((c) => c.key == 'qita');
  }

  int txnCountOf(String bookId) =>
      _txns.where((t) => t.bookId == bookId).length;

  List<Txn> _sorted(Iterable<Txn> src) {
    return src.toList()..sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
    });
  }

  /// 指定账期的账单,按日期/创建时间倒序
  List<Txn> txnsInPeriod(String bookId, Period p) {
    return _sorted(
      _txns.where((t) {
        if (t.bookId != bookId) return false;
        return p.contains(t.day);
      }),
    );
  }

  /// 事件账本:全部账单,与账期无关
  List<Txn> txnsAll(String bookId) =>
      _sorted(_txns.where((t) => t.bookId == bookId));

  PeriodSummary summaryInPeriod(String bookId, Period p) {
    var exp = 0, inc = 0;
    for (final t in _txns) {
      if (t.bookId != bookId || !p.contains(t.day)) continue;
      if (t.type == TxnType.expense) {
        exp += t.amountCents;
      } else {
        inc += t.amountCents;
      }
    }
    return PeriodSummary(exp, inc);
  }

  /// 事件账本:累计收支
  PeriodSummary summaryAll(String bookId) {
    var exp = 0, inc = 0;
    for (final t in _txns) {
      if (t.bookId != bookId) continue;
      if (t.type == TxnType.expense) {
        exp += t.amountCents;
      } else {
        inc += t.amountCents;
      }
    }
    return PeriodSummary(exp, inc);
  }

  /// 按日分组(组内保持倒序);period 为 null 时不限账期(事件账本)
  Map<DateTime, List<Txn>> dayGroups(String bookId, [Period? p]) {
    final map = <DateTime, List<Txn>>{};
    final src = p == null ? txnsAll(bookId) : txnsInPeriod(bookId, p);
    for (final t in src) {
      final d = DateTime(t.day.year, t.day.month, t.day.day);
      map.putIfAbsent(d, () => []).add(t);
    }
    return map;
  }

  // ---------- 变更 ----------

  void switchBook(String id) {
    if (_currentBookId == id) return;
    _currentBookId = id;
    _changed();
  }

  Book addBook({
    required String name,
    required int colorValue,
    required int iconIndex,
    BookMode mode = BookMode.monthly,
    int monthStartDay = 1,
    String currencyCode = 'CNY',
    String currencySymbol = '¥',
  }) {
    final book = Book(
      id: _genId('b'),
      name: name,
      colorValue: colorValue,
      iconIndex: iconIndex,
      mode: mode,
      monthStartDay: monthStartDay,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
    books.add(book);
    _changed();
    return book;
  }

  void updateBook(Book book) => _changed();

  /// 删除账本及其全部账单;若删除的是当前账本则切到第一个。
  void deleteBook(String id) {
    if (books.length <= 1) return;
    books.removeWhere((b) => b.id == id);
    _txns.removeWhere((t) => t.bookId == id);
    if (_currentBookId == id) _currentBookId = books.first.id;
    _changed();
  }

  void addTxn(Txn txn) {
    _txns.add(txn);
    _changed();
  }

  Txn createTxn({
    required String bookId,
    required TxnType type,
    required String categoryKey,
    required int amountCents,
    String remark = '',
    required DateTime date,
  }) {
    final txn = Txn(
      id: _genId('t'),
      bookId: bookId,
      type: type,
      categoryKey: categoryKey,
      amountCents: amountCents,
      remark: remark,
      // 当天记的账保留具体时分;补记其他日期只保留到天
      date:
          (isSameDay(date, DateTime.now())
                  ? DateTime.now()
                  : DateTime(date.year, date.month, date.day))
              .millisecondsSinceEpoch,
    );
    _txns.add(txn);
    _changed();
    return txn;
  }

  void deleteTxn(String id) {
    _txns.removeWhere((t) => t.id == id);
    _changed();
  }

  Category addCustomCategory({
    required String title,
    required TxnType type,
    required int colorValue,
  }) {
    final c = Category(
      key: _genId('custom_'),
      title: title,
      type: type,
      colorValue: colorValue,
      isCustom: true,
    );
    _customCategories.add(c);
    _changed();
    return c;
  }

  void updateCustomCategory(Category c) => _changed();

  void deleteCustomCategory(String key) {
    _customCategories.removeWhere((c) => c.key == key);
    _changed();
  }

  // ---------- 持久化 ----------

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/simple_ledger.json');
  }

  Future<void> load() async {
    try {
      final f = await _file();
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        books
          ..clear()
          ..addAll(
            (j['books'] as List).map(
              (e) => Book.fromJson(e as Map<String, dynamic>),
            ),
          );
        _txns
          ..clear()
          ..addAll(
            (j['txns'] as List).map(
              (e) => Txn.fromJson(e as Map<String, dynamic>),
            ),
          );
        _customCategories
          ..clear()
          ..addAll(
            (j['customCategories'] as List? ?? []).map(
              (e) => Category.fromJson(e as Map<String, dynamic>),
            ),
          );
        _currentBookId = j['currentBookId'] as String? ?? '';
      }
    } catch (_) {
      // 数据损坏时回退到初始状态
    }
    if (books.isEmpty) {
      final book = Book(
        id: _genId('b'),
        name: '默认账本',
        colorValue: CupertinoColors.systemBlue.toARGB32(),
        iconIndex: 0,
      );
      books.add(book);
      _currentBookId = book.id;
      await _persist();
    }
    if (!books.any((b) => b.id == _currentBookId)) {
      _currentBookId = books.first.id;
    }
    loaded = true;
    notifyListeners();
  }

  void _changed() {
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final f = await _file();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(
        jsonEncode({
          'version': 1,
          'currentBookId': _currentBookId,
          'books': books.map((b) => b.toJson()).toList(),
          'txns': _txns.map((t) => t.toJson()).toList(),
          'customCategories': _customCategories.map((c) => c.toJson()).toList(),
        }),
      );
      await tmp.rename(f.path);
    } catch (_) {
      // 忽略单次写入失败,下次变更会重试
    }
  }
}
