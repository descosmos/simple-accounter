import 'package:flutter/services.dart' show rootBundle;

/// 应用版本号(如 1.0.1)。单一来源是 pubspec.yaml 的 version 字段:
/// 构建时随 assets 打包,启动时由 [loadAppInfo] 解析到内存。
String appVersion = '';

/// 启动时读取打包的 pubspec.yaml,解析出展示用版本号。
/// 失败时保持空串,不阻塞启动。
Future<void> loadAppInfo() async {
  try {
    final text = await rootBundle.loadString('pubspec.yaml');
    final m = RegExp(
      r'^version:\s*([^\s+]+)',
      multiLine: true,
    ).firstMatch(text);
    appVersion = m?.group(1) ?? '';
  } catch (_) {
    // 忽略:设置页将只显示应用名
  }
}
