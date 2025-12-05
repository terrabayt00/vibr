import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:magic/model/girls_model.dart';
import 'package:magic/style/color/brand_color.dart';

import 'chat.dart';
import 'util.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.girls});

  final List<GirlModel> girls;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _makeRoom = false;

  Widget _buildAvatar(types.User user) {
    final color = getUserAvatarNameColor(user);
    final hasImage = user.imageUrl != null;
    final name = getUserName(user);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        backgroundColor: hasImage ? Colors.transparent : color,
        backgroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
        radius: 48,
        child: !hasImage
            ? Text(
                name.isEmpty ? '' : name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  void _handlePressed(types.User otherUser, BuildContext context) async {
    //!set make room
    setState(() {
      _makeRoom = true;
    });
    final navigator = Navigator.of(context);

    final room = await FirebaseChatCore.instance.createRoom(otherUser);

    navigator.pop();
    await navigator.push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          room: room,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: BrandColor.kRed,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text(
            'Пользователи',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: StreamBuilder<List<types.User>>(
          stream: FirebaseChatCore.instance.users(),
          initialData: const [],
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(
                  bottom: 200,
                ),
                child: const Text('Нету пользователей'),
              );
            }
            List<types.User> girlList = [];
            for (GirlModel model in widget.girls) {
              girlList.add(
                  snapshot.data!.where((user) => user.id == model.id).first);
            }

            return _makeRoom
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount: girlList.length,
                    itemBuilder: (context, index) {
                      final user = girlList[index];

                      return GestureDetector(
                        onTap: () {
                          _handlePressed(user, context);
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                _buildAvatar(user),
                                Text(
                                  getUserName(user),
                                  style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
          },
        ),
      );
}
