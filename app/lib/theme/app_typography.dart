import 'package:flutter/material.dart';

/// Figma `Typography` 컬렉션과 텍스트 스타일을 옮긴 서체 토큰입니다.
///
/// 서체 · 굵기는 Figma Variables 에, 크기 · 행간 · 자간은 이름 붙은 텍스트
/// 스타일(`display/price` · `title` · `body` · `label` · `caption`)에 정의되어
/// 있습니다. 아래 상수는 그 텍스트 스타일을 1:1로 옮긴 것입니다.
///
/// 색은 담지 않습니다. 화면에서 `context.colors` 로 입혀 주세요.
///
/// ```dart
/// Text('삼성전자', style: AppTypography.body.copyWith(color: context.colors.textPrimary))
/// ```
abstract final class AppTypography {
  /// `pubspec.yaml`의 `flutter.fonts`에 등록한 family 이름과 일치해야 합니다.
  static const String fontFamily = 'NotoSansKR';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;

  /// Figma `display/price` — 상세 화면 현재가.
  static const TextStyle displayPrice = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    height: 36 / 30,
    fontWeight: bold,
    letterSpacing: -0.4,
  );

  /// Figma `title` — 화면 제목, 바텀시트 제목, 빈 상태 제목.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    height: 22 / 19,
    fontWeight: bold,
    letterSpacing: -0.2,
  );

  /// Figma `body` — 종목명, 현재가, 정렬 항목.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: medium,
    letterSpacing: -0.1,
  );

  /// Figma `label` — 헤더 정렬 칩, 표 헤더.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: bold,
  );

  /// Figma `caption` — `종목코드 · 시장`, 등락, 탭 라벨, 안내 문구.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: regular,
  );
}
