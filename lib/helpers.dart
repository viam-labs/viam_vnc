import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getCLI({bool forceUpdate = false}) async {
  final (os, arch) = _archString();
  final dir = await getApplicationSupportDirectory();
  String path = join(dir.path, "viam-cli");
  if (os == "windows") {
    path += ".exe";
  }
  final file = File(path);
  final isOld =
      file.existsSync() &&
      file.statSync().modified.difference(DateTime.now()) < Duration(days: -14);
  if (!file.existsSync() || isOld || forceUpdate) {
    await _downloadCLI(file);
    await _makeExecutable(file);
  }
  return path;
}

Future<void> _downloadCLI(File downloadFile) async {
  final (os, arch) = _archString();
  String url =
      "https://storage.googleapis.com/packages.viam.com/apps/viam-cli/viam-cli-latest-$os-$arch";
  if (os == "windows") {
    url += ".exe";
  }
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  if (response.statusCode != 200) {
    throw Exception("Failed to download CLI: ${response.statusCode}");
  }
  var bytes = await consolidateHttpClientResponseBytes(response);
  await downloadFile.writeAsBytes(bytes);
}

(String, String) _archString() {
  final abi = Abi.current();
  switch (abi) {
    case Abi.windowsX64:
      return ("windows", "amd64");
    case Abi.linuxArm64:
      return ("linux", "arm64");
    case Abi.linuxX64:
      return ("linux", "amd64");
    case Abi.macosArm64:
      return ("darwin", "arm64");
    case Abi.macosX64:
      return ("darwin", "amd64");
    default:
      throw UnsupportedError("Unsupported ABI: $abi");
  }
}

Future<void> _makeExecutable(File file) async {
  if (file.path.contains(".exe")) {
    return;
  }
  final process = await Process.run("chmod", ["+x", file.path]);
  final exitCode = process.exitCode;
  if (exitCode != 0) {
    throw Exception("Failed to make file executable: $exitCode");
  }
}

Future<void> setupVNC() async {
  final file = File((await getVNCPath())!);
  if (await file.exists()) {
    return;
  }
  if (Platform.isWindows) {
    final asset = await rootBundle.load("assets/exe/vncviewer.exe");
    await file.writeAsBytes(Uint8List.sublistView(asset));
  }
  if (Platform.isMacOS) {
    try {
      final asset = await rootBundle.load("assets/macos/RustDesk.zip");
      final zipFile = File(join(file.parent.path, 'RustDesk.zip'));
      await zipFile.writeAsBytes(Uint8List.sublistView(asset));
      await Process.run('unzip', ['-o', zipFile.path, '-d', file.parent.path]);
    } catch (err) {
      print(err);
    }
  }
}

Future<String?> getVNCPath() async {
  if (Platform.isWindows) {
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, "vncviewer.exe");
  } else if (Platform.isMacOS) {
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, "RustDesk.app");
  }
  return null;
}

Future<void> setupHostsUpdater() async {
  if (Platform.isWindows) {
    final file = File((await getHostsUpdaterPath())!);
    if (await file.exists()) {
      return;
    }
    final asset = await rootBundle.load("assets/exe/hosts_updater.exe");
    await file.writeAsBytes(Uint8List.sublistView(asset));
  }
}

Future<String?> getHostsUpdaterPath() async {
  if (Platform.isWindows) {
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, "hosts_updater.exe");
  }
  return null;
}
