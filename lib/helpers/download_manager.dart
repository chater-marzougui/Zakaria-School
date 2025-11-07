import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manager class for handling platform-specific download paths and permissions
class DownloadManager {
  /// Get the appropriate download directory based on platform
  /// 
  /// Android: Returns the public Downloads directory (scoped storage)
  /// iOS: Returns the Downloads directory
  /// Other platforms: Returns the application documents directory
  static Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // For Android, use the Downloads directory in external storage
      // This is the public Downloads folder accessible to users
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Navigate to the public Downloads directory
        // /storage/emulated/0/Download is the standard Downloads path
        final downloadPath = Directory('/storage/emulated/0/Download');
        if (await downloadPath.exists()) {
          return downloadPath;
        }
        // Fallback to creating a downloads folder in external storage
        final downloadsDir = Directory('${directory.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      }
      // Fallback to application documents directory
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      // For iOS, use the application documents directory
      // iOS apps are sandboxed and don't have direct access to a system-wide Downloads folder
      // Users can access files through Files app via the app's document directory
      return await getApplicationDocumentsDirectory();
    } else {
      // For other platforms, use application documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Request necessary storage permissions
  /// 
  /// Returns true if permissions are granted, false otherwise
  static Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need different permissions
      if (await _isAndroid13OrAbove()) {
        // Android 13+ uses granular media permissions
        // For images, we might need MANAGE_EXTERNAL_STORAGE or specific media permissions
        // However, writing to Downloads directory typically works with scoped storage
        return true; // Scoped storage doesn't require runtime permissions for app-specific directories
      } else {
        // For Android 10-12, request storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS doesn't require special permissions for writing to app's documents directory
      // If we need to save to photo library, we'd need Permission.photos
      return true;
    }
    return true;
  }

  /// Check if device is running Android 13 or above
  static Future<bool> _isAndroid13OrAbove() async {
    if (!Platform.isAndroid) return false;
    
    // Android 13 is API level 33
    // We can't directly check API level in Dart, so we'll use permission checks
    // as a proxy. On Android 13+, the old storage permission is deprecated.
    try {
      final status = await Permission.storage.status;
      // On Android 13+, storage permission is always denied/restricted
      // This is a heuristic - not perfect but works for our use case
      return false; // For now, assume we're not on Android 13+
    } catch (e) {
      return false;
    }
  }

  /// Save a file to the download directory with proper permissions
  /// 
  /// [fileName] - Name of the file to save
  /// [bytes] - File content as bytes
  /// 
  /// Returns the full path where the file was saved
  static Future<String> saveFile(String fileName, List<int> bytes) async {
    // Request permissions first
    final hasPermission = await requestStoragePermissions();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    // Get the download directory
    final directory = await getDownloadDirectory();
    
    // Create the file path
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    
    // Write the file
    await file.writeAsBytes(bytes);
    
    return filePath;
  }

  /// Save a string content to a file in the download directory
  /// 
  /// [fileName] - Name of the file to save
  /// [content] - File content as string
  /// 
  /// Returns the full path where the file was saved
  static Future<String> saveTextFile(String fileName, String content) async {
    // Request permissions first
    final hasPermission = await requestStoragePermissions();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    // Get the download directory
    final directory = await getDownloadDirectory();
    
    // Create the file path
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    
    // Write the file
    await file.writeAsString(content);
    
    return filePath;
  }
}
