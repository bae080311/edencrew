import 'package:edencrew_assignment_starter/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('thousands', () {
    test('천 단위마다 쉼표를 넣는다', () {
      expect(thousands(0), '0');
      expect(thousands(999), '999');
      expect(thousands(1000), '1,000');
      expect(thousands(258000), '258,000');
      expect(thousands(5846278608), '5,846,278,608');
    });

    test('음수는 부호를 앞에 둔다', () {
      expect(thousands(-400), '-400');
      expect(thousands(-1234567), '-1,234,567');
    });

    test('소수는 반올림해 정수로 보여준다', () {
      expect(thousands(1234.4), '1,234');
      expect(thousands(1234.6), '1,235');
    });
  });

  group('signedThousands', () {
    test('상승은 +, 하락은 -, 보합은 부호 없이 0', () {
      expect(signedThousands(400), '+400');
      expect(signedThousands(-400), '-400');
      expect(signedThousands(0), '0');
    });
  });

  group('percent', () {
    test('비율을 퍼센트 소수 2자리로 바꾼다', () {
      expect(percent(0.0409), '+4.09%');
      expect(percent(-0.0022), '-0.22%');
    });

    test('보합은 부호 없이 0.00%', () {
      expect(percent(0), '0.00%');
      expect(percent(0.00002), '0.00%');
    });
  });

  group('changeLabel', () {
    test('과제 원문의 표기 형식과 같다', () {
      expect(changeLabel(-400, -0.0022), '-400 (-0.22%)');
      expect(changeLabel(11000, 0.0409), '+11,000 (+4.09%)');
      expect(changeLabel(0, 0), '0 (0.00%)');
    });
  });

  group('arrowChangeLabel', () {
    test('시안의 현재가 옆 표기와 같다 — 등락액은 절대값', () {
      expect(arrowChangeLabel(-400, -0.0022), '▼ 400 (-0.22%)');
      expect(arrowChangeLabel(1200, 0.0068), '▲ 1,200 (+0.68%)');
    });

    test('보합은 화살표가 없다', () {
      expect(arrowChangeLabel(0, 0), '0 (0.00%)');
    });
  });

  group('abbrev', () {
    test('과제 원문의 축약 예시와 같다', () {
      expect(abbrev(29113000), '29,113천');
      expect(abbrev(1063000000000000), '1,063조');
    });

    test('축약 경계', () {
      expect(abbrev(999), '999');
      expect(abbrev(1000), '1천');
      expect(abbrev(999999999999), '999,999,999천');
      expect(abbrev(1000000000000), '1조');
    });

    test('버림한다 — 반올림하면 실제보다 커 보인다', () {
      expect(abbrev(1999), '1천');
      expect(abbrev(1999999999999), '1조');
    });

    test('0 과 음수', () {
      expect(abbrev(0), '0');
      expect(abbrev(-1500), '-1천');
    });
  });

  group('monthDay', () {
    test('yyyyMMdd 를 MM.DD 로 바꾼다', () {
      expect(monthDay('20260911'), '09.11');
      expect(monthDay('20261231'), '12.31');
    });

    test('형식이 아니면 예외를 던진다', () {
      expect(() => monthDay('2026091'), throwsFormatException);
    });
  });
}
