import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_signature/signature.dart';
import 'package:path_provider/path_provider.dart';


HandSignatureControl control = HandSignatureControl(
  threshold: 5.0,
  smoothRatio: 0.65,
  velocityRange: 3.0,
);

ValueNotifier<ByteData?> rawImageFit = ValueNotifier<ByteData?>(null);

class HandsignmyApp extends StatelessWidget {
  bool get scrollTest => false;

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
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 2.0,
                      child: Stack(
                        children: <Widget>[
                          Container(
                            constraints: BoxConstraints.expand(),
                            color: Colors.white,
                            child: HandSignature(
                              control: control,
                              type: SignatureDrawType.shape,
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
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
                        _saveImage(context,rawImageFit.value);
                      },
                      child: Text('Download'),
                    ),
                  ],
                ),
                SizedBox(
                  height: 16.0,
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
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

  void _saveImage(BuildContext context,ByteData? byteData) async {
    if (byteData == null) {
      return;
    }
    try {
      final buffer = byteData.buffer;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/signature.png';
      File(filePath).writeAsBytesSync(buffer.asUint8List());
      print(filePath);

      // Show a snackbar or toast to indicate successful download
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved at $filePath')),
      );
    } catch (e) {
      print('Error saving image: $e');
      // Show an error message if the image couldn't be saved
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image')),
      );
    }
  }

  Widget _buildScaledImageView() => Container(
    width: 150.0,
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
