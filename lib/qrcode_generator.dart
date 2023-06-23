import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GenerateQRCode extends StatefulWidget {
  const GenerateQRCode({Key? key}) : super(key: key);

  @override
  GenerateQRCodeState createState() => GenerateQRCodeState();
}

class GenerateQRCodeState extends State<GenerateQRCode> {
  TextEditingController controller = TextEditingController();
  String qrData = '';

  Future<void> printQrImage() async {
    final pdf = pw.Document();

    final qrImageData = await QrPainter(
      data: qrData,
      version: QrVersions.auto,
    ).toImageData(200.0);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pw.MemoryImage(qrImageData!.buffer.asUint8List())),
          );
        },
        // pageFormat: PdfPageFormat.a4,
        pageFormat: PdfPageFormat(100, 100),
      ),
    );

    final Uint8List pdfData = await pdf.save();

    // await Printing.directPrintPdf(
    //   onLayout: (format) => pdfData,
    //   printer: Printer
    // );

    await Printing.sharePdf(bytes: pdfData, filename: 'qr_code.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR code Generator'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'QR Code Data',
              ),
              maxLines: 5,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                qrData = controller.text;
              });
            },
            child: const Text('GENERATE QR CODE'),
          ),
          if (qrData.isNotEmpty)
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: printQrImage,
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }
}
