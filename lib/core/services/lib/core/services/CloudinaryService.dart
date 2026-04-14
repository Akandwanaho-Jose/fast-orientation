import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String _cloudName = 'duvyajgmw'; // Your Cloudinary cloud name
  static const String _uploadPreset = 'fast-annoucements'; // Your upload preset
  
  // Add these - get them from your Cloudinary dashboard
  static const String _apiKey = 'YOUR_API_KEY'; // Replace with your API Key
  static const String _apiSecret = 'YOUR_API_SECRET'; // Replace with your API Secret
  
  late final CloudinaryPublic _cloudinary;
  
  CloudinaryService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }
  
  /// Upload a single image to Cloudinary
  Future<String> uploadImage(XFile imageFile) async {
    try {
      // Upload the image
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'FAST', // Optional: organize images in folders
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      // Return the secure URL
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  /// Upload multiple images to Cloudinary
  Future<List<String>> uploadMultipleImages(List<XFile> imageFiles) async {
    try {
      List<String> imageUrls = [];
      
      // Upload images one by one
      for (XFile imageFile in imageFiles) {
        String imageUrl = await uploadImage(imageFile);
        imageUrls.add(imageUrl);
      }
      
      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }
  
  /// Delete an image from Cloudinary using Admin API
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Check if API credentials are set
      if (_apiKey == 'YOUR_API_KEY' || _apiSecret == 'YOUR_API_SECRET') {
        if (kDebugMode) {
          print('Cloudinary API credentials not set. Please add your API Key and Secret.');
          print('Image URL: $imageUrl');
          print('For now, image will remain in Cloudinary but removed from app.');
        }
        return false; // Return false but don't throw error
      }
      
      // Extract public ID from URL
      String publicId = _extractPublicIdFromUrl(imageUrl);
      
      if (publicId.isEmpty) {
        if (kDebugMode) {
          print('Could not extract public ID from URL: $imageUrl');
        }
        return false;
      }
      
      // Generate timestamp
      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Create signature for authenticated request
      String signature = _generateSignature(publicId, timestamp);
      
      // Make delete request to Cloudinary Admin API
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['result'] == 'ok') {
          if (kDebugMode) {
            print('Successfully deleted image from Cloudinary: $publicId');
          }
          return true;
        } else {
          if (kDebugMode) {
            print('Cloudinary deletion failed: ${result['result']}');
          }
          return false;
        }
      } else {
        if (kDebugMode) {
          print('HTTP error deleting image: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete image from Cloudinary: $e');
      }
      return false; // Return false but don't crash the app
    }
  }
  
  /// Delete multiple images from Cloudinary
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;
    
    if (kDebugMode) {
      print('Attempting to delete ${imageUrls.length} images from Cloudinary...');
    }
    
    int successCount = 0;
    for (String imageUrl in imageUrls) {
      bool success = await deleteImage(imageUrl);
      if (success) successCount++;
    }
    
    if (kDebugMode) {
      print('Successfully deleted $successCount out of ${imageUrls.length} images from Cloudinary');
    }
  }
  
  /// Generate signature for Cloudinary Admin API
  String _generateSignature(String publicId, int timestamp) {
    // Create string to sign: public_id=publicId&timestamp=timestamp
    String stringToSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    
    // Generate SHA1 hash
    var bytes = utf8.encode(stringToSign);
    var digest = sha1.convert(bytes);
    
    return digest.toString();
  }
  
  /// Extract public ID from Cloudinary URL
  String _extractPublicIdFromUrl(String url) {
    try {
      // Example URL: https://res.cloudinary.com/duvyajgmw/image/upload/v1234567890/FAST/sample.jpg
      // Public ID would be: FAST/sample
      
      Uri uri = Uri.parse(url);
      List<String> pathSegments = uri.pathSegments;
      
      // Find the index of 'upload'
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex + 2 < pathSegments.length) {
        // Skip version (v1234567890) if present
        int startIndex = uploadIndex + 1;
        
        // Check if next segment is version (starts with 'v' followed by numbers)
        if (pathSegments[startIndex].startsWith('v') && 
            pathSegments[startIndex].length > 1 &&
            int.tryParse(pathSegments[startIndex].substring(1)) != null) {
          startIndex++; // Skip version
        }
        
        // Get all remaining segments for the public ID
        List<String> publicIdParts = pathSegments.sublist(startIndex);
        
        if (publicIdParts.isNotEmpty) {
          // Join all parts and remove extension from the last part
          String publicId = publicIdParts.join('/');
          
          // Remove file extension from the last part
          if (publicId.contains('.')) {
            publicId = publicId.substring(0, publicId.lastIndexOf('.'));
          }
          
          return publicId;
        }
      }
      
      // Fallback: return empty string if can't extract
      return '';
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting public ID from URL: $e');
      }
      return '';
    }
  }
  
  /// Get optimized image URL with transformations
  String getOptimizedImageUrl(String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    try {
      Uri uri = Uri.parse(originalUrl);
      List<String> pathSegments = List.from(uri.pathSegments);
      
      // Find upload segment
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1) {
        // Build transformation string
        List<String> transformations = [];
        
        if (width != null) transformations.add('w_$width');
        if (height != null) transformations.add('h_$height');
        transformations.add('q_$quality');
        transformations.add('f_$format');
        
        String transformationString = transformations.join(',');
        
        // Insert transformation after 'upload'
        pathSegments.insert(uploadIndex + 1, transformationString);
        
        // Rebuild URL
        return uri.replace(pathSegments: pathSegments).toString();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to optimize image URL: $e');
      }
    }
    
    // Return original URL if transformation fails
    return originalUrl;
  }
}