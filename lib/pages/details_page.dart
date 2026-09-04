import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/hairline.dart';
import '../widgets/txn_row.dart';
import 'book_switcher.dart';

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
          const Padding(
            padding: EdgeInsets.only(top: 90),
            child: Center(
              child: Column(
                children: [
                  Icon(CupertinoIcons.tray, size: 44, color: AppTheme.inkWeak),
                  SizedBox(height: 12),
                  Text('还没有账单', style: AppTheme.caption),
                ],
              ),
            ),
          )
        else
          for (final entry in groups.entries) _daySection(entry, book),
      ],
    );
  }

  Widget _pagerArrow(IconData icon, VoidCallback onTap) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      minimumSize: const Size(32, 32),
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
