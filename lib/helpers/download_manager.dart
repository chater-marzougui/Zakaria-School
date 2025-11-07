import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manager class for handling platform-specific download paths and permissions
class DownloadManager {
  static const String appFolderName = 'Zakaria-Auto-Ecole';

  /// Get the appropriate download directory based on platform
  ///
  /// Android: Returns /storage/emulated/0/Zakaria-Auto-Ecole/files
  /// Windows: Returns Downloads/Zakaria-Auto-Ecole
  /// iOS: Returns the application documents directory (accessible via Files app)
  /// Other platforms: Returns the application documents directory
  static Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // For Android, use the public storage directory
      // This creates a folder in the shared storage area visible to users
      // Path will be: /storage/emulated/0/Zakaria-Auto-Ecole/files

      // Get the external storage directory (typically /storage/emulated/0)
      Directory? baseDir;

      // Try to get the external storage directory
      if (await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted) {
        baseDir = Directory('/storage/emulated/0');
      } else {
        // Fallback to getExternalStorageDirectory if permissions not granted
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Extract the base path (usually /storage/emulated/0)
          final pathSegments = externalDir.path.split('/');
          final baseIndex = pathSegments.indexOf('0');
          if (baseIndex != -1) {
            baseDir = Directory(pathSegments.sublist(0, baseIndex + 1).join('/'));
          }
        }
      }

      if (baseDir != null && await baseDir.exists()) {
        // Create the app folder in public storage
        final appDir = Directory('${baseDir.path}/$appFolderName/files');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDir;
      }

      // Fallback to application documents directory
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      // For Windows, use Downloads/Zakaria-Auto-Ecole
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final appDownloadsDir = Directory('${downloadsDir.path}/$appFolderName');
        if (!await appDownloadsDir.exists()) {
          await appDownloadsDir.create(recursive: true);
        }
        return appDownloadsDir;
      }
      // Fallback
      return await getApplicationDocumentsDirectory();
    } 
    // For iOS and other platforms, use application documents directory
    return await getApplicationDocumentsDirectory();
  }

  /// Request necessary storage permissions
  ///
  /// Returns true if permissions are granted, false otherwise
  static Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      // First, try regular storage permission
      var storageStatus = await Permission.storage.status;
      
      if (!storageStatus.isGranted) {
        // Request storage permission
        storageStatus = await Permission.storage.request();
      }
      
      // Check if we need manage external storage (Android 11+)
      var manageStatus = await Permission.manageExternalStorage.status;
      
      if (!manageStatus.isGranted) {
        // Request manage external storage permission
        manageStatus = await Permission.manageExternalStorage.request();
        
        // If denied, open app settings so user can grant it manually
        if (manageStatus.isDenied || manageStatus.isPermanentlyDenied) {
          // For manage external storage, we need to open settings
          await openAppSettings();
          // Check again after user comes back
          manageStatus = await Permission.manageExternalStorage.status;
        }
      }
      
      // Return true if either permission is granted
      return storageStatus.isGranted || manageStatus.isGranted;
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
      throw Exception('Storage permission denied. Please grant storage permissions in settings.');
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
      throw Exception('Storage permission denied. Please grant storage permissions in settings.');
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