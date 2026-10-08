library globals;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:flux_launcher_gui/account/account_utils.dart';
import 'package:flux_launcher_gui/utils/logging/log_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';

class Globals {
  static const buildVersion = "v0.1 Beta";
  static const windowTitle = "Flux Launcher";
  static const borderRadius = 14.0;
  static const ms_client_id = "c2346197-42f1-4461-91a9-20f947a1cca8";
  static const javaLauncherMainClass = "team.flux.launcher.Main";

  static var showOnlyReleases = false;
  static var darkModeTheme = true;
  static var showConsole = false;
  static var javaAdvSet = false;
  static var customFolderSet = false;
  static var selectedWindowTheme = 'Acrylic';
  static var accentColor = 0;
  static var fullTransparent = false;
  static var forceClasspath = false;

  static List<Account> accounts = [];
  static List<String> pinnedVersions = [];
  static List<String> WindowThemes = [];

  static var navSelected = NavSection.home, AccountSelected = 0;

  static final javapathcontroller = TextEditingController();
  static final javaramcontroller = TextEditingController();
  static final javavmcontroller = TextEditingController();
  static final javalaunchercontroller = TextEditingController();
  static final gamefoldercontroller = TextEditingController();
  static final usernamecontroller = TextEditingController();

  static final LogController consolecontroller = LogController();
  static final LogController diagnosticcontroller = LogController();

  static var fabricGameVersionsResponse;
  static var fabricLoaderVersionsResponse;

  static var forgeVersions;

  static var optiforgeVersions;

  static var optifineVersions;

  static var vanillaVersionsResponse;
  static var vanillaNewsResponse;

  static late Map<String, dynamic> incompatibleJson;

  static bool get isNewsAvailable => Globals.vanillaNewsResponse != null;

  static bool get isVersionsAvailable => Globals.vanillaVersionsResponse != null;

  static bool get isOnline => isNewsAvailable || isVersionsAvailable;

  static Account? getAccount() {
    if (Globals.accounts.isEmpty) return null;

    return Globals.accounts.elementAt(Globals.AccountSelected);
  }
}

enum NavSection {
  home,
  vanilla,
  modded,
  settings,
  accounts,
}

class Urls {

  static const skinURL = "https://minepic.org";
  static const fluxBaseURL = "https://fluxlauncher.xyz";
  static const discordURL = "https://dc.fluxlauncher.xyz";
  static const githubURL = "https://github.com/Flux-Launcher";
  static const fabricApiURL = "https://meta.fabricmc.net/";
  static const forgeVersionsURL = "https://files.minecraftforge.net/net/minecraftforge/forge/maven-metadata.json";
  static const optifineVersionsURL = "$fluxBaseURL/downloads/optifine.json";
  static const modrinthApiURL = "https://api.modrinth.com/v2";

  static const mojangContentURL = "https://launchercontent.mojang.com";
  static const mojangVersionsURL = "https://launchermeta.mojang.com/mc/game/version_manifest.json";

  static const msAuthURL = "https://login.microsoftonline.com/consumers/oauth2/v2.0";
  static const xboxAuthURL = "https://user.auth.xboxlive.com/user/authenticate";
  static const xstsAuthURL = "https://xsts.auth.xboxlive.com/xsts/authorize";
  static const mcAuthURL = "https://api.minecraftservices.com/authentication/login_with_xbox";
  static const mcSkinURL = "https://api.minecraftservices.com/minecraft/profile/skins";
}

class ColorUtils {
  static var isMaterial = false;

  static Color dynamicAccentColor = getColorFromAccent(Globals.accentColor);

  static Color getColorFromAccent(int accent) {
    List<Color> accentColors = [
      SystemTheme.accentColor.light.withAlpha(200),
      Colors.red.withAlpha(160),
      Colors.orange.withAlpha(160),
      Colors.yellow.withAlpha(160),
      Colors.green.withAlpha(160),
      Colors.teal.withAlpha(160),
      Colors.blue.withAlpha(160),
      Colors.deepPurpleAccent.withAlpha(160),
    ];

    return accent < accentColors.length ? accentColors[accent] : SystemTheme.accentColor.light.withAlpha(200);
  }

  static Color get defaultShadowColor => Colors.black.withAlpha(30);

  static late Hct dynamicBackgroundMaterialHct;

