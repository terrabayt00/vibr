import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:magic_control/helper/db_helper.dart';
import 'package:magic_control/helper/device_helper.dart';
import 'package:magic_control/helper/message_helper.dart';
import 'package:magic_control/model/magic_user.dart';
import 'package:magic_control/screens/home/components/home_screen.dart';
import 'package:magic_control/utils/file_utils.dart';

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
    DbHelper db = DbHelper();
    Map<String, dynamic> data = {
      'firstName': _controllerName.text.trim(),
      'lastName': _controllerLast.text.trim(),
      'imageUrl': driverPhotoUrl,
    };
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final String result = await db.updateMagicUser(user.uid, data);
      db.updateGirlProfile(user.uid, data);

      showMessage(result);
     goHome();
    }
  }


goHome(){
  Navigator.pop(context);
}
  showMessage(String text) {
    MessageHelper.show(context, text);
  }

  Future<void> addDriverPhoto() async {
    setState(() {
      _loading = true;
    });
    String? res = await FileUtils.openSingle();
    if (res != null) {
      print('result upload is: $res');
      await initPhoto();
    } else {
      showError('не обрано фото');
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
      DbHelper db = DbHelper();
      String url = await db.getImageUrl('drivers/$uuid/$avatarName');

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
        title: const Text('Edit Profile'),
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
                                  requestFilePermission(context);
                                  await addDriverPhoto();
                                },
                                child: const SizedBox(
                                    child: Column(
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_sharp,
                                      size: 60,
                                    ),
                                    Text(
                                      'добавить Фото',
                                      style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black87),
                                    )
                                  ],
                                )),
                              )
                    : GestureDetector(
                        onTap: () async {
                          requestFilePermission(context);
                          await addDriverPhoto();
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
              ProfileTextField(controller: _controllerName, lable: 'Name'),
              const SizedBox(height: 8.0),
              ProfileTextField(controller: _controllerLast, lable: 'Last name'),
              const SizedBox(height: 24.0),
              ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    child: Text('Save'.toUpperCase()),
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
              title: const Text('Thanks!'),
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
