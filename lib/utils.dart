/// 金额、日期等纯工具函数(无 Flutter 依赖,便于单测)。
library;

/// 分 -> "1,234.56"
String fmtCents(int cents) {
  final neg = cents < 0;
  final abs = cents.abs();
  final yuan = abs ~/ 100;
  final fen = (abs % 100).toString().padLeft(2, '0');
  final s = yuan.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final remain = s.length - i;
    buf.write(s[i]);
    if (remain > 1 && remain % 3 == 1) buf.write(',');
  }
  return '${neg ? '-' : ''}$buf.$fen';
}

/// 计算 "12+3.5-2" 这类只含加减的表达式,非法输入返回 null。
double? evalAmountExpr(String expr) {
  if (expr.isEmpty) return null;
  // 按 +/- 的前瞻位置切分,符号保留在后一个数字上,如 ['12', '+3.5', '-2']
  final tokens = expr.split(RegExp(r'(?=[+\-])'));
  var sum = 0.0;
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    if (t.isEmpty) {
      if (i == 0) continue; // 表达式以符号开头
      return null;
    }
    final v = double.tryParse(t);
    if (v == null) return null;
    sum += v;
  }
  // 规避浮点误差,保留两位
  return (sum * 100).roundToDouble() / 100;
}

/// 账本账期:monthStartDay 为月起始日(1~28)。
/// 返回 [start, end) 的闭开区间。
class Period {
  Period(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  bool get isNaturalMonth =>
      start.day == 1 && end.month == (start.month % 12) + 1;

  String label() {
    if (isNaturalMonth) return '${start.year}年${start.month}月';
    return '${start.month}.${start.day} – ${end.month}.${end.day - 1 < 1 ? 1 : end.day - 1}';
  }

  /// 短标签,如 "9月" 或 "8.15–9.14"
  String shortLabel() {
    if (isNaturalMonth) return '${start.month}月';
    final e = end.subtract(const Duration(days: 1));
    return '${start.month}.${start.day}–${e.month}.${e.day}';
  }
}

Period periodOf(DateTime anchor, int monthStartDay) {
  final d = monthStartDay.clamp(1, 28);
  final y = anchor.year;
  final m = anchor.month;
  if (d == 1) {
    return Period(DateTime(y, m), DateTime(y, m + 1));
  }
  if (anchor.day >= d) {
    return Period(DateTime(y, m, d), DateTime(y, m + 1, d));
  }
  return Period(DateTime(y, m - 1, d), DateTime(y, m, d));
}

Period nextPeriod(Period p, int monthStartDay) => periodOf(
  p.start.add(Duration(days: (p.end.difference(p.start).inDays))),
  monthStartDay,
);

Period prevPeriod(Period p, int monthStartDay) =>
    periodOf(p.start.subtract(const Duration(days: 1)), monthStartDay);

const weekdaysCn = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String weekdayCn(DateTime d) => weekdaysCn[d.weekday - 1];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dayLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return '今天';
  if (day == today.subtract(const Duration(days: 1))) return '昨天';
  return '${d.month}月${d.day}日 ${weekdayCn(d)}';
}

/// 英文月份/星期(参考设备的窄体大写风格)
const monthAbbrEn = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

const monthFullEn = [
  'JANUARY',
  'FEBRUARY',
  'MARCH',
  'APRIL',
  'MAY',
  'JUNE',
  'JULY',
  'AUGUST',
  'SEPTEMBER',
  'OCTOBER',
  'NOVEMBER',
  'DECEMBER',
];

const weekdayFullEn = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

/// 账期标题:自然月用英文大写(SEPTEMBER 2026),自定义区间用中文。
String periodLabelEn(Period p) {
  if (p.isNaturalMonth) {
    return '${monthFullEn[p.start.month - 1]} ${p.start.year}';
  }
  return p.label();
}
