import 'package:flutter/cupertino.dart';

import '../models.dart';
import '../theme.dart';

/// 分类字块:不使用彩色圆形图标。
/// 默认透明底 + 炭黑首字;选中 = 浅灰底 + 黑色描边 + 橙色小点。
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    this.size = 48,
    this.selected = false,
  });

  final Category category;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? AppTheme.paperDim : const Color(0x00000000),
        border: Border.all(
          color: selected ? AppTheme.ink : AppTheme.line,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              category.avatarChar,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: AppTheme.ink,
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
