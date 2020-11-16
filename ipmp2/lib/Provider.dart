import "package:provider/provider.dart";
import 'package:flutter/material.dart';
import 'package:file/file.dart';

class Foto extends ChangeNotifier {

  File _foto = null;
  String _path = null;
  bool _visible = false;

  String get path => _path;

  File get foto => _foto;

  bool get visible => _visible;


  void change(File i, String p) {
    _foto=i;
    _path=p;
    _visible= (i!=null);
    notifyListeners();
  }
}