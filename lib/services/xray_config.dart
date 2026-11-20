/// Собирает конфиг Xray из ссылки vless://... (для Windows-ядра).
Map<String, dynamic> buildXrayConfig(String link, {int socksPort = 10808, int httpPort = 10809}) {
  final u = Uri.parse(link);
  final q = u.queryParameters;
  final net = q['type'] ?? 'tcp';
  final sec = q['security'] ?? 'none';

  final stream = <String, dynamic>{'network': net, 'security': sec};
  if (sec == 'reality') {
    stream['realitySettings'] = {
      'serverName': q['sni'] ?? '',
      'fingerprint': q['fp'] ?? 'chrome',
      'publicKey': q['pbk'] ?? '',
      'shortId': q['sid'] ?? '',
      'spiderX': q['spx'] ?? '',
    };
  } else if (sec == 'tls') {
    stream['tlsSettings'] = {
      'serverName': q['sni'] ?? u.host,
      'fingerprint': q['fp'] ?? 'chrome',
      if (q['alpn'] != null) 'alpn': q['alpn']!.split(','),
    };
  }
  if (net == 'ws') {
    stream['wsSettings'] = {'path': q['path'] ?? '/', 'headers': {'Host': q['host'] ?? ''}};
  } else if (net == 'grpc') {
    stream['grpcSettings'] = {'serviceName': q['serviceName'] ?? ''};
  }

  return {
    'log': {'loglevel': 'warning'},
    'dns': {'servers': ['1.1.1.1', '8.8.8.8']},
    'inbounds': [
      {
        'tag': 'socks', 'listen': '127.0.0.1', 'port': socksPort, 'protocol': 'socks',
        'settings': {'udp': true},
        'sniffing': {'enabled': true, 'destOverride': ['http', 'tls']},
      },
      {'tag': 'http', 'listen': '127.0.0.1', 'port': httpPort, 'protocol': 'http'},
    ],
    'outbounds': [
      {
        'tag': 'proxy',
        'protocol': 'vless',
        'settings': {
          'vnext': [
            {
              'address': u.host,
              'port': u.hasPort ? u.port : 443,
              'users': [
                {'id': u.userInfo, 'encryption': q['encryption'] ?? 'none', 'flow': q['flow'] ?? ''}
              ],
            }
          ]
        },
        'streamSettings': stream,
      },
      {'tag': 'direct', 'protocol': 'freedom'},
    ],
    'routing': {
      'domainStrategy': 'IPIfNonMatch',
      'rules': [
        {'type': 'field', 'ip': ['127.0.0.0/8', '10.0.0.0/8', '192.168.0.0/16'], 'outboundTag': 'direct'},
      ],
    },
  };
}
