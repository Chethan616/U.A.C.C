import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImageUtils {
  /// Compress image to Base64 string suitable for Firestore storage
  /// Targets maximum 100KB file size for mobile app
  static Future<String?> compressImageToBase64(XFile imageFile) async {
    try {
      Uint8List imageBytes;

      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await File(imageFile.path).readAsBytes();
      }

      // Decode the image
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      // Resize image to reasonable dimensions (max 300x300 for profile pic)
      img.Image resizedImage;
      if (originalImage.width > originalImage.height) {
        resizedImage = img.copyResize(originalImage, width: 300);
      } else {
        resizedImage = img.copyResize(originalImage, height: 300);
      }

      // Start with high quality and reduce if needed
      int quality = 90;
      Uint8List compressedBytes;

      do {
        compressedBytes =
            Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
        quality -= 10;
      } while (
          compressedBytes.length > 100 * 1024 && quality > 20); // 100KB limit

      // Convert to base64
      String base64String = base64Encode(compressedBytes);

      // Add data URL prefix for proper image display
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      if (kDebugMode) print('Error compressing image: $e');
      return null;
    }
  }

  /// Get image size from Base64 string
  static int getBase64ImageSize(String base64String) {
    // Remove data URL prefix if present
    if (base64String.startsWith('data:image/')) {
      base64String = base64String.split(',')[1];
    }

    // Calculate size (Base64 is ~1.33x larger than original)
    return (base64String.length * 0.75).round();
  }

  /// Validate if image is suitable for profile picture
  static Future<bool> validateProfileImage(XFile imageFile) async {
    try {
      final fileSize = await imageFile.length();

      // Original file should be reasonable (max 5MB)
      if (fileSize > 5 * 1024 * 1024) {
        return false;
      }

      // Check if it's a valid image format
      final mimeType = imageFile.mimeType ?? '';
      return mimeType.startsWith('image/') &&
          (mimeType.contains('jpeg') ||
              mimeType.contains('jpg') ||
              mimeType.contains('png') ||
              mimeType.contains('webp'));
    } catch (e) {
      return false;
    }
  }
}
