import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/theme.dart';
import '../common/app_icon.dart';
import '../common/load_state.dart';
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
    if (rows.isEmpty) return const _Empty();

    if (viewModel.state == LoadState.failed) {
      return _Failure(
        message: viewModel.errorMessage ?? '시세를 불러오지 못했습니다',
        onRetry: viewModel.load,
      );
    }

    // 조회 중에도 행은 이미 있고 가격 자리만 스켈레톤이라 따로 로딩 화면을 두지 않는다.

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (BuildContext context, int index) =>
          WatchlistRow(row: rows[index]),
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
              GestureDetector(
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
              SizedBox(width: dimens.space4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // 갱신 중에는 같은 요청을 겹치지 않도록 막고 색을 낮춘다.
                onTap: isBusy ? null : onRefreshTap,
                child: AppIcon(
                  AppIcon.refresh,
                  size: dimens.iconMd,
                  color: isBusy ? colors.textDisabled : colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIcon(
              AppIcon.star,
              size: dimens.iconEmpty,
              color: colors.textTertiary,
            ),
            SizedBox(height: dimens.space3),
            Text(
              '관심 종목이 없습니다',
              style: AppTypography.title.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: dimens.space3),
            Text(
              '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 시안에 없는 상태다. 사용자가 할 수 있는 일이 다시 시도 하나뿐이라 단순하게 둔다.
class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: dimens.space3),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: colors.accentDefault,
              ),
              child: Text('다시 시도', style: AppTypography.label),
            ),
          ],
        ),
      ),
    );
  }
}
