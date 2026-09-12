import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // SvgPicture 는 에셋을 못 찾아도 조용히 빈 자리를 그린다. 레이아웃 테스트가
  // 통과해도 아이콘이 통째로 빠질 수 있어 파일 존재를 따로 확인한다.
  test('아이콘 에셋이 번들에 들어있다', () async {
    for (final String name in <String>[
      'align',
      'refresh',
      'star',
      'star-fill',
      'search',
      'check',
      'x',
      'search-empty',
      'back',
    ]) {
      final ByteData data = await rootBundle.load('assets/icons/$name.svg');
      expect(data.lengthInBytes, greaterThan(0), reason: name);
    }
  });
}
