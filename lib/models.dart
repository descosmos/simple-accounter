import 'package:flutter/cupertino.dart';

/// 账单类型:支出 / 收入
enum TxnType { expense, income }

/// 账本封面可选图标(SF Symbols 风格)。
/// 以索引形式持久化,避免非常量 IconData 阻断字体 tree-shake。
const List<IconData> bookCoverIcons = [
  CupertinoIcons.book_fill,
  CupertinoIcons.tray_full_fill,
  CupertinoIcons.briefcase_fill,
  CupertinoIcons.cart_fill,
  CupertinoIcons.house_fill,
  CupertinoIcons.airplane,
  CupertinoIcons.gift_fill,
  CupertinoIcons.heart_fill,
  CupertinoIcons.paw_solid,
  CupertinoIcons.star_fill,
  CupertinoIcons.game_controller_solid,
  CupertinoIcons.music_note,
];

/// 分类(内置 + 自定义)
class Category {
  Category({
    required this.key,
    required this.title,
    required this.type,
    required this.colorValue,
    this.isCustom = false,
  });

  /// 拼音 key(内置)或 custom_ 前缀 id(自定义)
  final String key;
  String title;
  final TxnType type;
  int colorValue;
  final bool isCustom;

  Color get color => Color(colorValue);

  /// 头像字符:取标题首字
  String get avatarChar => title.isEmpty ? '?' : title.characters.first;

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'type': type.index,
    'color': colorValue,
  };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    key: j['key'] as String,
    title: j['title'] as String,
    type: TxnType.values[j['type'] as int],
    colorValue: j['color'] as int,
    isCustom: true,
  );
}

/// 账本
class Book {
  Book({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconIndex,
    this.mode = BookMode.monthly,
    this.monthStartDay = 1,
    this.currencyCode = 'CNY',
    this.currencySymbol = '¥',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  final String id;
  String name;
  int colorValue;

  /// bookCoverIcons 下标
  int iconIndex;

  /// 账本类型:月度(按账期查看) / 事件(一件事全程累计,不分月)
  BookMode mode;

  /// 月起始日 1~28(账期从该日开始,仅月度账本生效)
  int monthStartDay;
  String currencyCode;
  String currencySymbol;
  final int createdAt;

  Color get color => Color(colorValue);

  IconData get icon =>
      bookCoverIcons[iconIndex.clamp(0, bookCoverIcons.length - 1)];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': colorValue,
    'icon': iconIndex,
    'mode': mode.index,
    'monthStartDay': monthStartDay,
    'currencyCode': currencyCode,
    'currencySymbol': currencySymbol,
    'createdAt': createdAt,
  };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
    id: j['id'] as String,
    name: j['name'] as String,
    colorValue: j['color'] as int,
    iconIndex: (j['icon'] as num?)?.toInt() ?? 0,
    mode: BookMode.values[(j['mode'] as num?)?.toInt() ?? 0],
    monthStartDay: (j['monthStartDay'] as num?)?.toInt() ?? 1,
    currencyCode: j['currencyCode'] as String? ?? 'CNY',
    currencySymbol: j['currencySymbol'] as String? ?? '¥',
    createdAt: (j['createdAt'] as num).toInt(),
  );
}

/// 账本类型
enum BookMode {
  /// 月度账本:按月起始日划分账期,逐月翻看
  monthly,

  /// 事件账本:一件事(旅行/装修等)全程持续累计,与月份无关
  event,
}

/// 一笔账单
class Txn {
  Txn({
    required this.id,
    required this.bookId,
    required this.type,
    required this.categoryKey,
    required this.amountCents,
    this.remark = '',
    required this.date,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  final String id;
  final String bookId;
  TxnType type;
  String categoryKey;
  int amountCents;
  String remark;

  /// 记账日期(毫秒,取到天)
  int date;
  final int createdAt;

  DateTime get day => DateTime.fromMillisecondsSinceEpoch(date);

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'type': type.index,
    'categoryKey': categoryKey,
    'amountCents': amountCents,
    'remark': remark,
    'date': date,
    'createdAt': createdAt,
  };

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
    id: j['id'] as String,
    bookId: j['bookId'] as String,
    type: TxnType.values[j['type'] as int],
    categoryKey: j['categoryKey'] as String,
    amountCents: (j['amountCents'] as num).toInt(),
    remark: j['remark'] as String? ?? '',
    date: (j['date'] as num).toInt(),
    createdAt: (j['createdAt'] as num).toInt(),
  );
}
