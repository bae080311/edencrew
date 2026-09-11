import '../../data/model/price_tone.dart';

/// 일별 시세 표의 한 행.
class DailyPriceRowUi {
  const DailyPriceRowUi({
    required this.dateLabel,
    required this.closeLabel,
    required this.diffLabel,
    required this.volumeLabel,
    required this.tone,
  });

  /// `09.11`
  final String dateLabel;
  final String closeLabel;

  /// 부호를 포함한다. 색은 [tone] 으로 가른다.
  final String diffLabel;
  final String volumeLabel;
  final PriceTone tone;
}
