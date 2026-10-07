import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flux_launcher_gui/globals.dart';
import 'package:flux_launcher_gui/l10n/app_localizations.dart';
import 'package:flux_launcher_gui/utils/launcher/launch_policy.dart';
import 'package:flux_launcher_gui/utils/launcher/version_utils.dart';
import 'package:flux_launcher_gui/utils/widget_utils.dart';
import 'package:flux_launcher_gui/views/main_page.dart';

export 'package:flux_launcher_gui/utils/launcher/launch_policy.dart' show LaunchConfig, LaunchPolicy, ModLoader, LaunchProfile;

class LaunchUtils {

  static Future<void> launchMinecraft(
    BuildContext context,
    LaunchConfig config, {
    required VoidCallback onAccountRequired,
    String? gameDirectory,
  }) async {

    final account = Globals.getAccount();
    if (account == null) {
      WidgetUtils.showMessageDialog(
        context,
        AppLocalizations.of(context)!.account_required_title,
        AppLocalizations.of(context)!.account_required_msg,
        () {
          Navigator.pop(context);
          onAccountRequired();
        },
      );

      return;
    }

    WidgetUtils.showLoadingCircle(context);
    Globals.consolecontroller.clear();
    await AccountUtils.refreshPremium(context);

    try {

      if (!Globals.javaAdvSet) {
        await LauncherUtils.JavaAutoInstall(
          config.isModded ? config.realGameVersion : config.gameVersion,
        );
      }

      if (context.mounted) Navigator.pop(context);

      final args = buildLaunchArguments(config, gameDirectory: gameDirectory);

      final Process process;

      if (Platform.isLinux) {
        final javaPath = Globals.javapathcontroller.text;
        final lastSlashIndex = javaPath.lastIndexOf('/');

        if (lastSlashIndex > 0) {

          final javaDir = javaPath.substring(0, lastSlashIndex);
          final javaArgs = args.map(_escapeShellArg).join(' ');
          process = await Process.start('sh', ['-c', "cd '${javaDir.replaceAll("'", "'\\''")}' && exec ./java $javaArgs"]);
        } else {
          process = await Process.start(
            javaPath,
            args,
            workingDirectory: gameDirectory ?? Globals.gamefoldercontroller.text,
          );
        }
      } else {

        process = await Process.start(
          Globals.javapathcontroller.text,
          args,
          workingDirectory: gameDirectory ?? Globals.gamefoldercontroller.text,
        );
      }

      if (Globals.showConsole && context.mounted) {
        WidgetUtils.showConsole(context, process, gameDirectory: gameDirectory);
      } else {

        process.stdout.transform(systemEncoding.decoder).listen((data) {
          final cleaned = data.replaceAll(RegExp(r'[\r\n]+'), '');
          print('[STDOUT] $cleaned');
        });

        process.stderr.transform(systemEncoding.decoder).listen((data) {
          final cleaned = data.replaceAll(RegExp(r'[\r\n]+'), '');
          print('[STDERR] $cleaned');
        });
      }

      _handleProcessExit(context, process);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        WidgetUtils.showMessageDialog(
          context,
          AppLocalizations.of(context)!.generic_error_msg,
          "$e",
          () => Navigator.pop(context),
        );
      }
    }
  }

  static String _escapeShellArg(String arg) {

    if (arg.contains(' ') || arg.contains('\$') || arg.contains('!') || arg.contains('"') || arg.contains('\'') || arg.contains('\\')) {

      return "'${arg.replaceAll("'", "'\\''")}'";
    }

    return arg;
  }

  static Future<void> _handleProcessExit(BuildContext context, Process process) async {
    final exitCode = await process.exitCode;
    Globals.consolecontroller.append("[LAUNCHER]: exit code $exitCode\n");

    if (exitCode != 0 && exitCode != 143 && context.mounted) {
      _showCrashDialog(context);
    }
  }

  static List<String> buildLaunchArguments(LaunchConfig config, {String? gameDirectory}) {
    final account = Globals.getAccount()!;
    final args = <String>[];

    args.addAll(config.jvmArgs);

    if ((config.realGameVersion == "1.16.4" || config.realGameVersion == "1.16.5") && !account.isPremium) {
      args.addAll([
        "-Dminecraft.api.auth.host=https://0.0.0.0/",
        "-Dminecraft.api.account.host=https://0.0.0.0/",
        "-Dminecraft.api.session.host=https://0.0.0.0/",
        "-Dminecraft.api.services.host=https://0.0.0.0/",
      ]);
    }

    if (config.startOnFirstThread) args.add("-XstartOnFirstThread");

    if (Globals.javavmcontroller.text.isNotEmpty) {
      args.addAll(Globals.javavmcontroller.text.split(" "));
    }

    final workingDir = gameDirectory ?? Globals.gamefoldercontroller.text;
    args.addAll([
      "-Duser.dir=$workingDir",
      "-Djava.library.path=$workingDir/versions/${config.gameVersion}/natives/",
      ...LauncherUtils.buildJVMOptimizedArgs(Globals.javaramcontroller.text),
    ]);

    args.addAll([
      "-cp",
      "${LauncherUtils.getApplicationFolder("flux")}/Launcher.jar",
      Globals.javaLauncherMainClass,
    ]);

    args.addAll([
      "-version",
      config.productId ?? config.gameVersion,
      "-minecraftToken",
      account.accessToken,
      "-minecraftUsername",
      account.username,
      "-minecraftUUID",
      account.uuid,
    ]);

    if (config.enableClassPath) args.add("-c");
    if (config.startOnFirstThread) args.add("-startOnFirstThread");

    if (Globals.customFolderSet || gameDirectory != null) {
      args.addAll(["-gameFolder", gameDirectory ?? Globals.gamefoldercontroller.text]);
    }

    if (Globals.javalaunchercontroller.text.isNotEmpty) {
      args.addAll(Globals.javalaunchercontroller.text.split(" ").where((arg) => arg != "-c"));
    }

    args.addAll(config.launcherArgs);

    return args;
  }

  static void _showCrashDialog(BuildContext context) {
    WidgetUtils.showPopup(
      context,
      AppLocalizations.of(context)!.generic_error_msg,
      <Widget>[
        Text(
          AppLocalizations.of(context)!.console_crash_msg,
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
            "OK",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Comfortaa',
              fontWeight: FontWeight.w300,
            ),
          ),
          onPressed: () {},
        ),
        TextButton(
          child: Text(
            AppLocalizations.of(context)!.generic_cancel,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Comfortaa',
              fontWeight: FontWeight.w300,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  static bool shouldUseStartOnFirstThread(String resolvedGameVersion) {
    if (!Platform.isMacOS) return false;

    final verList = VersionUtils.getMinecraftVersions(false);
    final currentVersionIndex = verList.indexWhere(
      (version) => version["id"] == resolvedGameVersion,
    );
    final startingVersionIndex = verList.indexWhere(
      (version) => version["id"] == "17w43a",
    );

    return currentVersionIndex != -1 && startingVersionIndex != -1 && currentVersionIndex <= startingVersionIndex;
  }
}
