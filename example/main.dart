import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/src/pretty_dio_logger.dart';

void main() async {
  final dio = Dio()
    ..interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
      ),
    );
  try {
    Future.wait(
      [
        dio.get('https://jsonplaceholder.typicode.com/posts/1'),
        dio.get('https://jsonplaceholder.typicode.com/posts/2'),
        dio.get('https://jsonplaceholder.typicode.com/posts/3'),
        dio.get('https://jsonplaceholder.typicode.com/posts/4'),
        dio.get('https://jsonplaceholder.typicode.com/posts/5'),
        dio.get('https://jsonplaceholder.typicode.com/posts/6'),
        dio.get('https://jsonplaceholder.typicode.com/posts/7'),
        dio.get('https://jsonplaceholder.typicode.com/posts/8'),
        dio.get('https://jsonplaceholder.typicode.com/posts/9'),
        dio.get('https://jsonplaceholder.typicode.com/posts/10'),
      ],
    );
  } catch (e) {
    print(e);
  }
}
