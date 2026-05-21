// Mobile/Desktop-specific file saver
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveFile(String content, String fileName) async {
  Directory? directory;
  try {
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
  } catch (e) {
    directory = await getApplicationDocumentsDirectory();
  }
  
  final file = File('${directory!.path}/$fileName');
  await file.writeAsString(content);
  return file.path;
}
