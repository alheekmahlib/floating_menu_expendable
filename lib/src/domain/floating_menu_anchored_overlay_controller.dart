import 'package:flutter/foundation.dart';

class FloatingMenuAnchoredOverlayController extends ChangeNotifier {
  bool _isOpen;

  FloatingMenuAnchoredOverlayController({bool initialIsOpen = false})
    : _isOpen = initialIsOpen;

  bool get isOpen => _isOpen;

  void open() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  void toggle() {
    _isOpen ? close() : open();
  }
}
