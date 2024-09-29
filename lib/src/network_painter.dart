library network_painter;

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dio/dio.dart';

import 'filter_args.dart';

const _timeStampKey = '_pdl_timeStamp_';

/// A class that allows you to paint a network dio object (Request, Response, Error) in a custom way.
class NetworkPainter {
  /// The function that will be called to paint the object.
  final void Function(Object object) paint;

  /// paint request [Options]
  final bool request;

  /// paint request header [Options.headers]
  final bool requestHeader;

  /// paint request data [Options.data]
  final bool requestBody;

  /// Emoji for request
  final String? requestEmoji;

  /// Emoji for response
  final String? responseEmoji;

  /// Emoji for error
  final String? errorEmoji;

  final String? timeEmoji;

  /// paint [Response.data]
  final bool responseBody;

  /// paint [Response.headers]
  final bool responseHeader;

  /// paint error message
  final bool error;

  /// Width size per paint
  final int maxWidth;

  /// paint compact json response
  final bool compact;

  /// Size in which the Uint8List will be split
  static const int chunkSize = 20;

  /// InitialTab count to paint json response
  static const int kInitialTab = 1;

  /// 1 tab length
  static const String tabStep = '    ';

  /// Filter request/response by [RequestOptions]
  final bool Function(RequestOptions options, FilterArgs args)? filter;

  static void _defaultPaint(Object object) => print(object);

  NetworkPainter({
    this.request = true,
    this.requestHeader = false,
    this.requestBody = false,
    this.responseBody = true,
    this.responseHeader = false,
    this.error = true,
    this.compact = false,
    this.maxWidth = 90,
    this.paint = _defaultPaint,
    this.filter,
    this.requestEmoji = '🚀',
    this.responseEmoji = '✅',
    this.errorEmoji = '❌',
    this.timeEmoji = '⏳',
  });

  // Request Painting
  void paintRequest(RequestOptions options) {
    final extra = Map.of(options.extra);
    options.extra[_timeStampKey] = DateTime.timestamp().millisecondsSinceEpoch;

    if (filter != null && !filter!(options, FilterArgs(false, options.data))) {
      return;
    }

    if (request) {
      _paintRequestHeader(options);
    }
    if (requestHeader) {
      _paintMapAsTable(options.queryParameters, header: 'Query Parameters');
      final requestHeaders = <String, dynamic>{};
      requestHeaders.addAll(options.headers);
      if (options.contentType != null) {
        requestHeaders['contentType'] = options.contentType?.toString();
      }
      requestHeaders['responseType'] = options.responseType.toString();
      requestHeaders['followRedirects'] = options.followRedirects;
      if (options.connectTimeout != null) {
        requestHeaders['connectTimeout'] = options.connectTimeout?.toString();
      }
      if (options.receiveTimeout != null) {
        requestHeaders['receiveTimeout'] = options.receiveTimeout?.toString();
      }
      _paintMapAsTable(requestHeaders, header: 'Headers');
      _paintMapAsTable(extra, header: 'Extras');
    }
    if (requestBody && options.method != 'GET') {
      final dynamic data = options.data;
      if (data != null) {
        if (data is Map) _paintMapAsTable(options.data as Map?, header: 'Body');
        if (data is FormData) {
          final formDataMap = <String, dynamic>{}
            ..addEntries(data.fields)
            ..addEntries(data.files);
          _paintMapAsTable(formDataMap, header: 'Form data | ${data.boundary}');
        } else {
          _paintBlock(data.toString());
        }
      }
    }
  }

  // Response Painting
  void paintResponse(Response response) {
    if (filter != null && !filter!(response.requestOptions, FilterArgs(true, response.data))) {
      return;
    }

    final triggerTime = response.requestOptions.extra[_timeStampKey];

    int diff = 0;
    if (triggerTime is int) {
      diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
    }
    _paintResponseHeader(response, diff);
    if (responseHeader) {
      final responseHeaders = <String, String>{};
      response.headers.forEach((k, list) => responseHeaders[k] = list.toString());
      _paintMapAsTable(responseHeaders, header: 'Headers');
    }

    if (responseBody) {
      paint('╔ Body');
      paint('║');
      _paintResponse(response);
      paint('║');
      _paintLine(pre: '╚');
    }
  }

  // Error Painting
  void paintError(DioException err) {
    if (filter != null && !filter!(err.requestOptions, FilterArgs(true, err.response?.data))) {
      return;
    }

    final triggerTime = err.requestOptions.extra[_timeStampKey];

    if (error) {
      final uri = err.response?.requestOptions.uri;
      int diff = 0;
      if (triggerTime is int) {
        diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
      }
      _paintBoxed(
          header:
              '${errorEmoji ?? ""} DioException ║ Status: ${err.response?.statusCode} ${err.response?.statusMessage} ║ ${timeEmoji ?? "Time"}: $diff ms',
          text: uri.toString());
      if (err.response != null && err.response?.data != null) {
        paint('╔ ${err.type.toString()}');
        _paintResponse(err.response!);
      }
      _paintLine(pre: '╚');
      paint('');
    }
  }

  // Main Painting
  void _paintLine({String pre = '', String suf = '╝'}) => paint('$pre${'═' * maxWidth}$suf');

