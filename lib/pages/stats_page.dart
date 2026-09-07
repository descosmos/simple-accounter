import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/category_avatar.dart';
import '../widgets/eink_toggle.dart';
import '../widgets/hairline.dart';

/// 统计:黑灰横向条形图 + 单色分类排行,选中项仅以橙色标记。
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _CatStat {
  _CatStat(this.category, this.cents, this.count);
  final Category category;
  final int cents;
  final int count;
}

class _StatsPageState extends State<StatsPage> {
  TxnType _type = TxnType.expense;
  DateTime _anchor = DateTime.now();
  String? _selectedKey;

  Period get _period =>
      periodOf(_anchor, ledgerStore.currentBook.monthStartDay);

  void _shift(int dir) {
    setState(() {
      _anchor = dir > 0
          ? _period.end
          : _period.start.subtract(const Duration(days: 1));
      _selectedKey = null;
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

  Widget _buildBody(BuildContext context) {
    final book = ledgerStore.currentBook;
    final isEvent = book.mode == BookMode.event;
    final txns =
        (isEvent
                ? ledgerStore.txnsAll(book.id)
                : ledgerStore.txnsInPeriod(book.id, _period))
            .where((t) => t.type == _type)
            .toList();

    // 按分类聚合
    final byKey = <String, _CatStat>{};
    var total = 0;
    for (final t in txns) {
      final c = ledgerStore.categoryOf(t.categoryKey);
      final s = byKey[c.key];
      byKey[c.key] = _CatStat(
        c,
        (s?.cents ?? 0) + t.amountCents,
        (s?.count ?? 0) + 1,
      );
      total += t.amountCents;
    }
    final stats = byKey.values.toList()
      ..sort((a, b) => b.cents.compareTo(a.cents));
    final maxCents = stats.isEmpty ? 0 : stats.first.cents;

    return ListView(
      key: ValueKey('${book.id}-$_type'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const SizedBox(height: 10),
        Center(child: Text(book.name, style: AppTheme.overline)),
        const SizedBox(height: 2),
        // ---- 月份 / 全部 ----
        if (isEvent)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                '全部记录',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _arrow(CupertinoIcons.chevron_left, () => _shift(-1)),
              GestureDetector(
                onTap: () => setState(() {
                  _anchor = DateTime.now();
                  _selectedKey = null;
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Text(
                    periodLabelEn(_period),
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
        // ---- 类型拨杆 + 合计 ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 4),
          child: EinkToggle<TxnType>(
            options: const [(TxnType.expense, '支出'), (TxnType.income, '收入')],
            groupValue: _type,
            onChanged: (v) => setState(() {
              _type = v;
              _selectedKey = null;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              '${book.currencySymbol}${fmtCents(total)}',
              style: AppTheme.dots(36),
            ),
          ),
        ),
        const Hairline(),
        // ---- 分类排行 ----
        if (stats.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: Text('暂无记录', style: AppTheme.caption)),
          )
        else
          for (var i = 0; i < stats.length; i++)
            _rankRow(stats[i], total, maxCents, book),
      ],
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

  Widget _rankRow(_CatStat s, int total, int maxCents, Book book) {
    final selected = _selectedKey == s.category.key;
    final pct = total == 0 ? 0.0 : s.cents / total;
    final barFrac = maxCents == 0 ? 0.0 : s.cents / maxCents;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedKey = selected ? null : s.category.key);
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Column(
              children: [
                Row(
                  children: [
                    CategoryTile(
                      category: s.category,
                      size: 32,
                      selected: selected,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.category.title, style: AppTheme.body),
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: AppTheme.mono(12, color: AppTheme.inkSub),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${book.currencySymbol}${fmtCents(s.cents)}',
                      style: AppTheme.mono(14, weight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 细线轨道 + 黑灰条;选中时为橙色
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
                    padding: const EdgeInsets.only(top: 6),
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
                        Text('共 ${s.count} 笔', style: AppTheme.caption),
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
}
