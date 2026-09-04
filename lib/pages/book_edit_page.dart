import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../seed.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/book_cover.dart';
import '../widgets/eink_toggle.dart';
import '../widgets/hairline.dart';

/// 新建 / 编辑账本:名称、图标、类型(月度/事件)、月起始日、本位币。
class BookEditPage extends StatefulWidget {
  const BookEditPage({super.key, this.book});

  /// 为空表示新建
  final Book? book;

  @override
  State<BookEditPage> createState() => _BookEditPageState();
}

class _BookEditPageState extends State<BookEditPage> {
  late final bool _isNew = widget.book == null;
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.book?.name ?? '',
  );
  late final int _colorValue =
      widget.book?.colorValue ?? AppTheme.ink.toARGB32();
  late int _iconIndex = widget.book?.iconIndex ?? 0;
  late BookMode _mode = widget.book?.mode ?? BookMode.monthly;
  late int _monthStartDay = widget.book?.monthStartDay ?? 1;
  late String _currencyCode = widget.book?.currencyCode ?? 'CNY';

  String get _currencySymbol => currencies
      .firstWhere((c) => c.$1 == _currencyCode, orElse: () => currencies.first)
      .$2;

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_canSave) return;
    HapticFeedback.mediumImpact();
    final name = _nameCtrl.text.trim();
    if (_isNew) {
      final book = ledgerStore.addBook(
        name: name,
        colorValue: _colorValue,
        iconIndex: _iconIndex,
        mode: _mode,
        monthStartDay: _monthStartDay,
        currencyCode: _currencyCode,
        currencySymbol: _currencySymbol,
      );
      // 新建后自动切换过去,开箱即用
      ledgerStore.switchBook(book.id);
    } else {
      final b = widget.book!;
      b
        ..name = name
        ..colorValue = _colorValue
        ..iconIndex = _iconIndex
        ..mode = _mode
        ..monthStartDay = _monthStartDay
        ..currencyCode = _currencyCode
        ..currencySymbol = _currencySymbol;
      ledgerStore.updateBook(b);
    }
    Navigator.of(context).pop();
  }

  void _delete() {
    final count = ledgerStore.txnCountOf(widget.book!.id);
    showCupertinoDialog<void>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text('删除「${widget.book!.name}」?'),
        content: Text(count > 0 ? '账本中的 $count 条账单将一并删除,且无法恢复。' : '删除后无法恢复。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(c),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(c);
              HapticFeedback.mediumImpact();
              ledgerStore.deleteBook(widget.book!.id);
              Navigator.of(context).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _pickWheel({
    required List<String> items,
    required int initial,
    required ValueChanged<int> onSelected,
  }) {
    var temp = initial;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (c) => Container(
        height: 280,
        color: AppTheme.paper,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    CupertinoButton(
                      pressedOpacity: 0.5,
                      onPressed: () => Navigator.pop(c),
                      child: const Text('取消', style: AppTheme.body),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      pressedOpacity: 0.5,
                      onPressed: () {
                        onSelected(temp);
                        Navigator.pop(c);
                      },
                      child: const Text(
                        '完成',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Hairline(),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(
                    initialItem: initial,
                  ),
                  onSelectedItemChanged: (i) => temp = i,
                  children: [
                    for (final s in items)
                      Center(child: Text(s, style: AppTheme.body)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewBook = Book(
      id: 'preview',
      name: _nameCtrl.text.trim().isEmpty ? '账本名称' : _nameCtrl.text.trim(),
      colorValue: _colorValue,
      iconIndex: _iconIndex,
    );

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---- 顶部 ----
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    pressedOpacity: 0.5,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(_isNew ? '取消' : '返回', style: AppTheme.body),
                  ),
                  const Spacer(),
                  Text(
                    _isNew ? '新建账本' : '编辑账本',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _canSave ? _save : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '保存',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _canSave ? AppTheme.ink : AppTheme.inkWeak,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ---- 预览 ----
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: BookCover(
                          key: ValueKey(_iconIndex),
                          book: previewBook,
                          width: 76,
                          height: 88,
                          radius: 14,
                          iconSize: 34,
                        ),
                      ),
                    ),
                  ),
                  // ---- 名称 ----
                  const Text('名称', style: AppTheme.overline),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: _nameCtrl,
                    placeholder: '限 9 个汉字或 12 个字母',
                    placeholderStyle: AppTheme.body.copyWith(
                      color: AppTheme.inkWeak,
                    ),
                    style: AppTheme.body,
                    decoration: null,
                    maxLength: 12,
                    onChanged: (_) => setState(() {}),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  const Hairline(),
                  // ---- 图标 ----
                  const Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 10),
                    child: Text('图标', style: AppTheme.overline),
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < bookCoverIcons.length; i++)
                        GestureDetector(
                          onTap: () => setState(() => _iconIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _iconIndex == i
                                  ? AppTheme.paperDim
                                  : const Color(0x00000000),
                              border: Border.all(
                                color: _iconIndex == i
                                    ? AppTheme.ink
                                    : AppTheme.line,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              bookCoverIcons[i],
                              size: 19,
                              color: _iconIndex == i
                                  ? AppTheme.ink
                                  : AppTheme.inkSub,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // ---- 账本类型 ----
                  const Padding(
                    padding: EdgeInsets.only(top: 24, bottom: 10),
                    child: Text('账本类型', style: AppTheme.overline),
                  ),
                  EinkToggle<BookMode>(
                    options: const [
                      (BookMode.monthly, '月度账本'),
                      (BookMode.event, '事件账本'),
                    ],
                    groupValue: _mode,
                    onChanged: (v) => setState(() => _mode = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _mode == BookMode.monthly
                          ? '按月起始日划分账期,逐月翻看收支。'
                          : '一件事全程持续累计,与月份无关。适合旅行、装修、婚礼等。',
                      style: AppTheme.caption,
                    ),
                  ),
                  // ---- 基础信息 ----
                  const Padding(
                    padding: EdgeInsets.only(top: 24, bottom: 6),
                    child: Text('基础信息', style: AppTheme.overline),
                  ),
                  const Hairline(),
                  if (_mode == BookMode.monthly) ...[
                    _row(
                      '月起始日',
                      _monthStartDay == 1 ? '每月 1 号' : '每月 $_monthStartDay 号',
                      onTap: () => _pickWheel(
                        items: [for (var i = 1; i <= 28; i++) '每月 $i 号'],
                        initial: _monthStartDay - 1,
                        onSelected: (i) =>
                            setState(() => _monthStartDay = i + 1),
                      ),
                    ),
                    const Hairline(),
                  ],
                  _row(
                    '本位币',
                    '$_currencyCode $_currencySymbol',
                    onTap: () => _pickWheel(
                      items: [for (final c in currencies) '${c.$1} ${c.$2}'],
                      initial: currencies
                          .indexWhere((c) => c.$1 == _currencyCode)
                          .clamp(0, currencies.length - 1),
                      onSelected: (i) =>
                          setState(() => _currencyCode = currencies[i].$1),
                    ),
                  ),
                  const Hairline(),
                  // ---- 删除 ----
                  if (!_isNew && ledgerStore.books.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        pressedOpacity: 0.5,
                        onPressed: _delete,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.ink, width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '删除账本',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Text(label, style: AppTheme.body),
            const Spacer(),
            Text(value, style: AppTheme.mono(14, color: AppTheme.inkSub)),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 12,
              color: AppTheme.inkWeak,
            ),
          ],
        ),
      ),
    );
  }
}
