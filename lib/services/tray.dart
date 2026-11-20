import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../state.dart';

/// Системный трей Windows: левый клик — открыть, правый — меню.
/// Закрытие окна (×) сворачивает в трей.
class TrayService with TrayListener, WindowListener {
  late final AppState _s;

  Future<void> init(AppState s) async {
    _s = s;
    await trayManager.setIcon('assets/tray/tray.ico');
    trayManager.addListener(this);
    windowManager.addListener(this);
    s.addListener(_menu);
    await _menu();
  }

  Future<void> _menu() async {
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'toggle', label: _s.isConnected ? 'Отключить' : 'Подключить'),
      MenuItem.separator(),
      MenuItem(key: 'show', label: 'Открыть Баранку'),
      MenuItem(key: 'quit', label: 'Выход'),
    ]));
    await trayManager.setToolTip(_s.isConnected ? 'Баранка: путь открыт' : 'Баранка: путь закрыт');
  }

  Future<void> _show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onTrayIconMouseDown() => _show();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem item) async {
    switch (item.key) {
      case 'toggle':
        await _s.toggle();
        break;
      case 'show':
        await _show();
        break;
      case 'quit':
        await _s.disconnect();
        await trayManager.destroy();
        await windowManager.destroy();
        break;
    }
  }

  @override
  void onWindowClose() => windowManager.hide();
}
