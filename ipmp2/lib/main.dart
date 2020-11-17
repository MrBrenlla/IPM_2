import 'dart:io';
import "package:provider/provider.dart";
import 'package:flutter/material.dart';
import "Provider.dart";
import 'package:image_picker/image_picker.dart';
import 'package:flutter/painting.dart';
import 'package:permission_handler/permission_handler.dart';
import "requests.dart";


void main() {
  runApp(
    ChangeNotifierProvider(
      builder: (context) => Foto(),
      child: MyApp(),
    ),
  );
}
//------Main VIEW
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final picker = ImagePicker();

  Future getImage(Foto f,BuildContext context) async {
    var camera_status = await Permission.camera.status;
    print("Camera status: " + camera_status.toString());

    //Wait for camera Permissions
    try {
      await Permission.camera.isGranted;

      final pickedFile = await picker.getImage(source: ImageSource.camera); //Get file from camera

      if (pickedFile != null) {
        f.change(File(pickedFile.path));
      } else {
        print('No image selected.');
      }

    }
    catch (e){ //In caso of not get camera permissions
      String texto = "No tienes activados los permisos de la cámara.";
      String contenido = "Por favor, activa tus permisos pulsando 'Aceptar' cuando la ventana de permisos se despliege";
      _showDialog(texto,contenido,context);
    }

  }

  //Get a photo from gallery
  Future getGallery(Foto f,BuildContext context) async {

    //Pick the photo
   // final pickedFile = await picker.getImage(
    //    source: ImageSource.gallery, imageQuality: 50
   // );
    var fi = await ImagePicker().getImage(source: ImageSource.gallery, imageQuality: 50);
    String path=fi.path;
    File aux = File(path);
    try
    {
        f.change(aux);
    }
    catch (_)
    {
      print("Error in get photo from gallery");
      String texto = "Foto no seleccionada";
      String contenido = "Vuelva a intentarlo.";
      _showDialog(texto,contenido,context);
    }

  }

  //Delete actual photo
  File emptyPhoto() {
    PaintingBinding.instance.imageCache.clear();
    imageCache.clear();
    return null;
  }

  //Open second window
  Future getColors(File _image, String path,BuildContext context) async
  {
    if(_image==null) return;
    try { //In case of get Internet permissions/connection
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        //Call secondary window to open
        try {
          Requests().makePostRequest(_image, path).then((colorList) {
            if(colorList[0].length>0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MySecondaryPage(colors: colorList)),
              );
            }else{
              print('No se detectaron colores');
              String texto = "No se detectaron colores";
              String contenido = "Este tipo de errores se producen por servicios de terceros, por favor vuelva a intentarlo. Si el error persiste prueba con otra foto";
              _showDialog(texto,contenido,context);
            }
          });
        }catch(e){
          String texto = "Error inesperado";
          _showDialog(texto,e.toString(),context);
        }
      }
    } on SocketException catch (_) { //In case of not get Internet permissions/connection
      print('not connected');
      String texto = "No tienes activado WIFI/Red.";
      String contenido = "Por favor, activa tu conexión o conéctate a una red";
      _showDialog(texto,contenido,context);
    }
  }

  //Alert dialog - Use for Errors (Connection,Camera permissions,...)
  void _showDialog(String texto, String contenido, BuildContext context) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {

        return AlertDialog(
          title: new Text(texto),
          content: new Text(contenido),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  //Build MAIN view
  @override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                  text: 'Co', style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold, fontSize: 25)),
              TextSpan(
                  text: 'Lor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
              TextSpan(
                  text: ' APP',
                  style: TextStyle(color: Colors.lightGreenAccent, fontSize: 25)),
            ],
          ),
        ),
      ),
      body: Center(
          child: Consumer<Foto>(
          builder: (context, p, child)  {
          return  Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(   //Use of SizedBox
                height: 5,
              ),
              Text("Por favor, seleccione una fotografía"),
              SizedBox(   //Use of SizedBox
                height: 20,
              ),
              p.foto == null
                  ? Text('No image selected.')
                  : Image.file(
                p.foto,
                width: 300,
                height: 350,
              ),
              FlatButton(
                  onPressed: ()=>getColors(p.foto,p.path,context),
                  child: Visibility(
                    child:
                    Text('Scan photo'),
                    visible: p.visible,
                  )
              ),
              FlatButton(
                  onPressed:() => p.change(null),
                  child: Visibility(
                    child:
                    Text('Remove photo'),
                    visible: p.visible,
                  )
              ),
                SizedBox(   //Use of SizedBox
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    height: 100.0,
                    width: 100.0,
                    child: FittedBox(
                      child: FloatingActionButton(
                        child: Icon(Icons.add_a_photo),
                        onPressed: () => getImage(p,context),
                        heroTag: Text("btn1"),
                      ),
                    ),
                  ),
                  SizedBox(   //Use of SizedBox
                    width: 60,
                  ),

                  Container(
                    height: 100.0,
                    width: 100.0,
                    child: FittedBox(
                      child: FloatingActionButton(
                        child: Icon(Icons.photo_album),
                        onPressed: () async {
                          await getGallery(p,context);
                        },
                        heroTag: Text("btn2"),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  child:
                  Text(
                    'Selecciona una imagen de la galería o toma una foto para extraer los colores',
                    style: TextStyle(height: 5, fontSize: 10),
                  ),
                ),
              ),
              SizedBox(   //Use of SizedBox
                height: 10,
              ),
            ],
          );
        })
      ),
    );
  }
}

