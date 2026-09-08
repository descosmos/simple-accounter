import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/category_avatar.dart';
import '../widgets/eink_toggle.dart';
import '../widgets/hairline.dart';
import '../widgets/txn_row.dart';

/// 统计范围:日 / 月 / 年
enum _Range { day, month, year }

class BarPoint {
  BarPoint(this.label, this.title, this.expense, this.income);
  final String label; // X 轴短标签
  final String title; // 选中详情标题
  final int expense;
  final int income;
}

/// 统计:范围(年/月/日)可切换的收支图表 + 分类排行。
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  TxnType _type = TxnType.expense;
  _Range _range = _Range.month;
  DateTime _anchor = DateTime.now();
  String? _selectedCatKey;

  void _shift(int dir) {
    setState(() {
      _selectedCatKey = null;
      _anchor = switch (_range) {
        _Range.day => _anchor.add(Duration(days: dir)),
        _Range.month => DateTime(_anchor.year, _anchor.month + dir),
        _Range.year => DateTime(_anchor.year + dir, _anchor.month),
      };
    });
  }

  void _setRange(_Range r) {
    if (r == _range) return;
    HapticFeedback.selectionClick();
    setState(() {
      _range = r;
      _selectedCatKey = null;
      _anchor = DateTime.now();
    });
  }

  /// 点按柱子下钻:年视图进入该月,月视图进入该日。
  void _drillDown(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCatKey = null;
      if (_range == _Range.year) {
        _anchor = DateTime(_anchor.year, i + 1);
        _range = _Range.month;
      } else if (_range == _Range.month) {
        _anchor = _monthScope.start.add(Duration(days: i));
        _range = _Range.day;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.paper,
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: ledgerStore,
          builder: (context, _) => _buildBody(context),
        ),
      ),
    );
  }

  // ---------- 数据 ----------

  /// 月范围:月度账本按其账期,事件账本按自然月
  Period get _monthScope {
    final book = ledgerStore.currentBook;
    if (book.mode == BookMode.monthly) {
      return periodOf(_anchor, book.monthStartDay);
    }
    return Period(
      DateTime(_anchor.year, _anchor.month),
      DateTime(_anchor.year, _anchor.month + 1),
    );
  }

  bool _inScope(Txn t) {
    switch (_range) {
      case _Range.day:
        return isSameDay(t.day, _anchor);
      case _Range.month:
        return _monthScope.contains(t.day);
      case _Range.year:
        return t.day.year == _anchor.year;
    }
  }

  String get _title {
    switch (_range) {
      case _Range.day:
        return '${_anchor.month}月${_anchor.day}日 ${weekdayCn(_anchor)}';
      case _Range.month:
        return periodLabelEn(_monthScope);
      case _Range.year:
        return '${_anchor.year}年';
    }
  }

  List<BarPoint> _chartPoints(List<Txn> scopeTxns) {
    if (_range == _Range.month) {
      final p = _monthScope;
      final days = p.end.difference(p.start).inDays;
      return [
        for (var i = 0; i < days; i++)
          _dayPoint(scopeTxns, p.start.add(Duration(days: i))),
      ];
    }
    // 年:12 个月
    return [
      for (var m = 1; m <= 12; m++) _monthPoint(scopeTxns, _anchor.year, m),
    ];
  }

  BarPoint _dayPoint(List<Txn> txns, DateTime day) {
    var exp = 0, inc = 0;
    for (final t in txns) {
      if (!isSameDay(t.day, day)) continue;
      if (t.type == TxnType.expense) {
        exp += t.amountCents;
      } else {
        inc += t.amountCents;
      }
    }
    return BarPoint(
      '${day.day}',
      '${day.month}月${day.day}日 ${weekdayCn(day)}',
      exp,
      inc,
    );
  }

  BarPoint _monthPoint(List<Txn> txns, int year, int month) {
    var exp = 0, inc = 0;
    for (final t in txns) {
      if (t.day.year != year || t.day.month != month) continue;
      if (t.type == TxnType.expense) {
        exp += t.amountCents;
      } else {
        inc += t.amountCents;
      }
    }
    return BarPoint('$month', '$month月', exp, inc);
  }

  // ---------- UI ----------

  Widget _buildBody(BuildContext context) {
    final book = ledgerStore.currentBook;
    final scopeTxns = ledgerStore
        .txnsInPeriod(book.id, Period(DateTime(2000), DateTime(2100)))
        .where(_inScope)
        .toList();

    final typeTxns = scopeTxns.where((t) => t.type == _type).toList();
    var typeTotal = 0;
    for (final t in typeTxns) {
      typeTotal += t.amountCents;
    }

    final points = _range == _Range.day ? null : _chartPoints(scopeTxns);

    return ListView(
      key: ValueKey('${book.id}-$_type-$_range'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const SizedBox(height: 10),
        Center(child: Text(book.name, style: AppTheme.overline)),
        const SizedBox(height: 2),
        // ---- 账期翻页 ----
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _arrow(CupertinoIcons.chevron_left, () => _shift(-1)),
            GestureDetector(
              onTap: () => setState(() {
                _anchor = DateTime.now();
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            _arrow(CupertinoIcons.chevron_right, () => _shift(1)),
          ],
        ),
        // ---- 范围切换 日/月/年 ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
          child: EinkToggle<_Range>(
            options: const [
              (_Range.day, '日'),
              (_Range.month, '月'),
              (_Range.year, '年'),
            ],
            groupValue: _range,
            onChanged: _setRange,
          ),
        ),
        // ---- 合计 + 类型 ----
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: Text(
              '${book.currencySymbol}${fmtCents(typeTotal)}',
              style: AppTheme.dots(36),
            ),
          ),
        ),
        Center(
          child: Text(
            _range == _Range.day
                ? '当日${_type == TxnType.expense ? '支出' : '收入'}'
                : _type == TxnType.expense
                ? '支出合计'
                : '收入合计',
            style: AppTheme.caption,
          ),
        ),
        const SizedBox(height: 10),
        // ---- 图表(月/年) 或 当日明细(日) ----
        if (points != null) ...[
          _chartLegend(),
          const SizedBox(height: 6),
          RangeChart(points: points, onSelect: _drillDown),
          SizedBox(
            height: 22,
            child: Center(
              child: Text(
                _range == _Range.year ? '双指缩放 · 点按查看单月' : '双指缩放 · 点按查看单日',
                style: AppTheme.caption,
              ),
            ),
          ),
        ] else
          _dayDetail(book, scopeTxns),
        const SizedBox(height: 6),
        // ---- 类型拨杆(作用于分类排行) ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: EinkToggle<TxnType>(
            options: const [(TxnType.expense, '支出'), (TxnType.income, '收入')],
            groupValue: _type,
            onChanged: (v) => setState(() {
              _type = v;
              _selectedCatKey = null;
            }),
          ),
        ),
        const SizedBox(height: 10),
        const Hairline(),
        _categoryRanking(book, typeTxns, typeTotal),
      ],
    );
  }

  Widget _dayDetail(Book book, List<Txn> txns) {
    if (txns.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('当日没有账单', style: AppTheme.caption)),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < txns.length; i++)
          Column(
            children: [
              if (i > 0) const Hairline(),
              TxnRow(txn: txns[i], currencySymbol: book.currencySymbol),
            ],
          ),
        const Hairline(),
      ],
    );
  }

  Widget _chartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(width: 8, height: 8, color: AppTheme.ink),
        const SizedBox(width: 4),
        const Text('支出', style: AppTheme.caption),
        const SizedBox(width: 12),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.ink, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        const Text('收入', style: AppTheme.caption),
      ],
    );
  }

  Widget _categoryRanking(Book book, List<Txn> typeTxns, int typeTotal) {
    final byKey = <String, (Category, int, int)>{};
    for (final t in typeTxns) {
      final c = ledgerStore.categoryOf(t.categoryKey);
      final s = byKey[c.key];
      byKey[c.key] = (c, (s?.$2 ?? 0) + t.amountCents, (s?.$3 ?? 0) + 1);
    }
    final stats = byKey.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
    if (stats.isEmpty) {
      // 日视图的空态由 _dayDetail 展示,此处不再重复
      if (_range == _Range.day) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: Text('该范围暂无记录', style: AppTheme.caption)),
      );
    }
    final maxCents = stats.first.$2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 2),
          child: Text('分类排行', style: AppTheme.overline),
        ),
        for (final s in stats) _rankRow(book, s, typeTotal, maxCents),
      ],
    );
  }

  Widget _rankRow(Book book, (Category, int, int) s, int total, int maxCents) {
    final selected = _selectedCatKey == s.$1.key;
    final pct = total == 0 ? 0.0 : s.$2 / total;
    final barFrac = maxCents == 0 ? 0.0 : s.$2 / maxCents;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCatKey = selected ? null : s.$1.key);
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    CategoryTile(category: s.$1, size: 30, selected: selected),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.$1.title, style: AppTheme.body)),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: AppTheme.mono(12, color: AppTheme.inkSub),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${book.currencySymbol}${fmtCents(s.$2)}',
                      style: AppTheme.mono(13, weight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                LayoutBuilder(
                  builder: (context, c) => Container(
                    height: 3,
                    color: AppTheme.paperDim,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: c.maxWidth * barFrac,
                      height: 3,
                      color: selected ? AppTheme.accent : AppTheme.ink,
                    ),
                  ),
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('共 ${s.$3} 笔', style: AppTheme.caption),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Hairline(),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return CupertinoButton(
      padding: const EdgeInsets.all(12),
      minimumSize: const Size(38, 38),
      pressedOpacity: 0.4,
      onPressed: onTap,
      child: Icon(icon, size: 18, color: AppTheme.inkSub),
    );
  }
}

