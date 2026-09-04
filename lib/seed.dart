import 'package:flutter/cupertino.dart';

import 'models.dart';

/// 内置分类(参考喵喵记账 assets/billcats.json 的分类体系),
/// 视觉执行改为 iOS 风格:系统色圆形 + 首字头像。
Category _c(String key, String title, TxnType type, Color color) =>
    Category(key: key, title: title, type: type, colorValue: color.toARGB32());

final List<Category> seedCategories = [
  // ---- 支出 34 项 ----
  _c('canyin', '餐饮', TxnType.expense, CupertinoColors.systemOrange),
  _c('gouwu', '购物', TxnType.expense, CupertinoColors.systemPink),
  _c('riyong', '日用', TxnType.expense, CupertinoColors.systemTeal),
  _c('jiaotong', '交通', TxnType.expense, CupertinoColors.systemBlue),
  _c('shucai', '蔬菜', TxnType.expense, CupertinoColors.systemGreen),
  _c('shuiguo', '水果', TxnType.expense, CupertinoColors.systemRed),
  _c('lingshi', '零食', TxnType.expense, CupertinoColors.systemYellow),
  _c('yundong', '运动', TxnType.expense, CupertinoColors.systemIndigo),
  _c('yule', '娱乐', TxnType.expense, CupertinoColors.systemPurple),
  _c('tongxun', '通讯', TxnType.expense, CupertinoColors.systemCyan),
  _c('fushi', '服饰', TxnType.expense, CupertinoColors.systemPink),
  _c('meirong', '美容', TxnType.expense, CupertinoColors.systemPurple),
  _c('zhufang', '住房', TxnType.expense, CupertinoColors.systemBrown),
  _c('jiating', '家庭', TxnType.expense, CupertinoColors.systemOrange),
  _c('shejiao', '社交', TxnType.expense, CupertinoColors.systemRed),
  _c('lvxing', '旅行', TxnType.expense, CupertinoColors.systemBlue),
  _c('yanjiu', '烟酒', TxnType.expense, CupertinoColors.systemBrown),
  _c('shuma', '数码', TxnType.expense, CupertinoColors.systemIndigo),
  _c('qiche', '汽车', TxnType.expense, CupertinoColors.systemTeal),
  _c('yiliao', '医疗', TxnType.expense, CupertinoColors.systemRed),
  _c('shuji', '书籍', TxnType.expense, CupertinoColors.systemBrown),
  _c('xuexi', '学习', TxnType.expense, CupertinoColors.systemBlue),
  _c('chongwu', '宠物', TxnType.expense, CupertinoColors.systemOrange),
  _c('lijin', '礼金', TxnType.expense, CupertinoColors.systemRed),
  _c('lipin', '礼品', TxnType.expense, CupertinoColors.systemPink),
  _c('bangong', '办公', TxnType.expense, CupertinoColors.systemIndigo),
  _c('weixiu', '维修', TxnType.expense, CupertinoColors.systemGrey),
  _c('juanzeng', '捐赠', TxnType.expense, CupertinoColors.systemGreen),
  _c('caipiao', '彩票', TxnType.expense, CupertinoColors.systemYellow),
  _c('hongbao', '红包', TxnType.expense, CupertinoColors.systemRed),
  _c('kuaidi', '快递', TxnType.expense, CupertinoColors.systemTeal),
  _c('qita', '其它', TxnType.expense, CupertinoColors.systemGrey),
  _c('huankuan', '还款', TxnType.expense, CupertinoColors.systemPurple),
  _c('jiechu', '借出', TxnType.expense, CupertinoColors.systemOrange),
  // ---- 收入 10 项 ----
  _c('gongzi', '工资', TxnType.income, CupertinoColors.systemGreen),
  _c('hongbao_in', '红包', TxnType.income, CupertinoColors.systemRed),
  _c('zujin', '租金', TxnType.income, CupertinoColors.systemTeal),
  _c('lijin_in', '礼金', TxnType.income, CupertinoColors.systemPink),
  _c('fenhong', '分红', TxnType.income, CupertinoColors.systemPurple),
  _c('licai', '理财', TxnType.income, CupertinoColors.systemBlue),
  _c('nianzhongjiang', '年终奖', TxnType.income, CupertinoColors.systemOrange),
  _c('qita_in', '其它', TxnType.income, CupertinoColors.systemGrey),
  _c('jieru', '借入', TxnType.income, CupertinoColors.systemBrown),
  _c('shoukuan', '收款', TxnType.income, CupertinoColors.systemIndigo),
];

/// 可选币种
const List<(String, String)> currencies = [
  ('CNY', '¥'),
  ('USD', '\$'),
  ('EUR', '€'),
  ('GBP', '£'),
  ('JPY', 'JP¥'),
  ('HKD', 'HK\$'),
  ('TWD', 'NT\$'),
];
