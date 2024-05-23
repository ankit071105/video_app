import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoProcessor(),
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: HomePage(),
        routes: {
          '/display': (context) => DisplayPage(),
        },
      ),
    );
  }
}

class VideoProcessor extends ChangeNotifier {
  List<String> details = [];
  String? pdfPath;
  bool isPdfReady = false;
  PDFDocument? pdfDocument;

  void processVideo(String name, String password) async {
    String encryptedPassword = _encryptPassword(password);
    details = [name, password, encryptedPassword];
    notifyListeners();
  }

  Future<void> generatePdf() async {
    final pdf = pw.Document();
    final name = details[0];
    final password = details[1];
    final encryptedPassword = details[2];

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            children: [
              pw.Text('Name: $name'),
              pw.Text('Password: $password'),
              pw.Text('Encrypted Password: $encryptedPassword'),
            ],
          ),
        ),
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/assets/details.pdf');
    await file.writeAsBytes(await pdf.save());
    pdfPath = file.path;
    pdfDocument = await PDFDocument.fromFile(file);
    isPdfReady = true;
    notifyListeners();
  }

  String _encryptPassword(String password) {
    final key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(password, iv: iv);
    return encrypted.base64;
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Video App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 150,
              backgroundImage: AssetImage('assets/avatar.webp'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Provider.of<VideoProcessor>(context, listen: false)
                    .processVideo(_nameController.text, _passwordController.text);
                Navigator.pushNamed(context, '/display');
              },
              child: Text('Select Video'),
            ),
          ],
        ),
      ),
    );
  }
}

class DisplayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final videoProcessor = Provider.of<VideoProcessor>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Display'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await videoProcessor.generatePdf();
              },
              child: Text('Generate PDF'),
            ),
            SizedBox(height: 20),
            if (videoProcessor.details.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: videoProcessor.details.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      
                      title: Text(
                        videoProcessor.details[index],
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (videoProcessor.isPdfReady && videoProcessor.pdfDocument != null)
              Expanded(
                child: PDFViewer(document: videoProcessor.pdfDocument!),
              ),
          ],
        ),
      ),
    );
  }
}
