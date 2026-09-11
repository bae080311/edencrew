import 'dart:convert';
import 'dart:io';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:edencrew_assignment_starter/data/dto/realtime_quote_dto.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadMock() {
  final bytes = File('assets/mock/realtime_batch.json').readAsBytesSync();
  // 실시간 시세 응답도 EUC-KR 이다. UTF-8 로 읽으면 종목명이 깨진다.
  return jsonDecode(cp949.decode(bytes)) as Map<String, dynamic>;
}

void main() {
  test('batch 응답에서 종목 3개를 모두 꺼낸다', () {
    final quotes = RealtimeQuoteDto.listFromResponse(_loadMock());

    expect(quotes.map((q) => q.cd), ['005930', '000660', '035420']);
  });

  test('EUC-KR 종목명이 온전히 복원된다', () {
    final quotes = RealtimeQuoteDto.listFromResponse(_loadMock());

    expect(quotes[0].nm, '삼성전자');
    expect(quotes[1].nm, 'SK하이닉스');
  });

  test('시세 필드를 원본 이름 그대로 담는다', () {
    final samsung = RealtimeQuoteDto.listFromResponse(_loadMock()).first;

    expect(samsung.nv, 258000);
    expect(samsung.pcv, 269000);
    expect(samsung.ov, 258000);
    expect(samsung.hv, 261000);
    expect(samsung.lv, 257500);
    expect(samsung.aq, 6450845);
    expect(samsung.countOfListedStock, 5846278608);
  });

  test('껍데기가 어긋나면 빈 목록을 준다', () {
    expect(RealtimeQuoteDto.listFromResponse(<String, dynamic>{}), isEmpty);
    expect(
      RealtimeQuoteDto.listFromResponse(<String, dynamic>{'result': 'nope'}),
      isEmpty,
    );
  });

  test('항목 하나가 어긋나도 나머지는 살린다', () {
    final response = <String, dynamic>{
      'result': <String, dynamic>{
        'areas': <dynamic>[
          <String, dynamic>{
            'datas': <dynamic>[
              <String, dynamic>{'cd': '005930'}, // 시세 필드가 없다
              <String, dynamic>{
                'cd': '000660',
                'nm': 'SK하이닉스',
                'nv': 1791500,
                'pcv': 1853000,
                'ov': 1773000,
                'hv': 1795000,
                'lv': 1768000,
                'aq': 1236986,
                'countOfListedStock': 730492365,
              },
            ],
          },
        ],
      },
    };

    final quotes = RealtimeQuoteDto.listFromResponse(response);

    expect(quotes.map((q) => q.cd), ['000660']);
  });

  test('정수 자리에 실수가 와도 받는다', () {
    final response = <String, dynamic>{
      'result': <String, dynamic>{
        'areas': <dynamic>[
          <String, dynamic>{
            'datas': <dynamic>[
              <String, dynamic>{
                'cd': '005930',
                'nm': '삼성전자',
                'nv': 258000.0,
                'pcv': 269000,
                'ov': 258000,
                'hv': 261000,
                'lv': 257500,
                'aq': 6064160,
                'countOfListedStock': 5846278608,
              },
            ],
          },
        ],
      },
    };

    expect(RealtimeQuoteDto.listFromResponse(response).first.nv, 258000);
  });
}
