import 'package:dio/dio.dart';
import 'filter_args.dart';
import 'isolate_logger.dart';
import 'network_painter.dart';

/// A pretty logger for Dio
/// it will print request/response info with a pretty format
/// and also can filter the request/response by [RequestOptions]
class PrettyDioLogger extends Interceptor {
  /// Enable logPrint
  final bool enabled;

  late IsolateLogger _isolateLogger;

  /// Default constructor
  PrettyDioLogger({
    bool request = true,
    bool requestHeader = false,
    bool requestBody = false,
    bool responseHeader = false,
    bool responseBody = true,
    bool error = true,
    int maxWidth = 90,
    bool compact = true,
    void Function(Object) logPrint = NetworkPainter.defaultPaint,
    bool Function(RequestOptions, FilterArgs)? filter,
    this.enabled = true,
  }) {
    _isolateLogger = IsolateLogger(
      NetworkPainter(
        request: request,
        requestHeader: requestHeader,
        requestBody: requestBody,
        responseHeader: responseHeader,
        responseBody: responseBody,
        error: error,
        compact: compact,
        paint: logPrint,
        maxWidth: maxWidth,
        filter: filter,
      ),
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      _isolateLogger.logRequest(options);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      _isolateLogger.logResponse(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      _isolateLogger.logError(err);
    }
    handler.next(err);
  }
}
