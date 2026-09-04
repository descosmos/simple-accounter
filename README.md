# simple-accounter（简账）

一个使用 Flutter 构建的极简记账 App，采用 Cupertino 风格 + 墨水屏（e-ink）质感设计，数据完全存储在本地。

## 功能

- **记账**：快速记一笔收入/支出，自带计算器键盘
- **多账本**：支持创建和切换多个账本
- **分类管理**：自定义收支分类与图标
- **明细**：按日浏览流水明细
- **统计**：收支统计分析
- **设置**：主题与偏好设置

## 技术栈

- Flutter（Cupertino UI，中文本地化）
- 本地持久化存储（path_provider）
- 自定义字体（VT323 / EinkDots）

## 项目结构

```
lib/
├── main.dart        # 入口
├── store.dart       # 数据存储层
├── models.dart      # 数据模型
├── theme.dart       # 主题
├── pages/           # 页面（记账、明细、统计、设置、账本等）
└── widgets/         # 通用组件（计算器键盘、分类头像等）
```

## 运行

```bash
flutter pub get
flutter run
```

## 测试

```bash
flutter test
```
