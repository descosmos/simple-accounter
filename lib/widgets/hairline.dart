import 'package:flutter/cupertino.dart';

import '../theme.dart';

/// 1px 浅灰分隔线(电子纸风格的信息层级主要靠它)。
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0, this.endIndent = 0});

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: indent, right: endIndent),
      color: AppTheme.line,
    );
  }
}