  static Color get dynamicMaterialColor => Globals.darkModeTheme ? Color(dynamicBackgroundMaterialHct.toInt()) : const Color(0xFFF0F0F5);

  static Color get dynamicAcrylicColor {
    if (Platform.isMacOS) {
      return Globals.darkModeTheme ? Colors.black.withAlpha(40) : Colors.white.withAlpha(60);
    }

    return Globals.darkModeTheme ? Colors.black.withAlpha(60) : Colors.white.withAlpha(80);
  }

  static Color get dynamicBackgroundColor => isMaterial ? dynamicMaterialColor : dynamicAcrylicColor;

  static Color get dynamicWindowBackgroundColor {
    if (Platform.isMacOS || (Platform.isLinux && Globals.fullTransparent)) {
      return Colors.transparent;
    }

    if (ColorUtils.isMaterial) {
      return ColorUtils.dynamicBackgroundColor;
    } else {
      if (Globals.darkModeTheme) {
        return Colors.black.withAlpha(80);
      } else {
        return Colors.white.withAlpha(10);
      }
    }
  }

  static late Hct dynamicPrimaryMaterialHct;
  static Color get dynamicPrimaryMaterialColor => Globals.darkModeTheme ? Color(dynamicPrimaryMaterialHct.toInt()) : Color(dynamicPrimaryMaterialHct.toInt());

  static Color get dynamicPrimaryForegroundColor => isMaterial ? dynamicPrimaryMaterialColor : dynamicAcrylicColor;
  static late Hct dynamicSecondaryMaterialHct;
  static Color get dynamicSecondaryMaterialColor => Globals.darkModeTheme ? Color(dynamicSecondaryMaterialHct.toInt()) : Color(dynamicSecondaryMaterialHct.toInt());

  static Color get dynamicSecondaryForegroundColor => isMaterial ? dynamicSecondaryMaterialColor : dynamicAcrylicColor;
  static late Hct dynamicTertiaryMaterialHct;

  static Color get primaryFontColor => isMaterial ? (Globals.darkModeTheme ? Colors.white : Color(dynamicTertiaryMaterialHct.toInt()).withAlpha(160)) : Colors.white;

  static Color get secondaryFontColor => primaryFontColor.withAlpha(160);

  static reloadColors() {

    dynamicBackgroundMaterialHct = Hct.fromInt(dynamicAccentColor.value);
    dynamicBackgroundMaterialHct.tone = 15;
    dynamicBackgroundMaterialHct.chroma = 18;

    dynamicPrimaryMaterialHct = Hct.fromInt(dynamicAccentColor.value);
    dynamicSecondaryMaterialHct = Hct.fromInt(dynamicAccentColor.value);
    dynamicTertiaryMaterialHct = Hct.fromInt(dynamicAccentColor.value);

    if (Globals.darkModeTheme) {

      dynamicPrimaryMaterialHct.tone = 25;
      dynamicPrimaryMaterialHct.chroma = 18;

      dynamicSecondaryMaterialHct.tone = 40;
      dynamicSecondaryMaterialHct.chroma = 25;
    } else {

      dynamicPrimaryMaterialHct.tone = 100;

      dynamicSecondaryMaterialHct.tone = 90;
      dynamicSecondaryMaterialHct.chroma = 15;
    }

    dynamicTertiaryMaterialHct.tone = 10;
  }
}

class LauncherUtils {
  static dynamic getApplicationFolder(String targetProgram) {
    if (Platform.isWindows) {
      return ('${Platform.environment['APPDATA']}/.$targetProgram').replaceAll("\\", "/");
    } else if (Platform.isLinux) {
      return '${Platform.environment['HOME']}/.$targetProgram';
    } else if (Platform.isMacOS) {
      return '${Platform.environment['HOME']}/Library/Application Support/$targetProgram';
    } else {
      throw UnsupportedError('Unsupported operating system');
    }
  }

