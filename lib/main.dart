import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PixabayPage(),
    );
  }
}

class PixabayPage extends StatefulWidget {
  const PixabayPage({Key? key}) : super(key: key);

  @override
  State<PixabayPage> createState() => _PixabayPageState();
}

class _PixabayPageState extends State<PixabayPage> {

  //初めは空のListを入れておく
  List<PixabayImage> PixabayImages = [];

  Future<void> fetchImages(String text) async {
    final  response = await Dio().get(
        'https://pixabay.com/api',
    queryParameters: {
          'key' : '36593559-f0d470902e19c92aa40185d1c',
          'q' : text,
          'image_type' : 'photo',
          'per_page' : 100

    },
    );
    final List hits = response.data['hits'];
    PixabayImages = hits
        .map(
            (e) {
              return PixabayImage.fromMap(e);
            },
    ).toList();
    setState(() {});
  }

  //webAPIを通して画像を取得する
  Future<void> shareImage(String url) async {
    //1. URLから画像をダウンロード
    final response = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    //2. ダウンロードしたデータをファイルに保存
    final dir = await getTemporaryDirectory();
    final file = await File('${dir.path}/image.png').writeAsBytes(response.data);

    //3. Shareパッケージを呼び出して共有
    Share.shareFiles([file.path]);
  }

  @override
  void initState() {
    super.initState();
    //最初に一度だけよばれる
    fetchImages('花');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          initialValue: '花',
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
          ),
          onFieldSubmitted: (text){
            fetchImages(text);
          },
        ),
      ),
      body: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: PixabayImages.length,
        itemBuilder: (context, index){
            final PixabayImage = PixabayImages[index];
            return InkWell(
              onTap: () async {
                shareImage(PixabayImage.webformatURL);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    PixabayImage.previewURL,
                  fit: BoxFit.cover,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      color: Colors.white,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.thumb_up_alt_outlined,
                            size: 14,
                            ),
                            Text('${PixabayImage.likes}'),
                          ],
                        )),
                  ),
                ],
              ),
            );

    },
      ),
    );
  }
}

class PixabayImage {

  final String webformatURL;
  final String previewURL;
  final int likes;

  PixabayImage({
    required this.webformatURL,
    required this.previewURL,
    required this.likes
  });

  factory PixabayImage.fromMap(Map<String, dynamic> map) {
    return PixabayImage(
      webformatURL: map ['webformatURL'],
      previewURL: map ['previewURL'],
      likes: map ['likes'],
    );
  }
}
