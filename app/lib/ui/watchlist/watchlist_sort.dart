/// 관심 목록 정렬 기준.
///
/// 표시 문자열은 헤더 칩과 바텀시트가 같은 값을 써야 해서 여기 붙여 둔다.
/// 이 enum 은 `ui` 레이어에만 있고 ViewModel 은 값만 쓴다.
enum WatchlistSort {
  price('현재가순'),
  changeRate('등락률순'),
  name('가나다순');

  const WatchlistSort(this.label);

  final String label;
}