/// 收支柱状图:实心 = 支出,描边 = 收入。
/// 双指捏合放大柱子(可横滑),点按柱子下钻(年→月,月→日)。
class RangeChart extends StatefulWidget {
  const RangeChart({super.key, required this.points, required this.onSelect});

  final List<BarPoint> points;
  final ValueChanged<int> onSelect;

  @override
  State<RangeChart> createState() => _RangeChartState();
}

class _RangeChartState extends State<RangeChart> {
  static const _minScale = 1.0;
  static const _maxScale = 6.0;

  final ScrollController _scroll = ScrollController();
  double _scale = 1.0;
  double _startScale = 1.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final next = (_startScale * d.scale).clamp(_minScale, _maxScale);
    if (next == _scale) return;
    final old = _scale;
    setState(() => _scale = next);
    // 以双指焦点为锚,让焦点下的柱子在缩放后尽量保持不动
    final focal = d.localFocalPoint.dx;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = (_scroll.offset + focal) * (next / old) - focal;
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    // 用 P90 分位数做归一上限,避免单根巨柱(如工资)压扁其余柱子;
    // 被截断的柱子顶部画白色斜切纹示意。
    final values = <int>[
      for (final p in widget.points) ...[p.expense, p.income],
    ]..sort();
    var maxV =
        values[(values.length * 0.9).floor().clamp(0, values.length - 1)];
    if (maxV <= 0) maxV = 1;
    return LayoutBuilder(
      builder: (context, c) {
        final groupW = c.maxWidth / widget.points.length * _scale;
        return GestureDetector(
          onScaleStart: (d) => _startScale = _scale,
          onScaleUpdate: _onScaleUpdate,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            // 未放大时内容与视口同宽,禁用滚动以免和外层列表抢手势
            physics: _scale > 1
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: groupW * widget.points.length,
              child: Column(
                children: [
                  SizedBox(
                    height: 148,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < widget.points.length; i++)
                          SizedBox(
                            width: groupW,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onSelect(i),
                              child: _barGroup(widget.points[i], maxV),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Hairline(),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var i = 0; i < widget.points.length; i++)
                        SizedBox(
                          width: groupW,
                          child: Text(
                            _labelFor(i, groupW),
                            textAlign: TextAlign.center,
                            softWrap: false,
                            style: AppTheme.mono(9, color: AppTheme.inkWeak),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _labelFor(int i, double groupW) {
    final n = widget.points.length;
    if (n <= 12) return widget.points[i].label; // 年:全显示
    // 放大到足够宽后每个刻度都显示
    if (groupW >= 24) return widget.points[i].label;
    // 月:隔 5 个显示
    final day = int.tryParse(widget.points[i].label) ?? 0;
    if (day == 1 || (day - 1) % 5 == 0) return widget.points[i].label;
    return '';
  }

  Widget _barGroup(BarPoint p, int maxV) {
    const chartH = 128.0;
    final expH = p.expense == 0
        ? 0.0
        : (p.expense / maxV * chartH).clamp(3.0, chartH);
    final incH = p.income == 0
        ? 0.0
        : (p.income / maxV * chartH).clamp(3.0, chartH);
    final isToday = p.title.startsWith(
      '${DateTime.now().month}月${DateTime.now().day}日',
    );
    final expClipped = p.expense > maxV;
    final incClipped = p.income > maxV;
    return SizedBox(
      height: 148,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 支出:实心(截断时柱体带白色斜切纹)
                Flexible(
                  child: _maybeSlashed(
                    height: expH,
                    clipped: expClipped,
                    margin: const EdgeInsets.only(right: 1),
                    fill: isToday ? AppTheme.ink : AppTheme.inkSub,
                  ),
                ),
                // 收入:描边
                Flexible(
                  child: _maybeSlashed(
                    height: incH,
                    clipped: incClipped,
                    margin: const EdgeInsets.only(left: 1),
                    border: Border.all(color: AppTheme.inkSub, width: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 柱体;截断时在距顶部 4px 处叠加两条白色斜切纹(断轴符号)。
  Widget _maybeSlashed({
    required double height,
    required bool clipped,
    required EdgeInsets margin,
    Color? fill,
    Border? border,
  }) {
    final bar = Container(
      height: height,
      margin: margin,
      color: fill,
      decoration: border != null ? BoxDecoration(border: border) : null,
    );
    if (!clipped || height < 16) return bar;
    return Stack(
      children: [
        bar,
        Positioned(
          top: 4,
          left: margin.left,
          right: margin.right,
          height: 8,
          child: CustomPaint(painter: _SlashPainter()),
        ),
      ],
    );
  }
}

/// 断轴斜切纹:两条白色斜线,画在被截断柱体的顶部。
class _SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.paper
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(-2, size.height - 1),
      Offset(size.width + 2, -1),
      paint,
    );
    canvas.drawLine(
      Offset(-2, size.height + 2),
      Offset(size.width + 2, 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
