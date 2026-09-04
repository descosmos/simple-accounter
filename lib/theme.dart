import 'package:flutter/cupertino.dart';

/// 暖白电子纸 × 工业极简(Warm E-ink Industrial Minimalism)。
///
/// 规则:
/// - 背景暖白/米灰,禁止纯白与渐变、阴影、玻璃拟态;
/// - 全 App 唯一强调色为机械橙,且每页至多一个橙色焦点;
/// - 层级靠字号/字重/间距/1px 细线建立,不靠色块与卡片;
/// - 金额使用等宽/点阵数字;收入支出靠正负号与字重区分,不用红绿。
class AppTheme {
  AppTheme._();

  // ---- 色彩规范 ----
  static const Color paper = Color(0xFFF4F2EC); // 主背景
  static const Color paperDim = Color(0xFFECE9E2); // 次级背景/按压
  static const Color ink = Color(0xFF1C1C1A); // 主文字(炭黑)
  static const Color inkSub = Color(0xFF6F6D67); // 次级文字
  static const Color inkWeak = Color(0xFF9A9790); // 弱文字
  static const Color line = Color(0xFFD5D1C8); // 分隔线
  static const Color accent = Color(0xFFE35F2D); // 强调橙
  static const Color accentDown = Color(0xFFC94C22); // 强调橙按下

  static const double radius = 12.0; // 克制的圆角
  static const double pageMargin = 20.0; // 页面左右边距

  // ---- 数字 ----
  /// 点阵数字(仅用于本月结余、金额输入等核心数字)
  static TextStyle dots(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: 'EinkDots',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.5,
      height: 1.0,
    );
  }

  /// 等宽数字(普通账单金额)
  static TextStyle mono(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // ---- 文字 ----
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: ink,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: inkSub,
  );

  /// 日期/英文小标题:窄体大写感(用 letterSpacing 模拟)
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: inkSub,
    letterSpacing: 1.6,
  );
}

/// 兼容旧调用:动态色解析已不需要,统一返回颜色本身。
Color resolve(Color color, BuildContext context) => color;
