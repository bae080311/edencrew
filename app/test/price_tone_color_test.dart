import 'package:edencrew_assignment_starter/data/model/price_tone.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:edencrew_assignment_starter/ui/common/price_tone_color.dart';
import 'package:flutter_test/flutter_test.dart';

/// 과제 원문이 "반대로 구현하지 않도록 주의"라고 따로 적은 지점이다.
/// 화면이 세 곳(관심 행 · 현재가 · 일별 시세 표)인데 색을 정하는 곳은 여기 하나뿐이라,
/// 여기만 고정하면 셋이 함께 지켜진다.
void main() {
  const AppColors colors = AppColors.dark();

  group('등락 글자색 — 국내 시장 관행', () {
    test('상승은 priceUpText 를 쓴다', () {
      expect(priceToneText(colors, PriceTone.up), colors.priceUpText);
    });

    test('하락은 priceDownText 를 쓴다', () {
      expect(priceToneText(colors, PriceTone.down), colors.priceDownText);
    });

    test('상승이 하락보다 붉다 — 뒤집히면 여기서 잡힌다', () {
      // 토큰 값을 적어두지 않고 성질로 고정한다. 스타터 토큰이 바뀌어도 방향은 남는다.
      expect(colors.priceUpText.r, greaterThan(colors.priceDownText.r));
      expect(colors.priceDownText.b, greaterThan(colors.priceUpText.b));
    });

    test('보합은 중립색', () {
      expect(priceToneText(colors, PriceTone.flat), colors.priceFlatText);
    });

    test('빨강과 파랑이 서로 다르다 — 뒤집히면 이 셋이 함께 깨진다', () {
      expect(colors.priceUpText, isNot(colors.priceDownText));
    });
  });

  group('차트 캔들도 같은 방향을 쓴다', () {
    test('상승 캔들은 등락 글자와 같은 빨강 계열', () {
      expect(colors.chartLineUp, colors.priceUpText);
    });

    test('하락 캔들은 등락 글자와 같은 파랑 계열', () {
      expect(colors.chartLineDown, colors.priceDownText);
    });
  });
}
