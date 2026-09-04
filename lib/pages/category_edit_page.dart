import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/category_avatar.dart';
import '../widgets/hairline.dart';

/// 新建 / 编辑自定义分类:名称(≤4字)。
class CategoryEditPage extends StatefulWidget {
  const CategoryEditPage({super.key, required this.type, this.category});

  final TxnType type;
  final Category? category;

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  late final bool _isNew = widget.category == null;
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.category?.title ?? '',
  );
  late final int _colorValue =
      widget.category?.colorValue ?? AppTheme.ink.toARGB32();

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_canSave) return;
    HapticFeedback.mediumImpact();
    final title = _nameCtrl.text.trim();
    if (_isNew) {
      ledgerStore.addCustomCategory(
        title: title,
        type: widget.type,
        colorValue: _colorValue,
      );
    } else {
      widget.category!
        ..title = title
        ..colorValue = _colorValue;
      ledgerStore.updateCustomCategory(widget.category!);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final typeName = widget.type == TxnType.expense ? '支出' : '收入';
    final preview = Category(
      key: 'preview',
      title: _nameCtrl.text.trim().isEmpty ? '类' : _nameCtrl.text.trim(),
      type: widget.type,
      colorValue: _colorValue,
    );

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    pressedOpacity: 0.5,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消', style: AppTheme.body),
                  ),
                  const Spacer(),
                  Text(
                    _isNew ? '新建$typeName分类' : '编辑分类',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _canSave ? _save : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '保存',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _canSave ? AppTheme.ink : AppTheme.inkWeak,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    child: Center(
                      child: CategoryTile(
                        category: preview,
                        size: 72,
                        selected: true,
                      ),
                    ),
                  ),
                  const Text('名称', style: AppTheme.overline),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: _nameCtrl,
                    placeholder: '限 4 个汉字',
                    placeholderStyle: AppTheme.body.copyWith(
                      color: AppTheme.inkWeak,
                    ),
                    style: AppTheme.body,
                    decoration: null,
                    maxLength: 4,
                    onChanged: (_) => setState(() {}),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  const Hairline(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
