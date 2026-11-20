import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state.dart';
import '../theme.dart';
import 'home_screen.dart' show PingBadge;

class ServersScreen extends StatefulWidget {
  final AppState state;
  const ServersScreen({super.key, required this.state});
  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  final _ctrl = TextEditingController();
  String? _msg;

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d?.text != null) setState(() => _ctrl.text = d!.text!);
  }

  Future<void> _add() async {
    final n = await widget.state.addKeys(_ctrl.text);
    setState(() {
      _msg = n > 0 ? 'Добавлено: $n' : (widget.state.error ?? 'Вставьте ключ vless://…');
      if (n > 0) _ctrl.clear();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.state;
    return ListenableBuilder(
      listenable: st,
      builder: (context, _) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: C.cinnabar,
          title: Text('Сервера', style: titleStyle(28)),
          actions: [
            IconButton(tooltip: 'Замерить пинг', icon: const Icon(Icons.refresh), onPressed: st.pingAll),
          ],
        ),
        body: LinenBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(children: [
                  const Padding(padding: EdgeInsets.fromLTRB(20, 56, 20, 0), child: Ornament()),
                  Expanded(
                    child: st.servers.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('Серверов пока нет.\nВставьте ключ ниже.',
                                  textAlign: TextAlign.center, style: TextStyle(fontSize: 17)),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: st.servers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final s = st.servers[i];
                              final sel = i == st.selected;
                              return Dismissible(
                                key: ValueKey(s.link),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                    color: C.cinnabar,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.delete_outline, color: Colors.white)),
                                onDismissed: (_) => st.remove(i),
                                child: InkWell(
                                  onTap: () {
                                    st.select(i);
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: sel ? C.cinnabar : C.ink, width: sel ? 2 : 1),
                                      color: C.linen.withOpacity(.7),
                                    ),
                                    child: Row(children: [
                                      Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                          color: sel ? C.cinnabar : C.inkSoft, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(s.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 17)),
                                          Text('${s.host}:${s.port}',
                                              style: const TextStyle(color: C.inkSoft, fontSize: 13)),
                                        ]),
                                      ),
                                      PingBadge(ping: s.pingMs),
                                    ]),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.ink, width: 1))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      TextField(
                        controller: _ctrl,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'vless://…',
                          filled: true,
                          fillColor: Colors.white.withOpacity(.5),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                          suffixIcon: IconButton(
                              tooltip: 'Вставить из буфера',
                              icon: const Icon(Icons.content_paste, color: C.cinnabar),
                              onPressed: _paste),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: C.cinnabar,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _add,
                        child: const Text('Добавить ключ', style: TextStyle(fontSize: 16)),
                      ),
                      if (_msg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_msg!, textAlign: TextAlign.center, style: const TextStyle(color: C.inkSoft)),
                        ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
