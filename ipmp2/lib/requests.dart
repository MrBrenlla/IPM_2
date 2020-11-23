import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

//Class for Get,Post,...Http calls.
class Requests {

  String url = 'https://api.imagga.com/v2/colors?image_url=https://imagga.com/static/images/tagging/wind-farm-538576_640.jpg&deterministic=1';
  List<String> image_colors = [];
  List<double> image_percent = [];

  //Get array
  getColors(List<String> colorsArray)
  {
    return colorsArray;
  }

  //HTTP get call
  makeGetRequest() async {
    //Authentication
    String api_key = 'acc_e5ab7b791d7db70';
    String api_secret = 'd933167f2b26f4926944e9b062abba62';
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$api_key:$api_secret'));
    print(basicAuth);

    //Response
    try
    {
      Response response = await get(url,
          headers: <String, String>{'authorization': basicAuth});

      int statusCode = response.statusCode;
      Map<String, String> headers = response.headers;
      String contentType = headers['content-type'];
      String json = response.body;
      print(json);
    }
    catch (e){
      print("Error in GET HTTP Call");
    }
  }

  //HTTP post call
  Future<List> makePostRequest(File img) async {
    //Authentication
    String api_key = 'acc_e5ab7b791d7db70';
    String api_secret = 'd933167f2b26f4926944e9b062abba62';
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$api_key:$api_secret'));

    String url_b = 'https://api.imagga.com/v2/colors?deterministic=1';

    var stream = new http.ByteStream(DelegatingStream(img.openRead()));
    stream.cast();
    // get file length
    var length = await img.length(); //imageFile is your image file
    Map<String, String> headers = {
      "Authorization": basicAuth
    }; // ignore this headers if there is no authentication

    // string to uri
    var uri = Uri.parse(url_b);

    // create multipart request
    var request = new http.MultipartRequest("POST", uri);

    // multipart that takes file
    var multipartFileSign = new http.MultipartFile('image', stream, length,
        filename: img.path.split("/").last);

    // add file to multipart
    request.files.add(multipartFileSign);

    //add headers
    request.headers.addAll(headers);


    // send
    await request.send().then((response) async {
      try {
        // listen for response
        response.stream.transform(utf8.decoder).listen((value) {
          for (var color in jsonDecode(
              value)['result']['colors']['background_colors']) {
            image_colors.add(
                color['closest_palette_color_html_code'].toString());
            image_percent.add(color['percent'].toDouble());
          }
        });
      } catch (_) {
        print("Error in POST HTTP Call");
        rethrow;
      }
    });
    print("IMAGECOLORS::::::::::::::::::::::::::::::::::");
    print(image_colors);
    print("IMAGEPERCENT::::::::::::::::::::::::::::::::::");
    print(image_percent);

    return [image_colors,image_percent];

  }


}