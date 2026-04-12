/// 加载更多内容的状态。
enum LoadMoreStatus {
  /// 空闲，可以触发加载。
  idle,

  /// 加载中。
  loading,

  /// 没有更多数据。
  noMore,

  /// 加载失败。
  error,
}
