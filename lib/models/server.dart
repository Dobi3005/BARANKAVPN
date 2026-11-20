class Server {
  final String name;
  final String link;
  final String host;
  final int port;
  int pingMs; // -2 = не измерялся, -1 = недоступен

  Server({required this.name, required this.link, required this.host, required this.port, this.pingMs = -2});

  factory Server.fromLink(String raw) {
    final link = raw.trim();
    if (!link.startsWith('vless://')) {
      throw const FormatException('Ключ должен начинаться с vless://');
    }
    final u = Uri.parse(link);
    if (u.host.isEmpty || u.userInfo.isEmpty) {
      throw const FormatException('В ключе нет адреса или UUID');
    }
    var name = u.fragment.isEmpty ? u.host : u.fragment;
    try {
      name = Uri.decodeComponent(name);
    } catch (_) {}
    return Server(name: name, link: link, host: u.host, port: u.hasPort ? u.port : 443);
  }

  Map<String, dynamic> toJson() => {'name': name, 'link': link};
  factory Server.fromJson(Map<String, dynamic> j) => Server.fromLink(j['link'] as String);
}
