import 'package:flutter/material.dart';
import 'package:viam_sdk/protos/app/app.dart';
import 'package:viam_sdk/viam_sdk.dart';

import 'robot.dart';

class LocationScreen extends StatefulWidget {
  final Viam _viam;
  final Location location;
  final List<Location> locations;

  const LocationScreen(this._viam, this.location, this.locations, {super.key});

  @override
  State<StatefulWidget> createState() => _LocationState();
}

class _LocationState extends State<LocationScreen> {
  bool _isLoading = true;
  List<Robot> robots = [];

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    final robots = await widget._viam.appClient.listRobots(widget.location.id);
    robots.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      this.robots = robots;
      _isLoading = false;
    });
  }

  void _navigateToLocation(Location location) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => LocationScreen(
              widget._viam,
              location,
              widget.locations
                  .where((loc) => loc.parentLocationId == location.id)
                  .toList(),
            ),
      ),
    );
  }

  void _navigateToRobot(Robot robot) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RobotScreen(widget._viam, robot)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.location.name)),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : ListView.builder(
                itemCount: widget.locations.length + robots.length,
                itemBuilder: (_, index) {
                  if (index < widget.locations.length) {
                    final location = widget.locations[index];
                    return ListTile(
                      title: Text(location.name),
                      onTap: () => _navigateToLocation(location),
                      trailing: Icon(Icons.chevron_right),
                    );
                  } else {
                    final robotIndex = index - widget.locations.length;
                    final robot = robots[robotIndex];
                    return ListTile(
                      title: Text(robot.name),
                      onTap: () => _navigateToRobot(robot),
                    );
                  }
                },
              ),
    );
  }
}
