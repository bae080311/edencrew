import 'dart:convert';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:http/http.dart' as http;

/// Naver endpoint 4개를 호출한다. 응답 해석은 DTO · 파서가 맡는다.
class NaverApi {
  NaverApi({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 10);

  final http.Client _client;
  final Duration _timeout;

  /// 일별 시세는 브라우저 User-Agent 가 아니면 표 대신 에러 페이지를 돌려준다.
  static const Map<String, String> _headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  /// 검색 자동완성. 응답은 UTF-8.
  Future<Map<String, dynamic>> fetchSearch(String query) => _getJson(
    Uri.https('ac.stock.naver.com', '/ac', <String, String>{
      'q': query,
      'target': 'stock,ipo,index,marketindicator',
    }),
    utf8,
  );

  /// 관심종목 시세를 **한 번의 요청으로** 가져온다. 응답은 EUC-KR.
  Future<Map<String, dynamic>> fetchRealtimeQuotes(List<String> symbols) =>
      _getJson(
        Uri.https(
          'polling.finance.naver.com',
          '/api/realtime',
          <String, String>{'query': 'SERVICE_ITEM:${symbols.join(',')}'},
        ),
        cp949,
      );

  /// 종목 메타데이터. 응답은 UTF-8.
  Future<Map<String, dynamic>> fetchStockMeta(String symbol) => _getJson(
    Uri.https(
      'stock.naver.com',
      '/api/securityFe/api/fchart/domestic/stock/$symbol',
    ),
    utf8,
  );

  /// 일별 시세 HTML. 디코딩은 `SiseDayParser` 가 하므로 바이트로 넘긴다.
  Future<List<int>> fetchSiseDayPage(String symbol, int page) async {
    final http.Response response = await _get(
      Uri.https('finance.naver.com', '/item/sise_day.naver', <String, String>{
        'code': symbol,
        'page': '$page',
      }),
    );
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, Encoding codec) async {
    final http.Response response = await _get(uri);
    final Object? decoded = jsonDecode(codec.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('$uri 응답이 객체가 아니다');
    }
    return decoded;
  }

  Future<http.Response> _get(Uri uri) async {
    final http.Response response = await _client
        .get(uri, headers: _headers)
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('${uri.host} 응답 ${response.statusCode}');
    }
    return response;
  }

  void close() => _client.close();
}
