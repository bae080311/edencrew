/// 상세 화면의 기간 탭. 표시 문자열은 View 가 갖는다.
///
/// 일별 시세 1페이지 = 10거래일이라 필요한 페이지 수가 기간마다 정해진다.
/// 받은 페이지는 repository 가 재사용하므로 `1개월 → 3개월` 전환 때
/// 1~2 페이지를 다시 받지 않는다.
enum ChartPeriod {
  oneMonth(tradingDays: 20, pageCount: 2),
  threeMonths(tradingDays: 60, pageCount: 6),
  sixMonths(tradingDays: 120, pageCount: 12),
  oneYear(tradingDays: 245, pageCount: 25);

  const ChartPeriod({required this.tradingDays, required this.pageCount});

  final int tradingDays;
  final int pageCount;
}
