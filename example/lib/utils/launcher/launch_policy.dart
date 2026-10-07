import 'package:flux_launcher_gui/globals.dart';

enum ModLoader {
  vanilla,
  fabric,
  optifine,
  optiforge,
  forge,
  neoforge,
  quilt,
}

class LaunchProfile {
  final String minecraftVersion;
  final ModLoader loader;

  const LaunchProfile({required this.minecraftVersion, required this.loader});
}

class LaunchConfig {
  final String gameVersion;
  final String? productId;
  final bool isModded;
  final String realGameVersion;
  final ModLoader loader;
  final bool startOnFirstThread;

  final bool forceClassPath;

  final List<String> jvmArgs;
  final List<String> launcherArgs;

  LaunchConfig({
    required this.gameVersion,
    this.productId,
    required this.isModded,
    required this.realGameVersion,
    required this.loader,
    required this.startOnFirstThread,
    this.forceClassPath = false,
    this.jvmArgs = const [],
    this.launcherArgs = const [],
  });

  bool get enableClassPath {

    if (productId != null) return false;
    if (forceClassPath) return true;

    return LaunchPolicy.resolveEnableClassPathFor(loader, realGameVersion);
  }
}

class LaunchPolicy {

  static const String forgeClasspathBaseline = '1.17.1';

  static bool resolveEnableClassPathFor(ModLoader loader, String minecraftVersion) {
    if (Globals.forceClasspath || hasManualClasspathOverride()) return true;

    switch (loader) {
      case ModLoader.forge:
      case ModLoader.optiforge:
        return _compareMinecraftVersions(minecraftVersion, forgeClasspathBaseline) >= 0;
      case ModLoader.neoforge:
      case ModLoader.quilt:
        return true;
      case ModLoader.vanilla:
      case ModLoader.fabric:
      case ModLoader.optifine:
        return false;
    }
  }

  static bool hasManualClasspathOverride() {
    return Globals.javalaunchercontroller.text.split(' ').contains('-c');
  }

  static ModLoader loaderFromModrinthId(String id) {
    switch (id) {
      case 'fabric':
        return ModLoader.fabric;
      case 'forge':
        return ModLoader.forge;
      case 'quilt':
        return ModLoader.quilt;
      case 'neoforge':
        return ModLoader.neoforge;
      default:
        return ModLoader.vanilla;
    }
  }

  static ModLoader detectLoaderFromId(String id) {
    final lower = id.toLowerCase();

    if (lower.startsWith('neoforge-') || lower.startsWith('neoforge_')) return ModLoader.neoforge;
    if (lower.startsWith('fabric-loader-')) return ModLoader.fabric;
    if (lower.startsWith('quilt-loader-')) return ModLoader.quilt;
    if (lower.contains('optiforge')) return ModLoader.optiforge;
    if (lower.contains('optifine')) return ModLoader.optifine;
    if (lower.contains('forge')) return ModLoader.forge;
    if (lower.contains('fabric')) return ModLoader.fabric;
    if (lower.contains('quilt')) return ModLoader.quilt;

    return ModLoader.vanilla;
  }

  static ModLoader detectLoaderFromType(String type) {
    final lower = type.toLowerCase();

    if (lower.contains('neoforge')) return ModLoader.neoforge;
    if (lower.contains('optiforge')) return ModLoader.optiforge;
    if (lower.contains('optifine')) return ModLoader.optifine;
    if (lower.contains('forge')) return ModLoader.forge;
    if (lower.contains('fabric')) return ModLoader.fabric;
    if (lower.contains('quilt')) return ModLoader.quilt;

    return ModLoader.vanilla;
  }

  static ModLoader? detectLoaderFromLibraries(List<dynamic> libraries) {
    for (final entry in libraries) {
      final name = entry is Map ? entry['name']?.toString().toLowerCase() : null;
      if (name == null) continue;

      if (name.startsWith('net.neoforged:')) return ModLoader.neoforge;
      if (name.startsWith('net.minecraftforge:forge:')) return ModLoader.forge;
      if (name.startsWith('net.fabricmc:fabric-loader:')) return ModLoader.fabric;
      if (name.startsWith('org.quiltmc:quilt-loader:')) return ModLoader.quilt;
    }

    return null;
  }

  static String extractMinecraftVersion(String id, ModLoader loader) {
    switch (loader) {
      case ModLoader.fabric:
        return _stripLoaderPrefix(id, 'fabric-loader-');
      case ModLoader.quilt:
        return _stripLoaderPrefix(id, 'quilt-loader-');
      case ModLoader.forge:
      case ModLoader.optiforge:
      case ModLoader.optifine:
        return id.split('-').first;
      case ModLoader.neoforge:
      case ModLoader.vanilla:
        return id;
    }
  }

  static String _stripLoaderPrefix(String id, String prefix) {
    if (!id.toLowerCase().startsWith(prefix)) return id;

    final remainder = id.substring(prefix.length);
    final separatorIndex = remainder.indexOf('-');

    return separatorIndex == -1 ? remainder : remainder.substring(separatorIndex + 1);
  }

  static int _compareMinecraftVersions(String a, String b) {
    final partsA = a.split('.');
    final partsB = b.split('.');
    final length = partsA.length > partsB.length ? partsA.length : partsB.length;

    for (var i = 0; i < length; i++) {
      final numA = i < partsA.length ? int.tryParse(partsA[i]) ?? 0 : 0;
      final numB = i < partsB.length ? int.tryParse(partsB[i]) ?? 0 : 0;
      if (numA != numB) return numA.compareTo(numB);
    }

    return 0;
  }
}
