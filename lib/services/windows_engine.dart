import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/server.dart';
import 'vpn_engine.dart';
import 'xray_config.dart';

/// Windows: запускает xray.exe (socks/http на localhost) и включает системный прокси.
class WindowsEngine implements VpnEngine {
  static const _httpPort = 10809;
  static const _regKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';
  Process? _proc;
  void Function(VpnStatus)? _cb;

  String get _xrayPath => p.join(p.dirname(Platform.resolvedExecutable), 'data',
      'flutter_assets', 'assets', 'xray', 'xray.exe');

  @override
  Future<void> init(void Function(VpnStatus) onStatus) async {
    _cb = onStatus;
    await _setProxy(false); // подчистить после возможного аварийного выхода
  }

  @override
  Future<void> start(Server server) async {
    _cb?.call(VpnStatus.connecting);
    await _kill();
    if (!File(_xrayPath).existsSync()) {
      _cb?.call(VpnStatus.disconnected);
      throw Exception('Не найден xray.exe в assets/xray/');
    }
    final dir = await getApplicationSupportDirectory();
    final cfg = File(p.join(dir.path, 'config.json'));
    await cfg.writeAsString(jsonEncode(buildXrayConfig(server.link, httpPort: _httpPort)));

    final proc = await Process.start(_xrayPath, ['run', '-c', cfg.path],
        workingDirectory: p.dirname(_xrayPath));
    proc.stdout.drain();
    proc.stderr.drain();
    _proc = proc;

    final early = await proc.exitCode
        .timeout(const Duration(milliseconds: 1500), onTimeout: () => -999);
    if (early != -999) {
      _proc = null;
      _cb?.call(VpnStatus.disconnected);
      throw Exception('Ядро Xray завершилось (код $early). Проверьте ключ.');
    }
    await _setProxy(true);
    _cb?.call(VpnStatus.connected);

    proc.exitCode.then((_) async {
      if (identical(_proc, proc)) {
        _proc = null;
        await _setProxy(false);
        _cb?.call(VpnStatus.disconnected);
      }
    });
  }

  @override
  Future<void> stop() async {
    await _kill();
    await _setProxy(false);
    _cb?.call(VpnStatus.disconnected);
  }

  Future<void> _kill() async {
    final proc = _proc;
    _proc = null;
    proc?.kill();
  }

  Future<void> _setProxy(bool on) async {
    Future<void> reg(String name, String type, String data) => Process.run(
        'reg', ['add', _regKey, '/v', name, '/t', type, '/d', data, '/f']);
    if (on) {
      await reg('ProxyServer', 'REG_SZ', '127.0.0.1:$_httpPort');
      await reg('ProxyOverride', 'REG_SZ', '<local>;localhost;127.*;10.*;192.168.*');
    }
    await reg('ProxyEnable', 'REG_DWORD', on ? '1' : '0');
  }
}
