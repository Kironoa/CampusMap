import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ModelDownloader {
  final Dio _dio = Dio();

  Future<File?> downloadModel(String url, String fileName) async {
    try {
      // 1. Get the local directory
      Directory appDocDir = await getApplicationSupportDirectory();
      String savePath = "${appDocDir.path}/$fileName";

      // 2. Check if it already exists
      if (await File(savePath).exists()) {
        print("Model already downloaded at: $savePath");
        return File(savePath);
      }

      // 3. Start download
      print("Downloading model...");
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print("${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      return File(savePath);
    } catch (e) {
      print("Download Error: $e");
      return null;
    }
  }
}
