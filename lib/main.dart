import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/dashboard_page.dart';
import 'pages/details_page.dart';
import 'pages/record_page.dart';
import 'pages/settings_page.dart';
import 'pages/stats_page.dart';
import 'store.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SimpleLedgerApp());
}

class SimpleLedgerApp extends StatefulWidget {
  const SimpleLedgerApp({super.key});

  @override
  State<SimpleLedgerApp> createState() => _SimpleLedgerAppState();
}

class _SimpleLedgerAppState extends State<SimpleLedgerApp> {
  late final Future<void> _loading = ledgerStore.load();

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: '简账',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      locale: const Locale('zh', 'CN'),
      theme: const CupertinoThemeData(
        primaryColor: AppTheme.accent,
        scaffoldBackgroundColor: AppTheme.paper,
        barBackgroundColor: AppTheme.paper,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontSize: 15,
            color: AppTheme.ink,
            letterSpacing: 0,
          ),
        ),
      ),
      home: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CupertinoPageScaffold(
              backgroundColor: AppTheme.paper,
              child: Center(child: CupertinoActivityIndicator(radius: 13)),
            );
          }
          return const RootTabs();
        },
      ),
    );
  }
}

/// 底部五栏:首页 / 明细 / 记一笔 / 统计 / 设置。
/// 「记一笔」为动作项(小型橙点标记),弹出记账页,不切换页面。
class RootTabs extends StatefulWidget {
  const RootTabs({super.key});

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  int _index = 0;

  void _openRecord() {
    HapticFeedback.lightImpact();
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const RecordPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.paper,
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                DashboardPage(onGoDetails: () => setState(() => _index = 1)),
                const DetailsPage(),
                SizedBox.shrink(), // 记一笔占位,永不显示
                StatsPage(),
                SettingsPage(),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.paper,
              border: Border(top: BorderSide(color: AppTheme.line, width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 54,
                child: Row(
                  children: [
                    _item(0, CupertinoIcons.home, '首页'),
                    _item(1, CupertinoIcons.list_bullet, '明细'),
                    _recordItem(),
                    _item(3, CupertinoIcons.chart_bar, '统计'),
                    _item(4, CupertinoIcons.gear, '设置'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(int index, IconData icon, String label) {
    final active = _index == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _index = index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppTheme.ink : AppTheme.inkWeak,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: active ? AppTheme.ink : AppTheme.inkWeak,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordItem() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openRecord,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 描边方块 + 橙色小点,像设备上的机械拨片,保持可操作感
                Container(
                  width: 36,
                  height: 26,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.ink, width: 1.2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.plus,
                    size: 17,
                    color: AppTheme.ink,
                  ),
                ),
                Positioned(
                  right: -5,
                  top: -3,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              '记一笔',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
