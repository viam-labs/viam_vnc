import 'package:flutter/material.dart';
import 'package:viam_sdk/protos/app/app.dart';
import 'package:viam_sdk/viam_sdk.dart';

import 'location.dart';

class ListLocationsScreen extends StatefulWidget {
  final Viam _viam;
  final Organization org;

  const ListLocationsScreen(this._viam, this.org, {super.key});

  @override
  State<StatefulWidget> createState() => _ListLocationsState();
}

class _ListLocationsState extends State<ListLocationsScreen> {
  bool _isLoading = true;

  List<Location> locations = [];
  List<Location> parentLocations = [];

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    final locations = await widget._viam.appClient.listLocations(widget.org.id);
    locations.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      this.locations = locations;
      parentLocations = locations.where((loc) => loc.parentLocationId.isEmpty).toList();
      _isLoading = false;
    });
    if (locations.length == 1) {
      return _navigateToLocation(locations.first);
    }
  }

  void _navigateToLocation(Location location) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationScreen(widget._viam, location, locations.where((loc) => loc.parentLocationId == location.id).toList()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Column(children: [const Text('Locations'), Text(widget.org.name, style: TextStyle(fontSize: 12))])),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : ListView.builder(
                itemCount: parentLocations.length,
                itemBuilder: (_, index) {
                  final location = parentLocations[index];
                  return ListTile(
                    title: Text(location.name),
                    onTap: () => _navigateToLocation(location),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
    );
  }
}
