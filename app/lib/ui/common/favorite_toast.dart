import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'app_icon.dart';

/// 시안에 노출 시간이 없다. 별 아이콘이 행에서 이미 바뀌어 토스트는 보조 확인이라
/// 짧게 둔다. 여러 종목을 연달아 등록할 때 이전 토스트가 다음 조작을 가리지 않는 길이다.
const Duration _duration = Duration(seconds: 2);

/// 시안의 그림자는 `0 8 24 rgba(0,0,0,.55)` 인데 SnackBar 의 elevation 으로 근사했다.
const double _elevation = 8;


/// 관심 등록 · 해제 결과를 화면 하단에 알린다.
///
/// 직접 `Overlay` 를 짜지 않는다. 노출 시간 · 등퇴장 애니메이션 · 탭 바 위 배치를
/// `ScaffoldMessenger` 가 이미 한다.
///
/// [onUndo] 를 주면 `실행 취소` 를 함께 띄운다. 스와이프처럼 되돌릴 방법이 없는
/// 동작에만 붙인다 — 별 아이콘은 다시 누르면 되므로 필요 없다.
void showFavoriteToast(
  BuildContext context, {
  required bool added,
  VoidCallback? onUndo,
}) {
  final AppColors colors = context.colors;
  final AppDimens dimens = context.dimens;

  ScaffoldMessenger.of(context)
    // 연달아 토글하면 이전 토스트가 큐에 남아 뒤늦게 뜬다. 바로 갈아 끼운다.
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: _duration,
        behavior: SnackBarBehavior.floating,
        elevation: _elevation,
        backgroundColor: colors.surfaceOverlay,
        margin: EdgeInsets.only(
          left: dimens.space4,
          right: dimens.space4,
          bottom: dimens.gapToastBottom,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
          vertical: dimens.toastPaddingVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dimens.radiusLg),
          side: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
        content: Row(
          children: <Widget>[
            AppIcon(
              added ? AppIcon.starFill : AppIcon.star,
              size: dimens.iconToast,
              color: added ? colors.favoriteActive : colors.textSecondary,
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: Text(
                added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
                style: AppTypography.label.copyWith(color: colors.textPrimary),
              ),
            ),
            if (onUndo != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onUndo();
                },
                child: Text(
                  '실행 취소',
                  style: AppTypography.label.copyWith(
                    color: colors.accentDefault,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
}
