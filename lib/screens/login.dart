import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:viam_sdk/viam_sdk.dart';

import '../helpers.dart';
import 'list_orgs.dart';
import 'settings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  bool _isLoading = true;
  String loadingText = "";
  late String viamCLI;
  String loginText = "";
  String errorText = "";
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    setState(() {
      loadingText = "Preparing Viam tools...";
    });
    try {
      viamCLI = await getCLI();
    } catch (err) {
      setState(() {
        loadingText = "";
        errorText = err.toString();
      });
    }
    setState(() {
      loadingText = "Setting up VNC viewer...";
    });
    try {
      await setupVNC();
    } catch (err) {
      setState(() {
        loadingText = "";
        errorText = err.toString();
      });
    }

    setState(() {
      loadingText = "Checking if logged in...";
    });
    final process = await Process.run(viamCLI, ["login", "print-access-token"]);
    if (process.exitCode != 0) {
      setState(() {
        _isLoading = false;
      });
    } else {
      navigateToOrgs();
    }
  }

  Future<void> onPressed() async {
    setState(() {
      _isLoggingIn = true;
    });
    final process = await Process.start(viamCLI, ["login"]);
    process.stdout.transform(utf8.decoder).listen((event) {
      setState(() {
        loginText += event;
      });
    });
    process.stderr.transform(utf8.decoder).listen((event) {
      setState(() {
        errorText += event;
      });
    });
    if (await process.exitCode == 0) {
      navigateToOrgs();
    } else {
      _isLoading = false;
    }
  }

  void navigateToOrgs() {
    final process = Process.runSync(viamCLI, ["login", "print-access-token"]);
    final accessToken = process.stdout.toString();
    final viam = Viam.withAccessToken(accessToken);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ListOrgsScreen(viam)));
  }

  Future<void> showSettings(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(children: [SettingsScreen(isLoggedIn: false)]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showSettings(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              _isLoading
                  ? [CircularProgressIndicator.adaptive(), Text(loadingText)]
                  : [
                    Text(loginText.replaceAll("Info: ", "")),
                    Text(errorText, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    TextButton(onPressed: _isLoggingIn ? null : onPressed, child: Text("Login")),
                  ],
        ),
      ),
    );
  }
}
