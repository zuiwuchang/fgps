import 'package:fgps/db/data/gps.dart';
import 'package:fgps/db/data/place.dart';
import 'package:fgps/db/db.dart';
import 'package:fgps/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_z_location/flutter_z_location.dart';
import 'package:permission_handler/permission_handler.dart';

class MyGPS {
  MyGPS(this.gps);
  final GPS gps;
  dynamic error;
  bool disabled = false;

  int get id => gps.id;
  String get latitude => gps.latitude;
  String get longitude => gps.longitude;
  String get text => '$latitude, $longitude';
}

class MyGPSPage extends StatefulWidget {
  const MyGPSPage({super.key, required this.place});

  final Place place;
  @override
  State<MyGPSPage> createState() => _MyGPSPageState();
}

class _MyGPSPageState extends State<MyGPSPage> {
  List<MyGPS>? _items;
  dynamic _error;
  bool _isInit = true;
  bool _isAdd = false;
  bool _isDelete = false;
  get _disabled => _isAdd || _isDelete;

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    try {
      final helpers = await DB.helpers;
      final items = (await helpers.gps.list(widget.place.id))
          .map((e) => MyGPS(e))
          .toList();
      setState(() {
        _items = items;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _isInit = false;
      });
    }
  }

  _clear() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const MyConfirmDialog(
        title: Text("Clear"),
        child: Text("Clear all gps"),
      ),
    );
    if (result != true) {
      return;
    }

    setState(() {
      _isDelete = true;
    });
    try {
      final helpers = await DB.helpers;
      await helpers.gps.clear(widget.place.id);
      setState(() {
        _items!.clear();
        _isDelete = false;
      });
    } catch (e) {
      setState(() {
        _isDelete = false;
      });
      showErrorDialog(context, e);
    }
  }

  _delete(MyGPS gps) async {
    setState(() {
      _isDelete = true;
      gps.disabled = true;
      gps.error = null;
    });
    try {
      final helpers = await DB.helpers;
      await helpers.gps.delete(gps.id);
      setState(() {
        final items = _items;
        for (var i = 0; i < items!.length; i++) {
          if (items[i].id == gps.id) {
            items.removeAt(i);
            break;
          }
        }
        _isDelete = false;
        gps.disabled = false;
      });
    } catch (e) {
      setState(() {
        _isDelete = false;
        gps.disabled = false;
        gps.error = e;
      });
    }
  }

  _add() async {
    setState(() {
      _isAdd = true;
    });
    try {
      if (!await Permission.location.isGranted) {
        final status = await Permission.location.request();
        if (!status.isGranted) {
          throw Exception('Permission.location is not granted');
        }
      }
      final result = await FlutterZLocation.getCoordinate();
      if (!result.hasSuccess) {
        throw Exception("${result.code} ${result.message}");
      }
      // const result =
      //     GpsEntity(code: "0", message: "ok", latitude: 1, longitude: 2);

      final helpers = await DB.helpers;
      final latitude = '${result.latitude}';
      final longitude = '${result.longitude}';
      final id = await helpers.gps.add(widget.place.id, latitude, longitude);
      final item = MyGPS(
        GPS(
            id: id,
            place: widget.place.id,
            latitude: latitude,
            longitude: longitude),
      );
      setState(() {
        _isAdd = false;
        _items!.add(item);
      });
    } catch (e) {
      setState(() {
        _isAdd = false;
      });
      showErrorDialog(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_disabled,
      child: _buildItems(context) ??
          _buildInit(context) ??
          _buildError(context) ??
          Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.place.name),
            ),
          ),
    );
  }

  Widget? _buildItems(BuildContext context) {
    final items = _items;
    if (items == null) {
      return null;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.place.name),
        actions: items.length == 0
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'clear',
                  onPressed: _disabled ? null : _clear,
                ),
              ],
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: item.disabled
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(),
                  )
                : const Icon(Icons.group_work),
            title: Text(item.text),
            subtitle: item.error == null
                ? null
                : Wrap(
                    children: [
                      Text(
                        '${item.error}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ),
            trailing: IconButton(
                onPressed: _disabled || item.disabled
                    ? null
                    : () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => MyConfirmDialog(
                            title: const Text("Delete"),
                            child: Text("Delete gps: ${item.text}"),
                          ),
                        );
                        if (result == true) {
                          _delete(item);
                        }
                      },
                tooltip: 'Delete',
                icon: const Icon(Icons.delete)),
            onTap: _disabled
                ? null
                : () async {
                    try {
                      await Clipboard.setData(ClipboardData(text: item.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('copied: ${item.text}'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'error :$e',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      );
                    }
                  },
          );
        },
      ),
      floatingActionButton: _isAdd
          ? const CircularProgressIndicator()
          : FloatingActionButton(
              onPressed: _add,
              tooltip: "Add GPS",
              child: const Icon(Icons.add_location),
            ),
    );
  }

  Widget? _buildInit(BuildContext context) {
    if (!_isInit) {
      return null;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('${widget.place.name} loading...'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget? _buildError(BuildContext context) {
    if (_error == null) {
      return null;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.place.name),
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        child: ListView(
          children: [
            Wrap(
              children: [
                Text(
                  '$_error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Refresh',
        onPressed: () {
          setState(() {
            _isInit = true;
            _error = null;
          });
          _init();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
