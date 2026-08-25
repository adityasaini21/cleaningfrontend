import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {

  // =========================================
  // 🔥 YOUR CLOUDINARY DETAILS
  // =========================================

  final CloudinaryPublic cloudinary;

  CloudinaryService() : cloudinary = CloudinaryPublic(
    dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '',
    dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '',
    cache: false,
  );

  // =========================================
  // 🔥 UPLOAD IMAGE
  // =========================================

  Future<String> uploadImage(File file) async {

    try {

      CloudinaryResponse response =
      await cloudinary.uploadFile(

        CloudinaryFile.fromFile(
          file.path,
          folder: 'products',
        ),
      );

      return response.secureUrl;

    } catch (e) {

      throw Exception(
        "Cloudinary upload failed: $e",
      );
    }
  }
}