import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/hairline.dart';
import '../widgets/txn_row.dart';
import 'book_switcher.dart';
import 'record_page.dart';

/// 明细:月份切换 + 收支概览 + 按日分组的全部账单(事件账本为全程记录)。
class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  DateTime _anchor = DateTime.now();

  Period get _period =>
      periodOf(_anchor, ledgerStore.currentBook.monthStartDay);

  void _shiftPeriod(int dir) {
    setState(() {
      _anchor = dir > 0
          ? _period.end
          : _period.start.subtract(const Duration(days: 1));
    });
  }

  /// 滑动删除前的确认;返回 true 才真正删除。
  Future<bool> _confirmDeleteTxn(Txn t) async {
    final book = ledgerStore.currentBook;
    final cat = ledgerStore.categoryOf(t.categoryKey);
    final sign = t.type == TxnType.expense ? '-' : '+';
    final what = t.remark.isEmpty ? cat.title : t.remark;
    final amount = '$sign${book.currencySymbol}${fmtCents(t.amountCents)}';
    var ok = false;
    await showCupertinoDialog<void>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: const Text('删除这条账单?'),
        content: Text('$what $amount,删除后无法恢复。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(c),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ok = true;
              Navigator.pop(c);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.paper,
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: ledgerStore,
          builder: (context, _) {
            final book = ledgerStore.currentBook;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildBody(context, book),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Book book) {
    final isEvent = book.mode == BookMode.event;
    final period = _period;
    final groups = isEvent
        ? ledgerStore.dayGroups(book.id)
        : ledgerStore.dayGroups(book.id, period);
    final summary = isEvent
        ? ledgerStore.summaryAll(book.id)
        : ledgerStore.summaryInPeriod(book.id, period);

    return ListView(
      key: ValueKey(book.id),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // ---- 顶部:账本名 + 月份 ----
        const SizedBox(height: 10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showBookSwitcher(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  book.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.overline,
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_down,
                size: 10,
                color: AppTheme.inkSub,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
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
              _pagerArrow(CupertinoIcons.chevron_left, () => _shiftPeriod(-1)),
              GestureDetector(
                onTap: () => setState(() => _anchor = DateTime.now()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Text(
                    periodLabelEn(period),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              _pagerArrow(CupertinoIcons.chevron_right, () => _shiftPeriod(1)),
            ],
          ),
        // ---- 概览 ----
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _overviewItem(
                '收入 ',
                '+${book.currencySymbol}${fmtCents(summary.incomeCents)}',
              ),
              _overviewDivider(),
              _overviewItem(
                '支出 ',
                '-${book.currencySymbol}${fmtCents(summary.expenseCents)}',
              ),
              _overviewDivider(),
              _overviewItem(
                '结余 ',
                '${summary.balanceCents < 0 ? '-' : ''}${book.currencySymbol}${fmtCents(summary.balanceCents.abs())}',
              ),
            ],
          ),
        ),
        const Hairline(),
        // ---- 按日分组 ----
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 90),
            child: Column(
              children: [
                const Icon(
                  CupertinoIcons.tray,
                  size: 44,
                  color: AppTheme.inkWeak,
                ),
                const SizedBox(height: 12),
                const Text('还没有账单', style: AppTheme.caption),
                const SizedBox(height: 14),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  pressedOpacity: 0.5,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context, rootNavigator: true).push(
                      CupertinoPageRoute<void>(
                        fullscreenDialog: true,
                        builder: (_) => const RecordPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.ink, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '记一笔',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.ink,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.arrow_right,
                          size: 14,
                          color: AppTheme.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final entry in groups.entries) _daySection(entry, book),
      ],
    );
  }

  Widget _pagerArrow(IconData icon, VoidCallback onTap) {
    return CupertinoButton(
      padding: const EdgeInsets.all(12),
      minimumSize: const Size(38, 38),
      pressedOpacity: 0.4,
      onPressed: onTap,
      child: Icon(icon, size: 18, color: AppTheme.inkSub),
    );
  }

  Widget _overviewItem(String label, String value) {
    return Row(
      children: [
        Text(label, style: AppTheme.caption),
        Text(value, style: AppTheme.mono(13, weight: FontWeight.w500)),
      ],
    );
  }

  Widget _overviewDivider() {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppTheme.line,
    );
  }

  Widget _daySection(MapEntry<DateTime, List<Txn>> entry, Book book) {
    final day = entry.key;
    final txns = entry.value;
    var exp = 0, inc = 0;
    for (final t in txns) {
      if (t.type == TxnType.expense) {
        exp += t.amountCents;
      } else {
        inc += t.amountCents;
      }
    }
    final stats = [
      if (exp > 0) '-${book.currencySymbol}${fmtCents(exp)}',
      if (inc > 0) '+${book.currencySymbol}${fmtCents(inc)}',
    ].join('  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 4),
          child: Row(
            children: [
              Text(
                '${day.day.toString().padLeft(2, '0')} ${weekdayCn(day)}',
                style: AppTheme.overline.copyWith(color: AppTheme.ink),
              ),
              const Spacer(),
              Text(stats, style: AppTheme.mono(11, color: AppTheme.inkWeak)),
            ],
          ),
        ),
        for (var i = 0; i < txns.length; i++)
          Column(
            children: [
              if (i > 0) const Hairline(),
              Dismissible(
                key: ValueKey(txns[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppTheme.paperDim,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    CupertinoIcons.delete,
                    color: AppTheme.inkSub,
                    size: 20,
                  ),
                ),
                confirmDismiss: (_) => _confirmDeleteTxn(txns[i]),
                onDismissed: (_) {
                  HapticFeedback.lightImpact();
                  ledgerStore.deleteTxn(txns[i].id);
                },
                child: TxnRow(
                  txn: txns[i],
                  currencySymbol: book.currencySymbol,
                ),
              ),
            ],
          ),
        const Hairline(),
      ],
    );
  }
}
