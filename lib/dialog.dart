import 'package:fgps/db/data/place.dart';
import 'package:fgps/db/db.dart';
import 'package:flutter/material.dart';

class MyConfirmDialog extends StatelessWidget {
  const MyConfirmDialog({super.key, required this.title, required this.child});
  final Widget title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: SingleChildScrollView(
        child: child,
      ),
      actions: <Widget>[
        TextButton(
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

showErrorDialog(BuildContext context, dynamic error) {
  return showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: SingleChildScrollView(
              child: Wrap(
                children: [
                  Text(
                    '$error',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ),
            ),
          ));
}

class MyInputPlaceNameDialog extends StatefulWidget {
  const MyInputPlaceNameDialog({super.key});

  @override
  State<MyInputPlaceNameDialog> createState() => _MyInputPlaceNameDialogState();
}

class _MyInputPlaceNameDialogState extends State<MyInputPlaceNameDialog> {
  final _controller = TextEditingController();
  bool _disabled = false;
  dynamic _error;
  _submit() async {
    final name = _controller.text.trim();
    if (name == '') {
      return;
    }
    setState(() {
      _disabled = true;
      _error = null;
    });
    try {
      final helpers = await DB.helpers;
      final id = await helpers.place.add(name);
      setState(() {
        _disabled = false;
      });
      Navigator.of(context).pop(Place(id: id, name: name));
    } catch (e) {
      setState(() {
        _error = e;
        _disabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_disabled,
      child: AlertDialog(
        title: _disabled
            ? Row(
                children: [
                  const Text("Add place"),
                  Container(
                    padding: const EdgeInsets.only(left: 8),
                    child: const CircularProgressIndicator(),
                  ),
                ],
              )
            : const Text("Add place"),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              TextField(
                autofocus: true,
                decoration:
                    const InputDecoration(label: Text("Type name here")),
                controller: _controller,
                readOnly: _disabled,
                onEditingComplete: _submit,
              ),
              _error == null
                  ? Container()
                  : Wrap(
                      children: [
                        Text(
                          '$_error',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _disabled ? null : () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: _disabled ? null : _submit,
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }
}


