import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/calc_keyboard.dart';
import '../widgets/category_avatar.dart';
import '../widgets/eink_toggle.dart';
import '../widgets/hairline.dart';
import 'book_switcher.dart';

/// 记一笔:超大金额数字为唯一视觉焦点,三步以内完成记录。
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  TxnType _type = TxnType.expense;
  late String _categoryKey = ledgerStore.categoriesOf(_type).first.key;
  String _expr = '';
  DateTime _date = DateTime.now();
  final _remarkCtrl = TextEditingController();
  final _remarkFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // 备注输入框获得焦点(系统键盘弹出)时隐藏自带键盘,避免布局溢出。
    // 用焦点而非 viewInsets 判断:部分机型 IME 弹出时 viewInsets 不变。
    _remarkFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    _remarkFocus.dispose();
    super.dispose();
  }

  // ---------- 表达式 ----------

  String get _currentSegment {
    final i = _expr.lastIndexOf(RegExp(r'[+\-]'));
    return i < 0 ? _expr : _expr.substring(i + 1);
  }

  void _append(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      if (k == '+' || k == '-') {
        if (_expr.isEmpty ||
            _expr.endsWith('.') ||
            _expr.endsWith('+') ||
            _expr.endsWith('-')) {
          return;
        }
        if ('+-'.allMatches(_expr).length >= 7) return;
        _expr += k;
        return;
      }
      final seg = _currentSegment;
      if (k == '.') {
        if (seg.contains('.')) return;
        if (seg.isEmpty) {
          _expr += '0.';
          return;
        }
      } else {
        if (seg == '0') {
          _expr = _expr.substring(0, _expr.length - 1) + k;
          return;
        }
        final dot = seg.indexOf('.');
        if (dot >= 0 && seg.length - dot - 1 >= 2) return;
        if (seg.replaceAll('.', '').length >= 9) return;
      }
      _expr += k;
    });
  }

  void _delete() {
    if (_expr.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _expr = _expr.substring(0, _expr.length - 1));
  }

  double? get _result => evalAmountExpr(_expr);

  bool get _hasOp => _expr.contains('+') || _expr.contains('-');

  // ---------- 保存 ----------

  void _save() {
    final amount = _result;
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      showCupertinoDialog<void>(
        context: context,
        builder: (c) => CupertinoAlertDialog(
          title: const Text('请输入正确的金额'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(c),
              child: const Text('好'),
            ),
          ],
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    ledgerStore.createTxn(
      bookId: ledgerStore.currentBookId,
      type: _type,
      categoryKey: _categoryKey,
      amountCents: (amount * 100).round(),
      remark: _remarkCtrl.text.trim(),
      date: _date,
    );
    Navigator.of(context).pop();
  }

  // ---------- 日期 ----------

  void _pickDate() {
    final now = DateTime.now();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (c) => Container(
        height: 280,
        color: AppTheme.paper,
        child: SafeArea(
          top: false,
          child: CupertinoTheme(
            data: const CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  fontSize: 18,
                  color: AppTheme.ink,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              dateOrder: DatePickerDateOrder.ymd,
              initialDateTime: _date,
              minimumYear: now.year - 10,
              maximumYear: now.year + 5,
              onDateTimeChanged: (d) => setState(() => _date = d),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.paper,
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          // 点备注以外的区域即收起系统键盘,回到金额输入
          onTap: () => _remarkFocus.unfocus(),
          child: ListenableBuilder(
            listenable: ledgerStore,
            builder: (context, _) => Column(
              children: [
                // 上半部分整体可滚:页面推入动画/键盘切换的过渡帧高度
                // 很小时也能自适应,不会 RenderFlex 溢出
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // ---- 顶部:取消 / 记一笔 / 日期 ----
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
                          child: Row(
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                pressedOpacity: 0.5,
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('取消', style: AppTheme.body),
                              ),
                              const Spacer(),
                              const Text(
                                '记一笔',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Text(
                                  '${_date.month}月${_date.day}日',
                                  style: AppTheme.mono(
                                    14,
                                    color: AppTheme.inkSub,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ---- 金额(唯一视觉焦点) ----
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    ledgerStore.currentBook.currencySymbol,
                                    style: AppTheme.dots(
                                      22,
                                      color: AppTheme.inkSub,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _expr.isEmpty ? '0' : _expr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.dots(
                                        50,
                                        color: _expr.isEmpty
                                            ? AppTheme.inkWeak
                                            : AppTheme.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 18,
                                child: _hasOp && _result != null
                                    ? Text(
                                        '= ${_result!.toStringAsFixed(2)}',
                                        style: AppTheme.mono(
                                          14,
                                          color: AppTheme.accent,
                                          weight: FontWeight.w500,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        // ---- 支出/收入 拨杆 ----
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 60),
                          child: EinkToggle<TxnType>(
                            options: const [
                              (TxnType.expense, '支出'),
                              (TxnType.income, '收入'),
                            ],
                            groupValue: _type,
                            onChanged: (v) => setState(() {
                              _type = v;
                              _categoryKey = ledgerStore
                                  .categoriesOf(v)
                                  .first
                                  .key;
                            }),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ---- 分类宫格(固定高度带,内部可滚) ----
                        SizedBox(height: 192, child: _buildGrid()),
                        // ---- 账本 / 日期 / 备注 ----
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Hairline(),
                        ),
                        _listRow(
                          '账本',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ledgerStore.currentBook.name,
                                style: AppTheme.mono(
                                  14,
                                  color: AppTheme.inkSub,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                CupertinoIcons.chevron_down,
                                size: 10,
                                color: AppTheme.inkWeak,
                              ),
                            ],
                          ),
                          onTap: () => showBookSwitcher(context),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Hairline(),
                        ),
                        _listRow(
                          '日期',
                          trailing: Text(
                            dayLabel(_date),
                            style: AppTheme.mono(14, color: AppTheme.inkSub),
                          ),
                          onTap: _pickDate,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Hairline(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              const Text('备注', style: AppTheme.body),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CupertinoTextField(
                                  controller: _remarkCtrl,
                                  focusNode: _remarkFocus,
                                  placeholder: '写点什么…',
                                  placeholderStyle: AppTheme.body.copyWith(
                                    color: AppTheme.inkWeak,
                                  ),
                                  style: AppTheme.body,
                                  decoration: null,
                                  maxLength: 50,
                                  textAlign: TextAlign.end,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // ---- 底部输入区:默认数字键盘;备注聚焦(系统键盘弹出)时
                // 换成紧凑的「金额 + 完成」栏,金额入口始终可见 ----
                if (MediaQuery.of(context).viewInsets.bottom == 0 &&
                    !_remarkFocus.hasFocus)
                  SizedBox(
                    height: 236,
                    child: CalcKeyboard(
                      dateLabel: isSameDay(_date, DateTime.now())
                          ? '今天'
                          : '${_date.month}.${_date.day}',
                      onKey: _append,
                      onDelete: _delete,
                      onDate: _pickDate,
                      onDone: _save,
                    ),
                  )
                else
                  _CompactAmountBar(
                    expr: _expr,
                    symbol: ledgerStore.currentBook.currencySymbol,
                    onTapAmount: () => _remarkFocus.unfocus(),
                    onDone: _save,
                  ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _listRow(
    String label, {
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Text(label, style: AppTheme.body),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final categories = ledgerStore.categoriesOf(_type);
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.78,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final c = categories[i];
        final selected = c.key == _categoryKey;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _categoryKey = c.key);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryTile(category: c, size: 48, selected: selected),
              const SizedBox(height: 4),
              Text(
                c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected ? AppTheme.ink : AppTheme.inkSub,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 备注聚焦时的紧凑金额栏:金额入口不消失,点击金额回到数字键盘,
/// 右侧保留「完成」按钮,无需先收起系统键盘。
class _CompactAmountBar extends StatelessWidget {
  const _CompactAmountBar({
    required this.expr,
    required this.symbol,
    required this.onTapAmount,
    required this.onDone,
  });

  final String expr;
  final String symbol;
  final VoidCallback onTapAmount;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.line, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapAmount,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(symbol, style: AppTheme.dots(16, color: AppTheme.inkSub)),
                const SizedBox(width: 3),
                Text(
                  expr.isEmpty ? '0' : expr,
                  style: AppTheme.dots(
                    30,
                    color: expr.isEmpty ? AppTheme.inkWeak : AppTheme.ink,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('点这里输入金额', style: AppTheme.caption),
              ],
            ),
          ),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            pressedOpacity: 0.5,
            onPressed: onDone,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.ink, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Text(
                    '完成',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.ink,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    CupertinoIcons.arrow_right,
                    size: 13,
                    color: AppTheme.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
