// Conditional export: re-export the platform implementation so callers can call
// downloadCsvFile() and downloadXlsxFile().
export 'download_helper_io.dart' if (dart.library.html) 'download_helper_web.dart';

// The exported file exposes:
// Future<String> downloadCsvFile(String filename, String content)
// Future<String> downloadXlsxFile(String filename, List<int> bytes)
