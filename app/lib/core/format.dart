/// 숫자 · 날짜의 표시 형식은 이 파일에서만 만든다.
///
/// 화면마다 같은 값이 다르게 보이는 것을 막기 위한 단일 지점이다.
/// 한국식 축약(천 · 조)은 `intl` 로도 결국 직접 써야 해서 의존성을 두지 않았다.
library;

/// 천 단위 구분 쉼표. 소수는 반올림해 정수로 보여준다.
String thousands(num value) {
  final rounded = value.abs().round();
  final grouped = rounded.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]},',
  );
  return value < 0 ? '-$grouped' : grouped;
}

/// 등락액. 상승에 `+` 를 붙이고 보합은 부호 없이 `0`.
String signedThousands(num diff) {
  if (diff == 0) return '0';
  return diff > 0 ? '+${thousands(diff)}' : thousands(diff);
}

/// 등락률. 입력은 비율(`0.0022`)이고 표시는 퍼센트 소수 2자리.
String percent(double rate) {
  final value = rate * 100;
  if (value.abs() < 0.005) return '0.00%';
  final body = '${value.abs().toStringAsFixed(2)}%';
  return value > 0 ? '+$body' : '-$body';
}

/// 관심 목록의 등락 표기. 예: `-400 (-0.22%)`
String changeLabel(num diff, double rate) =>
    '${signedThousands(diff)} (${percent(rate)})';

/// 상세 화면 현재가 옆 등락. 예: `▼ 400 (-0.22%)`
///
/// 방향을 화살표가 말하므로 등락액은 절대값으로 둔다. 보합은 화살표가 없다.
String arrowChangeLabel(num diff, double rate) {
  final String arrow = diff > 0
      ? '▲ '
      : diff < 0
      ? '▼ '
      : '';
  return '$arrow${thousands(diff.abs())} (${percent(rate)})';
}

const int _thousand = 1000;
const int _trillion = 1000000000000;

/// 거래량 · 시가총액 축약. 예: `29,113천`, `1,063조`
///
/// 표시용 축약이라 **버림**한다 — 반올림하면 실제보다 큰 값으로 보인다.
String abbrev(num value) {
  final magnitude = value.abs();
  if (magnitude >= _trillion) {
    return '${thousands(value ~/ _trillion)}조';
  }
  if (magnitude >= _thousand) {
    return '${thousands(value ~/ _thousand)}천';
  }
  return thousands(value);
}

/// `yyyyMMdd` → `MM.DD`. 표시만 하므로 `DateTime` 으로 옮기지 않는다.
String monthDay(String yyyymmdd) {
  if (yyyymmdd.length != 8) {
    throw FormatException('yyyyMMdd 형식이 아니다', yyyymmdd);
  }
  return '${yyyymmdd.substring(4, 6)}.${yyyymmdd.substring(6)}';
}
