import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 시안에서 내보낸 SVG 아이콘입니다.
///
/// SVG 파일에는 시안 당시의 색이 박혀 있으므로 `srcIn` 으로 덮어씁니다.
/// 크기는 아이콘마다 달라서(20 · 22 · 24 · 40) 쓰는 쪽에서 지정합니다.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.name, {
    required this.size,
    required this.color,
    super.key,
  });

  static const String align = 'align';
  static const String refresh = 'refresh';
  static const String star = 'star';
  static const String starFill = 'star-fill';
  static const String search = 'search';
  static const String check = 'check';

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