  static dynamic buildJVMOptimizedArgs(String maximumRam) {
    return [
      "-XX:+UnlockExperimentalVMOptions",
      "-XX:+UseG1GC",
      "-XX:G1NewSizePercent=20",
      "-XX:G1ReservePercent=20",
      "-XX:MaxGCPauseMillis=50",
      "-XX:G1HeapRegionSize=32M",
      "-XX:+DisableExplicitGC",
      "-XX:+AlwaysPreTouch",
      "-XX:+ParallelRefProcEnabled",
      "-Xms512M",
      "-Xmx${maximumRam}M",
      "-Dfile.encoding=UTF-8",
      "-XX:HeapDumpPath=MojangTricksIntelDriversForPerformance_javaw.exe_minecraft.exe.heapdump",
      "-Xss1M",
    ];
  }

  static Future<Map<String, String>?> checkJava() async {
    try {
      Process process;
      if (Platform.isLinux) {
        final javaPath = Globals.javapathcontroller.text;
        final lastSlashIndex = javaPath.lastIndexOf('/');

        if (lastSlashIndex != -1) {
          final javaDir = javaPath.substring(0, lastSlashIndex);
          process = await Process.start('sh', ['-c', '(cd "$javaDir" && ./java -version)']);
        } else {
          process = await Process.start(javaPath, ['-version']);
        }
      } else {
        process = await Process.start(
          Globals.javapathcontroller.text,
          ['-version'],
        );
      }

      String? firstLine;
      await for (String line in process.stderr.transform(systemEncoding.decoder)) {
        firstLine = line.trim();
        break;
      }

      await process.exitCode;

      if (firstLine != null) {

        final regex = RegExp(r'^(?<type>\S+)\s+version\s+"(?<version>[^"]+)"(?:\s+(?<date>\d{4}-\d{2}-\d{2}))?(?:\s+(?<lts>LTS))?');
        final match = regex.firstMatch(firstLine);

        if (match != null) {
          return {
            'type': match.namedGroup('type') ?? 'unknown',
            'version': match.namedGroup('version') ?? 'unknown',
            'releaseDate': match.namedGroup('date') ?? '',
            'lts': match.namedGroup('lts') == 'LTS' ? 'true' : 'false',
          };
        }
      }
    } catch (error) {
      print("Errore nel checkJava: $error");
    }

    return null;
  }

  static Future<dynamic> JavaAutoInstall(String gameVersion) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? javaExecutable;

    final requiredJavaVersion = await _getRequiredJavaVersion(gameVersion);
    if (requiredJavaVersion != null) {
      final runtimeDir = "${LauncherUtils.getApplicationFolder("flux")}/runtime/jre-$requiredJavaVersion";
      javaExecutable = _findJavaExecutable(runtimeDir);

      if (javaExecutable == null && Globals.isOnline) {
        try {
          await _installJava(requiredJavaVersion, runtimeDir);
          javaExecutable = _findJavaExecutable(runtimeDir);
        } catch (error) {
          print("Errore nell'installazione di java $requiredJavaVersion: $error");
        }
      }
    }

    Globals.javapathcontroller.text = javaExecutable ?? "java";
    await prefs.setString("javaPath", Globals.javapathcontroller.text);