//------Secondary VIEW
class SecondApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MySecondaryPage(),
    );
  }
}

class MySecondaryPage extends StatefulWidget {
  final colors;
  @override
  const MySecondaryPage({Key key,this.colors}) : super(key: key);
  SecondRoute createState() => SecondRoute();
}

//Secondary Window
class SecondRoute extends State<MySecondaryPage> {
  String dropdownValue = 'One';

  //Get color values and percentajes
  get_listView()
  {
    return ListView.builder(
      itemCount: widget.colors[0].length,
      itemBuilder: (context, index) {
        return ListTile(
          title:
          RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                    text: widget.colors[0][index] + "-- '%': " + widget.colors[1][index].toStringAsFixed(2),
                    style: TextStyle(color: OpenPainter(widget.colors)._getColorFromHex(widget.colors[0][index]),fontWeight: FontWeight.normal, fontSize: 15)),
              ],
            ),
          ),
        );
      },
    );
  }

  //Build secondary view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                  text: 'Co', style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold, fontSize: 25)),
              TextSpan(
                  text: 'Lor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
              TextSpan(
                  text: ' APP',
                  style: TextStyle(color: Colors.lightGreenAccent, fontSize: 25)),
            ],
          ),
        ),
      ),
      body: Center(
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(   //Use of SizedBox
              height: 5,
            ),
            Container(
                width: 337,
                height: 85,
                child:
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                            text: 'Estos son los 3 principales colores presentes en la fotografía:', style: TextStyle(color: Colors.black,fontWeight: FontWeight.normal, fontSize: 12)),
                      ],
                    ),
                  ),
            ),
            Container(
              width: 400,
              height: 220,
              child: CustomPaint(
                painter: OpenPainter(widget.colors[0]),
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: 'HTML/HEX - COLORS :', style: TextStyle(color: Colors.black,fontWeight: FontWeight.normal, fontSize: 20)),
                ],
              ),
            ),
            SizedBox(   //Use of SizedBox
              height: 25,
            ),
            Container(
                width: 180,
                height: 150,
                child: get_listView()
            ),
            //Botón de pruebas
            Container(
                width: 40,
                height: 40,
            ),
          ],
        ),
      ),
    );
  }
}

//Class for paint circles in the secondary view
class OpenPainter extends CustomPainter {
  final List colorList;
  OpenPainter(this.colorList);

  //Return type Color from Hex value of colors
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }

  //Paint circles - CANVAS
  @override
  void paint(Canvas canvas, Size size) {
    int position = 100;

    for(var i = 0; i < colorList.length; i++) {
      var paint1 = Paint()
        ..color =  _getColorFromHex(colorList[i]) //0xff63aa65
        ..style = PaintingStyle.fill;
      //a circle
      if(i == 0)
        canvas.drawCircle(Offset((position+100).toDouble(), 10), 50, paint1); //Place upper circle.
      else
        canvas.drawCircle(Offset((position=position*3 - 160).toDouble(), 110), 50, paint1); //Place the other 2 circles like Primary Colors form.
    }

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
