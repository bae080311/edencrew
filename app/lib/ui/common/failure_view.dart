import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 조회가 실패했을 때의 안내. 시안에 없는 상태다.
///
/// 사용자가 할 수 있는 일이 다시 시도 하나뿐이라 단순하게 둔다.
class FailureView extends StatelessWidget {
  const FailureView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: dimens.space3),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: colors.accentDefault,
              ),
              child: Text('다시 시도', style: AppTypography.label),
            ),
          ],
        ),
      ),
    );
  }
}
