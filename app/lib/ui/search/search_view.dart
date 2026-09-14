import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/theme.dart';
import '../common/app_icon.dart';
import '../common/empty_state.dart';
import '../common/failure_view.dart';
import '../common/load_state.dart';
import '../detail/detail_view.dart';
import '../common/favorite_toast.dart';
import 'recent_queries.dart';
import 'search_row.dart';
import 'search_ui_model.dart';
import 'search_view_model.dart';

/// 종목 검색 화면. 배치만 하고 하이라이트 구간 · 관심 여부는 ViewModel 이 끝낸 값을 받는다.
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SearchViewModel viewModel = context.watch<SearchViewModel>();

    return Column(
      children: <Widget>[
        _SearchField(
          controller: _controller,
          onChanged: viewModel.onQueryChanged,
          onClear: () {
            _controller.clear();
            viewModel.clearQuery();
          },
        ),
        Expanded(child: _body(viewModel)),
      ],
    );
  }

  Widget _body(SearchViewModel viewModel) {
    if (viewModel.state == LoadState.failed) {
      return FailureView(
        message: viewModel.errorMessage,
        // 같은 검색어를 다시 흘려보내면 디바운스를 거쳐 재조회된다.
        onRetry: () => viewModel.onQueryChanged(viewModel.query),
      );
    }

    final List<SearchRowUi> rows = viewModel.rows;

    // 받아둔 결과가 있으면 다시 조회하는 동안에도 그대로 둔다. 한 글자마다 목록이 깜빡이지 않는다.
    if (rows.isNotEmpty) {
      return ListView.builder(
        itemCount: rows.length,
        itemBuilder: (BuildContext context, int index) => SearchRow(
          row: rows[index],
          onTap: () {
            // 결과를 눌렀다는 건 그 검색어가 찾던 것을 찾아줬다는 뜻이다.
            viewModel.recordQuery();
            openStockDetail(context, rows[index].symbol);
          },
          onFavoriteTap: () => _toggleFavorite(viewModel, rows[index].symbol),
        ),
      );
    }

    if (viewModel.state == LoadState.loading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.accentDefault),
      );
    }

    if (viewModel.state == LoadState.ready) {
      return EmptyState(
        icon: AppIcon.searchEmpty,
        title: '검색 결과가 없습니다',
        description: "'${viewModel.queryLabel}'와\n일치하는 검색 결과를 찾지 못했습니다.",
      );
    }

    if (viewModel.recentQueries.isNotEmpty) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: context.dimens.space4),
        child: RecentQueries(
          queries: viewModel.recentQueries,
          onSelected: _applyQuery,
          onRemoved: viewModel.removeRecentQuery,
          onCleared: viewModel.clearRecentQueries,
        ),
      );
    }

    return const EmptyState(
      icon: AppIcon.search,
      title: '종목을 검색해 보세요',
      description: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
    );
  }

  /// 최근 검색어를 누르면 입력창에도 같은 값을 채워 넣는다 — 입력창과 결과가
  /// 어긋나면 지우기 버튼이 무엇을 지우는지 알 수 없다.
  void _applyQuery(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    context.read<SearchViewModel>().onQueryChanged(query);
  }

  void _toggleFavorite(SearchViewModel viewModel, String symbol) {
    showFavoriteToast(context, added: viewModel.toggleFavorite(symbol));
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.only(
        left: dimens.space4,
        right: dimens.space4,
        top: dimens.space2,
        bottom: dimens.space3,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space3,
          vertical: dimens.fieldPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
          border: Border.all(
            color: colors.borderStrong,
            width: dimens.borderHairline,
          ),
        ),
        child: Row(
          children: <Widget>[
            AppIcon(
              AppIcon.search,
              size: dimens.iconSm,
              color: colors.textTertiary,
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                cursorColor: colors.accentDefault,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
                decoration: InputDecoration.collapsed(
                  hintText: '종목명 또는 종목코드',
                  hintStyle: AppTypography.body.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
            SizedBox(width: dimens.space2),
            // 시안은 입력 전에도 이 버튼을 보여준다. 조건부로 감추지 않는다.
            Semantics(
              button: true,
              label: '검색어 지우기',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: AppIcon(
                  AppIcon.x,
                  size: dimens.iconSm,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
