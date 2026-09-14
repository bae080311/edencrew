import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'common/app_icon.dart';
import 'search/search_view.dart';
import 'watchlist/watchlist_view.dart';

/// 하단 탭으로 관심 · 검색을 오간다.
///
/// 두 화면의 상태를 유지해야 해서 `IndexedStack` 을 쓴다. 탭을 옮겼다 돌아왔을 때
/// 목록을 다시 조회하지 않는다.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceBase,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const <Widget>[WatchlistView(), SearchView()],
        ),
      ),
      bottomNavigationBar: _TabBar(
        index: _index,
        onChanged: (int index) => setState(() => _index = index),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dimens.space2),
          child: Row(
            children: <Widget>[
              _Tab(
                // 시안의 관심 탭은 활성일 때만 채운 별이고 비활성은 빈 별이다.
                // 검색 탭은 돋보기 하나라 색만 바뀐다.
                icon: index == 0 ? AppIcon.starFill : AppIcon.star,
                label: '관심',
                isActive: index == 0,
                onTap: () => onChanged(0),
              ),
              _Tab(
                icon: AppIcon.search,
                label: '검색',
                isActive: index == 1,
                onTap: () => onChanged(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final Color color = isActive ? colors.navActive : colors.navInactive;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dimens.space1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(icon, size: dimens.iconTabBar, color: color),
              SizedBox(height: dimens.gapTabLabel),
              Text(label, style: AppTypography.caption.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
