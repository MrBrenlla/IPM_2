import 'dart:io';
import 'package:flutter/services.dart';
import "package:provider/provider.dart";
import 'package:flutter/material.dart';
import "Provider.dart";
import 'package:image_picker/image_picker.dart';
import 'package:flutter/painting.dart';
import 'package:permission_handler/permission_handler.dart';
import "requests.dart";
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';

const PrimaryColor = Colors.red;
final Logo= RichText(
  text: TextSpan(
    children: <TextSpan>[
      TextSpan(
          text: 'Co', style: TextStyle(color: Colors.pink[700],fontWeight: FontWeight.bold, fontSize: 20)),
      TextSpan(
          text: 'Lor', style: TextStyle(color: Colors.green,fontWeight: FontWeight.bold, fontSize: 20)),
      TextSpan(
          text: ' APP',
          style: TextStyle(color: Colors.blueAccent[700], fontSize: 20)),
    ],
  ),
);

final audioPlayer = new AudioPlayer();
final audioCache = new AudioCache(fixedPlayer: audioPlayer);

void main() {

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, //or set color with: Color(0xFF0000FF)
  ));

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
      debugShowCheckedModeBanner: false,
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
    var fi;
    try {
      fi = await ImagePicker().getImage(
          source: ImageSource.gallery, imageQuality: 50);
    }catch(PlatformException){
      print("Error in get photo from gallery");
      String texto = "Sin permisos para usar la galeria";
      String contenido = "Habilita los permisos de galeria y vuelva a intentarlo.";
      _showDialog(texto,contenido,context);
      return;
    }
    try
    {
      File aux = File(fi.path);
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

  //Open second window
  Future getColors(Foto f,BuildContext context) async{
    if(f.foto==null) return;
    final audioPlayer = new AudioPlayer();
    final audioCache = new AudioCache(fixedPlayer: audioPlayer);
    audioCache.play("Scan.wav");
    f.scan(true);
    try { //In case of get Internet permissions/connection
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        //Call secondary window to open
        try {
          Requests().makePostRequest(f.foto).then((colorList) {
            f.scan(false);
            audioPlayer.stop();
            if(colorList[0].length>0) {
              audioCache.play("Scan_end.wav");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MySecondaryPage(colors: colorList),
            ));
            }else{
              print('No se detectaron colores');
              String texto = "No se detectaron colores";
              String contenido = "Este tipo de errores se producen por servicios de terceros, por favor vuelva a intentarlo. Si el error persiste prueba con otra foto";
              _showDialog(texto,contenido,context);
            }
          });
        }catch(e){
          f.scan(false);
          audioPlayer.stop();
          String texto = "Error inesperado";
          _showDialog(texto,e.toString(),context);
        }
      }
    } on SocketException catch (_) { //In case of not get Internet permissions/connection
      audioPlayer.stop();
      f.scan(false);
      print('not connected');
      String texto = "No tienes activado WIFI/Red.";
      String contenido = "Por favor, activa tu conexión o conéctate a una red";
      _showDialog(texto,contenido,context);
    }
  }

  borrar(Foto f){
    if(f.foto!=null){
      audioCache.play("Eliminar_foto.wav");
      f.change(null);
    }
  }


  Widget loading(Foto f, double size,BuildContext context){
    if(f.scaning) return Image.asset("camara.gif");
    else return FlatButton(
        onPressed: ()=>getColors(f,context),
        child: Visibility(
          child:
          Text('Scan photo',style: TextStyle(height: 5, fontSize: size*0.015,color:PrimaryColor[800])),
          visible: f.visible,
        )
    );
  }

  //Alert dialog - Use for Errors (Connection,Camera permissions,...)
  void _showDialog(String texto, String contenido, BuildContext context) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {

        audioCache.play("Dialogo.wav");

        return AlertDialog(
          backgroundColor: PrimaryColor[50],
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

  Widget portrait_View(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Consumer<Foto>(
            builder: (context, p, child)  {
              return  Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    height: height*0.5,
                    child: p.foto == null
                        ? Column(
                        children:[
                          SizedBox(   //Use of SizedBox
                            height: height*0.3,
                          ),
                          Text('No image selected.',style: TextStyle(height: 5, fontSize: height*0.015,color:PrimaryColor,)),
                        ]
                    )
                        : Image.file(
                      p.foto,
                      width: width*0.85,
                      height: height*0.5,
                    ),
                  ),
                  Container(
                    height:height*0.1,
                    alignment:Alignment.bottomCenter,
                    child: loading(p,height,context),
                  ),
                  Container(
                    height:height*0.06,
                    child: FlatButton(
                        onPressed:() => borrar(p),
                        child: Visibility(
                          child:
                          Text('Remove photo',style: TextStyle(height: 5, fontSize: height*0.015,color:PrimaryColor[800])),
                          visible: p.visible,
                        )
                    ),
                  ),
                  Container(
                    height:height*0.2,
                    alignment:Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          height: height*0.2,
                          width: width*0.2,
                          child: FittedBox(
                            child: FloatingActionButton(
                              backgroundColor: PrimaryColor[400],
                              child: Icon(Icons.add_a_photo),
                              onPressed: () => getImage(p,context),
                              heroTag: Text("btn1"),
                            ),
                          ),
                        ),
                        SizedBox(   //Use of SizedBox
                          width: width*0.35,
                        ),

                        Container(
                          height: height*0.2,
                          width: width*0.2,
                          child: FittedBox(
                            child: FloatingActionButton(

                              backgroundColor: PrimaryColor[400],
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
                  ),
                  Expanded(
                    child: Align(
                      alignment: FractionalOffset.bottomCenter,
                      child:
                      Text(
                        'Selecciona una imagen de la galería o toma una foto para extraer los colores',
                        style: TextStyle(height: 5, fontSize: width*0.0275,color:PrimaryColor[800]),
                      ),
                    ),
                  ),
                ],
              );
            }),
      ],
    );
  }

  Widget landscape_View(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Stack(
      //fit: StackFit.expand,
      children: <Widget>[
        new Center(
          child: Consumer<Foto>(
              builder: (context, p, child)  {
                return  Row(
                  children: <Widget>[

                    Container(
                      width:width*0.55,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(   //Use of SizedBox
                            height: height*0.0,
                          ),
                          p.foto == null
                              ? Text('No image selected.',style: TextStyle(height: 5, fontSize: width*0.025,color:PrimaryColor[800]))
                              : Image.file(
                            p.foto,
                            width: width*0.3,
                            height: height*0.7,
                          ),
                          Text(
                            'Selecciona una imagen para extraer los colores',
                            style: TextStyle(height: height*0.01, fontSize: width*0.0125,color:PrimaryColor[800]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width:width*0.2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: width*0.2,
                            height: height*0.35,
                            child: loading(p,width,context),
                          ),
                          FlatButton(
                              onPressed:() => borrar(p),
                              child: Visibility(
                                child:
                                Text('Remove photo',style: TextStyle(height: 5, fontSize: width*0.015,color:PrimaryColor[800])),
                                visible: p.visible,
                              )
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width:width*0.2,
                      alignment:Alignment.centerRight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: height*0.15,
                            width: height*0.15,
                            child: FittedBox(
                              child: FloatingActionButton(
                                backgroundColor: PrimaryColor[400],
                                child: Icon(Icons.add_a_photo),
                                onPressed: () => getImage(p,context),
                                heroTag: Text("btn1"),
                              ),
                            ),
                          ),
                          SizedBox(   //Use of SizedBox
                            height: height*0.05,
                          ),

                          Container(
                            height: height*0.15,
                            width: height*0.15,
                            child: FittedBox(
                              child: FloatingActionButton(
                                backgroundColor: PrimaryColor[400],
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
                    ),
                    SizedBox(   //Use of SizedBox
                      width: width*0.05,
                    ),
                  ],
                );
              }
          ),
        ),
      ],
    );
  }

  Widget portrait_View_Tablet(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Consumer<Foto>(
            builder: (context, p, child)  {
              return  Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    height: height*0.55,
                    child: p.foto == null
                        ? Column(
                        children:[
                          SizedBox(   //Use of SizedBox
                            height: height*0.3,
                          ),
                          Text('No image selected.',style: TextStyle(height: 5, fontSize: height*0.015,color:PrimaryColor[800])),
                        ]
                    )
                        : Image.file(
                      p.foto,
                      width: width*0.9,
                    ),
                  ),
                  Container(
                    height:height*0.1,
                    child: loading(p, height, context),
                  ),
                  Container(
                    height:height*0.06,
                    child: FlatButton(
                        onPressed:() => borrar(p),
                        child: Visibility(
                          child:
                          Text('Remove photo',style: TextStyle(height: 5, fontSize: height*0.015,color:PrimaryColor[800])),
                          visible: p.visible,
                        )
                    ),
                  ),
                  Container(
                    height:height*0.2,
                    alignment:Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          height: height*0.2,
                          width: width*0.2,
                          child: FittedBox(
                            child: FloatingActionButton(
                              backgroundColor: PrimaryColor[400],
                              child: Icon(Icons.add_a_photo),
                              onPressed: () => getImage(p,context),
                              heroTag: Text("btn1"),
                            ),
                          ),
                        ),
                        SizedBox(   //Use of SizedBox
                          width: width*0.35,
                        ),

                        Container(
                          height: height*0.2,
                          width: width*0.2,
                          child: FittedBox(
                            child: FloatingActionButton(

                              backgroundColor: PrimaryColor[400],
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
                  ),
                ],
              );
            }),
      ],
    );
  }

  Widget landscape_View_Tablet(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        new Center(
          child: Consumer<Foto>(
              builder: (context, p, child)  {
                return  Row(
                  children: <Widget>[
                    Container(
                      width:width*0.65,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          p.foto == null
                              ? Text('No image selected.',style: TextStyle(height: 5, fontSize: width*0.025,color:PrimaryColor[800]))
                              : Image.file(
                            p.foto,
                            width: width*0.65,
                            height: height*0.82,
                          ),
                          Text(
                            'Selecciona una imagen para extraer los colores',
                            style: TextStyle(height: height*0.002, fontSize: width*0.01,color:PrimaryColor[800]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width:width*0.15,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width:width*0.15,
                            height: height*0.15,
                            child: loading(p, width, context),
                          ),
                          FlatButton(
                              onPressed:() => borrar(p),
                              child: Visibility(
                                child:
                                Text('Remove photo',style: TextStyle(height: 5, fontSize: width*0.015,color:PrimaryColor[800])),
                                visible: p.visible,
                              )
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width:width*0.15,
                      alignment:Alignment.centerRight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: height*0.15,
                            width: height*0.15,
                            child: FittedBox(
                              child: FloatingActionButton(
                                backgroundColor: PrimaryColor[400],
                                child: Icon(Icons.add_a_photo),
                                onPressed: () => getImage(p,context),
                                heroTag: Text("btn1"),
                              ),
                            ),
                          ),
                          SizedBox(   //Use of SizedBox
                            height: height*0.1,
                          ),

                          Container(
                            height: height*0.15,
                            width: height*0.15,
                            child: FittedBox(
                              child: FloatingActionButton(
                                backgroundColor: PrimaryColor[400],
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
                    ),
                    SizedBox(   //Use of SizedBox
                      width: width*0.05,
                    ),
                  ],
                );
              }
          ),
        ),
      ],
    );
  }

  //Build MAIN view
  @override
  Widget build(BuildContext context) {
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(

      backgroundColor: PrimaryColor[50],
      appBar: AppBar(
        toolbarHeight: height*0.075,
        backgroundColor: PrimaryColor,
        title: Logo,
      ),
      body:
      OrientationBuilder(
        builder: (context, orientation){
          if(shortestSide < 600) { //Mobile
              if(orientation == Orientation.portrait){
                return portrait_View(context);
              }else{
                return landscape_View(context);
              }
          }
          else { //Tablet
            if(orientation == Orientation.portrait){
              return portrait_View_Tablet(context);
            }else{
              return landscape_View_Tablet(context);
            }
          }
        },
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
class SecondRoute extends State<MySecondaryPage> with SingleTickerProviderStateMixin {
  String dropdownValue = 'One';
  Animation<double> animation;
  AnimationController controller;

  double calRadius(double w, double h){
    if(w>h) return h*0.07;
    else return w*0.1;
  }

  //Get color values and percentajes
  get_listView(double _fontsize) {
    return
      Column(
        children: <Widget>[
          SizedBox(   //Use of SizedBox
            height: _fontsize*2,
          ),
          RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                    text: widget.colors[0][0] + "-- '%': " + widget.colors[1][0].toStringAsFixed(2),
                    style: TextStyle(color: OpenPainter(widget.colors,50)._getColorFromHex(widget.colors[0][0]),fontWeight: FontWeight.normal, fontSize: _fontsize)),
              ],
            ),
          ),
          SizedBox(   //Use of SizedBox
            height: _fontsize*3,
          ),
          RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                    text: widget.colors[0][1] + "-- '%': " + widget.colors[1][1].toStringAsFixed(2),
                    style: TextStyle(color: OpenPainter(widget.colors,50)._getColorFromHex(widget.colors[0][1]),fontWeight: FontWeight.normal, fontSize: _fontsize)),
              ],
            ),
          ),
          SizedBox(   //Use of SizedBox
            height: _fontsize*3,
          ),
          RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                    text: widget.colors[0][2] + "-- '%': " + widget.colors[1][2].toStringAsFixed(2),
                    style: TextStyle(color: OpenPainter(widget.colors,50)._getColorFromHex(widget.colors[0][2]),fontWeight: FontWeight.normal, fontSize: _fontsize)),
              ],
            ),
          ),
        ],
      );



  }

  Widget portrait_View(BuildContext context)
  {

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double radius=width*0.075;

    return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new  Center(
            child:  Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(   //Use of SizedBox
                  height: 5,
                ),
                Container(
                  width: width,
                  height: height*0.05,
                  alignment: Alignment.center,
                  child:
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                            text: '3 principales colores de la fotografía:', style: TextStyle(fontWeight: FontWeight.normal, fontSize: height*0.025,color:PrimaryColor[800])),
                      ],
                    ),
                  ),
                ),
                SizedBox(   //Use of SizedBox
                  height: height*0.1,
                ),
                Container(
                  width: radius*6,
                  height: radius*5,
                  child: CustomPaint(
                    painter: OpenPainter(widget.colors[0],radius),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                          text: 'HTML/HEX - COLORS :', style: TextStyle(color:PrimaryColor[800],fontWeight: FontWeight.normal, fontSize: height*0.03)),
                    ],
                  ),
                ),
                SizedBox(   //Use of SizedBox
                  height: height*0.01,
                ),
                Container(
                    width: width,
                    height: height*0.25,
                    child: get_listView(height*0.02)
                ),
                //Botón de pruebas
              ],
            ),
          ),
        ],
    );
  }

  Widget landscape_View(BuildContext context)
  {

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double radius=height*0.1;

    return Stack(
        children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: '3 principales colores de la fotografía:', style: TextStyle(color:PrimaryColor[800],fontWeight: FontWeight.normal, fontSize: width*0.04)),
                 ],
                ),
              ),
            ]
          ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(   //Use of SizedBox
                          height: height*0.25,
                        ),
                        Container(

                          width: radius*6,
                          height: radius*5,
                          child: CustomPaint(
                            painter: OpenPainter(widget.colors[0],radius),
                          ),
                        ),
                      ],
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(   //Use of SizedBox
                      height: height*0.1,
                    ),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                                text: 'HTML/HEX - COLORS :', style: TextStyle(color:PrimaryColor[800],fontWeight: FontWeight.normal, fontSize: width*0.025)),
                          ],
                        ),
                      ),
                      Container(
                          width: width*0.3,
                          height: height*0.5,
                          child: get_listView(width*0.02)
                      ),
                    ],
                  ),

                ],
            )
        ],
    );
  }

  //Build secondary view
  Widget build(BuildContext context) {
    var shortestSide = MediaQuery.of(context).size.shortestSide;

    return Scaffold(
      backgroundColor: PrimaryColor[50],
      appBar: AppBar(
        backgroundColor: PrimaryColor,
        title: Logo,
      ),
      body: OrientationBuilder(
        builder: (context, orientation){

            if(orientation == Orientation.portrait){
              return portrait_View(context);
            }else{
              return landscape_View(context);
            }

        },
      ),
    );
  }
}

//Class for paint circles in the secondary view
class OpenPainter extends CustomPainter {
  final List colorList;
  final double radius;
  OpenPainter(this.colorList,this.radius);

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
    int position = radius.toInt();

    for(var i = 0; i < colorList.length; i++) {
      var paint1 = Paint()
        ..color =  _getColorFromHex(colorList[i]) //0xff63aa65
        ..style = PaintingStyle.fill;
      //a circle
      if(i == 0)
        canvas.drawCircle(Offset(radius*3, 0), radius, paint1); //Place upper circle.
      else
        canvas.drawCircle(Offset(radius*(i-1)*4+radius, radius*3), radius, paint1); //Place the other 2 circles like Primary Colors form.
    }

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}


