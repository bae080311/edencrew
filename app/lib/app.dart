import 'package:flutter/material.dart';

import 'theme/theme.dart';
import 'ui/start_here_view.dart';

class EdencrewAssignmentApp extends StatelessWidget {
  const EdencrewAssignmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '이든크루 평가 과제',
      theme: AppTheme.dark,
      home: const StartHereView(),
    );
  }
}
