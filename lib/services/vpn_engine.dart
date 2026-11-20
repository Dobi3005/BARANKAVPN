import 'dart:io';
import '../models/server.dart';
import 'mobile_engine.dart';
import 'windows_engine.dart';

enum VpnStatus { disconnected, connecting, connected }

abstract class VpnEngine {
  Future<void> init(void Function(VpnStatus) onStatus);
  Future<void> start(Server server);
  Future<void> stop();

  static VpnEngine create() => Platform.isWindows ? WindowsEngine() : MobileEngine();
}
