import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final ws = await WebSocket.connect('ws://127.0.0.1:56324/p8FSw7zVEYw=/ws');
  final responses = <String, Map<String, dynamic>>{};
  ws.listen((data) {
    final msg = jsonDecode(data as String) as Map<String, dynamic>;
    if (msg['id'] != null) responses[msg['id'] as String] = msg;
  });

  Future<Map<String, dynamic>> call(String id, String method,
      [Map<String, dynamic>? params]) async {
    ws.add(jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    }));
    while (!responses.containsKey(id)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return responses[id]!;
  }

  final vm = await call('1', 'getVM');
  final isolateId = (vm['result']['isolates'] as List).first['id'] as String;

  final dump = await call(
    '2',
    'ext.flutter.debugDumpRenderTree',
    {'isolateId': isolateId},
  );
  final text = (dump['result']?['data'] ?? dump['result']?.toString()) ?? '';
  File('build/widget_dump.txt').writeAsStringSync(text.toString());
  stdout.writeln('dump length: ${text.toString().length}');
  ws.close();
}
