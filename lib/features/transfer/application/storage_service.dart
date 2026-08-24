import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path/path.dart' as p;

part 'storage_service.g.dart';

@riverpod
class StorageService extends _$StorageService {
  @override
  void build() {
  }

  Future<Directory> getDownloadsDir() async {
    Directory? dir;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      try {
        dir = await getDownloadsDirectory();
      } catch (e) {
      }
    }
    
    dir ??= await getApplicationDocumentsDirectory();
    return dir;
  }

  Future<String> getUniqueFilePath(String fileName) async {
    String sanitizedFileName = fileName.replaceAll('/', '_').replaceAll('\\', '_');
    sanitizedFileName = p.basename(sanitizedFileName);

    final dir = await getDownloadsDir();
    String baseName = p.basenameWithoutExtension(sanitizedFileName);
    String extension = p.extension(sanitizedFileName);
    
    String finalPath = p.join(dir.path, sanitizedFileName);
    int counter = 1;
    
    while (await File(finalPath).exists()) {
      finalPath = p.join(dir.path, '$baseName ($counter)$extension');
      counter++;
    }
    
    return finalPath;
  }

  Future<(IOSink, String)> createDownloadFile(String originalFileName) async {
    final filePath = await getUniqueFilePath(originalFileName);
    final file = File(filePath);
    final sink = file.openWrite(mode: FileMode.writeOnlyAppend);
    return (sink, filePath);
  }

  Future<(IOSink, String, int)> resumeOrCreateDownloadFile(String originalFileName) async {
    String sanitizedFileName = originalFileName.replaceAll('/', '_').replaceAll('\\', '_');
    sanitizedFileName = p.basename(sanitizedFileName);

    final dir = await getDownloadsDir();
    String partPath = p.join(dir.path, '$sanitizedFileName.part');
    
    int existingBytes = 0;
    final partFile = File(partPath);
    if (await partFile.exists()) {
       existingBytes = await partFile.length();
    }
    
    final sink = partFile.openWrite(mode: FileMode.writeOnlyAppend);
    return (sink, partPath, existingBytes);
  }
  
  Future<String> finalizeDownloadFile(String partPath, String originalFileName) async {
    final uniquePath = await getUniqueFilePath(originalFileName);
    await File(partPath).rename(uniquePath);
    return uniquePath;
  }
}
