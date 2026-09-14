import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../theme/theme.dart';
import '../common/app_icon.dart';
import '../common/favorite_toast.dart';
import '../common/empty_state.dart';
import '../common/failure_view.dart';
import '../common/load_state.dart';
import '../detail/detail_view.dart';
import 'watchlist_row.dart';
import 'watchlist_sort.dart';
import 'watchlist_sort_sheet.dart';
import 'watchlist_ui_model.dart';
import 'watchlist_view_model.dart';

/// 관심 종목 목록 화면. 배치만 하고 정렬 · 포맷은 ViewModel 이 끝낸 값을 받는다.
class WatchlistView extends StatefulWidget {
  const WatchlistView({super.key});

  @override
  State<WatchlistView> createState() => _WatchlistViewState();
}

class _WatchlistViewState extends State<WatchlistView> {
  @override
  void initState() {
    super.initState();
    // 첫 빌드 중에 notifyListeners 가 돌지 않도록 프레임 뒤로 미룬다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WatchlistViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final WatchlistViewModel viewModel = context.watch<WatchlistViewModel>();

    return Column(
      children: <Widget>[
        _Header(
          sort: viewModel.sort,
          // 조회 중에도 막는다. ViewModel 이 중복 요청을 무시하므로 눌러도
          // 아무 일이 없는데, 눌리는 것처럼 보이면 안 된다.
          isBusy:
              viewModel.isRefreshing || viewModel.state == LoadState.loading,
          onSortTap: () => _pickSort(viewModel),
          onRefreshTap: viewModel.refresh,
        ),
        Expanded(child: _body(viewModel)),
      ],
    );
  }

  Widget _body(WatchlistViewModel viewModel) {
    final List<WatchlistRowUi> rows = viewModel.rows;

    // 관심이 하나도 없으면 불러올 것도 없다. 조회가 실패한 뒤 마지막 종목을
    // 해제한 경우까지 빈 상태로 받으려면 실패보다 이쪽을 먼저 본다.
    if (rows.isEmpty) {
      return const EmptyState(
        icon: AppIcon.star,
        title: '관심 종목이 없습니다',
        description: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
      );
    }

    if (viewModel.state == LoadState.failed) {
      return FailureView(
        message: viewModel.errorMessage,
        onRetry: viewModel.load,
      );
    }

    // 조회 중에도 행은 이미 있고 가격 자리만 스켈레톤이라 따로 로딩 화면을 두지 않는다.

    // 당겨서 새로고침은 헤더의 새로고침 버튼과 같은 동작을 부른다.
    // 행이 몇 개 없어 스크롤이 생기지 않을 때도 당길 수 있어야 하므로 physics 를 고정한다.
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: context.colors.accentDefault,
      backgroundColor: context.colors.surfaceOverlay,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows.length,
        itemBuilder: (BuildContext context, int index) =>
            _dismissible(context, rows[index]),
      ),
    );
  }

  /// 왼쪽으로 밀어 관심 해제. 시안에 없는 동작이라 배경은 해제 상태 색
  /// (`favoriteInactive`)으로만 알린다. 확인 다이얼로그 대신 **실행 취소**를 붙였다 —
  /// 미는 동작은 실수하기 쉬운데 매번 확인을 받으면 제대로 민 경우가 번거로워진다.
  Widget _dismissible(BuildContext context, WatchlistRowUi row) {
    final AppDimens dimens = context.dimens;

    return Dismissible(
      key: ValueKey<String>(row.symbol),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeFavorite(row.symbol),
      background: ColoredBox(
        color: context.colors.surfaceSunken,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dimens.space4),
          child: Align(
            alignment: Alignment.centerRight,
            child: AppIcon(
              AppIcon.star,
              size: dimens.iconMd,
              color: context.colors.favoriteInactive,
            ),
          ),
        ),
      ),
      child: WatchlistRow(
        row: row,
        onTap: () => openStockDetail(context, row.symbol),
      ),
    );
  }

  void _removeFavorite(String symbol) {
    final WatchlistViewModel viewModel = context.read<WatchlistViewModel>();
    viewModel.removeFavorite(symbol);
    // 행이 사라지는 순간을 손으로도 알린다. 스와이프는 화면을 안 보고도 한다.
    HapticFeedback.lightImpact();
    showFavoriteToast(
      context,
      added: false,
      onUndo: viewModel.undoRemoveFavorite,
    );
  }

  Future<void> _pickSort(WatchlistViewModel viewModel) async {
    final WatchlistSort? picked = await showWatchlistSortSheet(
      context,
      current: viewModel.sort,
    );
    if (picked != null) viewModel.changeSort(picked);
  }
}

/// 새로고침 한 바퀴. 요청이 짧게 끝나도 반 바퀴에서 끊기지 않을 만큼이다.
const Duration _spin = Duration(milliseconds: 900);

class _Header extends StatelessWidget {
  const _Header({
    required this.sort,
    required this.isBusy,
    required this.onSortTap,
    required this.onRefreshTap,
  });

  final WatchlistSort sort;
  final bool isBusy;
  final VoidCallback onSortTap;
  final VoidCallback onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            '관심',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                button: true,
                label: '정렬 기준 ${sort.label}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSortTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: dimens.space1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          sort.label,
                          style: AppTypography.label.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        AppIcon(
                          AppIcon.align,
                          size: dimens.iconMd,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: dimens.space4),
              Semantics(
                button: true,
                enabled: !isBusy,
                label: isBusy ? '시세 갱신 중' : '시세 새로고침',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // 갱신 중에는 같은 요청을 겹치지 않도록 막고 색을 낮춘다.
                  onTap: isBusy ? null : onRefreshTap,
                  child: _SpinningRefresh(
                    isBusy: isBusy,
                    size: dimens.iconMd,
                    color: isBusy ? colors.textDisabled : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 갱신 중에는 새로고침 아이콘이 돈다. 색만 낮추면 눌린 건지 멈춘 건지 알 수 없다.
class _SpinningRefresh extends StatefulWidget {
  const _SpinningRefresh({
    required this.isBusy,
    required this.size,
    required this.color,
  });

  final bool isBusy;
  final double size;
  final Color color;

  @override
  State<_SpinningRefresh> createState() => _SpinningRefreshState();
}

class _SpinningRefreshState extends State<_SpinningRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _spin,
  );

  @override
  void didUpdateWidget(_SpinningRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBusy) {
      _controller.repeat();
    } else {
      // 돌던 자리에서 끊지 않고 한 바퀴를 마치고 멈춘다.
      _controller.animateTo(1, duration: _spin * (1 - _controller.value));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _controller,
    child: AppIcon(AppIcon.refresh, size: widget.size, color: widget.color),
  );
}
