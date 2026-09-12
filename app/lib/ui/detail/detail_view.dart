import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository/stock_repository.dart';
import '../../state/favorites_store.dart';
import '../../theme/theme.dart';
import '../common/app_icon.dart';
import '../common/failure_view.dart';
import '../common/load_state.dart';
import '../common/price_tone_color.dart';
import 'candle_chart.dart';
import 'daily_price_table.dart';
import 'detail_view_model.dart';
import 'period_tabs.dart';
import 'quote_summary_card.dart';

/// 종목상세 화면을 연다. ViewModel 은 이 라우트에만 살아서 화면을 닫으면 함께 사라진다.
Future<void> openStockDetail(BuildContext context, String symbol) {
  final StockRepository repository = context.read<StockRepository>();
  final FavoritesStore favorites = context.read<FavoritesStore>();

  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) =>
          ChangeNotifierProvider<DetailViewModel>(
            create: (BuildContext context) => DetailViewModel(
              repository: repository,
              favorites: favorites,
              symbol: symbol,
            ),
            child: const DetailView(),
          ),
    ),
  );
}

/// 종목상세 화면. 배치만 하고 포맷 · 기간 전환은 ViewModel 이 끝낸 값을 받는다.
class DetailView extends StatefulWidget {
  const DetailView({super.key});

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  /// 시세를 받지 못한 자리. 0 으로 채우면 실제 값처럼 보인다.
  static const String _missing = '-';

  /// 기간을 바꿔 새 구간을 받는 동안 이전 차트 · 표를 흐리게 남긴다.
  static const double _staleOpacity = 0.4;

  @override
  void initState() {
    super.initState();
    // 첫 빌드 중에 notifyListeners 가 돌지 않도록 프레임 뒤로 미룬다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DetailViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DetailViewModel viewModel = context.watch<DetailViewModel>();

    return Scaffold(
      backgroundColor: context.colors.surfaceBase,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _AppBar(viewModel: viewModel),
            Expanded(child: _body(viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _body(DetailViewModel viewModel) {
    if (viewModel.state == LoadState.failed) {
      return FailureView(
        message: viewModel.errorMessage ?? '시세를 불러오지 못했습니다',
        onRetry: viewModel.load,
      );
    }

    if (viewModel.state != LoadState.ready) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.accentDefault),
      );
    }

    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        dimens.space4,
        dimens.bodyPaddingTop,
        dimens.space4,
        dimens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CurrentPrice(viewModel: viewModel),
          SizedBox(height: dimens.space4),
          PeriodTabs(
            selected: viewModel.period,
            onChanged: viewModel.changePeriod,
          ),
          // 기간 전환이 실패해도 이미 그린 구간은 그대로 둔다.
          if (viewModel.errorMessage != null) ...<Widget>[
            SizedBox(height: dimens.space2),
            Text(
              viewModel.errorMessage!,
              style: AppTypography.caption.copyWith(
                color: colors.feedbackWarning,
              ),
            ),
          ],
          SizedBox(height: dimens.space4),
          _stale(viewModel, CandleChart(prices: viewModel.chartPrices)),
          SizedBox(height: dimens.space4),
          QuoteSummaryCard(
            open: viewModel.openLabel ?? _missing,
            high: viewModel.highLabel ?? _missing,
            low: viewModel.lowLabel ?? _missing,
            volume: viewModel.volumeLabel ?? _missing,
            marketCap: viewModel.marketCapLabel ?? _missing,
          ),
          SizedBox(height: dimens.space6),
          Text(
            '일별 시세',
            style: AppTypography.label.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: dimens.space1),
          _stale(viewModel, DailyPriceTable(rows: viewModel.dailyRows)),
        ],
      ),
    );
  }

  Widget _stale(DetailViewModel viewModel, Widget child) => Opacity(
    opacity: viewModel.isPeriodLoading ? _staleOpacity : 1,
    child: child,
  );
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.viewModel});

  final DetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.appBarPaddingVertical,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: AppIcon(
              AppIcon.back,
              size: dimens.iconMd,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(width: dimens.space3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  viewModel.name ?? viewModel.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                SizedBox(height: dimens.gapTextLine),
                Text(
                  viewModel.marketLabel ?? viewModel.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: dimens.space3),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // 조회 중 · 실패 상태에서는 누를 수 없다. 새로고침 버튼과 같은 방식이다.
            onTap: viewModel.canToggleFavorite ? viewModel.toggleFavorite : null,
            child: AppIcon(
              viewModel.isFavorite ? AppIcon.starFill : AppIcon.star,
              size: dimens.iconFavorite,
              color: _favoriteColor(colors, viewModel),
            ),
          ),
        ],
      ),
    );
  }
}

Color _favoriteColor(AppColors colors, DetailViewModel viewModel) {
  if (!viewModel.canToggleFavorite) return colors.textDisabled;
  return viewModel.isFavorite
      ? colors.favoriteActive
      : colors.favoriteInactive;
}

class _CurrentPrice extends StatelessWidget {
  const _CurrentPrice({required this.viewModel});

  final DetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Flexible(
          child: Text(
            viewModel.priceLabel ?? _DetailViewState._missing,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.displayPrice.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(width: dimens.space2),
        Flexible(
          child: Text(
            viewModel.changeLabel ?? _DetailViewState._missing,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: priceToneText(colors, viewModel.tone),
            ),
          ),
        ),
      ],
    );
  }
}
