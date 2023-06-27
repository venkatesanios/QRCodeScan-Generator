import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrcodeprint/Permission.dart';
import 'package:share/share.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:open_file/open_file.dart';
import 'package:geolocator/geolocator.dart';

HandSignatureControl control = HandSignatureControl(
  threshold: 5.0,
  smoothRatio: 0.65,
  velocityRange: 3.0,
);

ValueNotifier<ByteData?> rawImageFit = ValueNotifier<ByteData?>(null);

class HandsignmyApp extends StatefulWidget {
  @override
  State<HandsignmyApp> createState() => _HandsignmyAppState();
}

class _HandsignmyAppState extends State<HandsignmyApp> {
  String downloadPath = '';

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Signature',
          style: TextStyle(fontSize: 24),
        ),
      ),
      backgroundColor: Colors.orange[300],
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _showSignatureDialog,
                      child: Text('Add Signature'),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    CupertinoButton(
                      onPressed: () {
                        control.clear();
                        rawImageFit.value = null;
                      },
                      child: Text('Clear'),
                    ),
                    CupertinoButton(
                      onPressed: () async {
                        PermissionClass permission = PermissionClass();
                        permission.checkPermission(
                            context, Permission.location);
                        rawImageFit.value = await control.toImage(
                          color: Colors.black,
                          background: Colors.lightGreenAccent[100],
                          fit: true,
                        );
                      },
                      child: Text('Export'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        _saveImage(rawImageFit.value);
                      },
                      child: Text('Download/open'),
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16.0,
                ),
                Text(downloadPath),
                const SizedBox(
                  height: 16.0,
                ),
              ],
            ),
            Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildScaledImageView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignatureDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Customer Signature'),
          content: Container(
            width: double.infinity,
            height: 300,
            child: HandSignature(
              control: control,
              type: SignatureDrawType.shape,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                control.clear();
                rawImageFit.value = null;
              },
              child: Text('Clear'),
            ),
            TextButton(
              onPressed: () async {
                PermissionClass permission = PermissionClass();
                permission.checkPermission(context, Permission.location);
                rawImageFit.value = await control.toImage(
                  color: Colors.black,
                  background: Colors.lightGreenAccent[100],
                  fit: true,
                );
              },
              child: Text('Export'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _saveImage(rawImageFit.value);
              },
              child: Text('Download/open'),
            ),
          ],
        );
      },
    );
  }

  void _saveImage(ByteData? byteData) async {
    if (byteData == null) {
      return;
    }
    print('raw image fit $byteData');
    try {
      final buffer = byteData.buffer;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/signature.png';
      await File(filePath).writeAsBytes(buffer.asUint8List());

      final imageFile = File(filePath);
      final timeStamp =
          DateFormat('yyyy-MM-dd/HH-mm-ss').format(DateTime.now());
      final stampedFilePath = '${tempDir.path}/signature_$timeStamp.png';

      final imageBytes = await imageFile.readAsBytes();
      final image = await decodeImageFromList(imageBytes);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.black;
      final textSize = 20.0;
      final padding = 10.0;

      canvas.drawImage(image, Offset.zero, paint);

      final paragraphStyle = ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: textSize,
      );
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle);
      paragraphBuilder.addText(timeStamp);

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final location = ' ${position.latitude}, ${position.longitude}';
      paragraphBuilder.addText('\t$location');
      print('location');
      print(location);

      final paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: image.width.toDouble()));
      canvas.drawParagraph(
        paragraph,
        Offset(padding, image.height.toDouble() - textSize - padding),
      );

      final picture = recorder.endRecording();
      final stampedImage = await picture.toImage(image.width, image.height);
      final stampedImageData =
          await stampedImage.toByteData(format: ui.ImageByteFormat.png);
      final stampedImageBytes = Uint8List.view(stampedImageData!.buffer);
      await File(filePath).writeAsBytes(stampedImageBytes);

      openPath(filePath);
      final result = await ImageGallerySaver.saveFile(filePath);
      print('Image saved to gallery: $result');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to gallery')),
      );
    } catch (e) {
      print('Error saving image: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image')),
      );
    }
  }

  void openPath(String path) async {
    OpenResult result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      print('Unable to open file');
    }
  }

  Widget _buildScaledImageView() => Container(
        width: 120.0,
        height: 80.0,
        decoration: BoxDecoration(
          border: Border.all(),
          color: Colors.white30,
        ),
        child: ValueListenableBuilder<ByteData?>(
          valueListenable: rawImageFit,
          builder: (context, data, child) {
            if (data == null) {
              return Container(
                color: Colors.red,
                child: Center(
                  child: Text('Not signed yet (png)\nScaleToFill: true'),
                ),
              );
            } else {
              return Container(
                padding: EdgeInsets.all(8.0),
                color: Colors.white70,
                child: Image.memory(data.buffer.asUint8List()),
              );
            }
          },
        ),
      );
}
