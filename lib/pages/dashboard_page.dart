import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/category_avatar.dart';
import '../widgets/hairline.dart';
import 'book_edit_page.dart';
import 'book_switcher.dart';
import 'record_page.dart';

/// 首页:结余大数字 + 三列数据 + 最近记录 + 月度日历。
/// 页面唯一视觉焦点是中央的点阵结余数字。
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.onGoDetails});

  final VoidCallback? onGoDetails;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? _selectedDay;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftCalendarMonth(int dir) {
    setState(() {
      _calendarMonth = DateTime(
        _calendarMonth.year,
        _calendarMonth.month + dir,
      );
    });
  }

  void _openBookSwitcher() {
    showBookSwitcher(
      context,
      onCreateBook: () => Navigator.of(
        context,
        rootNavigator: true,
      ).push(CupertinoPageRoute<void>(builder: (_) => const BookEditPage())),
    );
  }

  void _openRecord() {
    HapticFeedback.lightImpact();
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const RecordPage(),
      ),
    );
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
    final now = DateTime.now();
    final isEvent = book.mode == BookMode.event;
    final summary = isEvent
        ? ledgerStore.summaryAll(book.id)
        : ledgerStore.summaryInPeriod(
            book.id,
            periodOf(now, book.monthStartDay),
          );
    final txnCount = isEvent
        ? ledgerStore.txnCountOf(book.id)
        : ledgerStore
              .txnsInPeriod(book.id, periodOf(now, book.monthStartDay))
              .length;

    // 最近记录:选中日历某天则显示当天,否则显示最新 4 条
    final allTxns = isEvent
        ? ledgerStore.txnsAll(book.id)
        : ledgerStore.txnsInPeriod(book.id, periodOf(now, book.monthStartDay));
    final shownTxns = _selectedDay == null
        ? allTxns.take(4).toList()
        : allTxns.where((t) => isSameDay(t.day, _selectedDay!)).toList();

    return ListView(
      key: ValueKey(book.id),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // ---- 顶部:日期 + 账本 ----
        const SizedBox(height: 10),
        Text(
          '${now.day.toString().padLeft(2, '0')} ${monthAbbrEn[now.month - 1]} · ${weekdayFullEn[now.weekday - 1]}',
          style: AppTheme.overline,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openBookSwitcher,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  book.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.title,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                CupertinoIcons.chevron_down,
                size: 12,
                color: AppTheme.inkSub,
              ),
            ],
          ),
        ),
        // ---- 核心数字:结余 ----
        const SizedBox(height: 34),
        Center(
          child: Text(
            '${summary.balanceCents < 0 ? '-' : ''}${book.currencySymbol}${fmtCents(summary.balanceCents.abs())}',
            style: AppTheme.dots(52),
          ),
        ),
        const SizedBox(height: 6),
        Center(child: Text(isEvent ? '累计结余' : '本月结余', style: AppTheme.caption)),
        const SizedBox(height: 26),
        const Hairline(),
        // ---- 三列数据 ----
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              _stat(
                '收入',
                '${book.currencySymbol}${fmtCents(summary.incomeCents)}',
              ),
              _stat(
                '支出',
                '${book.currencySymbol}${fmtCents(summary.expenseCents)}',
              ),
              _stat('笔数', '$txnCount'),
            ],
          ),
        ),
        const Hairline(),
        // ---- 最近记录 ----
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Row(
            children: [
              Text(
                _selectedDay == null
                    ? '最近记录'
                    : '${_selectedDay!.month}月${_selectedDay!.day}日',
                style: AppTheme.overline.copyWith(color: AppTheme.ink),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onGoDetails,
                child: const Row(
                  children: [
                    Text('查看全部', style: AppTheme.caption),
                    Icon(
                      CupertinoIcons.arrow_right,
                      size: 11,
                      color: AppTheme.inkSub,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (shownTxns.isEmpty)
          _EmptyRecent(onRecord: _openRecord)
        else
          for (var i = 0; i < shownTxns.length; i++)
            _homeTxnRow(shownTxns[i], book, showDivider: i > 0),
        const SizedBox(height: 10),
        const Hairline(),
        // ---- 月度日历 ----
        _MonthCalendar(
          month: _calendarMonth,
          daysWithTxns: _daysWithTxns(allTxns, _calendarMonth),
          selectedDay: _selectedDay,
          onSelect: (d) =>
              setState(() => _selectedDay = (_selectedDay == d) ? null : d),
          onShift: _shiftCalendarMonth,
        ),
      ],
    );
  }

  Set<int> _daysWithTxns(List<Txn> txns, DateTime month) {
    final days = <int>{};
    for (final t in txns) {
      if (t.day.year == month.year && t.day.month == month.month) {
        days.add(t.day.day);
      }
    }
    return days;
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.caption),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.mono(16, weight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _homeTxnRow(Txn txn, Book book, {required bool showDivider}) {
    final category = ledgerStore.categoryOf(txn.categoryKey);
    final isExpense = txn.type == TxnType.expense;
    return Container(
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.line, width: 1)),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: (txn.day.hour != 0 || txn.day.minute != 0)
                ? Text(
                    '${txn.day.hour.toString().padLeft(2, '0')}:${txn.day.minute.toString().padLeft(2, '0')}',
                    style: AppTheme.mono(12, color: AppTheme.inkWeak),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          CategoryTile(category: category, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              txn.remark.isNotEmpty ? txn.remark : category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body,
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${book.currencySymbol}${fmtCents(txn.amountCents)}',
            style: AppTheme.mono(
              15,
              weight: isExpense ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 月度日历:细线边框 + 月份翻页;小黑点 = 当天有账单,
/// 橙点 = 选中;今天 = 黑圆白字(参考 DAYRING 设备日历)。
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.daysWithTxns,
    required this.selectedDay,
    required this.onSelect,
    required this.onShift,
  });

  final DateTime month;
  final Set<int> daysWithTxns;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // 周日起始:DateTime.weekday 周日=7,转为偏移 0
    final firstOffset = DateTime(month.year, month.month, 1).weekday % 7;
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.line, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ---- 月份翻页 ----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pagerArrow(CupertinoIcons.chevron_left, () => onShift(-1)),
              Text(
                '${monthFullEn[month.month - 1]} ${month.year}',
                style: AppTheme.overline.copyWith(color: AppTheme.ink),
              ),
              _pagerArrow(CupertinoIcons.chevron_right, () => onShift(1)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final w in const ['日', '一', '二', '三', '四', '五', '六'])
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: AppTheme.caption.copyWith(color: AppTheme.inkWeak),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var week = 0; week * 7 - firstOffset + 1 <= daysInMonth; week++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (var wd = 0; wd < 7; wd++)
                    Expanded(
                      child: _dayCell(
                        week * 7 + wd - firstOffset + 1,
                        daysInMonth,
                        today,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pagerArrow(IconData icon, VoidCallback onTap) {
    return CupertinoButton(
      padding: const EdgeInsets.all(10),
      minimumSize: const Size(34, 34),
      pressedOpacity: 0.4,
      onPressed: onTap,
      child: Icon(icon, size: 15, color: AppTheme.inkSub),
    );
  }

  Widget _dayCell(int day, int daysInMonth, DateTime today) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 36);
    final date = DateTime(month.year, month.month, day);
    final isToday = isSameDay(date, today);
    final isSelected = selectedDay != null && isSameDay(date, selectedDay!);
    final hasTxns = daysWithTxns.contains(day);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect(date);
      },
      child: SizedBox(
        height: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? AppTheme.ink : const Color(0x00000000),
                border: isSelected && !isToday
                    ? Border.all(color: AppTheme.ink, width: 1)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: AppTheme.mono(
                  13,
                  color: isToday ? AppTheme.paper : AppTheme.inkSub,
                  weight: isToday ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppTheme.accent
                    : hasTxns
                    ? AppTheme.ink
                    : const Color(0x00000000),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 首页无记录时的引导:文字 + 明显的「记一笔」描边按钮(橙色箭头)。
class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.onRecord});

  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          const Text('暂无记录', style: AppTheme.caption),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            pressedOpacity: 0.5,
            onPressed: onRecord,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
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
    );
  }
}
