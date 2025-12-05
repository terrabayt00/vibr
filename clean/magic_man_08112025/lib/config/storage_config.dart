import 'package:magic/storage/storage_manager.dart';

class StorageConfig {
  /// Configure storage service
  /// You can change this to switch between different storage providers
  static Future<void> configureStorage() async {
    // Option 1: Use Firebase Storage (default)
    // await StorageManager.initialize(
    //   type: StorageServiceType.firebase,
    // );

    // Option 2: Use AWS S3 with credentials
    // await StorageManager.initialize(
    //   type: StorageServiceType.awsS3,
    //   config: {
    //     'bucketName': 'your-bucket-name',
    //     'region': 'us-east-1',
    //     'accessKeyId': 'your-access-key-id',
    //     'secretAccessKey': 'your-secret-access-key',
    //   },
    // );

    // Option 3: Use AWS S3 with public write access (no credentials needed)
    // await StorageManager.initialize(
    //   type: StorageServiceType.awsS3,
    //   config: {
    //     'bucketName': 'your-public-bucket-name',
    //     'region': 'us-east-1',
    //     // accessKeyId and secretAccessKey are optional for public buckets
    //   },
    // );

    // Option 4: Use AWS S3 with IAM roles (no credentials in code)
    await StorageManager.initialize(
      type: StorageServiceType.awsS3,
      config: {
        'bucketName': 'vibrbucket',
        'region': 'eu-west-3',
        // IAM roles will be used automatically
      },
    );
  }

  /// Get current storage service info
  static Map<String, dynamic> getCurrentServiceInfo() {
    return StorageManager.getServiceInfo();
  }
}
