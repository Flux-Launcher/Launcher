import 'package:flutter/foundation.dart';

class LogController extends ChangeNotifier {
  final List<String> _lines = [];

  LogController();

  List<String> get lines => List.unmodifiable(_lines);

  int get lineCount => _lines.length;

  void append(String text) {
    if (text.isEmpty) return;

    final incoming = text.split('\n');

    if (_lines.isNotEmpty && !_lines.last.endsWith('\n')) {
      _lines[_lines.length - 1] = _lines.last + incoming.first;
      for (int i = 1; i < incoming.length; i++) {
        _lines.add(incoming[i]);
      }
    } else {
      _lines.addAll(incoming);
    }

    notifyListeners();
  }

  void appendLine(String line) {
    _lines.add(line);
    notifyListeners();
  }

  set text(String text) {
    _lines
      ..clear()
      ..addAll(text.split('\n'));
    notifyListeners();
  }

  String get text => _lines.join('\n');

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