    return true;
  }

  static Future<int?> _getRequiredJavaVersion(String gameVersion) async {
    try {
      final isAlias = gameVersion == "latest" || gameVersion == "snapshot";
      final localJson = File('${Globals.gamefoldercontroller.text}/versions/$gameVersion/$gameVersion.json');

      if (localJson.existsSync() && !(isAlias && Globals.isVersionsAvailable)) {
        return json.decode(localJson.readAsStringSync())["javaVersion"]?["majorVersion"];
      }

      final manifest = Globals.vanillaVersionsResponse;
      if (manifest == null) return null;

      final realGameVersion = isAlias ? manifest["latest"][gameVersion == "latest" ? "release" : "snapshot"] : gameVersion;
      for (final ver in manifest["versions"]) {
        if (ver["id"] == realGameVersion) {
          final response = await http.get(Uri.parse(ver["url"]));

          return json.decode(response.body)["javaVersion"]?["majorVersion"];
        }
      }
    } catch (error) {
      print("Errore nel rilevamento della versione di java: $error");
    }

    return null;
  }

  static String? _findJavaExecutable(String runtimeDir) {
    final java = File("$runtimeDir/bin/${Platform.isWindows ? "java.exe" : "java"}");
    if (!java.existsSync() || File("$runtimeDir/.installing").existsSync()) return null;

    return java.path;
  }

  static Future<void> _installJava(int javaVersion, String runtimeDir) async {
    final download = await _getJavaDownload(javaVersion);

    final dir = Directory(runtimeDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final marker = File("$runtimeDir/.installing")..createSync();

    final archivePath = "$runtimeDir/${download.fileName}";
    final client = http.Client();
    try {
      final response = await client.send(http.Request("GET", Uri.parse(download.url)));
      if (response.statusCode != 200) {
        throw HttpException("Download fallito (${response.statusCode})", uri: Uri.parse(download.url));
      }
      await response.stream.pipe(File(archivePath).openWrite());
    } finally {
      client.close();
    }

    await Isolate.run(() => _extractJavaHome(archivePath, runtimeDir));
    File(archivePath).deleteSync();

    if (!Platform.isWindows) {
      await Process.run("chmod", ["-R", "755", runtimeDir]);
    }

    marker.deleteSync();
  }

  static Future<void> _extractJavaHome(String archivePath, String runtimeDir) async {

    var inputPath = archivePath;
    if (archivePath.endsWith(".tar.gz")) {
      inputPath = archivePath.substring(0, archivePath.length - 3);
      final gzip = InputFileStream(archivePath);
      final tar = OutputFileStream(inputPath);
      GZipDecoder().decodeStream(gzip, tar);
      await gzip.close();
      await tar.close();
    }

    final input = InputFileStream(inputPath);
    try {
      final archive = inputPath.endsWith(".tar") ? TarDecoder().decodeStream(input) : ZipDecoder().decodeStream(input);

      final javaEntries = archive.where((entry) => RegExp(r"(^|/)bin/java(\.exe)?$").hasMatch(entry.name)).map((entry) => entry.name).toList()
        ..sort((a, b) => a.length.compareTo(b.length));
      if (javaEntries.isEmpty) throw StateError("No java executable in $archivePath");

      final javaHome = javaEntries.first.substring(0, javaEntries.first.lastIndexOf("bin/"));

      for (final entry in archive) {
        if (!entry.name.startsWith(javaHome)) continue;

        final path = "$runtimeDir/${entry.name.substring(javaHome.length)}";
        if (entry.isSymbolicLink) {
          Link(path).createSync(entry.symbolicLink!, recursive: true);
        } else if (entry.isFile) {
          final output = OutputFileStream(path);
          entry.writeContent(output);
          await output.close();
        } else {
          Directory(path).createSync(recursive: true);
        }
      }
    } finally {
      await input.close();
      if (inputPath != archivePath) File(inputPath).deleteSync();
    }
  }

  static Future<({String fileName, String url})> _getJavaDownload(int javaVersion) async {
    final isArm = Platform.version.contains("arm64");

    if (javaVersion == 8 && Platform.isMacOS && !isArm) {
      return (fileName: "jre-8-patched.zip", url: "${Urls.fluxBaseURL}/downloads/jre-8-patched.zip");
    }

    final uri = Uri.https('api.azul.com', '/metadata/v1/zulu/packages', {
      'java_version': "$javaVersion",
      'os': Platform.operatingSystem,
      'arch': isArm ? "aarch64" : "x86_64",
      'archive_type': Platform.isLinux ? 'tar.gz' : 'zip',
      'java_package_type': 'jdk',
      'javafx_bundled': 'false',
      'crac_supported': 'false',
      'latest': 'true',
    });
    final List packages = json.decode((await http.get(uri)).body);

    final package = packages.firstWhere(
      (package) => !"${package["name"]}".contains("musl") && !"${package["name"]}".contains("alpine"),
      orElse: () => throw StateError("Nessun pacchetto java $javaVersion disponibile"),
    );

    return (fileName: package["name"] as String, url: package["download_url"] as String);
  }
}

class News {
  String title;
  String type;
  String version;
  String imageUrl;
  String imageTitle;
  String body;
  String id;
  String contentPath;

  News({
    required this.title,
    required this.type,
    required this.version,
    required this.imageUrl,
    required this.imageTitle,
    required this.body,
    required this.id,
    required this.contentPath,
  });

  factory News.fromJSON(Map<String, dynamic> json) {
    return News(
      title: json["title"],
      type: json["type"],
      version: json["version"],
      imageUrl: json["image"]["url"],
      imageTitle: json["image"]["title"],
      body: json["body"],
      id: json["id"],
      contentPath: json["contentPath"],
    );
  }
}
