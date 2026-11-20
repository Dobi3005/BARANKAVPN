import 'dart:io';

/// TCP-пинг до порта сервера (одинаково работает на Windows/Android/iOS).
Future<int> tcpPing(String host, int port) async {
  int best = -1;
  for (var i = 0; i < 2; i++) {
    final sw = Stopwatch()..start();
    try {
      final s = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
      s.destroy();
      final ms = sw.elapsedMilliseconds;
      if (best < 0 || ms < best) best = ms;
    } catch (_) {}
  }
  return best;
}
