import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/book_cover.dart';
import '../widgets/hairline.dart';
import 'book_edit_page.dart';

/// 账本管理:单行列表 + 细线分隔;当前账本以橙色小点标记。
class BooksPage extends StatelessWidget {
  const BooksPage({super.key});

  void _openEdit(BuildContext context, [Book? book]) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(CupertinoPageRoute<void>(builder: (_) => BookEditPage(book: book)));
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
            final books = ledgerStore.books;
            final currentId = ledgerStore.currentBookId;
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                // ---- 顶部 ----
                const SizedBox(height: 8),
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(30, 30),
                      pressedOpacity: 0.5,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(
                        CupertinoIcons.chevron_left,
                        size: 22,
                        color: AppTheme.ink,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '账本',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(30, 30),
                      pressedOpacity: 0.5,
                      onPressed: () => _openEdit(context),
                      child: const Icon(
                        CupertinoIcons.plus,
                        size: 22,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Hairline(),
                for (final book in books)
                  _bookRow(context, book, book.id == currentId),
                // ---- 新建 ----
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    pressedOpacity: 0.5,
                    onPressed: () => _openEdit(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.ink, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bookRow(BuildContext context, Book book, bool isCurrent) {
    final count = ledgerStore.txnCountOf(book.id);
    final isEvent = book.mode == BookMode.event;
    final summary = isEvent
        ? ledgerStore.summaryAll(book.id)
        : ledgerStore.summaryInPeriod(
            book.id,
            periodOf(DateTime.now(), book.monthStartDay),
          );
    final scope = isEvent
        ? '累计结余'
        : '${periodOf(DateTime.now(), book.monthStartDay).shortLabel()}结余';
    final subtitle = count == 0
        ? (isEvent ? '事件账本 · 暂无账单' : '暂无账单')
        : '${isEvent ? '事件账本 · ' : ''}$count 笔 · $scope '
              '${summary.balanceCents < 0 ? '-' : ''}${book.currencySymbol}${fmtCents(summary.balanceCents.abs())}';

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            ledgerStore.switchBook(book.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                BookCover(book: book, width: 38, height: 44, iconSize: 18),
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
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                CupertinoButton(
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28),
                  pressedOpacity: 0.5,
                  onPressed: () => _openEdit(context, book),
                  child: const Icon(
                    CupertinoIcons.chevron_right,
                    size: 15,
                    color: AppTheme.inkWeak,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Hairline(),
      ],
    );
  }
}