  void _paintBoxed({String? header, String? text}) {
    paint('');
    paint('╔╣ $header');
    paint('║  $text');
    _paintLine(pre: '╚');
  }

  void _paintKV(String? key, Object? v) {
    final pre = '╟ $key: ';
    final msg = v.toString();

    if (pre.length + msg.length > maxWidth) {
      paint(pre);
      _paintBlock(msg);
    } else {
      paint('$pre$msg');
    }
  }

  void _paintBlock(String msg) {
    final lines = (msg.length / maxWidth).ceil();
    for (var i = 0; i < lines; ++i) {
      paint((i >= 0 ? '║ ' : '') + msg.substring(i * maxWidth, math.min<int>(i * maxWidth + maxWidth, msg.length)));
    }
  }

  void _paintMapAsTable(Map? map, {String? header}) {
    if (map == null || map.isEmpty) return;
    paint('╔ $header ');
    for (final entry in map.entries) {
      _paintKV(entry.key.toString(), entry.value);
    }
    _paintLine(pre: '╚');
  }

  String _indent([int tabCount = kInitialTab]) => tabStep * tabCount;

  // Specific Paintings
  void _paintRequestHeader(RequestOptions options) {
    final uri = options.uri;
    final method = options.method;
    _paintBoxed(header: '${requestEmoji ?? ""} Request ║ $method ', text: uri.toString());
  }

  void _paintResponseHeader(Response response, int responseTime) {
    final uri = response.requestOptions.uri;
    final method = response.requestOptions.method;
    _paintBoxed(
      header:
          '${responseEmoji ?? ""} Response ║ $method ║ Status: ${response.statusCode} ${response.statusMessage}  ║ ${timeEmoji ?? "Time"}: $responseTime ms',
      text: uri.toString(),
    );
  }

  void _paintResponse(Response response) {
    if (response.data != null) {
      if (response.data is Map) {
        _paintPrettyMap(response.data as Map);
      } else if (response.data is Uint8List) {
        paint('║${_indent()}[');
        _paintUint8List(response.data as Uint8List);
        paint('║${_indent()}]');
      } else if (response.data is List) {
        paint('║${_indent()}[');
        _paintList(response.data as List);
        paint('║${_indent()}]');
      } else {
        _paintBlock(response.data.toString());
      }
    }
  }

  void _paintPrettyMap(
    Map data, {
    int initialTab = kInitialTab,
    bool isListItem = false,
    bool isLast = false,
  }) {
    var tabs = initialTab;
    final isRoot = tabs == kInitialTab;
    final initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) paint('║$initialIndent{');

    for (var index = 0; index < data.length; index++) {
      final isLast = index == data.length - 1;
      final key = '"${data.keys.elementAt(index)}"';
      dynamic value = data[data.keys.elementAt(index)];
      if (value is String) {
        value = '"${value.toString().replaceAll(RegExp(r'([\r\n])+'), " ")}"';
      }
      if (value is Map) {
        if (compact && _canFlattenMap(value)) {
          paint('║${_indent(tabs)} $key: $value${!isLast ? ',' : ''}');
        } else {
          paint('║${_indent(tabs)} $key: {');
          _paintPrettyMap(value, initialTab: tabs);
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          paint('║${_indent(tabs)} $key: ${value.toString()}');
        } else {
          paint('║${_indent(tabs)} $key: [');
          _paintList(value, tabs: tabs);
          paint('║${_indent(tabs)} ]${isLast ? '' : ','}');
        }
      } else {
        final msg = value.toString().replaceAll('\n', '');
        final indent = _indent(tabs);
        final linWidth = maxWidth - indent.length;
        if (msg.length + indent.length > linWidth) {
          final lines = (msg.length / linWidth).ceil();
          for (var i = 0; i < lines; ++i) {
            final multilineKey = i == 0 ? "$key:" : "";
            paint(
                '║${_indent(tabs)} $multilineKey ${msg.substring(i * linWidth, math.min<int>(i * linWidth + linWidth, msg.length))}');
          }
        } else {
          paint('║${_indent(tabs)} $key: $msg${!isLast ? ',' : ''}');
        }
      }
    }

    paint('║$initialIndent}${isListItem && !isLast ? ',' : ''}');
  }

  void _paintList(List list, {int tabs = kInitialTab}) {
    for (var i = 0; i < list.length; i++) {
      final element = list[i];
      final isLast = i == list.length - 1;
      if (element is Map) {
        if (compact && _canFlattenMap(element)) {
          paint('║${_indent(tabs)}  $element${!isLast ? ',' : ''}');
        } else {
          _paintPrettyMap(
            element,
            initialTab: tabs + 1,
            isListItem: true,
            isLast: isLast,
          );
        }
      } else {
        paint('║${_indent(tabs + 2)} $element${isLast ? '' : ','}');
      }
    }
  }

  void _paintUint8List(Uint8List list, {int tabs = kInitialTab}) {
    var chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize),
      );
    }
    for (var element in chunks) {
      paint('║${_indent(tabs)} ${element.join(", ")}');
    }
  }

  // Helper functions
  bool _canFlattenMap(Map map) =>
      map.values.where((dynamic val) => val is Map || val is List).isEmpty && map.toString().length < maxWidth;

  bool _canFlattenList(List list) => list.length < 10 && list.toString().length < maxWidth;
}