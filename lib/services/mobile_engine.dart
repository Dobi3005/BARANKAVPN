import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server.dart';
import 'vpn_engine.dart';

/// Android (VpnService) и iOS (Network Extension) через flutter_v2ray (ядро Xray).
class MobileEngine implements VpnEngine {
  late final FlutterV2ray _v2ray;
  void Function(VpnStatus)? _cb;

  @override
  Future<void> init(void Function(VpnStatus) onStatus) async {
    _cb = onStatus;
    _v2ray = FlutterV2ray(onStatusChanged: (status) {
      switch (status.state) {
        case 'CONNECTED':
          _cb?.call(VpnStatus.connected);
          break;
        case 'CONNECTING':
          _cb?.call(VpnStatus.connecting);
          break;
        default:
          _cb?.call(VpnStatus.disconnected);
      }
    });
    // iOS: providerBundleIdentifier и groupIdentifier — см. README, раздел iOS
    await _v2ray.initializeV2Ray();
  }

  @override
  Future<void> start(Server server) async {
    _cb?.call(VpnStatus.connecting);
    final parsed = FlutterV2ray.parseFromURL(server.link);
    if (!await _v2ray.requestPermission()) {
      _cb?.call(VpnStatus.disconnected);
      throw Exception('Нет разрешения на VPN');
    }
    _v2ray.startV2Ray(
      remark: parsed.remark,
      config: parsed.getFullConfiguration(),
      proxyOnly: false,
    );
  }

  @override
  Future<void> stop() async => _v2ray.stopV2Ray();
}
