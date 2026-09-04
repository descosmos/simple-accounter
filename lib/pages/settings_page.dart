import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/hairline.dart';
import 'books_page.dart';
import 'categories_page.dart';

/// 设置:账本管理 / 分类管理入口,单行列表 + 细分隔线。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _push(BuildContext context, Widget page) {
    HapticFeedback.selectionClick();
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(CupertinoPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.paper,
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: ledgerStore,
          builder: (context, _) => ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const SizedBox(height: 14),
              const Text(
                '设置',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 18),
              const Hairline(),
              _row(
                '账本管理',
                trailing: ledgerStore.currentBook.name,
                onTap: () => _push(context, const BooksPage()),
              ),
              const Hairline(),
              _row('分类管理', onTap: () => _push(context, const CategoriesPage())),
              const Hairline(),
              _row('关于', trailing: '简账 1.0.0'),
              const Hairline(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, {String? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Text(label, style: AppTheme.body),
            const Spacer(),
            if (trailing != null)
              Text(trailing, style: AppTheme.mono(13, color: AppTheme.inkSub)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 13,
                color: AppTheme.inkWeak,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
