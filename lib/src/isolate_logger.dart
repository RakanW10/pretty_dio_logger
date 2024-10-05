import 'dart:async';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/src/network_painter.dart';

class IsolateLogger {
  final SendPort _commands;
  final ReceivePort _responses;

  bool _closed = false;

  static NetworkPainter _networkPainter = NetworkPainter();

  // Public services
  Future<void> logRequest(RequestOptions request) async {
    if (_closed) return;
    _commands.send(request);
  }

  Future<void> logResponse(Response response) async {
    if (_closed) return;
    _commands.send(response);
  }

  Future<void> logError(DioException error) async {
    if (_closed) return;
    _commands.send(error);
  }

  // initialization
  static Future<IsolateLogger> spawn({required NetworkPainter painter}) async {
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();

    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete(
        (
          ReceivePort.fromRawReceivePort(initPort),
          commandPort,
        ),
      );
    };
    // Spawn the isolate
    try {
      await Isolate.spawn(_startRemoteIsolate, initPort.sendPort);
    } on Object {
      initPort.close();
      rethrow;
    }

    final (responses, commands) = await connection.future;

    return IsolateLogger._(responses, commands, painter);
  }

  IsolateLogger._(this._responses, this._commands, NetworkPainter painter) {
    _networkPainter = painter;
    Isolate.current.addOnExitListener(_commands, response: 'shutdown');
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
    }
  }

  // Isolate entry point
  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  static void _handleCommandsToIsolate(ReceivePort receivePort, SendPort sendPort) async {
    receivePort.listen(
      (message) {
        if (message == 'shutdown') {
          receivePort.close();
          print('IsolateLogger: shutting down');
          return;
        }

        if (message is RequestOptions) {
          _networkPainter.paintRequest(message);
        } else if (message is Response) {
          _networkPainter.paintResponse(message);
        } else if (message is DioException) {
          _networkPainter.paintError(message);
        }
      },
    );
  }
}
