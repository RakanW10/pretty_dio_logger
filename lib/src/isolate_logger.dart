import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/src/network_painter.dart';

class IsolateLogger {
  final NetworkPainter _networkPainter;

  const IsolateLogger(this._networkPainter);

  Future<void> logRequest(RequestOptions request) async {
    await Isolate.run(
      () {
        _networkPainter.paintRequest(request);
        return Future.value(null);
      },
    );
  }

  Future<void> logResponse(Response response) async {
    await Isolate.run(
      () {
        _networkPainter.paintResponse(response);
        return Future.value(null);
      },
    );
  }

  Future<void> logError(DioException error) async {
    await Isolate.run(
      () {
        _networkPainter.paintError(error);
        return Future.value(null);
      },
    );
  }
}
