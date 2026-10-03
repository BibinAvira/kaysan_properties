import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// The full raw `/projects` catalogue as last downloaded, and when.
class CachedCatalog {
  const CachedCatalog(this.savedAt, this.projects);
  final DateTime savedAt;
  final List<Map<String, dynamic>> projects;

  bool get isStale => DateTime.now().difference(savedAt) > CatalogCache.maxAge;
}

/// On-device copy of the full Reelly catalogue (~11 MB of JSON, ~3 MB
/// over the wire gzipped), so Best Match ranking, filters and search run
/// over every project without re-downloading on each launch.
///
/// JSON encode/decode runs on a background isolate — at this size it
/// would otherwise drop frames.
class CatalogCache {
  /// Older than this, the cache is still shown but refreshed in the
  /// background (stale-while-revalidate).
  static const Duration maxAge = Duration(hours: 6);

  /// Bump when the cached shape changes, so an old file is ignored.
  static const String _fileName = 'catalog_v1.json';

  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/$_fileName');

  Future<CachedCatalog?> read() async {
    try {
      final File file = await _file();
      if (!await file.exists()) return null;
      final String text = await file.readAsString();
      return await Isolate.run(() {
        final Map<String, dynamic> json =
            jsonDecode(text) as Map<String, dynamic>;
        return CachedCatalog(
          DateTime.parse(json['saved_at'] as String),
          (json['projects'] as List<dynamic>).cast<Map<String, dynamic>>(),
        );
      });
    } catch (e) {
      // A corrupt or unreadable cache is just a cache miss.
      debugPrint('Catalog cache unreadable: $e');
      return null;
    }
  }

  Future<void> write(List<Map<String, dynamic>> projects) async {
    try {
      final String text = await Isolate.run(() => jsonEncode(<String, dynamic>{
            'saved_at': DateTime.now().toIso8601String(),
            'projects': projects,
          }));
      await (await _file()).writeAsString(text, flush: true);
    } catch (e) {
      debugPrint('Catalog cache not saved: $e');
    }
  }
}
