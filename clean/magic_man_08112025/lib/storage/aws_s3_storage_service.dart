import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'storage_interface.dart';

class AwsS3StorageService implements StorageInterface {
  final String _bucketName;
  final String _region;
  final String _identityPoolId;

  AwsS3StorageService({
    required String bucketName,
    required String region,
    required String identityPoolId,
  })  : _bucketName = bucketName,
        _region = region,
        _identityPoolId = identityPoolId {
    print('🚀 AwsS3StorageService created');
    print('🚀 Bucket: $_bucketName, Region: $_region, IdentityPool: $_identityPoolId');
  }

  @override
  Future<String?> uploadFile({
    required File file,
    required String path,
    Map<String, String>? metadata,
  }) async {
    print('📤 === AwsS3StorageService.uploadFile START ===');
    print('📤 Path: $path');
    print('📤 File: ${file.path}');
    print('📤 File exists: ${await file.exists()}');

    try {
      // Детальна інформація про файл
      final fileStat = await file.stat();
      print('📊 File size: ${fileStat.size} bytes');
      print('📊 File last modified: ${fileStat.modified}');

      final bytes = await file.readAsBytes();
      final contentType = _getContentType(file.path);

      // Формуємо правильний URL для S3
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/$path';
      print('🔗 S3 URL: $url');

      // Отримуємо IdentityId з Cognito
      final identityId = await _getIdentityId();
      if (identityId == null) {
        print('❌ Failed to get IdentityId from Cognito');
        return null;
      }

      // Отримуємо тимчасові credential з Cognito
      final credentials = await _getCredentialsForIdentity(identityId);
      if (credentials == null) {
        print('❌ Failed to get AWS credentials');
        return null;
      }

      // Генеруємо AWS Signature Version 4
      final signedHeaders = await _signS3Request(
        method: 'PUT',
        url: url,
        region: _region,
        service: 's3',
        accessKey: credentials['accessKeyId']!,
        secretKey: credentials['secretKey']!,
        sessionToken: credentials['sessionToken']!,
        content: bytes,
        contentType: contentType,
        metadata: metadata,
      );

      print('🔄 Starting HTTP PUT request with AWS Signature...');
      print('📤 Headers: $signedHeaders');

      final response = await http.put(
        Uri.parse(url),
        headers: signedHeaders,
        body: bytes,
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ S3 upload successful!');
        print('🔗 File available at: $url');
        return url;
      } else {
        print('❌ S3 upload failed with status: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return null;
      }

    } catch (e, stack) {
      print('❌ AwsS3StorageService.uploadFile ERROR: $e');
      print('❌ Stack trace: $stack');
      return null;
    }
  }

  /// Отримання IdentityId з Cognito Identity Pool
  Future<String?> _getIdentityId() async {
    try {
      print('🔑 Getting IdentityId from Cognito...');

      final identityUrl = 'https://cognito-identity.$_region.amazonaws.com/';

      final response = await http.post(
        Uri.parse(identityUrl),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityService.GetId',
        },
        body: jsonEncode({
          'IdentityPoolId': _identityPoolId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final identityId = data['IdentityId'];
        print('✅ IdentityId obtained: $identityId');
        return identityId;
      } else {
        print('❌ GetId failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Cognito GetId error: $e');
      return null;
    }
  }

  /// Отримання тимчасових credential з Cognito
  Future<Map<String, String>?> _getCredentialsForIdentity(String identityId) async {
    try {
      print('🔑 Getting AWS credentials from Cognito...');

      final identityUrl = 'https://cognito-identity.$_region.amazonaws.com/';

      final response = await http.post(
        Uri.parse(identityUrl),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityService.GetCredentialsForIdentity',
        },
        body: jsonEncode({
          'IdentityId': identityId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final credentials = data['Credentials'];
        print('✅ AWS credentials obtained');
        return {
          'accessKeyId': credentials['AccessKeyId'],
          'secretKey': credentials['SecretKey'],
          'sessionToken': credentials['SessionToken'],
        };
      } else {
        print('❌ GetCredentials failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Cognito GetCredentials error: $e');
      return null;
    }
  }

  /// Генерація AWS Signature Version 4 для S3
  Future<Map<String, String>> _signS3Request({
    required String method,
    required String url,
    required String region,
    required String service,
    required String accessKey,
    required String secretKey,
    required String sessionToken,
    required List<int> content,
    required String contentType,
    Map<String, String>? metadata,
  }) async {
    final uri = Uri.parse(url);
    final now = DateTime.now().toUtc();

    // ВИПРАВЛЕННЯ: Правильний формат для x-amz-date
    final amzDate = _formatAmzDate(now);
    final dateStamp = _formatDateStamp(now);

    // Обчислюємо хеш контенту
    final payloadHash = sha256.convert(content).toString();

    // Базові заголовки
    final headers = <String, String>{
      'host': uri.host,
      'x-amz-date': amzDate,
      'x-amz-security-token': sessionToken,
      'x-amz-content-sha256': payloadHash,
      'content-type': contentType,
      'content-length': content.length.toString(),
    };

    // Додаємо метадані
    if (metadata != null) {
      metadata.forEach((key, value) {
        headers['x-amz-meta-$key'] = value;
      });
    }

    // Canonical Request
    final canonicalHeaders = _buildCanonicalHeaders(headers);
    final signedHeaders = _buildSignedHeaders(headers);

    final canonicalRequest = [
      method,
      _canonicalUri(uri.path),
      _canonicalQueryString(uri.query),
      canonicalHeaders,
      '',
      signedHeaders,
      payloadHash,
    ].join('\n');

    print('📄 Canonical Request:\n$canonicalRequest');

    // String to Sign
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    print('🔑 String to Sign:\n$stringToSign');

    // Signature
    final signingKey = _getSignatureKey(secretKey, dateStamp, region, service);
    final signature = _hmacSha256(signingKey, stringToSign);

    // Authorization Header
    final authorizationHeader =
        'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';

    // Фінальні заголовки
    final signedHeadersMap = Map<String, String>.from(headers);
    signedHeadersMap['authorization'] = authorizationHeader;

    print('✅ Signed headers generated successfully');
    return signedHeadersMap;
  }

  /// ВИПРАВЛЕННЯ: Правильний формат для x-amz-date (ISO8601 Basic Format)
  String _formatAmzDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '${year}${month}${day}T${hour}${minute}${second}Z';
  }

  String _formatDateStamp(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year$month$day';
  }

  String _canonicalUri(String path) {
    if (path.isEmpty) return '/';

    // Правильне кодування URI шляху
    final encodedPath = path.split('/').map((segment) {
      return Uri.encodeComponent(segment).replaceAll('+', '%20');
    }).join('/');

    return encodedPath.startsWith('/') ? encodedPath : '/$encodedPath';
  }

  String _canonicalQueryString(String query) {
    if (query.isEmpty) return '';

    final params = query.split('&');
    final sortedParams = <String, String>{};

    for (final param in params) {
      final parts = param.split('=');
      if (parts.length == 1) {
        sortedParams[Uri.encodeComponent(parts[0])] = '';
      } else {
        sortedParams[Uri.encodeComponent(parts[0])] = Uri.encodeComponent(parts[1]);
      }
    }

    final sortedKeys = sortedParams.keys.toList()..sort();
    return sortedKeys.map((key) => '$key=${sortedParams[key]}').join('&');
  }

  String _buildCanonicalHeaders(Map<String, String> headers) {
    final sortedKeys = headers.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sortedKeys.map((key) => '${key.toLowerCase()}:${headers[key]!.trim()}').join('\n');
  }

  String _buildSignedHeaders(Map<String, String> headers) {
    final sortedKeys = headers.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sortedKeys.map((key) => key.toLowerCase()).join(';');
  }

  List<int> _getSignatureKey(String key, String dateStamp, String region, String service) {
    final kDate = _hmacSha256Bytes(utf8.encode('AWS4$key'), dateStamp);
    final kRegion = _hmacSha256Bytes(kDate, region);
    final kService = _hmacSha256Bytes(kRegion, service);
    return _hmacSha256Bytes(kService, 'aws4_request');
  }

  String _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).toString();
  }

  List<int> _hmacSha256Bytes(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  // Решта методів залишаються незмінними
  @override
  Future<File?> downloadFile({
    required String url,
    required String localPath,
  }) async {
    print('📥 AwsS3StorageService.downloadFile');
    print('📥 URL: $url');
    print('📥 Local path: $localPath');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        print('✅ File downloaded successfully');
        return file;
      } else {
        print('❌ Download failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, stack) {
      print('❌ Download error: $e');
      print('❌ Stack: $stack');
      return null;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    print('🗑️ AwsS3StorageService.deleteFile: $path');

    try {
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/$path';

      // Отримуємо credential для DELETE запиту
      final identityId = await _getIdentityId();
      if (identityId == null) return false;

      final credentials = await _getCredentialsForIdentity(identityId);
      if (credentials == null) return false;

      final signedHeaders = await _signS3Request(
        method: 'DELETE',
        url: url,
        region: _region,
        service: 's3',
        accessKey: credentials['accessKeyId']!,
        secretKey: credentials['secretKey']!,
        sessionToken: credentials['sessionToken']!,
        content: [],
        contentType: '',
      );

      final response = await http.delete(Uri.parse(url), headers: signedHeaders);

      final success = response.statusCode == 204;
      print('🗑️ Delete ${success ? 'successful' : 'failed'}: ${response.statusCode}');
      return success;
    } catch (e, stack) {
      print('❌ Delete error: $e');
      print('❌ Stack: $stack');
      return false;
    }
  }

  @override
  Future<String?> getDownloadUrl(String path) async {
    print('🔗 AwsS3StorageService.getDownloadUrl: $path');

    try {
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/$path';
      print('🔗 Generated URL: $url');
      return url;
    } catch (e) {
      print('❌ Get URL error: $e');
      return null;
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    print('🔍 AwsS3StorageService.fileExists: $path');

    try {
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/$path';
      final response = await http.head(Uri.parse(url));

      final exists = response.statusCode == 200;
      print('🔍 File ${exists ? 'exists' : 'does not exist'}: ${response.statusCode}');
      return exists;
    } catch (e) {
      print('❌ File exists check error: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getFileMetadata(String path) async {
    print('📄 AwsS3StorageService.getFileMetadata: $path');

    try {
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/$path';
      final response = await http.head(Uri.parse(url));

      if (response.statusCode == 200) {
        final metadata = <String, dynamic>{
          'size': int.tryParse(response.headers['content-length'] ?? '0') ?? 0,
          'contentType': response.headers['content-type'],
          'lastModified': response.headers['last-modified'],
          'etag': response.headers['etag'],
        };

        response.headers.forEach((key, value) {
          if (key.startsWith('x-amz-meta-')) {
            final metaKey = key.substring(11);
            metadata[metaKey] = value;
          }
        });

        print('📄 Metadata retrieved: $metadata');
        return metadata;
      }

      return null;
    } catch (e) {
      print('❌ Get metadata error: $e');
      return null;
    }
  }

  @override
  Future<List<String?>> uploadBatch({
    required List<File> files,
    required List<String> paths,
    Map<String, String>? metadata,
  }) async {
    print('📦 AwsS3StorageService.uploadBatch');
    print('📦 Files count: ${files.length}');
    print('📦 Paths count: ${paths.length}');

    final results = <String?>[];

    for (int i = 0; i < files.length; i++) {
      print('📦 Processing file ${i + 1}/${files.length}: ${files[i].path}');

      final result = await uploadFile(
        file: files[i],
        path: paths[i],
        metadata: metadata,
      );
      results.add(result);

      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('📦 Batch upload completed. Success: ${results.where((r) => r != null).length}/${files.length}');
    return results;
  }

  /// Helper method to determine content type
  String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'webp':
        return 'image/webp';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}