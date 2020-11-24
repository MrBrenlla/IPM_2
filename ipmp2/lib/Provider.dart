import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ipm_p2/main.dart';
import 'package:permission_handler/permission_handler.dart';
import "requests.dart";

class Foto extends ChangeNotifier {

  File _foto = null;
  bool _visible = false;
  bool _scaning = false;


  bool get scaning => _scaning;

  File get foto => _foto;

  bool get visible => _visible;

  void scan(bool b) {
    _scaning=b;
    notifyListeners();
  }

  void change(File i) {
    _foto=i;
    _visible= (i!=null);
    notifyListeners();
  }
}