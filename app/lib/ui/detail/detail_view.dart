import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository/stock_repository.dart';
import '../../state/favorites_store.dart';
import '../../theme/theme.dart';
import '../common/failure_view.dart';
import '../common/load_state.dart';
import 'candle_chart.dart';
import 'current_price.dart';
import 'daily_price_row.dart';
import 'detail_app_bar.dart';
import 'detail_view_model.dart';
import 'period_tabs.dart';
import 'quote_summary_card.dart';

/// 기간을 바꿔 새 구간을 받는 동안 이전 차트 · 표를 흐리게 남긴다.
/// 비우면 탭을 눌렀다는 사실 말고는 아무것도 보이지 않는다.
const double _staleOpacity = 0.4;

/// 기간 전환 페이드. 새로고침이 빠를 때 깜빡임으로 보이지 않을 만큼만 준다.
const Duration _fade = Duration(milliseconds: 180);

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
            DetailAppBar(viewModel: viewModel),
            Expanded(child: _body(viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _body(DetailViewModel viewModel) {
    if (viewModel.state == LoadState.failed) {
      return FailureView(
        message: viewModel.errorMessage,
        onRetry: viewModel.load,
      );
    }

    // 첫 조회에는 이름 · 가격 · 표 어느 것도 없어 스켈레톤으로 채울 형태가 없다.
    if (viewModel.state != LoadState.ready) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.accentDefault),
      );
    }

    final AppDimens dimens = context.dimens;

    // 일별 시세는 1년치가 245행이다. `SingleChildScrollView` + `Column` 으로 두면
    // 기간을 1년으로 바꿀 때 위젯 천 개 이상을 한 프레임에 세워 화면이 멈춘다.
    // sliver 로 두면 보이는 행만 빌드한다.
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            dimens.space4,
            dimens.bodyPaddingTop,
            dimens.space4,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CurrentPrice(viewModel: viewModel),
                SizedBox(height: dimens.space4),
                PeriodTabs(
                  selected: viewModel.period,
                  onChanged: viewModel.changePeriod,
                ),
                ..._periodFailure(viewModel, dimens),
                SizedBox(height: dimens.space4),
                _stale(
                  viewModel,
                  CandleChart(
                    prices: viewModel.chartPrices,
                    axis: viewModel.chartAxis,
                  ),
                ),
                SizedBox(height: dimens.space4),
                QuoteSummaryCard(
                  open: viewModel.openLabel,
                  high: viewModel.highLabel,
                  low: viewModel.lowLabel,
                  volume: viewModel.volumeLabel,
                  marketCap: viewModel.marketCapLabel,
                ),
                SizedBox(height: dimens.space6),
                Text(
                  '일별 시세',
                  style: AppTypography.label.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                SizedBox(height: dimens.space1),
                DailyPriceRow.header(context),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            dimens.space4,
            0,
            dimens.space4,
            dimens.space4,
          ),
          // 행마다 AnimatedOpacity 를 두면 245개가 각각 애니메이션을 돌린다.
          // sliver 하나에 한 번만 건다.
          sliver: SliverOpacity(
            opacity: viewModel.isPeriodLoading ? _staleOpacity : 1,
            sliver: SliverList.builder(
              itemCount: viewModel.dailyRows.length,
              itemBuilder: (BuildContext context, int index) =>
                  DailyPriceRow.of(context, viewModel.dailyRows[index]),
            ),
          ),
        ),
      ],
    );
  }

  /// 기간 전환만 실패한 경우. 이미 그린 구간은 그대로 두고 한 줄로 알린다.
  List<Widget> _periodFailure(DetailViewModel viewModel, AppDimens dimens) {
    final String? message = viewModel.periodError;
    if (message == null) return const <Widget>[];

    return <Widget>[
      SizedBox(height: dimens.space2),
      Text(
        message,
        style: AppTypography.caption.copyWith(
          color: context.colors.feedbackWarning,
        ),
      ),
    ];
  }

  /// 기간을 바꾸면 옛 값이 잠깐 남는다. 그 사이를 흐리게 두고, 새 값이 오면
  /// 페이드로 바꾼다 — 값이 툭 바뀌면 어느 기간을 보고 있는지 놓치기 쉽다.
  Widget _stale(DetailViewModel viewModel, Widget child) => AnimatedOpacity(
    opacity: viewModel.isPeriodLoading ? _staleOpacity : 1,
    duration: _fade,
    curve: Curves.easeOut,
    child: child,
  );
}
