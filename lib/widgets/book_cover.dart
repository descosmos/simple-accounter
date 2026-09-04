import 'package:flutter/cupertino.dart';

import '../models.dart';
import '../theme.dart';

/// 账本封面:暖白底 + 1px 描边 + 炭黑图标,工业铭牌质感(无渐变无阴影)。
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.width = 40,
    this.height = 46,
    this.radius = 10,
    this.iconSize = 19,
  });

  final Book book;
  final double width;
  final double height;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.paper,
        border: Border.all(color: AppTheme.ink, width: 1),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(book.icon, color: AppTheme.ink, size: iconSize),
    );
  }
}
