import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/helpers/message_helper.dart';

class UserNameWidget extends StatefulWidget {
  const UserNameWidget({super.key, required this.id});
  final String id;

  @override
  State<UserNameWidget> createState() => _UserNameWidgetState();
}

class _UserNameWidgetState extends State<UserNameWidget> {
  final DbHelper _db = DbHelper();
  String _userName = '';
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _userName = await _db.getUserName(widget.id);
    if (_userName.isNotEmpty) {
      setState(() {
        _controller.text = _userName;
      });
    }
  }

  _showMessage(String text, bool state) {
    MessageHelper.show(context, text);
  }

  Future<void> _saveName() async {
    _db
        .setUserName(widget.id, _controller.text)
        .then((value) => _showMessage('User name SAVED!', true));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 250,
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
              ),
            ),
          ),
          const SizedBox(width: 18.0),
          ElevatedButton(
            onPressed: () => _controller.text.isEmpty
                ? _showMessage('Enter name', false)
                : _saveName(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_userName.isEmpty ? 'TYPE NAME' : 'SAVE'),
            ),
          )
        ],
      ),
    );
  }
}
