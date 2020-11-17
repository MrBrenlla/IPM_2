import 'dart:io';
import 'package:flutter/material.dart';

class Foto extends ChangeNotifier {

  File _foto = null;
  String _path = null;
  bool _visible = false;

  String get path => _path;

  File get foto => _foto;

  bool get visible => _visible;

  void change(File i) {
    _foto=i;
    _visible= (i!=null);
    notifyListeners();
  }
}