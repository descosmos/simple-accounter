import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_ledger/pages/stats_page.dart';

void main() {
  testWidgets('RangeChart 双指放大后柱子加宽可横滑,点按仍可选中', (tester) async {
    final selected = <int>[];
    final points = [
      for (var d = 1; d <= 30; d++)
        BarPoint('$d', '9月$d日', d * 10000, d % 3 == 0 ? 800000 : 0),
    ];
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: SizedBox(
              width: 360,
              child: RangeChart(points: points, onSelect: selected.add),
            ),
          ),
        ),
      ),
    );

    ScrollPosition pos() =>
        tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // 未放大时:内容刚好铺满,不可横滑
    expect(pos().maxScrollExtent, 0);

    // 双指向外捏合 → 放大
    final center = tester.getCenter(find.byType(RangeChart));
    final g1 = await tester.startGesture(center - const Offset(40, 0));
    final g2 = await tester.startGesture(center + const Offset(40, 0));
    await g2.moveBy(const Offset(120, 0));
    await tester.pump();
    await g1.moveBy(const Offset(-40, 0));
    await tester.pump();
    await g1.up();
    await g2.up();
    await tester.pump();
    await tester.pump(); // 等 postFrameCallback 的 jumpTo 落地

    // 放大后:内容超出视口,可以横滑
    expect(pos().maxScrollExtent, greaterThan(0));

    // 放大到足够宽后,每个刻度都显示
    expect(find.text('13'), findsOneWidget);

    // 横滑生效
    await tester.drag(find.byType(RangeChart), const Offset(-100, 0));
    await tester.pump();
    expect(pos().pixels, greaterThan(0));

    // 点按仍然触发 onSelect(点柱子区域,避开底部刻度行)
    await tester.tapAt(
      tester.getTopLeft(find.byType(RangeChart)) + const Offset(180, 60),
    );
    expect(selected, isNotEmpty);
  });
}
