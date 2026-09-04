import 'package:flutter/cupertino.dart';

import '../theme.dart';

/// 电子纸风格记账键盘:细线描边按键 + 等宽数字。
/// 完成键为暖白底、黑色描边、右侧橙红小箭头(不大面积使用橙色)。
class CalcKeyboard extends StatelessWidget {
  const CalcKeyboard({
    super.key,
    required this.onKey,
    required this.onDelete,
    required this.onDate,
    required this.onDone,
    this.dateLabel = '今天',
  });

  /// key: '0'..'9' | '.' | '+' | '-'
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback onDate;
  final VoidCallback onDone;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['7', '8', '9', '+'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', 'del'],
      ['.', '0', 'date', 'done'],
    ];
    return Container(
      color: AppTheme.paper,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Expanded(
              child: Row(
                children: [
                  for (final k in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(3.5),
                        child: _key(k),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _key(String k) {
    if (k == 'done') {
      return _KeyFrame(
        onTap: onDone,
        borderColor: AppTheme.ink,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '完成',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.ink,
              ),
            ),
            SizedBox(width: 6),
            Icon(CupertinoIcons.arrow_right, size: 15, color: AppTheme.accent),
          ],
        ),
      );
    }
    if (k == 'del') {
      return _KeyFrame(
        onTap: onDelete,
        child: const Icon(
          CupertinoIcons.delete_left,
          color: AppTheme.ink,
          size: 22,
        ),
      );
    }
    if (k == 'date') {
      return _KeyFrame(
        onTap: onDate,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.calendar, color: AppTheme.ink, size: 16),
            Text(
              dateLabel,
              style: const TextStyle(fontSize: 9, color: AppTheme.inkSub),
            ),
          ],
        ),
      );
    }
    final isOp = k == '+' || k == '-';
    return _KeyFrame(
      onTap: () => onKey(k),
      child: Text(
        isOp ? (k == '+' ? '＋' : '－') : k,
        style: AppTheme.mono(
          22,
          weight: isOp ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _KeyFrame extends StatelessWidget {
  const _KeyFrame({
    required this.onTap,
    required this.child,
    this.borderColor = AppTheme.line,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      pressedOpacity: 0.4,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.paper,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
