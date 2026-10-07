import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:flux_launcher_gui/globals.dart';

class ModrinthUtils {

  static String get packsRoot => '${LauncherUtils.getApplicationFolder("flux")}/modrinth-packs';

  static String get indexFile => '$packsRoot/index.json';

  static String instanceDir(String slug) => '$packsRoot/$slug';

  static String metaFile(String slug) => '${instanceDir(slug)}/pack.json';

  static List<Map<String, dynamic>> readIndex() {
    final file = File(indexFile);
    if (!file.existsSync()) return [];
    try {
      final decoded = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      final packs = decoded['packs'] as List? ?? [];

      return packs.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeIndex(List<Map<String, dynamic>> packs) async {
    Directory(packsRoot).createSync(recursive: true);
    final file = File(indexFile);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({'packs': packs}),
      flush: true,
    );
  }

  static Future<void> _upsertIndex(Map<String, dynamic> entry) async {
    final packs = readIndex();
    final idx = packs.indexWhere((p) => p['slug'] == entry['slug']);
    if (idx >= 0) {
      packs[idx] = entry;
    } else {
      packs.add(entry);
    }
    await _writeIndex(packs);
  }

  static Future<void> _removeFromIndex(String slug) async {
    final packs = readIndex()..removeWhere((p) => p['slug'] == slug);
    await _writeIndex(packs);
  }

  static Map<String, dynamic>? getIndexEntry(String slug) {
    return readIndex().cast<Map<String, dynamic>?>().firstWhere(
          (p) => p?['slug'] == slug,
          orElse: () => null,
        );
  }

  static bool instanceExists(String slug) => Directory(instanceDir(slug)).existsSync();

  static void _createInstanceDirs(String slug) {
    for (final sub in ['mods', 'config', 'saves', 'resourcepacks', 'shaderpacks', 'screenshots']) {
      Directory('${instanceDir(slug)}/$sub').createSync(recursive: true);
    }
  }

  static Future<void> _writeMeta(String slug, Map<String, dynamic> meta) async {
    final file = File(metaFile(slug));
    await file.writeAsString(json.encode(meta), flush: true);
  }

  static Map<String, dynamic>? readMeta(String slug) {
    final file = File(metaFile(slug));
    if (!file.existsSync()) return null;
    try {
      return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static List<String> installedSlugs() {
    final indexed = readIndex().map((p) => p['slug'].toString()).toList();
    if (indexed.isNotEmpty) return indexed;

    final root = Directory(packsRoot);
    if (!root.existsSync()) return [];

    return root
        .listSync()
        .whereType<Directory>()
        .map((d) => d.path.split(Platform.pathSeparator).last)
        .where((name) => name != 'index.json')
        .toList();
  }

  static Future<void> removeInstance(String slug) async {
    final dir = Directory(instanceDir(slug));
    if (dir.existsSync()) await dir.delete(recursive: true);
    await _removeFromIndex(slug);
  }

  static Future<void> installModpack({
    required String projectId,
    required String slug,
    required String title,
    String? iconUrl,
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('Fetching version info…');

    final versionsRes = await http.get(
      Uri.parse('${Urls.modrinthApiURL}/project/$projectId/version'),
    );
    if (versionsRes.statusCode != 200) {
      throw Exception('Failed to fetch versions for $projectId');
    }

    final versions = json.decode(versionsRes.body) as List;
    if (versions.isEmpty) throw Exception('No versions available for $projectId');

    final latest = versions.first as Map<String, dynamic>;
    final versionId = latest['id']?.toString() ?? '';
    final versionName = latest['version_number']?.toString() ?? '';

    final files = (latest['files'] as List? ?? []);
    final primaryFile = files.firstWhere(
      (f) => f['primary'] == true,
      orElse: () => files.isNotEmpty ? files.first : null,
    );
    if (primaryFile == null) throw Exception('No file found in version $versionId');

    final downloadUrl = primaryFile['url']?.toString() ?? '';
    if (downloadUrl.isEmpty) throw Exception('Empty download URL for $versionId');

    onStatus?.call('Downloading $title $versionName…');
    onProgress?.call(0.05);

    final mrpackRes = await http.get(Uri.parse(downloadUrl));
    if (mrpackRes.statusCode != 200) {
      throw Exception('Failed to download mrpack from $downloadUrl');
    }

    onProgress?.call(0.25);

    _createInstanceDirs(slug);

    final archive = ZipDecoder().decodeBytes(mrpackRes.bodyBytes);

    final indexEntry = archive.files.firstWhere(
      (f) => f.name == 'modrinth.index.json',
      orElse: () => throw Exception('modrinth.index.json not found in mrpack'),
    );
    final index = json.decode(utf8.decode(indexEntry.content as List<int>)) as Map<String, dynamic>;

    onStatus?.call('Extracting overrides…');
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (!file.name.startsWith('overrides/')) continue;

      final relativePath = file.name.substring('overrides/'.length);
      if (relativePath.isEmpty) continue;

      final outPath = '${instanceDir(slug)}/$relativePath';
      final outFile = File(outPath);
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(file.content as List<int>);
    }

    onProgress?.call(0.45);

    final modFiles = (index['files'] as List? ?? []);
    final total = modFiles.length;

    onStatus?.call('Downloading $total mod files…');

    for (var i = 0; i < total; i++) {
      final modFile = modFiles[i] as Map<String, dynamic>;
      final modPath = modFile['path']?.toString() ?? '';
      final downloads = (modFile['downloads'] as List? ?? []);
      if (downloads.isEmpty || modPath.isEmpty) continue;

      final modUrl = downloads.first.toString();
      final dest = File('${instanceDir(slug)}/$modPath');
      dest.parent.createSync(recursive: true);

      if (!dest.existsSync()) {
        try {
          final modRes = await http.get(Uri.parse(modUrl));
          if (modRes.statusCode == 200) {
            dest.writeAsBytesSync(modRes.bodyBytes);
          }
        } catch (e) {
          print('[ModrinthUtils] Failed to download $modUrl: $e');
        }
      }

      onProgress?.call(0.45 + 0.50 * ((i + 1) / total));
    }

    final deps = Map<String, String>.from(
      (index['dependencies'] as Map? ?? {}).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
    );
    final mcVersion = deps['minecraft'] ?? '';
    final loader = _detectLoader(deps);

    final meta = {
      'projectId': projectId,
      'slug': slug,
      'title': title,
      'iconUrl': iconUrl ?? '',
      'versionId': versionId,
      'versionName': versionName,
      'minecraft': mcVersion,
      'loader': loader,
      'installedAt': DateTime.now().toIso8601String(),
      'dependencies': deps,
    };
    await _writeMeta(slug, meta);

    await _upsertIndex({
      'slug': slug,
      'projectId': projectId,
      'title': title,
      'iconUrl': iconUrl ?? '',
      'versionName': versionName,
      'minecraft': mcVersion,
      'loader': loader,
      'installedAt': meta['installedAt'],
    });

    onProgress?.call(1.0);
    onStatus?.call('$title installed successfully!');
  }

  static String _detectLoader(Map<String, String> deps) {
    if (deps.containsKey('fabric-loader')) return 'fabric';
    if (deps.containsKey('forge')) return 'forge';
    if (deps.containsKey('quilt-loader')) return 'quilt';
    if (deps.containsKey('neoforge')) return 'neoforge';

    return 'unknown';
  }

  static String gameDir(String slug) => instanceDir(slug);

  static Map<String, String> getDependencies(String slug) {
    final meta = readMeta(slug);
    if (meta == null) return {};
    final deps = meta['dependencies'];
    if (deps == null) return {};

    return Map<String, String>.from(deps as Map);
  }
}
