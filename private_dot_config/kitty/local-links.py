import re

PATTERN = re.compile(
    r'(?P<full>(?:(?P<scheme>https?)://)?'
    r'(?P<host>localhost|127\.0\.0\.1|0\.0\.0\.0)'
    r'(?::(?P<port>\d{1,5}))?'
    r'(?P<path>/[^\s]*)?)'
)

def mark(text, args, Mark, extra_cli_args, *a):
    for idx, m in enumerate(PATTERN.finditer(text)):
        start, end = m.span('full')
        yield Mark(idx, start, end, m.group('full'), m.groupdict())

def handle_result(args, data, target_window_id, boss, extra_cli_args, *a):
    for m, g in zip(data['match'], data['groupdicts']):
        if not m:
            continue
        scheme = g.get('scheme') or 'http'
        host = g.get('host') or 'localhost'
        # Convert bind address to something your browser can actually open
        if host == '0.0.0.0':
            host = '127.0.0.1'
        port = g.get('port')
        path = g.get('path') or ''
        url = f"{scheme}://{host}{(':' + port) if port else ''}{path}"
        boss.open_url(url)
