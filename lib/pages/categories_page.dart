import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/category_avatar.dart';
import '../widgets/eink_toggle.dart';
import '../widgets/hairline.dart';
import 'category_edit_page.dart';

/// 分类管理:支出/收入拨杆切换,内置 + 自定义分类,细线单行列表。
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  TxnType _type = TxnType.expense;

  void _openEdit([Category? category]) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute<void>(
        builder: (_) => CategoryEditPage(type: _type, category: category),
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
            final categories = ledgerStore.categoriesOf(_type);
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
                      '分类',
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
                      onPressed: () => _openEdit(),
                      child: const Icon(
                        CupertinoIcons.plus,
                        size: 22,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                EinkToggle<TxnType>(
                  options: const [
                    (TxnType.expense, '支出'),
                    (TxnType.income, '收入'),
                  ],
                  groupValue: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
                const SizedBox(height: 14),
                const Hairline(),
                for (var i = 0; i < categories.length; i++)
                  _categoryRow(categories[i], showDivider: i > 0),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('自定义分类可点击进入编辑,向左滑动删除。', style: AppTheme.caption),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _categoryRow(Category category, {required bool showDivider}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          CategoryTile(category: category, size: 34),
          const SizedBox(width: 12),
          Expanded(child: Text(category.title, style: AppTheme.body)),
          if (category.isCustom) ...[
            const Text('自定义', style: AppTheme.caption),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 12,
              color: AppTheme.inkWeak,
            ),
          ],
        ],
      ),
    );

    final content = Column(children: [if (showDivider) const Hairline(), row]);

    if (!category.isCustom) return content;

    return Dismissible(
      key: ValueKey(category.key),
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
      confirmDismiss: (_) async {
        var ok = false;
        await showCupertinoDialog<void>(
          context: context,
          builder: (c) => CupertinoAlertDialog(
            title: Text('删除分类「${category.title}」?'),
            content: const Text('已使用该分类的账单将显示为「其它」。'),
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
      },
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        ledgerStore.deleteCustomCategory(category.key);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openEdit(category),
        child: content,
      ),
    );
  }
}
