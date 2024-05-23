import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class VideoProcessor extends ChangeNotifier {
  List<String> details = [];

  void processVideo(String name, String password) async {
    // Step 1: Pick Video File
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null) {
      File videoFile = File(result.files.single.path!);

      // Step 2: Compute Hash
      String videoHash = await _computeHash(videoFile);

      // Step 3: Encrypt Password
      String encryptedPassword = _encryptPassword(password);

      // Step 4: Create PDF
      String pdfPath = await _createPdf(name, password, encryptedPassword);

      // Step 5: Save details to MongoDB
      await _saveToMongoDB(name, password, videoFile, videoHash, pdfPath);

      // Collect details to display
      details = [name, password, videoFile.path, videoHash, pdfPath];

      notifyListeners();
    }
  }

  Future<String> _computeHash(File file) async {
    var bytes = await file.readAsBytes();
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _encryptPassword(String password) {
    final key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(password, iv: iv);
    return encrypted.base64;
  }

  Future<String> _createPdf(String name, String password, String encryptedPassword) async {
    final pdf = pw.Document();
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
    final file = File('${outputDir.path}/details.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  Future<void> _saveToMongoDB(String name, String password, File videoFile, String videoHash, String pdfPath) async {
    final db = mongo.Db('mongodb://your_mongo_db_url');
    await db.open();
    final collection = db.collection('video_details');

    await collection.insert({
      'name': name,
      'password': password,
      'video_path': videoFile.path,
      'video_hash': videoHash,
      'pdf_path': pdfPath,
    });

    await db.close();
  }
}
