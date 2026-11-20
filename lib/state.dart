import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/server.dart';
import 'services/ping.dart';
import 'services/vpn_engine.dart';

class AppState extends ChangeNotifier {
  final VpnEngine engine = VpnEngine.create();
  List<Server> servers = [];
  int selected = 0;
  VpnStatus status = VpnStatus.disconnected;
  String? error;
  late SharedPreferences _prefs;

  Server? get current => servers.isEmpty ? null : servers[selected];
  bool get isConnected => status == VpnStatus.connected;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString('servers');
    if (raw != null) {
      try {
        servers = (jsonDecode(raw) as List).map((e) => Server.fromJson(e)).toList();
      } catch (_) {}
    }
    selected = _prefs.getInt('selected') ?? 0;
    if (selected >= servers.length) selected = 0;
    await engine.init((s) {
      status = s;
      notifyListeners();
    });
    pingAll();
  }

  Future<void> _save() async {
    await _prefs.setString('servers', jsonEncode(servers.map((s) => s.toJson()).toList()));
    await _prefs.setInt('selected', selected);
  }

  /// Принимает один или несколько ключей. Возвращает число добавленных.
  Future<int> addKeys(String text) async {
    var added = 0;
    error = null;
    for (final line in text.split(RegExp(r'\s+'))) {
      if (line.isEmpty) continue;
      try {
        final s = Server.fromLink(line);
        if (servers.any((e) => e.link == s.link)) continue;
        servers.add(s);
        added++;
      } on FormatException catch (e) {
        error = e.message;
      }
    }
    await _save();
    notifyListeners();
    if (added > 0) pingAll();
    return added;
  }

  Future<void> remove(int i) async {
    servers.removeAt(i);
    if (selected >= servers.length) selected = servers.isEmpty ? 0 : servers.length - 1;
    await _save();
    notifyListeners();
  }

  Future<void> select(int i) async {
    selected = i;
    await _save();
    notifyListeners();
    if (isConnected) {
      await engine.stop();
      await connect();
    }
  }

  Future<void> pingAll() async {
    for (final s in servers) {
      s.pingMs = -2;
    }
    notifyListeners();
    await Future.wait(servers.map((s) async {
      s.pingMs = await tcpPing(s.host, s.port);
      notifyListeners();
    }));
  }

  Future<void> connect() async {
    final s = current;
    if (s == null) {
      error = 'Сначала добавьте ключ';
      notifyListeners();
      return;
    }
    error = null;
    try {
      await engine.start(s);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      status = VpnStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> disconnect() => engine.stop();

  Future<void> toggle() async {
    if (status == VpnStatus.disconnected) {
      await connect();
    } else {
      await disconnect();
    }
  }
}
