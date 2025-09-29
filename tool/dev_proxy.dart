// tool/dev_proxy.dart
// Simple local reverse proxy to work around CORS when running Flutter Web.
// Usage:
//   dart run tool/dev_proxy.dart
// Then set your API base URL in debug web to http://localhost:8080/api/
// which proxies to https://sr.visioncit.com/api/

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart';

Future<void> main(List<String> args) async {
  final target = Uri.parse('https://sr.visioncit.com');
  final proxy = proxyHandler(
    target.toString(),
    proxyName: 'dev-proxy',
  );

  Response cors(Response res, Request req) => res.change(headers: {
        ...res.headers,
        'Access-Control-Allow-Origin': req.headers['origin'] ?? '*',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Allow-Headers': req.headers['access-control-request-headers'] ??
            'Origin, Content-Type, Accept, Authorization',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler((Request req) async {
        // Handle CORS preflight locally
        if (req.method == 'OPTIONS') {
          return cors(Response.ok(''), req);
        }
        final res = await proxy(req);
        return cors(res, req);
      });

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress.loopbackIPv4, port);
  print('Dev proxy listening on http://${server.address.host}:${server.port} -> $target');
}
