import 'package:flutter/material.dart';
import 'package:viam_sdk/protos/app/app.dart';
import 'package:viam_sdk/viam_sdk.dart';

import 'list_locations.dart';

class ListOrgsScreen extends StatefulWidget {
  final Viam _viam;

  const ListOrgsScreen(this._viam, {super.key});

  @override
  State<StatefulWidget> createState() => _ListOrgsState();
}

class _ListOrgsState extends State<ListOrgsScreen> {
  bool _isLoading = true;
  List<Organization> organizations = [];

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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ListLocationsScreen(widget._viam, org)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Organizations")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : ListView.builder(
                itemCount: organizations.length,
                itemBuilder: (_, index) {
                  final org = organizations[index];
                  return ListTile(
                    title: Text(org.name),
                    onTap: () => _navigateToOrg(org),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
    );
  }
}
