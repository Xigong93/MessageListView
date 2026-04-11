import 'package:flutter/widgets.dart';

class MessageListController {
  final scrollController = ScrollController();

  /// 滚动到顶部
  void scrollToTop({bool anim = true}) {}

  /// 滚动到底部
  void scrollToBottom({bool anim = true}) {}

  /// 列表当前是否处于底部
  bool get atBottom => false;

  void dispose() {}
}
