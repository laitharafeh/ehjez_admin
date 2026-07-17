import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveCsv(List<int> bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$filename';
  await File(path).writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(path, mimeType: 'text/csv', name: filename),
      ],
    ),
  );
}
