import 'package:flutter/material.dart';
import '../services/vpn_engine.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/bagel_button.dart';
import 'servers_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});

  String get _caption => switch (state.status) {
        VpnStatus.disconnected => 'Путь закрыт',
        VpnStatus.connecting => 'Пробираемся через дебри…',
        VpnStatus.connected => 'Путь открыт',
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final s = state.current;
        return Scaffold(
          body: LinenBackground(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  // на десктопе и планшете контент не растягивается
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(children: [
                      const Ornament(),
                      const SizedBox(height: 20),
                      Text('Баранка', style: titleStyle(44)),
                      const Text('тихая дорога в сеть',
                          style: TextStyle(color: C.inkSoft, fontStyle: FontStyle.italic, fontSize: 15)),
                      const Spacer(),
                      BagelButton(status: state.status, onTap: state.toggle),
                      const SizedBox(height: 22),
                      Text(_caption, style: titleStyle(24)),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(state.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: C.cinnabar, fontSize: 14)),
                        ),
                      const Spacer(),
                      _ServerTile(
                        name: s?.name ?? 'Сервер не выбран',
                        ping: s?.pingMs ?? -2,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ServersScreen(state: state))),
                      ),
                      const SizedBox(height: 16),
                      const Ornament(),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ServerTile extends StatelessWidget {
  final String name;
  final int ping;
  final VoidCallback onTap;
  const _ServerTile({required this.name, required this.ping, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: C.ink, width: 1.2),
            color: C.linen.withOpacity(.6),
          ),
          child: Row(children: [
            Expanded(
                child: Text(name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17))),
            PingBadge(ping: ping),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: C.cinnabar),
          ]),
        ),
      );

}

class PingBadge extends StatelessWidget {
  final int ping;
  const PingBadge({super.key, required this.ping});
  @override
  Widget build(BuildContext context) {
    if (ping == -2) {
      return const SizedBox(
          width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: C.gold));
    }
    if (ping < 0) return const Text('нет связи', style: TextStyle(color: C.cinnabar, fontSize: 14));
    final color = ping < 120 ? C.ink : (ping < 250 ? C.gold : C.cinnabar);
    return Text('$ping мс', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15));
  }
}
