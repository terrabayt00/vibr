import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:magic_control/helper/db_helper.dart';
import 'package:magic_control/model/magic_user.dart';
import 'package:magic_control/screens/chat/components/edit_profile.dart';
import 'package:magic_control/screens/chat/components/register.dart';
import 'package:magic_control/style/brand_color.dart';

import 'chat.dart';
import 'login.dart';
import 'users.dart';
import 'util.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  bool _error = false;
  bool _initialized = false;
  User? _user;
  MagicUser? magicUser;
  bool toogelOn = false;

  @override
  void initState() {
    initializeFlutterFire();
    getUserData();

    super.initState();
  }

  initToogle(String id) async {
    DbHelper db = DbHelper();
    bool result = await db.checkActiveGirl(id);
    setState(() {
      toogelOn = result;
    });
  }

  getUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          //print('Document data: ${documentSnapshot.data()}');
          MagicUser model = MagicUser.fromMap(
              documentSnapshot.data() as Map<String, dynamic>);
          // print('MODEL: ${model.firstName}');
          setState(() {
            magicUser = model;
          });
          initToogle(user.uid);
        } else {
          print('Document does not exist on the database');
        }
      });
    }
  }

  void initializeFlutterFire() async {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        setState(() {
          _user = user;
        });
      });
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    setState(() {});
  }

  Widget _buildAvatar(types.Room room) {
    var color = Colors.transparent;

    if (room.type == types.RoomType.direct) {
      try {
        final otherUser = room.users.firstWhere(
          (u) => u.id != _user!.uid,
        );

        color = getUserAvatarNameColor(otherUser);
      } catch (e) {
        // Do nothing if other user is not found.
      }
    }

    final hasImage = room.imageUrl != null;
    final name = room.name ?? '';

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        backgroundColor: hasImage ? Colors.transparent : color,
        backgroundImage: hasImage ? NetworkImage(room.imageUrl!) : null,
        radius: 20,
        child: !hasImage
            ? Text(
                name.isEmpty ? '' : name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
    );
  }

  List<Widget> getActionButton() {
    if (_user == null) {
      return [];
    } else if (magicUser == null) {
      return [
        IconButton(
            onPressed: () {
              Navigator.push(context,
                      MaterialPageRoute(builder: (_) => RegisterPage()))
                  .then((value) {
                setState(() {
                  getUserData();
                });
              });
            },
            icon: Icon(
              Icons.person_pin_rounded,
              color: Colors.white,
              size: 32.0,
            ))
      ];
    } else if (_user != null && magicUser != null) {
      return [
        IconButton(
          icon: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32.0,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => const UsersPage(),
              ),
            );
          },
        ),
        SizedBox(width: 12.0),
      ];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container();
    }

    if (!_initialized) {
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: BrandColor.kRed,
        toolbarHeight: 250.0,
        actions: getActionButton(),
        leading: _user != null
            ? IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: logout,
              )
            : SizedBox(),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: magicUser != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Чати',
                        style: TextStyle(color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          EditProfile(user: magicUser)))
                              .then((value) {
                            setState(() {
                              getUserData();
                            });
                          });
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  NetworkImage(magicUser!.imageUrl),
                              radius: 48,
                            ),
                            Text(
                              magicUser!.firstName,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Girls profile\nActive in CHAT:',
                        style: TextStyle(color: Colors.white, fontSize: 14.0),
                      ),
                      const SizedBox(width: 18.0),
                      Text(
                        toogelOn ? 'Yes' : 'No',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 18.0),
                      IconButton(
                          onPressed: () async {
                            DbHelper db = DbHelper();
                            db
                                .updateGirlActive(_user!.uid, !toogelOn)
                                .then((val) {
                              initToogle(_user!.uid);
                            });
                          },
                          icon: Icon(
                            size: 48.0,
                            color: Colors.white,
                            toogelOn
                                ? Icons.toggle_on_outlined
                                : Icons.toggle_off_outlined,
                          ))
                    ],
                  ),
                ],
              )
            : const SizedBox(),
      ),
      body: _user == null
          ? Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(
                bottom: 200,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Не аутентифицирован'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => const LoginPage(),
                        ),
                      )
                          .then((value) {
                        setState(() {
                          getUserData();
                        });
                      });
                    },
                    child: const Text('Вход'),
                  ),
                ],
              ),
            )
          : StreamBuilder<List<types.Room>>(
              stream: FirebaseChatCore.instance.rooms(),
              initialData: const [],
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(
                      bottom: 200,
                    ),
                    child: const Text('нет Чатов'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final room = snapshot.data![index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              room: room,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            _buildAvatar(room),
                            Text(room.name ?? ''),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
