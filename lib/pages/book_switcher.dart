import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/book_cover.dart';
import '../widgets/hairline.dart';
import 'book_edit_page.dart';

/// 弹出账本切换面板(暖白电子纸底部弹层)。
/// 点击账本立即切换并收起;底部提供「新建账本」入口
/// (未传 onCreateBook 时默认打开新建账本页)。
Future<void> showBookSwitcher(
  BuildContext context, {
  VoidCallback? onCreateBook,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    barrierDismissible: true,
    builder: (sheetContext) {
      return _BookSwitcherSheet(
        onCreateBook: () {
          Navigator.of(sheetContext).pop();
          if (onCreateBook != null) {
            onCreateBook();
          } else {
            Navigator.of(context, rootNavigator: true).push(
              CupertinoPageRoute<void>(builder: (_) => const BookEditPage()),
            );
          }
        },
      );
    },
  );
}

class _BookSwitcherSheet extends StatelessWidget {
  const _BookSwitcherSheet({this.onCreateBook});

  final VoidCallback? onCreateBook;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.72;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: ledgerStore,
          builder: (context, _) {
            final books = ledgerStore.books;
            final currentId = ledgerStore.currentBookId;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 抓手
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 2),
                  child: Text(
                    '切换账本',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                ),
                Text('共 ${books.length} 个账本', style: AppTheme.caption),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Hairline(),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: books.length,
                    itemBuilder: (context, i) => _BookRow(
                      book: books[i],
                      isCurrent: books[i].id == currentId,
                      showDivider: i > 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ledgerStore.switchBook(books[i].id);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Hairline(),
                ),
                CupertinoButton(
                  pressedOpacity: 0.5,
                  onPressed: onCreateBook,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '新建账本',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.ink,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.arrow_right,
                        size: 13,
                        color: AppTheme.accent,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.book,
    required this.isCurrent,
    required this.showDivider,
    required this.onTap,
  });

  final Book book;
  final bool isCurrent;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = ledgerStore.txnCountOf(book.id);
    final String subtitle;
    if (count == 0) {
      subtitle = book.mode == BookMode.event ? '事件账本 · 暂无账单' : '暂无账单';
    } else if (book.mode == BookMode.event) {
      final summary = ledgerStore.summaryAll(book.id);
      subtitle =
          '事件账本 · $count 笔 · 累计支出 ${book.currencySymbol}${fmtCents(summary.expenseCents)}';
    } else {
      final period = periodOf(DateTime.now(), book.monthStartDay);
      final summary = ledgerStore.summaryInPeriod(book.id, period);
      subtitle =
          '$count 笔 · ${period.shortLabel()}支出 ${book.currencySymbol}${fmtCents(summary.expenseCents)}';
    }
    return Column(
      children: [
        if (showDivider) const Hairline(),
        CupertinoButton(
          padding: EdgeInsets.zero,
          pressedOpacity: 0.5,
          onPressed: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                BookCover(book: book, width: 36, height: 42, iconSize: 17),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTheme.caption),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
