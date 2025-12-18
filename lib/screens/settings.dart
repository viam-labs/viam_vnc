import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:viam_vnc/helpers.dart';
import 'package:viam_vnc/screens/login.dart';

class SettingsScreen extends StatefulWidget {
  final bool isLoggedIn;

  const SettingsScreen({super.key, this.isLoggedIn = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = "";

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      setState(() {
        _version = info.version;
      });
    });
  }

  bool _cliUpdating = false;
  Future<void> updateCLI() async {
    setState(() {
      _cliUpdating = true;
    });
    await getCLI(forceUpdate: true);
    setState(() {
      _cliUpdating = false;
    });
  }

  bool _isLoggingOut = false;
  String _logoutError = "";
  Future<void> logout() async {
    setState(() {
      _isLoggingOut = true;
    });
    final cli = await getCLI();
    final process = await Process.run(cli, ["logout"]);
    if (process.exitCode == 0) {
      navigateToLogin();
    } else {
      setState(() {
        _isLoggingOut = false;
        _logoutError = process.stderr;
      });
    }
  }

  void navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        TextButton.icon(
          onPressed: _cliUpdating ? null : updateCLI,
          label: Text(_cliUpdating ? "Updating..." : "Update CLI"),
          icon: const Icon(Icons.update),
        ),
        if (widget.isLoggedIn)
          TextButton.icon(
            onPressed: _isLoggingOut ? null : logout,
            label: Text("Logout"),
            icon: const Icon(Icons.logout),
          ),
        if (_logoutError.isNotEmpty)
          Text(
            _logoutError,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const Divider(),
        Text("Version $_version"),
      ],
    );
  }
}
