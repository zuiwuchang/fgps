import 'package:fgps/db/data/place.dart';
import 'package:fgps/db/db.dart';
import 'package:fgps/dialog.dart';
import 'package:fgps/gps.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'GPS'),
    );
  }
}

class MyPlace {
  MyPlace(this.place);
  final Place place;
  dynamic error;
  bool disabled = false;

  int get id => place.id;
  String get name => place.name;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<MyPlace>? _items;
  dynamic _error;
  bool _isInit = true;
  bool _disabled = false;
  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    try {
      final helpers = await DB.helpers;
      final items =
          (await helpers.place.list()).map((e) => MyPlace(e)).toList();
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

  _delete(MyPlace place) async {
    setState(() {
      _disabled = true;
      place.disabled = true;
      place.error = null;
    });
    try {
      final helpers = await DB.helpers;
      await helpers.place.delete(place.id);
      setState(() {
        final items = _items;
        for (var i = 0; i < items!.length; i++) {
          if (items[i].id == place.id) {
            items.removeAt(i);
            break;
          }
        }
        _disabled = false;
        place.disabled = false;
      });
    } catch (e) {
      setState(() {
        _disabled = false;
        place.disabled = false;
        place.error = e;
      });
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
              title: Text(widget.title),
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
        title: Text(widget.title),
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
            title: Text(item.name),
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
                            child: Text("Delete place: ${item.name}"),
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
                : () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => MyGPSPage(place: item.place)));
                  },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<Place>(
            context: context,
            builder: (context) => const MyInputPlaceNameDialog(),
          );
          if (result != null) {
            setState(() {
              items.add(MyPlace(result));
            });
          }
        },
        tooltip: 'Add Place',
        child: const Icon(Icons.add_circle_outline),
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
        title: Text('${widget.title} loading...'),
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
        title: Text(widget.title),
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
