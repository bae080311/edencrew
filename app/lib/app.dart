import 'package:flutter/material.dart';

import 'theme/theme.dart';
import 'ui/app_shell.dart';

class EdencrewAssignmentApp extends StatelessWidget {
  const EdencrewAssignmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '이든크루 평가 과제',
      theme: AppTheme.dark,
      // 우상단 DEBUG 리본은 시안에 없는 요소라 화면 구석을 가린다.
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}
