import 'package:flutter/foundation.dart';

/// 화면이 문구 하나로 뭉갠 예외를 **debug 빌드에서만** 드러낸다.
///
/// 사용자가 할 수 있는 일이 재시도뿐이라 화면에는 원인을 나누어 보여주지 않는데,
/// 그러면 개발 중에도 원인이 안 보인다. macOS 앱에서 조회가 전부 실패했을 때
/// 터미널에 아무것도 찍히지 않아 샌드박스 문제를 늦게 찾았다.
/// `assert` 안에 두면 release 빌드에서는 호출 자체가 빠진다.
void logSwallowed(String what, Object error) {
  assert(() {
    debugPrint('[$what] $error');
    return true;
  }());
}
