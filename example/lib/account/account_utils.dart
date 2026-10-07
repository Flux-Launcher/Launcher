library account_utils;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flux_launcher_gui/account/encryption.dart';
import 'package:flux_launcher_gui/account/uuid_utils.dart';
import 'package:flux_launcher_gui/globals.dart';

class Account {
  String username;
  String uuid;
  String accessToken;
  String refreshToken;
  bool isPremium;
  bool isSlimSkin;

  Account({
    required this.username,
    required this.uuid,
    required this.accessToken,
    required this.refreshToken,
    required this.isPremium,
    required this.isSlimSkin,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'uuid': uuid,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'isPremium': isPremium,
      'isSlimSkin': isSlimSkin,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      username: json['username'],
      uuid: json['uuid'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      isPremium: json['isPremium'] ?? false,
      isSlimSkin: json['isSlimSkin'] ?? false,
    );
  }
}

Uuid getOfflinePlayerUuid(String username) {
  Int8List bytes = Int8List.fromList(utf8.encode("OfflinePlayer:$username"));
  List<int> unsignedBytes = md5.convert(bytes).bytes;
  Int8List signedBytes = Int8List.fromList(
    unsignedBytes.map((b) => b > 127 ? b - 256 : b).toList(),
  );

  return Uuid.nameUUIDFromBytes(signedBytes);
}

bool isOfflineSlimSkin(String username) {
  return (getOfflinePlayerUuid(username).hashCode & 1) == 1;
}

void saveAccounts() {
  final filePath = "${LauncherUtils.getApplicationFolder("flux")}/accounts.json";
  saveAccountListToJson(Globals.accounts, filePath);
}

List<Account> importAccountListFromJsonPlain(String filePath) {
  final file = File(filePath);

  if (!file.existsSync()) {
    throw FormatException("File not found: $filePath");
  }

  final decoded = json.decode(file.readAsStringSync());
  if (decoded is! List || decoded.isEmpty) {
    throw const FormatException("The file does not contain an account list");
  }

  return decoded.map<Account>((entry) {
    if (entry is! Map<String, dynamic> ||
        entry['username'] is! String ||
        entry['uuid'] is! String ||
        entry['accessToken'] is! String ||
        entry['refreshToken'] is! String) {
      throw const FormatException("Invalid account entry in file");
    }
    return Account.fromJson(entry);
  }).toList();
}

int mergeImportedAccounts(List<Account> imported) {
  final known = Globals.accounts.map((a) => a.uuid).toSet();
  var added = 0;
  for (final account in imported) {
    if (known.add(account.uuid)) {
      Globals.accounts.add(account);
      added++;
    }
  }
  return added;
}

void exportAccountListToJsonPlain(List<Account> accountList, String filePath) {
  final List<Map<String, dynamic>> jsonList = accountList.map((account) => account.toJson()).toList();
  final jsonString = json.encode(jsonList);
  final file = File(filePath);

  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }

  file.writeAsStringSync(jsonString);
}
