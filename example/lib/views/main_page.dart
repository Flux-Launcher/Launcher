import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flux_launcher_gui/account/account_utils.dart';
import 'package:flux_launcher_gui/account/microsoft_auth.dart';
import 'package:flux_launcher_gui/globals.dart';
import 'package:flux_launcher_gui/l10n/app_localizations.dart';
import 'package:flux_launcher_gui/main.dart';
import 'package:flux_launcher_gui/utils/circle_utils.dart';
import 'package:flux_launcher_gui/utils/launcher/version_utils.dart';
import 'package:flux_launcher_gui/utils/launcher/launch_utils.dart';
import 'package:flux_launcher_gui/utils/launcher/modrinth_utils.dart';
import 'package:flux_launcher_gui/utils/flux_icons_icons.dart';
import 'package:flux_launcher_gui/utils/skinmodel/skin_utils.dart';
import 'package:flux_launcher_gui/utils/skinmodel/skin_viewer.dart';
import 'package:flux_launcher_gui/utils/widget_utils.dart';
import 'package:flux_launcher_gui/views/modrinth_view.dart';
import 'package:flux_launcher_gui/views/widget_news.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_3d/simple_3d.dart';
import 'package:simple_3d_renderer/simple_3d_renderer.dart';
import 'package:system_theme/system_theme.dart';
import 'package:text_divider/text_divider.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final ValueNotifier<String?> _themeNotifier = ValueNotifier(Globals.selectedWindowTheme);

  @override
  void initState() {
    super.initState();
    rebuild();
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  Future<void> rebuild() async {
    if (Globals.getAccount() != null) {
      ThreeDimensionalViewer.objs.clear();
      ThreeDimensionalViewer.setupUV(Globals.getAccount()!.isSlimSkin);
      ThreeDimensionalViewer.texturizePlayerModel();
      Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        setState(() {
          ThreeDimensionalViewer.isLoaded = ThreeDimensionalViewer.isLoaded;
        });
        timer.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorUtils.dynamicWindowBackgroundColor,
      child: Column(
        children: [
          drawTitleCustomBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Stack(
                children: [
                  _buildContent(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildNavbar(),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            reverseDuration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final progress = animation.value;
                  final scale = 0.85 + 0.15 * progress;
                  final blur = (1.0 - progress) * 8.0;
                  final opacity = progress.clamp(0.0, 1.0);

                  Widget res = Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: child,
                    ),
                  );

                  if (blur > 0.08) {
                    res = ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: blur * 1.5,
                        sigmaY: blur * 0.4,
                      ),
                      child: res,
                    );
                  }

                  return res;
                },
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey(Globals.navSelected),
              child: SmoothScrollWrapper(
                child: _getTabContent(Globals.navSelected),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getTabContent(NavSection section) {
    switch (section) {
      case NavSection.home:
        return buildHomeWidgetList();
      case NavSection.vanilla:
        return buildVanillaList();
      case NavSection.modded:
        return buildModdedList();
      case NavSection.settings:
        return buildSettingsList();
      case NavSection.accounts:
        return _buildAccountsContent();
    }
  }

  Widget _buildResponsiveTileGrid(
    List<Widget> children, {
    double minTileWidth = 340,
    double spacing = 8,
    double runSpacing = 0,
    int maxColumns = 4,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : MediaQuery.of(context).size.width;
        final columns = WidgetUtils.responsiveColumnCount(
          width,
          minTileWidth: minTileWidth,
          spacing: spacing,
          maxColumns: maxColumns,
        );

        final tileWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: tileWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }

  Widget buildNavbar() {
    final bool isPl = Localizations.localeOf(context).languageCode == 'pl';

    return Material(
      elevation: 15,
      color: ColorUtils.dynamicPrimaryForegroundColor,
      shadowColor: ColorUtils.defaultShadowColor,
      borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
      child: Container(
        width: 175,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4, bottom: 18),
              child: Row(
                children: [
                  Image.asset('assets/flux.png', width: 28, height: 28),
                  const SizedBox(width: 10),
                  Text(
                    "FLUX",
                    style: WidgetUtils.customTextStyle(
                      17,
                      FontWeight.w700,
                      ColorUtils.primaryFontColor,
                    ).copyWith(letterSpacing: 2.0),
                  ),
                ],
              ),
            ),
            buildNavItem(Icons.home_rounded, isPl ? "Główna" : "Home", NavSection.home),
            const SizedBox(height: 6),
            buildNavItem(FluxIcons.vanilla, "Vanilla", NavSection.vanilla),
            const SizedBox(height: 6),
            buildNavItem(FluxIcons.modded, isPl ? "Mody" : "Modded", NavSection.modded),
            const SizedBox(height: 6),
            buildNavItem(Icons.settings_rounded, isPl ? "Ustawienia" : "Settings", NavSection.settings),
            const Spacer(),
            buildNavAccountItem(NavSection.accounts, isPl ? "Konto" : "Account"),
          ],
        ),
      ),
    );
  }

  Widget buildNavItem(IconData icon, String title, NavSection section) {
    final bool selected = Globals.navSelected == section;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          setState(() {
            Globals.navSelected = section;
          });

          if (section == NavSection.home) {
            Globals.pinnedVersions = await VersionUtils.getPinnedVersions();
          }
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Globals.borderRadius / 2),
            color: selected
                ? ColorUtils.dynamicAccentColor.withAlpha(45)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? ColorUtils.primaryFontColor
                    : ColorUtils.primaryFontColor.withAlpha(140),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: WidgetUtils.customTextStyle(
                    14,
                    selected ? FontWeight.w600 : FontWeight.w400,
                    selected
                        ? ColorUtils.primaryFontColor
                        : ColorUtils.primaryFontColor.withAlpha(180),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNavAccountItem(NavSection section, String defaultTitle) {
    final bool selected = Globals.navSelected == section;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            Globals.navSelected = section;
          });
        },
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Globals.borderRadius / 2),
            color: selected
                ? ColorUtils.dynamicAccentColor.withAlpha(45)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              FutureBuilder<Uint8List>(
                future: SkinUtils.loadCroppedSkin(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorUtils.primaryFontColor.withAlpha(25),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: ColorUtils.primaryFontColor.withAlpha(150),
                      ),
                    );
                  }

                  final croppedBytes = snapshot.data!;
                  return Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        filterQuality: FilterQuality.none,
                        opacity: selected ? 1.0 : 0.7,
                        image: MemoryImage(croppedBytes),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  Globals.usernamecontroller.text.isNotEmpty
                      ? Globals.usernamecontroller.text
                      : defaultTitle,
                  style: WidgetUtils.customTextStyle(
                    13,
                    selected ? FontWeight.w600 : FontWeight.w400,
                    selected
                        ? ColorUtils.primaryFontColor
                        : ColorUtils.primaryFontColor.withAlpha(180),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListView buildHomeWidgetList() {
    return ListView(
      children: [

        if (Globals.pinnedVersions.isNotEmpty) ...[

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: TextDivider(
              color: ColorUtils.secondaryFontColor.withAlpha(80),
              thickness: 2,
              text: Text(
                AppLocalizations.of(context)!.home_favourite_title,
                textAlign: TextAlign.center,
                style: WidgetUtils.customTextStyle(
                  20,
                  FontWeight.w300,
                  ColorUtils.primaryFontColor,
                ),
              ),
            ),
          ),
          _buildResponsiveTileGrid([
            for (var version in VersionUtils.getAllVersions())
              if (Globals.pinnedVersions.contains(version["id"]))
                buildVanillaItem(
                  version["type"],
                  version["id"],
                  "",
                  VersionUtils.isCompatible(
                    version["type"],
                    version["id"],
                    context,
                  ),
                ),
          ]),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: TextDivider(
              color: ColorUtils.secondaryFontColor.withAlpha(80),
              thickness: 2,
              text: Text(
                AppLocalizations.of(context)!.home_news_title,
                textAlign: TextAlign.center,
                style: WidgetUtils.customTextStyle(
                  20,
                  FontWeight.w300,
                  ColorUtils.primaryFontColor,
                ),
              ),
            ),
          ),
        ],

        if (Globals.isNewsAvailable) ...[
          _buildResponsiveTileGrid(
            [
              for (var version in Globals.vanillaNewsResponse)
                if ((version["type"] == "release" && Globals.showOnlyReleases) || !Globals.showOnlyReleases)
                  buildNewsItem(
                    version["title"].toString().replaceAll(": Java Edition", "").replaceAll(" Aquatic", ""),
                    version["body"],
                    version["image"]["url"],
                    detailPath: version["detailPath"]?.toString(),
                    date: version["date"]?.toString(),
                  ),
            ],
            minTileWidth: 280,
          ),
        ] else ...[

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Text(
              AppLocalizations.of(context)!.home_news_empty_msg,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                14,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget buildNewsItem(
    String title,
    String body,
    String url, {
    String? detailPath,
    String? date,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          elevation: 15,
          color: ColorUtils.dynamicPrimaryForegroundColor,
          shadowColor: ColorUtils.defaultShadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsScreen(
                    title: title,
                    body: body,
                    url: url,
                    detailPath: detailPath,
                    date: date,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Globals.borderRadius - 2),
                    child: Stack(
                      children: [
                        Image.network(
                          "${Urls.mojangContentURL}$url",
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),

                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withAlpha(190)],
                                stops: const [0.4, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: WidgetUtils.customTextStyle(16, FontWeight.w600, Colors.white),
                              ),
                              if (date != null && date.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _formatNewsDate(date),
                                  style: WidgetUtils.customTextStyle(11, FontWeight.w500, Colors.white.withAlpha(190)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNewsDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();

      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return "";
    }
  }

  ListView buildVanillaList() {
    return ListView(
      children: [

        if (VersionUtils.getMinecraftVersions(false).isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              AppLocalizations.of(context)!.vanilla_empty_title,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                22,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),

        _buildResponsiveTileGrid([
          buildVanillaItem(
            AppLocalizations.of(context)!.vanilla_release_title,
            Globals.vanillaVersionsResponse != null ? Globals.vanillaVersionsResponse["latest"]["release"] : "",
            "",
            true,
          ),
          buildVanillaItem(
            AppLocalizations.of(context)!.vanilla_snapshot_title,
            Globals.vanillaVersionsResponse != null ? Globals.vanillaVersionsResponse["latest"]["snapshot"] : "",
            "",
            true,
          ),
        ]),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(
            color: ColorUtils.secondaryFontColor,
          ),
        ),

        _buildResponsiveTileGrid([
          for (var version in VersionUtils.getMinecraftVersions(false))
            if ((version["type"] == "release" && Globals.showOnlyReleases) || !Globals.showOnlyReleases)
              buildVanillaItem(
                version["type"],
                version["id"],
                version["releaseTime"],
                VersionUtils.isCompatible(
                  version["type"],
                  version["id"],
                  context,
                ),
              ),
        ]),
      ],
    );
  }

  Widget buildVanillaItem(String gameType, String gameVersion, String releaseDate, bool compatible) {
    final bool compatible = VersionUtils.isCompatible(gameType, gameVersion, context);
    final String? incompatibilityReason = compatible ? null : VersionUtils.getIncompatibilityReason(gameType, gameVersion, context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: Material(
          elevation: 15,
          color: ColorUtils.dynamicPrimaryForegroundColor,
          shadowColor: ColorUtils.defaultShadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Tooltip(
                  message: incompatibilityReason ?? "",
                  textStyle: WidgetUtils.customTextStyle(12, FontWeight.w500, ColorUtils.primaryFontColor),
                  decoration: BoxDecoration(
                    color: ColorUtils.dynamicBackgroundColor,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                  waitDuration: const Duration(milliseconds: 500),
                  child: ColorFiltered(
                    colorFilter: compatible
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                        : const ColorFilter.matrix(<double>[
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          filterQuality: FilterQuality.none,
                          image: AssetImage(_getVersionIcon(gameType, gameVersion)),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${gameType.substring(0, 1).toUpperCase()}${gameType.substring(1)} $gameVersion",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WidgetUtils.customTextStyle(
                        releaseDate.isNotEmpty ? 18 : 20,
                        FontWeight.w500,
                        ColorUtils.primaryFontColor,
                      ),
                    ),
                    if (releaseDate.isNotEmpty)
                      Text(
                        "${DateTime.parse(releaseDate).toLocal().day}/${DateTime.parse(releaseDate).toLocal().month}/${DateTime.parse(releaseDate).toLocal().year}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WidgetUtils.customTextStyle(
                          14,
                          FontWeight.w500,
                          ColorUtils.secondaryFontColor,
                        ),
                      ),
                  ],
                ),
              ),

              if (!gameType.contains(AppLocalizations.of(context)!.vanilla_release_title) && !gameType.contains(AppLocalizations.of(context)!.vanilla_snapshot_title))
                WidgetUtils.buildButton(
                  Globals.pinnedVersions.contains(gameVersion) ? Icons.favorite : Icons.favorite_border,
                  ColorUtils.dynamicSecondaryForegroundColor,
                  ColorUtils.primaryFontColor,
                  () async {
                    setState(() {
                      if (!Globals.pinnedVersions.contains(gameVersion)) {
                        Globals.pinnedVersions.add(gameVersion);
                      } else {
                        Globals.pinnedVersions.remove(gameVersion);
                      }
                    });
                    await VersionUtils.updateLauncherProfiles(Globals.pinnedVersions);
                  },
                ),

              WidgetUtils.buildButton(
                Icons.rocket_launch,
                ColorUtils.dynamicAccentColor,
                Colors.white,
                () async {
                  final resolvedVersion = versionResolver(gameType, gameVersion, context);
                  final profile = VersionUtils.resolveLaunchProfile(
                    resolvedVersion.gameVersion,
                    gameDirectory: Globals.gamefoldercontroller.text,
                  );
                  final config = LaunchConfig(
                    gameVersion: resolvedVersion.gameVersion,
                    productId: null,
                    isModded: profile.loader != ModLoader.vanilla,
                    realGameVersion: profile.minecraftVersion,
                    loader: profile.loader,
                    startOnFirstThread: LaunchUtils.shouldUseStartOnFirstThread(
                      profile.minecraftVersion,
                    ),
                    jvmArgs: resolvedVersion.additionalArgs,
                    launcherArgs: [],
                  );
                  await LaunchUtils.launchMinecraft(
                    context,
                    config,
                    onAccountRequired: () {
                      setState(() => Globals.navSelected = NavSection.accounts);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getVersionIcon(String gameType, String gameVersion) {
    final type = gameType.toLowerCase();
    final version = gameVersion.toLowerCase();

    if (type.contains("alpha")) return 'assets/alpha.png';
    if (type.contains("beta")) return 'assets/beta.png';
    if (type.contains("snapshot")) return 'assets/snapshot.png';
    if (type.contains("optifine") || version.contains("optifine")) return 'assets/optifine.png';
    if (type.contains("optiforge") || version.contains("optiforge")) return 'assets/optiforge.png';
    if (type.contains("forge") || version.contains("forge")) return 'assets/forge.png';
    if (type.contains("fabric") || version.contains("fabric")) return 'assets/fabric.png';

    return 'assets/release.png';
  }

  ({String gameVersion, List<String> additionalArgs}) versionResolver(
    String gameType,
    String gameVersion,
    BuildContext context,
  ) {

    if (gameType.contains(AppLocalizations.of(context)?.vanilla_release_title as Pattern) || gameVersion.contains("latest")) {
      return (gameVersion: "latest", additionalArgs: const []);
    }

    if (gameType.contains(AppLocalizations.of(context)?.vanilla_snapshot_title as Pattern) || gameVersion.contains("snapshot")) {
      return (gameVersion: "snapshot", additionalArgs: const []);
    }

    if (gameType.toLowerCase().contains("neoforge") || gameVersion.toLowerCase().contains("neoforge")) {
      return (gameVersion: gameVersion, additionalArgs: const []);
    }

    if (gameType.toLowerCase().contains("fabric") || gameVersion.toLowerCase().contains("fabric")) {
      if (!gameVersion.toLowerCase().startsWith("fabric")) {
        var fabricVersion = Globals.fabricLoaderVersionsResponse[0]["version"];
        gameVersion = "fabric-loader-$fabricVersion-$gameVersion";
      }

      return (gameVersion: gameVersion, additionalArgs: const []);
    }

    if (gameType.toLowerCase().contains("optifine") || gameVersion.toLowerCase().contains("optifine")) {
      if (gameType.toLowerCase().contains("optifine")) {
        final baseVersion = gameVersion.toLowerCase();
        for (var version in Globals.optifineVersions) {
          if (version.split("-")[0] == baseVersion) {
            gameVersion = version;
            break;
          }
        }
      }

      return (gameVersion: gameVersion, additionalArgs: const []);
    }

    if (gameType.toLowerCase().contains("optiforge") || gameVersion.toLowerCase().contains("optiforge")) {
      if (gameType.toLowerCase().contains("optiforge")) {
        final baseVersion = gameVersion.toLowerCase();
        for (var version in Globals.forgeVersions) {
          if (version.split("-")[0] == baseVersion) {
            gameVersion = version.toString().replaceAll("forge", "optiforge");
            break;
          }
        }
      }

      return (
        gameVersion: gameVersion,
        additionalArgs: ["-Dfml.ignoreInvalidMinecraftCertificates=true"],
      );
    }

    if (gameType.toLowerCase().contains("forge") || gameVersion.toLowerCase().contains("forge")) {
      if (gameType.toLowerCase().contains("forge")) {
        final baseVersion = gameVersion.toLowerCase();
        for (var version in Globals.forgeVersions) {
          if (version.split("-")[0] == baseVersion) {
            gameVersion = version;
            break;
          }
        }
      }

      return (
        gameVersion: gameVersion,
        additionalArgs: ["-Dfml.ignoreInvalidMinecraftCertificates=true"],
      );
    }

    return (gameVersion: gameVersion, additionalArgs: const []);
  }

  final Set<String> _selectedFilters = {};

  bool _isVisible(String label) {
    if (_selectedFilters.isEmpty) return true;

    return _selectedFilters.contains(label);
  }

  Widget _buildDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextDivider(
        color: ColorUtils.secondaryFontColor.withAlpha(80),
        thickness: 2,
        text: Text(
          label,
          textAlign: TextAlign.center,
          style: WidgetUtils.customTextStyle(
            20,
            FontWeight.w300,
            ColorUtils.primaryFontColor,
          ),
        ),
      ),
    );
  }

  Widget _buildModloaderSection({
    required String label,
    required List<Widget> children,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: ColorUtils.dynamicAcrylicColor,
        borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
        border: Border.all(
          color: ColorUtils.secondaryFontColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(
                  label,
                  style: WidgetUtils.customTextStyle(
                    16,
                    FontWeight.w500,
                    ColorUtils.primaryFontColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                  decoration: BoxDecoration(
                    color: ColorUtils.dynamicAcrylicColor,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Text(
                    "$count",
                    style: WidgetUtils.customTextStyle(
                      12,
                      FontWeight.w600,
                      ColorUtils.primaryFontColor.withAlpha(200),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: _buildResponsiveTileGrid(children),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required IconData icon,
    bool isActive = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ColorUtils.dynamicAcrylicColor,
          borderRadius: BorderRadius.circular(Globals.borderRadius - 2),
          border: Border.all(
            color: isActive ? ColorUtils.primaryFontColor.withAlpha(200) : ColorUtils.secondaryFontColor.withAlpha(80),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? ColorUtils.primaryFontColor.withAlpha(200) : ColorUtils.secondaryFontColor.withAlpha(80),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: WidgetUtils.customTextStyle(
                12,
                isActive ? FontWeight.w600 : FontWeight.w300,
                isActive ? ColorUtils.primaryFontColor.withAlpha(200) : ColorUtils.secondaryFontColor.withAlpha(80),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["OptiFine", "OptiForge", "Forge", "Fabric"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((label) {
            final isActive = _selectedFilters.contains(label);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildQuickChip(
                label: label,
                icon: isActive ? Icons.visibility : Icons.visibility_off,
                isActive: isActive || _selectedFilters.isEmpty,
                onTap: () {
                  setState(() {
                    if (isActive) {
                      _selectedFilters.remove(label);
                    } else {
                      _selectedFilters.add(label);
                    }
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildModdedList() {
    final fabricFiltered = Globals.fabricGameVersionsResponse != null
        ? Globals.fabricGameVersionsResponse.where((v) {
            if (Globals.showOnlyReleases != true) return true;

            return v["stable"] == true || (v["type"] is String && v["type"].toString().toLowerCase() == "release");
          }).toList()
        : [];

    final installedModpacks = ModrinthUtils.readIndex();

    return ListView(
      children: [

        if (Globals.isVersionsAvailable) ...[
          _buildDivider(AppLocalizations.of(context)!.modded_modrinth_section_title),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
            child: SizedBox(
              height: 55,
              width: double.infinity,
              child: Material(
                elevation: 15,
                color: ColorUtils.dynamicPrimaryForegroundColor,
                shadowColor: ColorUtils.defaultShadowColor,
                borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ModrinthView()),
                    );
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              filterQuality: FilterQuality.none,
                              image: AssetImage("assets/modrinth.png"),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.modded_modrinth_button,
                        style: WidgetUtils.customTextStyle(16, FontWeight.w500, ColorUtils.primaryFontColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        if (installedModpacks.isNotEmpty) ...[
          _buildDivider(AppLocalizations.of(context)!.modded_modrinth_title),
          _buildResponsiveTileGrid([
            for (final pack in installedModpacks) _buildModrinthPackItem(pack),
          ]),
        ],

        if (VersionUtils.getMinecraftVersions(true).isNotEmpty) _buildDivider(AppLocalizations.of(context)!.modded_installed_title),
        if (VersionUtils.getMinecraftVersions(true).isEmpty && !Globals.isVersionsAvailable && installedModpacks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              AppLocalizations.of(context)!.modded_empty_title,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(22, FontWeight.w300, ColorUtils.primaryFontColor),
            ),
          ),
        _buildResponsiveTileGrid([
          for (var version in VersionUtils.getMinecraftVersions(true))
            buildVanillaItem(
              version["type"],
              version["id"],
              "",
              VersionUtils.isCompatible(version["type"], version["id"], context),
            ),
        ]),

        _buildDivider(AppLocalizations.of(context)!.modded_available_versions_title),
        _buildFilterChips(),
        const SizedBox(height: 4),
        if (_isVisible("OptiFine") && Globals.optifineVersions != null)
          _buildModloaderSection(
            label: "OptiFine",
            count: Globals.optifineVersions.length,
            children: [
              for (var version in Globals.optifineVersions)
                buildVanillaItem(
                  "Optifine",
                  version.split("-")[0],
                  "",
                  VersionUtils.isCompatible("Optifine", version.split("-")[0], context),
                ),
            ],
          ),
        if (_isVisible("OptiForge") && Globals.optiforgeVersions != null)
          _buildModloaderSection(
            label: "OptiForge",
            count: Globals.optiforgeVersions.length,
            children: [
              for (var version in Globals.optiforgeVersions)
                buildVanillaItem(
                  "OptiForge",
                  version.split("-")[0],
                  "",
                  VersionUtils.isCompatible("OptiForge", version.split("-")[0], context),
                ),
            ],
          ),
        if (_isVisible("Forge") && Globals.forgeVersions != null)
          _buildModloaderSection(
            label: "Forge",
            count: Globals.forgeVersions.length,
            children: [
              for (var version in Globals.forgeVersions)
                buildVanillaItem(
                  "Forge",
                  version.split("-")[0],
                  "",
                  VersionUtils.isCompatible("Forge", version.split("-")[0], context),
                ),
            ],
          ),
        if (_isVisible("Fabric") && Globals.fabricGameVersionsResponse != null)
          _buildModloaderSection(
            label: "Fabric",
            count: fabricFiltered.length,
            children: [
              for (var version in fabricFiltered) buildVanillaItem("Fabric", version["version"], "", true),
            ],
          ),
      ],
    );
  }

  Widget _buildModrinthPackItem(Map<String, dynamic> pack) {
    final slug = pack['slug']?.toString() ?? '';
    final title = pack['title']?.toString() ?? slug;
    final iconUrl = pack['iconUrl']?.toString() ?? '';
    final mcVersion = pack['minecraft']?.toString() ?? '';
    final loader = pack['loader']?.toString() ?? '';
    final versionName = pack['versionName']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: Material(
          elevation: 15,
          color: ColorUtils.dynamicPrimaryForegroundColor,
          shadowColor: ColorUtils.defaultShadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  child: iconUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: iconUrl,
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _modrinthIconPlaceholder(),
                          errorWidget: (_, __, ___) => _modrinthIconPlaceholder(),
                        )
                      : _modrinthIconPlaceholder(),
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WidgetUtils.customTextStyle(16, FontWeight.w500, ColorUtils.primaryFontColor),
                    ),
                    Text(
                      '$loader $mcVersion, ver. $versionName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WidgetUtils.customTextStyle(12, FontWeight.w300, ColorUtils.secondaryFontColor),
                    ),
                  ],
                ),
              ),

              WidgetUtils.buildButton(
                Icons.delete_outline,
                Colors.redAccent,
                Colors.white,
                () {
                  WidgetUtils.showPopup(
                    context,
                    title,
                    <Widget>[
                      const Text(
                        'Remove this modpack and all its files?',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                    <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.of(context)!.generic_cancel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ModrinthUtils.removeInstance(slug);
                          setState(() {});
                        },
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              WidgetUtils.buildButton(
                Icons.rocket_launch,
                ColorUtils.dynamicAccentColor,
                Colors.white,
                () async {
                  final deps = ModrinthUtils.getDependencies(slug);
                  final mcVer = deps['minecraft'] ?? mcVersion;
                  final loaderName = loader;
                  final modLoader = LaunchPolicy.loaderFromModrinthId(loaderName);

                  String gameVersion;

                  switch (loaderName) {
                    case 'fabric':
                      final loaderVer =
                          deps['fabric-loader'] ?? (Globals.fabricLoaderVersionsResponse?.isNotEmpty == true ? Globals.fabricLoaderVersionsResponse[0]['version'].toString() : '');
                      gameVersion = loaderVer.isNotEmpty ? 'fabric-loader-$loaderVer-$mcVer' : mcVer;
                      break;
                    case 'forge':
                      final forgeVer = deps['forge'] ?? '';
                      gameVersion = forgeVer.isNotEmpty ? '$mcVer-forge-$forgeVer' : mcVer;
                      break;
                    case 'quilt':
                      final quiltVer = deps['quilt-loader'] ?? '';
                      gameVersion = quiltVer.isNotEmpty ? 'quilt-loader-$quiltVer-$mcVer' : mcVer;
                      break;
                    case 'neoforge':
                      final neoVer = deps['neoforge'] ?? '';
                      gameVersion = neoVer.isNotEmpty ? 'neoforge-$neoVer' : mcVer;
                      break;
                    default:
                      gameVersion = mcVer;
                  }

                  final config = LaunchConfig(
                    gameVersion: gameVersion,
                    productId: null,
                    isModded: modLoader != ModLoader.vanilla,
                    realGameVersion: mcVer,
                    loader: modLoader,

                    forceClassPath: true,
                    startOnFirstThread: LaunchUtils.shouldUseStartOnFirstThread(mcVer),
                    jvmArgs: [],
                    launcherArgs: [],
                  );

                  await LaunchUtils.launchMinecraft(
                    context,
                    config,
                    onAccountRequired: () {
                      setState(() => Globals.navSelected = NavSection.accounts);
                    },
                    gameDirectory: ModrinthUtils.gameDir(slug),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modrinthIconPlaceholder() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: ColorUtils.dynamicSecondaryForegroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Icon(Icons.extension_outlined, size: 16, color: ColorUtils.secondaryFontColor),
    );
  }

  ListView buildSettingsList() {
    return ListView(
      children: [

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: TextDivider(
            color: ColorUtils.secondaryFontColor.withAlpha(80),
            thickness: 2,
            text: Text(
              AppLocalizations.of(context)!.settings_appearance_label,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                20,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ),

        WidgetUtils.buildSettingSwitchItem(
          AppLocalizations.of(context)!.settings_dark_mode_switch,
          "darkModeTheme",
          CustomSettingSwitchStyle(
            icon: Icons.invert_colors_rounded,
            bgColor: ColorUtils.dynamicPrimaryForegroundColor,
            shadowColor: ColorUtils.defaultShadowColor,
            fontColor: ColorUtils.primaryFontColor,
            toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
            activeColor: ColorUtils.dynamicAccentColor,
            inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
          ),
          Globals.darkModeTheme,
          (value) {
            setState(() => Globals.darkModeTheme = value);
            ColorUtils.reloadColors();

            Window.setEffect(
              effect: getWindowEffect(),
              color: ColorUtils.dynamicBackgroundColor,
              dark: Globals.darkModeTheme,
            );
            if (Platform.isMacOS) {
              Window.overrideMacOSBrightness(
                dark: Globals.darkModeTheme,
              );
            }
          },
        ),

        WidgetUtils.buildSettingContainerItem(
          Stack(
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 55,
                    width: 45,
                    child: Center(
                      child: Material(
                        elevation: 10,
                        color: Colors.transparent,
                        shadowColor: ColorUtils.defaultShadowColor,
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        child: Icon(
                          Icons.color_lens,
                          color: ColorUtils.primaryFontColor,
                          size: 26,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.settings_follow_system_color,
                          style: WidgetUtils.customTextStyle(
                            16,
                            FontWeight.w500,
                            ColorUtils.primaryFontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 18, 10, 0),
                    child: Material(
                      elevation: 15,
                      color: Colors.transparent,
                      shadowColor: Colors.transparent,

                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: Row(
                        children: [
                          MouseRegion(
                            onEnter: (e) => {},
                            child: GestureDetector(
                              onTap: () async => {
                                Globals.accentColor = 0,
                                (await SharedPreferences.getInstance()).setInt('accentColor', Globals.accentColor),
                                setState(() => ColorUtils.dynamicAccentColor = ColorUtils.getColorFromAccent(
                                      Globals.accentColor,
                                    )),
                                ColorUtils.reloadColors(),
                                Window.setEffect(
                                  effect: getWindowEffect(),
                                  color: ColorUtils.dynamicBackgroundColor,
                                  dark: Globals.darkModeTheme,
                                ),
                                if (Platform.isMacOS) ...[
                                  Window.overrideMacOSBrightness(
                                    dark: Globals.darkModeTheme,
                                  ),
                                ],
                              },
                              child: Stack(
                                children: [
                                  ColoredCircle(
                                    size: 20,
                                    color: SystemTheme.accentColor.light.withAlpha(200),
                                    outlineColor: Globals.accentColor == 0 ? SystemTheme.accentColor.light : Colors.transparent,
                                    outlineWidth: 2,
                                    distance: 3,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(2, 4, 0, 0),
                                    child: Text(
                                      "OS",
                                      style: WidgetUtils.customTextStyle(
                                        10,
                                        FontWeight.w100,
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          for (int i = 1; i <= 7; i++) ...[
                            const SizedBox(
                              width: 2,
                            ),
                            MouseRegion(
                              onEnter: (e) => {},
                              child: GestureDetector(
                                onTap: () async => {
                                  Globals.accentColor = i,
                                  (await SharedPreferences.getInstance()).setInt(
                                    'accentColor',
                                    Globals.accentColor,
                                  ),
                                  setState(() => ColorUtils.dynamicAccentColor = ColorUtils.getColorFromAccent(
                                        Globals.accentColor,
                                      )),
                                  ColorUtils.reloadColors(),
                                  Window.setEffect(
                                    effect: getWindowEffect(),
                                    color: ColorUtils.dynamicBackgroundColor,
                                    dark: Globals.darkModeTheme,
                                  ),
                                  if (Platform.isMacOS) ...[
                                    Window.overrideMacOSBrightness(
                                      dark: Globals.darkModeTheme,
                                    ),
                                  ],
                                },
                                child: ColoredCircle(
                                  size: 20,
                                  color: ColorUtils.getColorFromAccent(i),
                                  outlineColor: Globals.accentColor == i
                                      ? ColorUtils.getColorFromAccent(
                                          Globals.accentColor,
                                        )
                                      : Colors.transparent,
                                  outlineWidth: 2,
                                  distance: 3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        WidgetUtils.buildSettingContainerItem(
          Stack(
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 55,
                    width: 45,
                    child: Center(
                      child: Material(
                        elevation: 10,
                        color: Colors.transparent,
                        shadowColor: ColorUtils.defaultShadowColor,
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        child: Icon(
                          Icons.brush,
                          color: ColorUtils.primaryFontColor,
                          size: 26,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.settings_theme,
                          style: WidgetUtils.customTextStyle(
                            16,
                            FontWeight.w500,
                            ColorUtils.primaryFontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                    child: Material(
                      elevation: 15,
                      color: Colors.transparent,
                      shadowColor: ColorUtils.defaultShadowColor,
                      borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
                      child: MouseRegion(
                        onEnter: (e) => {},
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            isExpanded: true,
                            hint: Text(
                              'Theme',
                              style: WidgetUtils.customTextStyle(
                                16,
                                FontWeight.w500,
                                ColorUtils.primaryFontColor,
                              ),
                            ),
                            items: Globals.WindowThemes.map(
                              (String item) => DropdownItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: WidgetUtils.customTextStyle(
                                    16,
                                    FontWeight.w500,
                                    ColorUtils.primaryFontColor,
                                  ),
                                ),
                              ),
                            ).toList(),
                            valueListenable: _themeNotifier,
                            onChanged: (String? value) async {
                              _themeNotifier.value = value;
                              Globals.selectedWindowTheme = value!;
                              ColorUtils.isMaterial = (Globals.selectedWindowTheme.contains('Material'));

                              if (ColorUtils.isMaterial) Globals.fullTransparent = false;

                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setString(
                                "themeSet",
                                Globals.selectedWindowTheme,
                              );
                              ColorUtils.reloadColors();

                              dynamic effect = getWindowEffect();
                              Window.setEffect(
                                effect: effect,
                                color: ColorUtils.dynamicBackgroundColor,
                                dark: Globals.darkModeTheme,
                              );
                              if (Platform.isMacOS) {
                                Window.overrideMacOSBrightness(
                                  dark: Globals.darkModeTheme,
                                );
                              }
                              setState(() => effect = effect);
                            },
                            buttonStyleData: ButtonStyleData(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              height: 40,
                              width: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  Globals.borderRadius - 4,
                                ),
                                color: ColorUtils.dynamicSecondaryForegroundColor,
                              ),
                            ),
                            menuItemStyleData: const MenuItemStyleData(),
                            dropdownStyleData: DropdownStyleData(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  Globals.borderRadius - 4,
                                ),
                                color: ColorUtils.dynamicPrimaryForegroundColor,
                              ),
                              offset: const Offset(0, -4),
                              elevation: ColorUtils.isMaterial ? 9 : 0,
                            ),
                            iconStyleData: IconStyleData(
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                              ),
                              iconSize: 14,
                              iconEnabledColor: ColorUtils.primaryFontColor,
                              iconDisabledColor: Colors.white30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (Platform.isLinux && Globals.selectedWindowTheme == 'Clear') ...[
          WidgetUtils.buildSettingSwitchItem(
            "Disable background tinting",
            "fullTransparent",
            CustomSettingSwitchStyle(
              icon: Icons.format_paint_rounded,
              bgColor: ColorUtils.dynamicPrimaryForegroundColor,
              shadowColor: ColorUtils.defaultShadowColor,
              fontColor: ColorUtils.primaryFontColor,
              toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
              activeColor: ColorUtils.dynamicAccentColor,
              inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
            ),
            Globals.fullTransparent,
            (value) {
              setState(() => Globals.fullTransparent = value);
            },
          ),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: TextDivider(
            color: ColorUtils.secondaryFontColor.withAlpha(80),
            thickness: 2,
            text: Text(
              AppLocalizations.of(context)!.settings_misc_label,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                20,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ),

        WidgetUtils.buildSettingSwitchItem(
          AppLocalizations.of(context)!.settings_only_release_switch,
          "showOnlyReleases",
          CustomSettingSwitchStyle(
            icon: Icons.widgets_rounded,
            bgColor: ColorUtils.dynamicPrimaryForegroundColor,
            shadowColor: ColorUtils.defaultShadowColor,
            fontColor: ColorUtils.primaryFontColor,
            toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
            activeColor: ColorUtils.dynamicAccentColor,
            inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
          ),
          Globals.showOnlyReleases,
          (value) => setState(() => Globals.showOnlyReleases = value),
        ),

        WidgetUtils.buildSettingSwitchItem(
          AppLocalizations.of(context)!.settings_console_switch,
          "showConsole",
          CustomSettingSwitchStyle(
            icon: Icons.terminal_rounded,
            bgColor: ColorUtils.dynamicPrimaryForegroundColor,
            shadowColor: ColorUtils.defaultShadowColor,
            fontColor: ColorUtils.primaryFontColor,
            toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
            activeColor: ColorUtils.dynamicAccentColor,
            inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
          ),
          Globals.showConsole,
          (value) => setState(() => Globals.showConsole = value),
        ),

        WidgetUtils.buildSettingContainerItem(
          Column(
            children: [
              WidgetUtils.buildSettingSwitchItem(
                AppLocalizations.of(context)!.settings_java_advanced_settings,
                "javaAdvSet",
                CustomSettingSwitchStyle(
                  icon: FluxIcons.java,
                  bgColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  fontColor: ColorUtils.primaryFontColor,
                  toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
                  activeColor: ColorUtils.dynamicAccentColor,
                  inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
                ),
                Globals.javaAdvSet,
                (value) => setState(() => Globals.javaAdvSet = value),
              ),
              if (Globals.javaAdvSet) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                  child: Column(
                    children: [

                      WidgetUtils.buildSettingTextItem(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WidgetUtils.buildButton(
                                Icons.folder,
                                ColorUtils.dynamicAccentColor,
                                Colors.white,
                                () async {
                                  FilePickerResult? result = await FilePicker.pickFiles();
                                  if (result != null) {
                                    File file = File(result.files.single.path!);
                                    Globals.javapathcontroller.text = file.path.replaceAll("\\", "/");
                                    SharedPreferences prefs = await SharedPreferences.getInstance();
                                    await prefs.setString(
                                      "javaPath",
                                      Globals.javapathcontroller.text,
                                    );
                                  }
                                },
                              ),
                              WidgetUtils.buildButton(
                                Icons.checklist,
                                ColorUtils.dynamicAccentColor,
                                Colors.white,
                                () async {
                                  final result = await LauncherUtils.checkJava();

                                  final title = AppLocalizations.of(context)!.settings_check_java_title;

                                  String message;
                                  if (result != null) {
                                    final type = result['type'];
                                    final version = result['version'];
                                    final date = result['releaseDate'];
                                    final lts = result['lts'] == 'true' ? 'LTS' : '';

                                    message =
                                        '${AppLocalizations.of(context)!.settings_check_java_yes}\n\n→ JVM: $type\n→ Versione: $version${date != null && date.isNotEmpty ? '\n→ Data rilascio: $date' : ''}${lts.isNotEmpty ? '\n→ Tipo: $lts' : ''}';
                                  } else {

                                    message = AppLocalizations.of(context)!.settings_check_java_no;
                                  }

                                  WidgetUtils.showMessageDialog(
                                    context,
                                    title,
                                    message,
                                    () => Navigator.pop(context),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        ColorUtils.dynamicSecondaryForegroundColor,
                        ColorUtils.primaryFontColor,
                        AppLocalizations.of(context)!.settings_java_path_msg,
                        Globals.javapathcontroller,
                        (value) async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            "javaPath",
                            Globals.javapathcontroller.text,
                          );
                        },
                      ),

                      WidgetUtils.buildSettingTextItem(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WidgetUtils.buildButton(
                                Icons.memory,
                                ColorUtils.dynamicAccentColor,
                                Colors.white,
                                () => {},
                              ),
                            ],
                          ),
                        ),
                        ColorUtils.dynamicSecondaryForegroundColor,
                        ColorUtils.primaryFontColor,
                        AppLocalizations.of(context)!.settings_java_ram_msg,
                        Globals.javaramcontroller,
                        (value) async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            "javaRAM",
                            Globals.javaramcontroller.text,
                          );
                        },
                      ),

                      WidgetUtils.buildSettingTextItem(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WidgetUtils.buildButton(
                                FluxIcons.java,
                                ColorUtils.dynamicAccentColor,
                                Colors.white,
                                () => {},
                              ),
                            ],
                          ),
                        ),
                        ColorUtils.dynamicSecondaryForegroundColor,
                        ColorUtils.primaryFontColor,
                        "VM Args",
                        Globals.javavmcontroller,
                        (value) async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            "javaVMArgs",
                            Globals.javavmcontroller.text,
                          );
                        },
                      ),

                      WidgetUtils.buildSettingTextItem(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WidgetUtils.buildButton(
                                Icons.terminal,
                                ColorUtils.dynamicAccentColor,
                                Colors.white,
                                () => {},
                              ),
                            ],
                          ),
                        ),
                        ColorUtils.dynamicSecondaryForegroundColor,
                        ColorUtils.primaryFontColor,
                        "Launcher args",
                        Globals.javalaunchercontroller,
                        (value) async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            "javaLauncherArgs",
                            Globals.javalaunchercontroller.text,
                          );
                        },
                      ),

                      WidgetUtils.buildSettingSwitchItem(
                        AppLocalizations.of(context)!.settings_force_classpath,
                        "forceClasspath",
                        CustomSettingSwitchStyle(
                          icon: Icons.fork_left_rounded,
                          bgColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          fontColor: ColorUtils.primaryFontColor,
                          toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
                          activeColor: ColorUtils.dynamicAccentColor,
                          inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
                        ),
                        Globals.forceClasspath,
                        (value) => setState(() => Globals.forceClasspath = value),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        WidgetUtils.buildSettingContainerItem(
          Column(
            children: [
              WidgetUtils.buildSettingSwitchItem(
                AppLocalizations.of(context)!.settings_custom_folder_title,
                "customFolderSet",
                CustomSettingSwitchStyle(
                  icon: Icons.folder_rounded,
                  bgColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  fontColor: ColorUtils.primaryFontColor,
                  toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
                  activeColor: ColorUtils.dynamicAccentColor,
                  inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
                ),
                Globals.customFolderSet,
                (value) async => {
                  setState(() => Globals.customFolderSet = value),
                  if (!Globals.customFolderSet) ...[
                    Globals.gamefoldercontroller.text = LauncherUtils.getApplicationFolder("minecraft"),
                    await (await SharedPreferences.getInstance()).setString(
                      "gameFolderPath",
                      Globals.gamefoldercontroller.text,
                    ),
                  ],
                },
              ),
              if (Globals.customFolderSet) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                  child: WidgetUtils.buildSettingTextItem(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          WidgetUtils.buildButton(
                            Icons.folder,
                            ColorUtils.dynamicAccentColor,
                            Colors.white,
                            () async {
                              final String? selectedDirectory = await getDirectoryPath();
                              if (selectedDirectory != null) {
                                Globals.gamefoldercontroller.text = selectedDirectory.replaceAll("\\", "/");
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                await prefs.setString(
                                  "gameFolderPath",
                                  Globals.gamefoldercontroller.text,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    ColorUtils.dynamicSecondaryForegroundColor,
                    ColorUtils.primaryFontColor,
                    AppLocalizations.of(context)!.settings_custom_folder,
                    Globals.gamefoldercontroller,
                    (value) async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        "gameFolderPath",
                        Globals.gamefoldercontroller.text,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        WidgetUtils.buildSettingContainerItem(
          Row(
            children: [

              WidgetUtils.buildTextButton(
                ColorUtils.dynamicSecondaryForegroundColor,
                ColorUtils.primaryFontColor,
                () {
                  WidgetUtils.showDiagnostic(context);
                },
                AppLocalizations.of(context)!.settings_diagnostic_title,
              ),

              WidgetUtils.buildTextButton(
                ColorUtils.dynamicSecondaryForegroundColor,
                ColorUtils.primaryFontColor,
                () async {
                  final folder = Globals.gamefoldercontroller.text;
                  if (folder.isEmpty) return;

                  try {
                    if (Platform.isWindows) {
                      await Process.start('explorer', [folder.replaceAll('/', '\\')]);
                    } else if (Platform.isMacOS) {
                      await Process.start('open', [folder]);
                    } else if (Platform.isLinux) {
                      await Process.start('xdg-open', [folder]);
                    }
                  } catch (e) {
                    WidgetUtils.showMessageDialog(
                      context,
                      AppLocalizations.of(context)!.generic_error_msg,
                      e.toString(),
                      () => Navigator.pop(context),
                    );
                  }
                },
                AppLocalizations.of(context)!.settings_open_game_folder,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: TextDivider(
            color: ColorUtils.secondaryFontColor.withAlpha(80),
            thickness: 2,
            text: Text(
              AppLocalizations.of(context)!.settings_account_label,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                20,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ),

        WidgetUtils.buildSettingContainerItem(
          Row(children: [

            WidgetUtils.buildTextButton(
              Colors.red.withAlpha(160),
              Colors.white,
              () async {
                await DefaultCacheManager().emptyCache();
              },
              AppLocalizations.of(context)!.settings_clear_cache,
            ),

            WidgetUtils.buildTextButton(
              ColorUtils.dynamicSecondaryForegroundColor,
              Colors.white,
              () async {
                try {
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result == null || result.files.single.path == null) return;
                  final importedAccounts = importAccountListFromJsonPlain(result.files.single.path!);
                  if (mergeImportedAccounts(importedAccounts) > 0) {
                    saveAccounts();
                    if (mounted) setState(() {});
                  }
                } catch (e) {
                  debugPrint("Account import failed: $e");
                  if (!mounted) return;
                  WidgetUtils.showMessageDialog(
                    context,
                    AppLocalizations.of(context)!.generic_error_msg,
                    e.toString(),
                    () => Navigator.pop(context),
                  );
                }
              },
              AppLocalizations.of(context)!.settings_account_import,
            ),

            WidgetUtils.buildTextButton(
              ColorUtils.dynamicSecondaryForegroundColor,
              Colors.white,
              () async {
                try {
                  final result = await FilePicker.saveFile(
                    dialogTitle: 'Save accounts as JSON',
                    fileName: 'accounts_plain.json',
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result != null) {
                    exportAccountListToJsonPlain(Globals.accounts, result);
                  }
                } catch (e) {
                  debugPrint("Account export failed: $e");
                  if (!mounted) return;
                  WidgetUtils.showMessageDialog(
                    context,
                    AppLocalizations.of(context)!.generic_error_msg,
                    e.toString(),
                    () => Navigator.pop(context),
                  );
                }
              },
              AppLocalizations.of(context)!.settings_account_export,
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Divider(
              color: ColorUtils.secondaryFontColor,
            ),
          ),
        ),

        Center(
          child: GestureDetector(
            child: Text(
              "build: ${Globals.buildVersion} on ${extractPlatformInfo(Platform.version)} - Flux Launcher",
              style: WidgetUtils.customTextStyle(
                12,
                FontWeight.w500,
                ColorUtils.secondaryFontColor,
              ),
            ),
            onTap: () {
              WidgetUtils.showMessageDialog(
                context,
                AppLocalizations.of(context)!.settings_credits_title,
                AppLocalizations.of(context)!.settings_credits_content,
                () => Navigator.pop(context),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              linkIcon(FluxIcons.globe, Urls.fluxBaseURL),
              linkIcon(FluxIcons.discord, Urls.discordURL),
              linkIcon(FluxIcons.github_mark, Urls.githubURL),
            ],
          ),
        ),
      ],
    );
  }

  Widget linkIcon(IconData icon, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: HoverIcon(icon: icon, url: url),
    );
  }

  String extractPlatformInfo(String versionString) {
    RegExp regex = RegExp(r'([a-zA-Z0-9]+_[a-zA-Z0-9]+)');
    RegExpMatch? match = regex.firstMatch(versionString);

    return match != null ? match.group(0)! : 'N/A';
  }

  Widget _buildAccountsContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: buildAccountList(),
        ),
        const SizedBox(width: 10),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          if (Globals.getAccount() != null && ThreeDimensionalViewer.objs.isNotEmpty) ...[
            Sp3dRenderer(
              const Size(150, 280),
              const Sp3dV2D(75, 125),
              ThreeDimensionalViewer.world,
              Sp3dCamera(Sp3dV3D(0, 0, 3000), 1500),
              Sp3dLight(Sp3dV3D(0, 0, 0), syncCam: true),
              allowUserWorldZoom: false,
              allowUserWorldRotation: true,
              useClipping: true,
            ),
          ],
          const SizedBox(height: 5),

          WidgetUtils.buildButton(
            Icons.brush,
            ColorUtils.dynamicPrimaryForegroundColor,
            ColorUtils.primaryFontColor,
            () async {
              if (Globals.getAccount()!.isPremium) {
                WidgetUtils.showPopup(
                  context,
                  AppLocalizations.of(context)!.account_skin_uploader_type_title,
                  <Widget>[
                    Text(
                      AppLocalizations.of(context)!.account_skin_uploader_msg,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Comfortaa',
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                  <Widget>[
                    TextButton(
                      child: const Text(
                        "Slim",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        FilePickerResult? result = await FilePicker.pickFiles();
                        if (result != null) {
                          File file = File(result.files.single.path!);
                          WidgetUtils.showMessageDialog(
                            context,
                            AppLocalizations.of(context)!.account_skin_uploader_title,
                            await uploadSkin(context, "slim", Globals.getAccount()!, file.path.replaceAll("\\", "/")),
                            () => Navigator.pop(context),
                          );
                        }
                      },
                    ),
                    TextButton(
                      child: const Text(
                        "Classic",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        FilePickerResult? result = await FilePicker.pickFiles();
                        if (result != null) {
                          File file = File(result.files.single.path!);
                          WidgetUtils.showMessageDialog(
                            context,
                            AppLocalizations.of(context)!.account_skin_uploader_title,
                            await uploadSkin(context, "classic", Globals.getAccount()!, file.path.replaceAll("\\", "/")),
                            () => Navigator.pop(context),
                          );
                        }
                      },
                    ),
                    TextButton(
                      child: Text(
                        AppLocalizations.of(context)!.generic_cancel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      onPressed: () async => Navigator.pop(context),
                    ),
                  ],
                );
              } else {
                WidgetUtils.showPopup(
                  context,
                  AppLocalizations.of(context)!.generic_error_msg,
                  [
                    Text(
                      AppLocalizations.of(context)!.account_skin_error_msg,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Comfortaa',
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                  [
                    TextButton(
                      onPressed: () async {
                        await launchUrl(Uri.parse(
                          "https://www.minecraft.net/it-it/store/minecraft-java-bedrock-edition-pc",
                        ));
                        Navigator.pop(context);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.account_skin_buy_game,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [

              WidgetUtils.buildButton(
                Icons.add,
                ColorUtils.dynamicPrimaryForegroundColor,
                ColorUtils.primaryFontColor,
                () {

                  WidgetUtils.showPopup(
                    context,
                    AppLocalizations.of(context)!.account_add_button,
                    <Widget>[
                      Text(
                        AppLocalizations.of(context)!.account_add_type,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                    <Widget>[
                      TextButton(
                        child: const Text(
                          "Offline",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          AccountUtils.addSP(
                            context,
                            () => {
                              setState(() {
                                if (Globals.usernamecontroller.text.isNotEmpty) {
                                  Globals.accounts.add(
                                    Account(
                                      username: Globals.usernamecontroller.text,
                                      uuid: getOfflinePlayerUuid(
                                        Globals.usernamecontroller.text,
                                      ).toString(),
                                      accessToken: "0",
                                      refreshToken: "",
                                      isPremium: false,
                                      isSlimSkin: isOfflineSlimSkin(Globals.usernamecontroller.text),
                                    ),
                                  );
                                }
                                saveAccounts();
                                Globals.usernamecontroller.text = "";
                              }),
                              rebuild(),
                            },
                          );
                        },
                      ),
                      TextButton(
                        child: const Text(
                          "Premium",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          AccountUtils.addPremium(
                            context,
                            (
                              username,
                              uuid,
                              accesstoken,
                              refreshtoken,
                              isPremium,
                              isSlimSkin,
                            ) =>
                                {
                              setState(
                                () {
                                  Globals.accounts.add(
                                    Account(
                                      username: username,
                                      uuid: uuid,
                                      accessToken: accesstoken,
                                      refreshToken: refreshtoken,
                                      isPremium: isPremium,
                                      isSlimSkin: isSlimSkin,
                                    ),
                                  );
                                },
                              ),
                              rebuild(),
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              WidgetUtils.buildButton(
                Icons.remove,
                ColorUtils.dynamicPrimaryForegroundColor,
                ColorUtils.primaryFontColor,
                () {
                  setState(() {
                    if (Globals.accounts.isNotEmpty) {
                      Globals.accounts.removeAt(Globals.AccountSelected);
                      saveAccounts();
                    } else {
                      WidgetUtils.showMessageDialog(
                        context,
                        AppLocalizations.of(context)!.generic_error_msg,
                        AppLocalizations.of(context)!.account_remove_error,
                        () => Navigator.pop(context),
                      );
                    }
                    Globals.AccountSelected = 0;
                  });
                  rebuild();
                },
              ),
            ],
          ),
        ],
      ),
      const SizedBox(width: 10),
    ]);
  }

  ListView buildAccountList() {
    return ListView(
      children: [
        if (Globals.accounts.isNotEmpty) ...[

          _buildResponsiveTileGrid(
            [
              for (var account in Globals.accounts)
                buildAccountEntry(
                  account.username,
                  account.isPremium,
                  Globals.accounts.indexOf(account),
                ),
            ],
            minTileWidth: 280,
          ),
        ] else ...[

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Text(
              AppLocalizations.of(context)!.account_empty_msg,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                14,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget buildAccountEntry(String username, bool premium, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: Material(
          elevation: 15,
          color: ColorUtils.dynamicPrimaryForegroundColor,
          shadowColor: ColorUtils.defaultShadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      opacity: 0.8,
                      image: CachedNetworkImageProvider("${Urls.skinURL}/head/$username"),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WidgetUtils.customTextStyle(18, FontWeight.w500, ColorUtils.primaryFontColor),
                    ),
                    Text(
                      premium ? "Premium" : "Offline",
                      maxLines: 1,
                      style: WidgetUtils.customTextStyle(14, FontWeight.w300, ColorUtils.secondaryFontColor),
                    ),
                  ],
                ),
              ),
              WidgetUtils.buildButton(
                Icons.check,
                Globals.AccountSelected == index ? ColorUtils.dynamicAccentColor : ColorUtils.dynamicSecondaryForegroundColor,
                Globals.AccountSelected == index ? Colors.white : (Globals.darkModeTheme ? Colors.white.withAlpha(80) : Colors.black.withAlpha(80)),
                () {
                  setState(() => Globals.AccountSelected = index);
                  rebuild();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HoverIcon extends StatefulWidget {
  final IconData icon;
  final String url;

  const HoverIcon({super.key, required this.icon, required this.url});

  @override
  _HoverIconState createState() => _HoverIconState();
}

class _HoverIconState extends State<HoverIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () async {
          if (!await launchUrl(Uri.parse(widget.url))) {
            throw 'Unable to open the link: ${widget.url}';
          }
        },
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 100),
          tween: ColorTween(
            begin: _hovering ? ColorUtils.secondaryFontColor.withAlpha(128) : ColorUtils.secondaryFontColor.withAlpha(255),
            end: _hovering ? ColorUtils.secondaryFontColor.withAlpha(255) : ColorUtils.secondaryFontColor.withAlpha(128),
          ),
          builder: (context, color, child) => Icon(
            widget.icon,
            color: color,
          ),
        ),
      ),
    );
  }
}

class AccountUtils {

  static void addSP(
    dynamic context,
    Function callback,
  ) {
    Navigator.pop(context);
    WidgetUtils.showPopup(
      context,
      AppLocalizations.of(context)!.account_add_offline,
      <Widget>[
        Material(
          elevation: 10,
          color: Colors.transparent,
          shadowColor: ColorUtils.defaultShadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: WidgetUtils.buildSettingTextItem(
            null,
            Colors.white ,
            Colors.black ,
            "Username",
            Globals.usernamecontroller,
            (value) => null,
          ),
        ),
      ],
      <Widget>[
        TextButton(
          child: const Text(
            "OK",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Comfortaa',
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () {
            callback();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  static Future<void> refreshPremium(
    dynamic context,
  ) async {
    if (Globals.getAccount()?.isPremium == true) {
      Globals.consolecontroller.append("[LAUNCHER]: ${AppLocalizations.of(context)!.account_token_refresh}\n");

      try {
        var minecraftAuth = await doMicrosoftRefresh(context, Globals.getAccount()!.refreshToken);
        if (!minecraftAuth.toString().startsWith("[MC]:")) {
          var minecraftToken = minecraftAuth['access_token'];
          var minecraft = await fetchMinecraftProfile(context, minecraftToken);

          if (!minecraft.toString().startsWith("[MC]:")) {
            Globals.getAccount()?.accessToken = minecraftToken;
            saveAccounts();
          } else {
            WidgetUtils.showMessageDialog(
              context,
              AppLocalizations.of(context)!.generic_error_msg,
              "$minecraft",
              () => Navigator.pop(context),
            );
          }
        }
      } catch (e) {
        Globals.consolecontroller.append("[LAUNCHER]: ${AppLocalizations.of(context)!.account_token_fail}\n");
      }
    }
  }

  static Future<void> addPremium(
    dynamic context,
    Function(
      dynamic username,
      dynamic uuid,
      dynamic accesstoken,
      dynamic refreshtoken,
      bool isPremium,
      bool isSlimSkin,
    ) callback,
  ) async {
    String str = await doMicrosoftConsent(context);

    if (!str.startsWith("[MS]:")) {
      Map<String, dynamic> data = json.decode(str);
      final String userCode = data['user_code'];
      final String deviceCode = data['device_code'];
      final String verificationUri = data['verification_uri'];

      print(verificationUri);
      print(userCode);

      Navigator.pop(context);

      WidgetUtils.showPopup(
        context,
        AppLocalizations.of(context)!.account_add_premium,
        <Widget>[
          Text(
            "${AppLocalizations.of(context)!.account_add_link1}: $verificationUri\n\n${AppLocalizations.of(context)!.account_add_link2} $userCode",
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Comfortaa',
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
        <Widget>[
          TextButton(
            child: Text(
              AppLocalizations.of(context)!.account_add_copy,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Comfortaa',
                fontWeight: FontWeight.w300,
              ),
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: userCode));
              if (!await launchUrl(Uri.parse(verificationUri))) {
                throw Exception(
                  "${AppLocalizations.of(context)!.account_add_fail}: $verificationUri",
                );
              }
            },
          ),
          TextButton(
            child: const Text(
              "OK",
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Comfortaa',
                fontWeight: FontWeight.w300,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );

      Timer.periodic(const Duration(seconds: 3), (timer) async {
        var data = await getToken(
          context,
          'urn:ietf:params:oauth:grant-type:device_code',
          null,
          deviceCode,
        );
        if (data != null) {
          if (!data.toString().startsWith("[MS]:")) {
            var microsoftAccess = data['access_token'];
            var microsoftRefresh = data['refresh_token'];
            var minecraftAuth = await doXboxLiveAuth(context, microsoftAccess);
            if (!minecraftAuth.toString().startsWith("[MC]:")) {
              var minecraftToken = minecraftAuth['access_token'];
              var minecraft = await fetchMinecraftProfile(context, minecraftToken);

              if (!minecraft.toString().startsWith("[MC]:")) {

                bool slim = minecraft['skins'][0]["variant"].toString().toUpperCase().contains("SLIM");
                callback(
                  minecraft['name'],
                  minecraft['id'],
                  minecraftToken,
                  microsoftRefresh,
                  true,
                  slim,
                );
                saveAccounts();
                Navigator.pop(context);
              } else {
                WidgetUtils.showMessageDialog(
                  context,
                  AppLocalizations.of(context)!.generic_error_msg,
                  "$minecraft",
                  () => Navigator.pop(context),
                );
              }
            } else {
              WidgetUtils.showMessageDialog(
                context,
                AppLocalizations.of(context)!.generic_error_msg,
                "$minecraftAuth",
                () => Navigator.pop(context),
              );
            }
            timer.cancel();
          }
        }
      });
    } else {
      WidgetUtils.showMessageDialog(
        context,
        AppLocalizations.of(context)!.generic_error_msg,
        str,
        () => Navigator.pop(context),
      );
    }
  }
}

class SmoothScrollWrapper extends StatefulWidget {
  final Widget child;
  const SmoothScrollWrapper({super.key, required this.child});

  @override
  State<SmoothScrollWrapper> createState() => _SmoothScrollWrapperState();
}

class _SmoothScrollWrapperState extends State<SmoothScrollWrapper> {
  final ScrollController _scrollController = ScrollController();
  double _scrollTarget = 0.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _scrollController.hasClients) {
      GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent e) {
        final pos = _scrollController.position;
        if (!pos.hasContentDimensions) return;
        final delta = (e as PointerScrollEvent).scrollDelta.dy;
        if (_scrollTarget < pos.minScrollExtent || _scrollTarget > pos.maxScrollExtent) {
          _scrollTarget = _scrollController.offset;
        }
        _scrollTarget = (_scrollTarget + delta * 1.6).clamp(pos.minScrollExtent, pos.maxScrollExtent);
        _scrollController.animateTo(
          _scrollTarget,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: PrimaryScrollController(
        controller: _scrollController,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
