import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class FaceValidationService {
  static const int _minImageSize = 100; // Minimum width/height in pixels
  static const int _maxImageSize = 4000; // Maximum width/height in pixels
  static const int _minFileSize = 10 * 1024; // 10KB minimum
  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB maximum

  /// Validates if an image file meets basic requirements for face photos
  static Future<FaceValidationResult> validateFacePhoto(File imageFile) async {
    try {
      // Check file existence
      if (!await imageFile.exists()) {
        return FaceValidationResult(
          isValid: false,
          errorMessage: 'Image file does not exist',
        );
      }

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize < _minFileSize) {
        return FaceValidationResult(
          isValid: false,
          errorMessage: 'Image file is too small. Please use a higher quality photo.',
        );
      }
      
      if (fileSize > _maxFileSize) {
        return FaceValidationResult(
          isValid: false,
          errorMessage: 'Image file is too large. Please use a smaller photo (max 5MB).',
        );
      }

      // Check file format by extension
      final extension = imageFile.path.toLowerCase().split('.').last;
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        return FaceValidationResult(
          isValid: false,
          errorMessage: 'Invalid image format. Please use JPG, PNG, or WebP.',
        );
      }

      // Basic image data validation
      Uint8List imageBytes;
      try {
        imageBytes = await imageFile.readAsBytes();
      } catch (e) {
        return FaceValidationResult(
          isValid: false,
          errorMessage: 'Unable to read image file. Please try a different photo.',
        );
      }

      // Check if it's actually an image by looking at header bytes
      if (!_isValidImageHeader(imageBytes)) {
        return FaceValidationResult(
          isValid: false,
          errorMessage: 'File is not a valid image. Please select a photo.',
        );
      }

      // All basic validations passed
      return FaceValidationResult(
        isValid: true,
        errorMessage: null,
        recommendations: _generateRecommendations(fileSize),
      );

    } catch (e) {
      debugPrint('Face validation error: $e');
      return FaceValidationResult(
        isValid: false,
        errorMessage: 'Error validating photo: ${e.toString()}',
      );
    }
  }

  /// Check image header bytes to verify it's a valid image
  static bool _isValidImageHeader(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // WebP: RIFF and WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 && // RIFF
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) { // WEBP
      return true;
    }

    return false;
  }

  static List<String> _generateRecommendations(int fileSize) {
    List<String> recommendations = [];

    recommendations.add('• Ensure your face is clearly visible and well-lit');
    recommendations.add('• Look directly at the camera');
    recommendations.add('• Remove sunglasses or face coverings');
    recommendations.add('• Use a plain background if possible');

    if (fileSize > 2 * 1024 * 1024) { // > 2MB
      recommendations.add('• Consider reducing image size for faster upload');
    }

    return recommendations;
  }

  /// Placeholder for future advanced face detection
  /// This would integrate with ML services like Google ML Kit, AWS Rekognition, etc.
  static Future<AdvancedFaceValidationResult> performAdvancedValidation(File imageFile) async {
    // TODO: Integrate with face detection API
    // For now, return a basic result
    return AdvancedFaceValidationResult(
      faceDetected: true,
      confidence: 0.95,
      faceCount: 1,
      quality: FaceQuality.good,
      recommendations: [
        'Photo appears to contain a clear face',
        'Consider better lighting for optimal results',
      ],
    );
  }
}

class FaceValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String>? recommendations;

  FaceValidationResult({
    required this.isValid,
    this.errorMessage,
    this.recommendations,
  });
}

class AdvancedFaceValidationResult {
  final bool faceDetected;
  final double confidence;
  final int faceCount;
  final FaceQuality quality;
  final List<String> recommendations;

  AdvancedFaceValidationResult({
    required this.faceDetected,
    required this.confidence,
    required this.faceCount,
    required this.quality,
    required this.recommendations,
  });
}

enum FaceQuality {
  excellent,
  good,
  fair,
  poor,
}