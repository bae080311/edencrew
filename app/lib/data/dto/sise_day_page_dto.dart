import 'daily_price_dto.dart';

/// 일별 시세 한 페이지. `lastPage` 를 넘겨 초과 요청을 막는다.
class SiseDayPageDto {
  const SiseDayPageDto({required this.items, required this.lastPage});

  final List<DailyPriceDto> items;
  final int lastPage;
}
