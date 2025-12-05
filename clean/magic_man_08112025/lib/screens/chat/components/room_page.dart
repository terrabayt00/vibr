import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/model/girls_model.dart';
import 'package:magic/model/magic_model.dart';
import 'package:magic/screens/chat/components/edit_profile.dart';
import 'package:magic/screens/home/home_page.dart';
import 'package:magic/style/color/brand_color.dart';

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

  // GirlModel? girlModel;
  List<GirlModel> _girlsList = [];
  MagicUser? magicUser;

  @override
  void initState() {
    initializeFlutterFire();
    getGirl();
    getUserData();
    super.initState();
  }

  getUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          //  print('Document data: ${documentSnapshot.data()}');
          MagicUser model = MagicUser.fromMap(
              documentSnapshot.data() as Map<String, dynamic>);
          //  print('MODEL: ${model.firstName}');

          setState(() {
            magicUser = model;
          });
        } else {
          // print('Document does not exist on the database');
        }
      });
    }
  }

  getGirl() async {
    DbHelper db = DbHelper();
    final List<GirlModel> girls = await db.getGirls();
    if (girls.isNotEmpty) {
      List<GirlModel> models =
          girls.where((element) => element.isActive == true).toList();
      setState(() {
        _girlsList = models;
      });
    }
  }

  void initializeFlutterFire() async {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
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
    //   await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(),
        ),
        (Route<dynamic> route) => false);
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
        backgroundImage: hasImage
            ? room.imageUrl != null
                ? NetworkImage(room.imageUrl!)
                : null
            : null,
        radius: 48,
        child: !hasImage
            ? Text(
                name.isEmpty ? '' : name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container();
    }

    if (!_initialized) {
      return Container();
    }
    //  print('USER: $_user girlModel: $girlModel');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: BrandColor.kRed,
        toolbarHeight: 150.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _user == null || _girlsList.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => UsersPage(
                          girls: _girlsList,
                        ),
                      ),
                    );
                  },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _user == null ? null : logout,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: magicUser != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Комнаты',
                    style: TextStyle(color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfile(user: magicUser))),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(magicUser!.imageUrl),
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => const LoginPage(),
                        ),
                      );
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
                    child: const Text('Нет комнат'),
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
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              _buildAvatar(room),
                              Text(
                                room.name ?? '',
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
}
