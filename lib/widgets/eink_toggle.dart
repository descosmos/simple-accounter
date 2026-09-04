import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// 机械拨杆式切换:细线轨道 + 小型橙色滑块标记。
/// 用于支出/收入、账本类型等二选一(也支持多项)。
class EinkToggle<T> extends StatelessWidget {
  const EinkToggle({
    super.key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T groupValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.line, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(child: _option(options[i], showDivider: i > 0)),
        ],
      ),
    );
  }

  Widget _option((T, String) opt, {required bool showDivider}) {
    final selected = opt.$1 == groupValue;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (selected) return;
        HapticFeedback.selectionClick();
        onChanged(opt.$1);
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppTheme.paperDim : const Color(0x00000000),
          border: showDivider
              ? const Border(left: BorderSide(color: AppTheme.line, width: 1))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 橙色小拨块,仅选中项出现
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent : const Color(0x00000000),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              opt.$2,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: selected ? AppTheme.ink : AppTheme.inkSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
