import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:viam_sdk/viam_sdk.dart';

import '../helpers.dart';
import 'list_orgs.dart';

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
    viamCLI = await getCLI();
    setState(() {
      loadingText = "Setting up VNC viewer...";
    });
    await setupVNC();

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
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => ListOrgsScreen(viam)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              _isLoading
                  ? [CircularProgressIndicator.adaptive(), Text(loadingText)]
                  : [
                    Text(loginText.replaceAll("Info: ", "")),
                    TextButton(
                      onPressed: _isLoggingIn ? null : onPressed,
                      child: Text("Login"),
                    ),
                  ],
        ),
      ),
    );
  }
}
