import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manager class for handling platform-specific download paths and permissions
class DownloadManager {
  /// Get the appropriate download directory based on platform
  /// 
  /// Android: Returns a Downloads folder in the app's external storage directory
  /// iOS: Returns the application documents directory (accessible via Files app)
  /// Other platforms: Returns the application documents directory
  static Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // For Android, use the external storage directory
      // This creates a folder in the app's external storage area
      // Path will be like: /storage/emulated/0/Android/data/com.example.app/files/Downloads
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Create a Downloads subfolder in the app's external storage
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
      // With UIFileSharingEnabled set to true in Info.plist, files are visible in Files app
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
      // For Android 10+ (API 29+), scoped storage is used
      // Writing to app-specific external storage directory doesn't require permissions
      // For older versions, request storage permission
      final status = await Permission.storage.request();
      // Even if denied on newer Android versions, we can still write to app-specific directories
      return status.isGranted || status.isPermanentlyDenied || status.isDenied;
    } else if (Platform.isIOS) {
      // iOS doesn't require special permissions for writing to app's documents directory
      return true;
    }
    return true;
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
