import 'package:flutter/cupertino.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import 'category_avatar.dart';

/// 电子纸风格账单行:左侧分类字块,中间名称(+分类灰字),右侧等宽金额。
/// 收支通过正负号与字重区分,不用红绿。
class TxnRow extends StatelessWidget {
  const TxnRow({super.key, required this.txn, this.currencySymbol = '¥'});

  final Txn txn;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final category = ledgerStore.categoryOf(txn.categoryKey);
    final isExpense = txn.type == TxnType.expense;
    final amount =
        '${isExpense ? '-' : '+'}$currencySymbol${fmtCents(txn.amountCents)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          CategoryTile(category: category, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              txn.remark.isNotEmpty ? txn.remark : category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body,
            ),
          ),
          // 无备注时主标题已是分类名,不再重复显示
          if (txn.remark.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              category.title,
              style: AppTheme.caption.copyWith(color: AppTheme.inkWeak),
            ),
          ],
          const SizedBox(width: 12),
          Text(
            amount,
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
