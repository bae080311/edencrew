/// 화면 단위 로딩 상태.
///
/// 플래그를 여러 개 두면 `isLoading && isEmpty && errorMessage != null` 처럼
/// 해석이 안 되는 조합이 생긴다. 빈 상태는 `ready && rows.isEmpty` 로 파생시키고
/// 행 단위 상태는 행 모델이 갖는다.
enum LoadState { initial, loading, ready, failed }
