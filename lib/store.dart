import 'dart:convert';
import 'dart:math' as math;
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
  bool _demoSeeded = false;

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
        _demoSeeded = j['demoSeededV1'] as bool? ?? false;
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

  /// 注入演示数据(虚构,仅一次)。
  /// 此前重复注入的设备会先按"完全相同记录"去重,再跳过注入。
  Future<void> seedDemoDataIfNeeded() async {
    if (_demoSeeded) return;
    // 1. 去重(修复重复注入产生的成对相同记录)
    final seen = <String>{};
    final before = _txns.length;
    _txns.retainWhere((t) {
      final k =
          '${t.bookId}|${t.type.index}|${t.categoryKey}|${t.amountCents}|${t.date}|${t.remark}';
      return seen.add(k);
    });
    final removedDup = _txns.length != before;
    // 2. 没有重复注入过的设备 → 首次注入
    if (!removedDup) {
      const expensePool = [
        'canyin',
        'canyin',
        'canyin',
        'jiaotong',
        'jiaotong',
        'gouwu',
        'shuiguo',
        'lingshi',
        'yule',
        'tongxun',
        'riyong',
        'kuaidi',
        'shucai',
        'meirong',
        'shuji',
        'yundong',
      ];
      const remarkByCat = {
        'canyin': ['午餐', '早餐', '晚餐', '咖啡'],
        'jiaotong': ['地铁', '打车'],
        'gouwu': ['超市'],
        'shuiguo': ['水果'],
        'lingshi': ['零食'],
        'yule': ['电影'],
        'tongxun': ['话费'],
        'riyong': ['超市'],
        'kuaidi': ['快递'],
        'shucai': ['买菜'],
        'meirong': ['理发'],
        'shuji': ['书'],
        'yundong': ['健身房'],
      };
      final rnd = math.Random(20260908);
      final bookId = books.first.id;
      final now = DateTime.now();

      for (var d = 130; d >= 0; d--) {
        final day = now.subtract(Duration(days: d));
        // 每月 1 号工资,15 号可能有一笔理财
        if (day.day == 1) {
          _addDemo(
            bookId,
            TxnType.income,
            'gongzi',
            800000,
            day,
            9,
            remark: '工资',
          );
        }
        if (day.day == 15 && rnd.nextDouble() < 0.5) {
          _addDemo(
            bookId,
            TxnType.income,
            'licai',
            (200 + rnd.nextInt(500)) * 100,
            day,
            18,
            remark: '理财收益',
          );
        }
        // 约七成日子有 1~3 笔日常支出
        if (rnd.nextDouble() < 0.72) {
          final n = 1 + rnd.nextInt(3);
          for (var i = 0; i < n; i++) {
            final cat = expensePool[rnd.nextInt(expensePool.length)];
            final remarks = remarkByCat[cat]!;
            final cents =
                (5 + rnd.nextDouble() * rnd.nextDouble() * 480).round() * 100 +
                rnd.nextInt(99);
            _addDemo(
              bookId,
              TxnType.expense,
              cat,
              cents,
              day,
              7 + rnd.nextInt(14),
              remark: rnd.nextDouble() < 0.6
                  ? remarks[rnd.nextInt(remarks.length)]
                  : '',
            );
          }
        }
      }
    }
    // 3. 内存标记 + 原子持久化(与数据同一次写入,不会再丢标记)
    _demoSeeded = true;
    _changed();
  }

  void _addDemo(
    String bookId,
    TxnType type,
    String cat,
    int cents,
    DateTime day,
    int hour, {
    String remark = '',
  }) {
    _txns.add(
      Txn(
        id: _genId('t'),
        bookId: bookId,
        type: type,
        categoryKey: cat,
        amountCents: cents,
        remark: remark,
        date: DateTime(
          day.year,
          day.month,
          day.day,
          hour,
          rndMinute(),
        ).millisecondsSinceEpoch,
      ),
    );
  }

  static int _rndMinuteSeed = 7;
  int rndMinute() => (_rndMinuteSeed = (_rndMinuteSeed * 13 + 17) % 60);

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
          'demoSeededV1': _demoSeeded,
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
