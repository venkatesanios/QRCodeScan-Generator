import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';
import 'package:qrcodeprint/handsignature.dart';
import 'package:qrcodeprint/qrcode_generator.dart';
import 'package:qrcodeprint/qrcode_scan.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRCode Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 183, 58, 173)),
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'QRCode Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GenerateQRCode()));
                },
                child: const Text('QR CODE GENERATOR')),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const QRcodeScanner()));
                },
                child: const Text('QR CODE SCAN')),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HandsignmyApp()));
                },
                child: const Text('Customer Signature')), //
          ],
        ),
      ),
    );
  }
}
