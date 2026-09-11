import 'dart:math';

import 'package:cp949_codec/cp949_codec.dart';

import '../dto/daily_price_dto.dart';

/// 일별 시세 HTML 을 표 단위로 읽는다.
///
/// 바이트를 받아 직접 디코딩한다 — 응답이 **EUC-KR** 이라 호출자가 문자열로
/// 먼저 바꾸면 이미 깨진 뒤다.
class SiseDayParser {
  const SiseDayParser();

  static final RegExp _row = RegExp(r'<tr[^>]*>.*?</tr>', dotAll: true);
  static final RegExp _date = RegExp(r'(\d{4})\.(\d{2})\.(\d{2})');

  /// 날짜는 `p10`, 숫자는 `p11` 로 갈린다. 전일비만 `p11 nv01`/`p11 red02` 처럼
  /// 색 class 가 덧붙는다.
  static final RegExp _number = RegExp(
    r'<span class="tah p11[^"]*">\s*([\d,]+)\s*</span>',
  );
  static final RegExp _direction = RegExp(r'<em class="bu_p (bu_p\w+)"');
  static final RegExp _navigation = RegExp(
    r'<table[^>]*class="Nnavi".*?</table>',
    dotAll: true,
  );
  static final RegExp _lastPageLink = RegExp(
    r'class="pgRR">\s*<a href="[^"]*?page=(\d+)',
  );
  static final RegExp _anyPageLink = RegExp(r'page=(\d+)');

  /// [requestedPage] 는 페이지 정보를 전혀 못 읽었을 때의 하한으로만 쓴다.
  SiseDayPageDto parse(List<int> bytes, {required int requestedPage}) {
    final String html = cp949.decode(bytes);

    final items = <DailyPriceDto>[];
    for (final RegExpMatch rowMatch in _row.allMatches(html)) {
      final String row = rowMatch.group(0)!;
      final RegExpMatch? date = _date.firstMatch(row);
      if (date == null) continue; // 헤더 · 구분선 행

      final List<int> numbers = _number
          .allMatches(row)
          .map((m) => _toInt(m.group(1)!))
          .toList();
      if (numbers.length < 6) continue;

      // 표 순서: 종가 · 전일비 · 시가 · 고가 · 저가 · 거래량
      items.add(
        DailyPriceDto(
          localDate: '${date[1]}.${date[2]}.${date[3]}',
          closePrice: numbers[0],
          previousDayCompare: _signOf(row) * numbers[1],
          openPrice: numbers[2],
          highPrice: numbers[3],
          lowPrice: numbers[4],
          accumulatedTradingVolume: numbers[5],
        ),
      );
    }

    return SiseDayPageDto(
      items: items,
      lastPage: _lastPage(html, requestedPage),
    );
  }

  /// 보합(`bu_pn`)은 전일비가 0 이라 부호를 0 으로 둬도 값이 변하지 않는다.
  static int _signOf(String row) {
    switch (_direction.firstMatch(row)?.group(1)) {
      case 'bu_pup':
        return 1;
      case 'bu_pdn':
        return -1;
      default:
        return 0;
    }
  }

  static int _lastPage(String html, int requestedPage) {
    final String navigation = _navigation.firstMatch(html)?.group(0) ?? html;

    final RegExpMatch? tail = _lastPageLink.firstMatch(navigation);
    if (tail != null) return int.parse(tail.group(1)!);

    // 마지막 페이지에는 `맨뒤` 링크가 없다. 남은 번호 중 최댓값이 마지막이다.
    final List<int> pages = _anyPageLink
        .allMatches(navigation)
        .map((m) => int.parse(m.group(1)!))
        .toList();
    return pages.isEmpty ? requestedPage : pages.reduce(max);
  }

  static int _toInt(String text) => int.parse(text.replaceAll(',', ''));
}
