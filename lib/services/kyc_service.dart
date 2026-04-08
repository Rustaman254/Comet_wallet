import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../models/kyc_model.dart';
import 'logger_service.dart';
import 'authenticated_http_client.dart';

class KYCService {
  static const String _uploadEndpoint = '${ApiConstants.imageUploadUrl}uploads';

  /// Upload image file to Cradle Voices image server
  /// Returns the URL of the uploaded image
  static Future<String> uploadImage(File imageFile) async {
    final startTime = DateTime.now();
    
    try {
      AppLogger.debug(
        LogTags.kyc,
        'Starting image upload',
        data: {
          'file_path': imageFile.path,
          'file_exists': imageFile.existsSync(),
        },
      );

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(_uploadEndpoint),
      );

      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final duration = DateTime.now().difference(startTime);
      final fileSize = imageFile.lengthSync();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        String? uploadedUrl;
        
        // Adjust the key based on the actual API response
        // Common patterns: 'url', 'data.url', 'imageUrl', etc.
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('url')) {
            uploadedUrl = jsonResponse['url'];
          } else if (jsonResponse.containsKey('data') && 
                     jsonResponse['data'] is Map && 
                     jsonResponse['data'].containsKey('url')) {
            uploadedUrl = jsonResponse['data']['url'];
          } else if (jsonResponse.containsKey('imageUrl')) {
            uploadedUrl = jsonResponse['imageUrl'];
          }
        }
        
        if (uploadedUrl == null) {
          throw Exception('Unable to parse image upload response');
        }

        AppLogger.logKYCImageUpload(
          imageType: _getImageTypeFromPath(imageFile.path),
          imageUrl: uploadedUrl,
          fileSizeBytes: fileSize,
          uploadDuration: duration,
        );

        return uploadedUrl;
      } else {
        AppLogger.error(
          LogTags.kyc,
          'Image upload failed with status code: ${response.statusCode}',
          data: {
            'status_code': response.statusCode,
            'response_body': response.body,
            'duration_ms': duration.inMilliseconds,
          },
        );
        throw Exception('Image upload failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error(
        LogTags.kyc,
        'Image upload error',
        data: {
          'error': e.toString(),
          'duration_ms': DateTime.now().difference(startTime).inMilliseconds,
        },
      );
      throw Exception('Image upload error: $e');
    }
  }

  /// Upload multiple images (ID front, ID back, KRA, profile photo, proof of address)
  /// Returns a map with the image URLs
  static Future<Map<String, String>> uploadKYCImages({
    required File idFrontImage,
    required File idBackImage,
    required File kraDocument,
    required File profilePhoto,
    required File proofOfAddress,
  }) async {
    AppLogger.debug(
      LogTags.kyc,
      'Starting KYC multiple image upload',
      data: {
        'total_images': 5,
      },
    );

    try {
      final uploadedUrls = {
        'idDocumentFront': await uploadImage(idFrontImage),
        'idDocumentBack': await uploadImage(idBackImage),
        'kraDocument': await uploadImage(kraDocument),
        'profilePhoto': await uploadImage(profilePhoto),
        'proofOfAddress': await uploadImage(proofOfAddress),
      };

      AppLogger.success(
        LogTags.kyc,
        'All KYC images uploaded successfully',
        data: {
          'total_images': 5,
          'urls': uploadedUrls,
        },
      );

      return uploadedUrls;
    } catch (e) {
      AppLogger.error(
        LogTags.kyc,
        'KYC images upload failed',
        data: {
          'error': e.toString(),
        },
      );
      throw Exception('KYC images upload failed: $e');
    }
  }

  /// Submit KYC data to the backend
  static Future<Map<String, dynamic>> submitKYC(KYCData kycData) async {
    final startTime = DateTime.now();

    try {
      final requestBody = kycData.toJson();

      AppLogger.logAPIRequest(
        endpoint: ApiConstants.kycCreateEndpoint,
        method: 'POST',
        body: requestBody,
      );

      final response = await AuthenticatedHttpClient.post(
        Uri.parse(ApiConstants.kycCreateEndpoint),
        body: jsonEncode(requestBody),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.logAPIResponse(
          endpoint: ApiConstants.kycCreateEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: jsonResponse,
        );

        AppLogger.logKYCSubmission(requestBody);

        return jsonResponse;
      } else {
        AppLogger.logAPIResponse(
          endpoint: ApiConstants.kycCreateEndpoint,
          method: 'POST',
          statusCode: response.statusCode,
          duration: duration,
          response: {'error': response.body},
        );

        throw Exception('KYC submission failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      AppLogger.error(
        LogTags.kyc,
        'KYC submission error',
        data: {
          'error': e.toString(),
          'duration_ms': duration.inMilliseconds,
        },
      );

      throw Exception('KYC submission error: $e');
    }
  }

  /// Complete KYC flow: upload images and submit data
  static Future<Map<String, dynamic>> completeKYC({
    required int userID,
    required File idFrontImage,
    required File idBackImage,
    required File kraDocument,
    required File profilePhoto,
    required File proofOfAddress,
  }) async {
    final startTime = DateTime.now();

    AppLogger.info(
      LogTags.kyc,
      'Starting complete KYC process',
      data: {
        'user_id': userID,
      },
    );

    try {
      // Upload all images
      final uploadedUrls = await uploadKYCImages(
        idFrontImage: idFrontImage,
        idBackImage: idBackImage,
        kraDocument: kraDocument,
        profilePhoto: profilePhoto,
        proofOfAddress: proofOfAddress,
      );

      // Create KYC data object
      final kycData = KYCData(
        userID: userID,
        idDocumentFront: uploadedUrls['idDocumentFront']!,
        idDocumentBack: uploadedUrls['idDocumentBack']!,
        kraDocument: uploadedUrls['kraDocument']!,
        profilePhoto: uploadedUrls['profilePhoto']!,
        proofOfAddress: uploadedUrls['proofOfAddress']!,
      );

      // Submit KYC data
      final response = await submitKYC(kycData);

      final duration = DateTime.now().difference(startTime);

      AppLogger.success(
        LogTags.kyc,
        'Complete KYC process finished successfully',
        data: {
          'user_id': userID,
          'duration_ms': duration.inMilliseconds,
          'response': response,
        },
      );

      return response;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      AppLogger.error(
        LogTags.kyc,
        'Complete KYC process failed',
        data: {
          'user_id': userID,
          'error': e.toString(),
          'duration_ms': duration.inMilliseconds,
        },
      );

      throw Exception('KYC process failed: $e');
    }
  }

  /// Helper method to determine image type from file path
  static String _getImageTypeFromPath(String path) {
    if (path.contains('front')) return 'ID_Front';
    if (path.contains('back')) return 'ID_Back';
    if (path.contains('kra')) return 'KRA_Document';
    if (path.contains('profile')) return 'Profile_Photo';
    if (path.contains('address')) return 'Proof_of_Address';
    return 'Unknown';
  }
}
