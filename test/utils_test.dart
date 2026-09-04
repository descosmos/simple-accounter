import 'package:flutter_test/flutter_test.dart';
import 'package:simple_ledger/utils.dart';

void main() {
  group('fmtCents', () {
    test('基本格式化', () {
      expect(fmtCents(0), '0.00');
      expect(fmtCents(5), '0.05');
      expect(fmtCents(123456789), '1,234,567.89');
      expect(fmtCents(-4500), '-45.00');
      expect(fmtCents(100000), '1,000.00');
    });
  });

  group('evalAmountExpr', () {
    test('加减连算', () {
      expect(evalAmountExpr('12'), 12);
      expect(evalAmountExpr('12+3.5'), 15.5);
      expect(evalAmountExpr('12+3.5-2'), 13.5);
      expect(evalAmountExpr('0.1+0.2'), 0.3);
      expect(evalAmountExpr('100-200'), -100);
    });
    test('非法输入', () {
      expect(evalAmountExpr(''), isNull);
      expect(evalAmountExpr('12+'), isNull);
      expect(evalAmountExpr('abc'), isNull);
    });
  });

  group('periodOf', () {
    test('月起始日为 1 时是自然月', () {
      final p = periodOf(DateTime(2026, 9, 2), 1);
      expect(p.start, DateTime(2026, 9, 1));
      expect(p.end, DateTime(2026, 10, 1));
      expect(p.isNaturalMonth, isTrue);
      expect(p.contains(DateTime(2026, 9, 30, 23, 59)), isTrue);
      expect(p.contains(DateTime(2026, 10, 1)), isFalse);
    });
    test('月起始日为 15 时跨月', () {
      // 9月2日属于 8.15-9.15 账期
      var p = periodOf(DateTime(2026, 9, 2), 15);
      expect(p.start, DateTime(2026, 8, 15));
      expect(p.end, DateTime(2026, 9, 15));
      // 9月20日属于 9.15-10.15 账期
      p = periodOf(DateTime(2026, 9, 20), 15);
      expect(p.start, DateTime(2026, 9, 15));
      expect(p.end, DateTime(2026, 10, 15));
      expect(p.contains(DateTime(2026, 9, 15)), isTrue);
      expect(p.contains(DateTime(2026, 10, 15)), isFalse);
    });
    test('账期前后翻页回到同一账期', () {
      final p = periodOf(DateTime(2026, 9, 2), 15);
      final prev = prevPeriod(p, 15);
      expect(prev.contains(DateTime(2026, 8, 1)), isTrue);
      final next = nextPeriod(prev, 15);
      expect(next.start, p.start);
    });
  });
}
