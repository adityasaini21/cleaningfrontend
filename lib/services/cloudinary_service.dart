import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {

  // =========================================
  // 🔥 YOUR CLOUDINARY DETAILS
  // =========================================

  final cloudinary = CloudinaryPublic(
    'dxfph9w2w',
    'premChemicals',
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