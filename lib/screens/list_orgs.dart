import 'package:flutter/material.dart';
import 'package:viam_sdk/protos/app/app.dart';
import 'package:viam_sdk/viam_sdk.dart';

import 'list_locations.dart';
import 'settings.dart';

class ListOrgsScreen extends StatefulWidget {
  final Viam _viam;

  const ListOrgsScreen(this._viam, {super.key});

  @override
  State<StatefulWidget> createState() => _ListOrgsState();
}

class _ListOrgsState extends State<ListOrgsScreen> {
  bool _isLoading = true;
  List<Organization> organizations = [];
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    final orgs = await widget._viam.appClient.listOrganizations();
    orgs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      organizations = orgs;
      _isLoading = false;
    });
    if (orgs.length == 1) {
      return _navigateToOrg(orgs.first);
    }
  }

  void _navigateToOrg(Organization org) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListLocationsScreen(widget._viam, org)));
  }

  Future<void> showSettings(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(children: [SettingsScreen()]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organizations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showSettings(context);
              // setState(() {
              //   _showSettings = !_showSettings;
              // });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : ListView.builder(
                itemCount: organizations.length,
                itemBuilder: (_, index) {
                  final org = organizations[index];
                  return ListTile(title: Text(org.name), onTap: () => _navigateToOrg(org), trailing: const Icon(Icons.chevron_right));
                },
              ),
          if (_showSettings)
            Center(
              child: Container(
                width: 600,
                height: 400,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: SettingsScreen(),
              ),
            ),
        ],
      ),
    );
  }
}
