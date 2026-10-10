import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Connect only to the isolated verification Chrome, never the user's browser.
class BrowserSession {
  BrowserSession._(this.socket) {
    socket.listen((dynamic raw) {
      final message = jsonDecode(raw as String) as Map<String, dynamic>;
      if (message['id'] case final int id) {
        _pending.remove(id)?.complete(message);
      } else if (message['method'] == 'Runtime.exceptionThrown') {
        errors.add(message['params'] as Object);
      }
    });
  }
  final WebSocket socket;
  final errors = <Object>[];
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  int _id = 0;
  static Future<BrowserSession> connect() async {
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(
        Uri.parse('http://127.0.0.1:9237/json/list'),
      )).close();
      final targets =
          jsonDecode(await utf8.decoder.bind(response).join()) as List;
      final page = targets.firstWhere(
        (dynamic target) => target['type'] == 'page',
      );
      final result = BrowserSession._(
        await WebSocket.connect(page['webSocketDebuggerUrl'] as String),
      );
      await result.call('Page.enable');
      await result.call('Runtime.enable');
      return result;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    final id = ++_id;
    final pending = Completer<Map<String, dynamic>>();
    _pending[id] = pending;
    socket.add(jsonEncode({'id': id, 'method': method, 'params': params}));
    final response = await pending.future.timeout(const Duration(seconds: 45));
    if (response['error'] != null) {
      throw StateError('$method: ${response['error']}');
    }
    return response['result'] as Map<String, dynamic>;
  }

  Future<dynamic> js(String expression) async {
    final result = await call('Runtime.evaluate', {
      'expression': expression,
      'returnByValue': true,
      'awaitPromise': true,
    });
    if (result['exceptionDetails'] != null) {
      throw StateError(jsonEncode(result));
    }
    return result['result']['value'];
  }

  Future<void> settle([int ms = 500]) =>
      Future<void>.delayed(Duration(milliseconds: ms));
  Future<void> viewport(int width, int height) async {
    await call('Emulation.setDeviceMetricsOverride', {
      'width': width,
      'height': height,
      'deviceScaleFactor': 1,
      'mobile': width < 600,
    });
    await settle();
  }

  Future<void> load(String url) async {
    await call('Page.navigate', {'url': url});
    var loaded = false;
    for (var i = 0; i < 100; i++) {
      await settle(300);
      if (await js(
            "document.querySelector('flutter-view') !== null && document.getElementById('loading') === null",
          ) ==
          true) {
        loaded = true;
        break;
      }
    }
    if (!loaded) throw StateError('Flutter did not load: $url');
    // Firebase's first HTTPS initialization can outlast the engine's loading
    // element. Wait for rendered app semantics instead of a fixed short delay.
    for (var i = 0; i < 100; i++) {
      await js("document.querySelector('flt-semantics-placeholder')?.click()");
      if (await js(
            "document.querySelector('flt-semantics') !== null && document.body.innerText.trim().length > 10",
          ) ==
          true) {
        await settle(300);
        return;
      }
      await settle(300);
    }
    throw StateError('App content did not become ready: $url');
  }

  Future<void> clearStorage(String origin) => call(
    'Storage.clearDataForOrigin',
    {'origin': origin, 'storageTypes': 'all'},
  );
  Future<void> expectText(String text, {bool present = true}) async {
    final found = await js(
      "(document.body.innerText + Array.from(document.querySelectorAll('[aria-label]')).map(e=>e.getAttribute('aria-label')).join(' ')).includes(${jsonEncode(text)})",
    );
    if (found != present) {
      throw StateError('Expected text $text present=$present');
    }
  }

  Future<void> waitText(String text) async {
    for (var i = 0; i < 60; i++) {
      if (await js("document.body.innerText.includes(${jsonEncode(text)})") ==
          true) {
        return;
      }
      await settle(500);
    }
    throw StateError('Text did not appear: $text');
  }

  Future<void> button(String label) async {
    final exists = await js(
      "(() => { const e=Array.from(document.querySelectorAll('[role=button],[role=tab],[role=checkbox]')).find(e=>e.innerText.trim()===${jsonEncode(label)} || e.getAttribute('aria-label')===${jsonEncode(label)}); if (!e)return false; e.click(); return true; })()",
    );
    if (exists != true) throw StateError('Button not found: $label');
    await settle();
  }

  Future<void> click(num x, num y) async {
    for (final type in ['mousePressed', 'mouseReleased']) {
      await call('Input.dispatchMouseEvent', {
        'type': type,
        'x': x,
        'y': y,
        'button': 'left',
        'clickCount': 1,
      });
    }
    await settle();
  }

  Future<void> nav(
    int index, {
    bool arabic = false,
    int width = 390,
    int height = 844,
  }) =>
      click((arabic ? 3 - index : index) * width / 4 + width / 8, height - 38);
  Future<void> enter(String value, {int index = 0}) async {
    final rect = await js(
      "(() => { const e=document.querySelectorAll('input,textarea')[$index]; if(!e)return null; e.scrollIntoView({block:'center'}); const r=e.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2}; })()",
    );
    if (rect == null) throw StateError('Input not found.');
    await click(rect['x'] as num, rect['y'] as num);
    await call('Input.dispatchKeyEvent', {
      'type': 'keyDown',
      'key': 'a',
      'code': 'KeyA',
      'windowsVirtualKeyCode': 65,
      'modifiers': 2,
    });
    await call('Input.dispatchKeyEvent', {
      'type': 'keyUp',
      'key': 'a',
      'code': 'KeyA',
      'windowsVirtualKeyCode': 65,
      'modifiers': 2,
    });
    await call('Input.insertText', {'text': value});
    await settle();
  }

  Future<void> screenshot(String name) async {
    await Directory('build/verification').create(recursive: true);
    final result = await call('Page.captureScreenshot', {'format': 'png'});
    await File('build/verification/$name.png')
        .writeAsBytes(base64Decode(result['data'] as String));
  }

  Future<void> close() => socket.close();
}
