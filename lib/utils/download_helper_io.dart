import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

Future<String> downloadCsvFile(String filename, String content) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content);

  // On mobile, surface the file using share sheet so the user can save/open it.
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles([XFile(file.path)], text: filename);
      return 'shared:$filename';
    }
  } catch (_) {}

  return file.path;
}

Future<String> downloadXlsxFile(String filename, List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);

  // Try to move/save to a visible Downloads folder on desktop platforms
  try {
    if (!Platform.isAndroid && !Platform.isIOS) {
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          final out = File('${downloads.path}/$filename');
          await out.writeAsBytes(bytes, flush: true);
          return out.path;
        }
      } catch (_) {}
      return file.path;
    } else {
      // On Android/iOS, open share sheet so user can save/open the file
      await Share.shareXFiles([XFile(file.path)], text: filename);
      return 'shared:$filename';
    }
  } catch (e) {
    // Fallback to temp file path
    return file.path;
  }
}
