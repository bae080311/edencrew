import 'package:flutter/foundation.dart';

/// 화면이 문구 하나로 뭉갠 예외를 **debug 빌드에서 드러낸다.**
///
/// 사용자가 할 수 있는 일이 재시도뿐이라 화면에는 원인을 나누어 보여주지 않는데,
/// 그러면 개발 중에도 원인이 안 보인다. macOS 앱에서 조회가 전부 실패했을 때
/// 터미널에 아무것도 찍히지 않아 샌드박스 문제를 늦게 찾았다.
///
/// [stackTrace] 를 함께 넘긴다. 같은 문구가 여러 경로에서 나오므로 어디서 났는지
/// 없으면 결국 다시 재현해야 한다.
void logSwallowed(String what, Object error, [StackTrace? stackTrace]) {
  assert(() {
    debugPrint('[$what] $error');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    return true;
  }());
}

/// 어디서도 받지 않은 예외를 마지막으로 받아 남긴다.
///
/// 화면이 잡는 것은 조회 실패뿐이다. 위젯 빌드 중 오류나 `await` 없이 던진
/// Future 는 아무 데도 걸리지 않아 콘솔에도 한 줄만 스치고 지나간다.
/// `main()` 에서 한 번 걸어 두면 그런 것들이 같은 형식으로 남는다.
void installErrorHandlers() {
  final FlutterExceptionHandler? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    logSwallowed(
      '프레임워크 ${details.library ?? ''}'.trim(),
      details.exception,
      details.stack,
    );
    previous?.call(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    logSwallowed('처리되지 않은 비동기 오류', error, stack);
    // 앱을 죽이지 않는다. 조회 하나가 실패했다고 화면 전체를 잃을 이유가 없다.
    return true;
  };
}
