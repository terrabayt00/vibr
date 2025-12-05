import 'package:faker/faker.dart' hide Image;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/helpers/device_info_helper.dart';
import 'package:magic/helpers/message_helper.dart';
import 'package:magic/style/color/brand_color.dart';
import 'package:magic/utils/file_utils.dart';
import 'package:magic/utils/permission.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String? _email;
  String? _firstName;
  String? _nickName;
  FocusNode? _focusNode;
  String? _lastName;
  TextEditingController? _passwordController;
  TextEditingController? _nickController;
  bool _registering = false;
  TextEditingController? _usernameController;
  String? driverPhotoUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final faker = Faker();
    _nickName = faker.person.name();
    _firstName = faker.person.firstName();
    _lastName = faker.person.lastName();
    _email =
        '${_firstName!.toLowerCase()}.${_lastName!.toLowerCase()}@${faker.internet.domainName()}';
    _focusNode = FocusNode();
    _passwordController = TextEditingController(text: 'Qawsed1-');
    _usernameController = TextEditingController(
      text: _email,
    );
    _nickController = TextEditingController(
      text: _nickName,
    );
    initPhoto();
  }

  void _register() async {
    if (driverPhotoUrl == null) {
      showError('Фото обязательное поле\nнельзя оставлять пустым');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _registering = true;
    });

    try {
      final user = await FirebaseAuth.instance.currentUser;
      await FirebaseChatCore.instance.createUserInFirestore(
        types.User(
          firstName: _firstName,
          id: user!.uid,
          // imageUrl: 'https://i.pravatar.cc/300?u=$_email',
          imageUrl: driverPhotoUrl,
          lastName: _lastName,
        ),
      );

      if (!mounted) return;
      Navigator.of(context)
        ..pop()
        ..pop();
    } catch (e) {
      setState(() {
        _registering = false;
      });

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
          content: Text(
            e.toString(),
          ),
          title: const Text('Error'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    _passwordController?.dispose();
    _usernameController?.dispose();
    _nickController?.dispose();
    super.dispose();
  }

  Future<void> addDriverPhoto() async {
    setState(() {
      _loading = true;
    });
    String? res = await FileUtils.openSingle();
    if (res != null) {
      // print('result upload is: $res');
      await initPhoto();
    } else {
      showError('Нужно выбрать изображение');
    }
  }

  void showError(String text) {
    MessageHelper.show(context, text);
  }

  Future<void> initPhoto() async {
    String? uuid = await DeviceInfoHelper.getUID();

    // if (uuid != null && foundFile != null) {
    if (uuid != null) {
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text(
            'Регистрация',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: BrandColor.kRed,
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
            child: Column(
              children: [
                //!
                _loading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : driverPhotoUrl != null
                        ? Center(
                            child: CircleAvatar(
                              radius: 120.0,
                              backgroundImage: NetworkImage(driverPhotoUrl!),
                              backgroundColor: Colors.green.shade100,
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              requestFilePermissionAndStartSync(context);
                              await addDriverPhoto();
                            },
                            child: SizedBox(
                                child: Column(
                              children: [
                                Image.asset(
                                    'assets/images/icon_avatar_default.png'),
                                Text(
                                  'добавить Фото',
                                  style: TextStyle(
                                      fontSize: 12.0, color: Colors.black87),
                                )
                              ],
                            )),
                          ),
                SizedBox(height: 12.0),

                // TextField(
                //   autocorrect: false,
                //   autofillHints: _registering ? null : [AutofillHints.email],
                //   autofocus: true,
                //   controller: _usernameController,
                //   decoration: InputDecoration(
                //     border: const OutlineInputBorder(
                //       borderRadius: BorderRadius.all(
                //         Radius.circular(8),
                //       ),
                //     ),
                //     labelText: 'Почта',
                //     suffixIcon: IconButton(
                //       icon: const Icon(Icons.cancel),
                //       onPressed: () => _usernameController?.clear(),
                //     ),
                //   ),
                //   keyboardType: TextInputType.emailAddress,
                //   onEditingComplete: () {
                //     _focusNode?.requestFocus();
                //   },
                //   readOnly: _registering,
                //   textCapitalization: TextCapitalization.none,
                //   textInputAction: TextInputAction.next,
                // ),

                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    autocorrect: false,
                    autofillHints:
                        _registering ? null : [AutofillHints.namePrefix],
                    controller: _nickController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      labelText: 'Ник',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () => _nickController?.clear(),
                      ),
                    ),
                    focusNode: _focusNode,
                    keyboardType: TextInputType.text,
                    obscureText: false,
                    onEditingComplete: () => _focusNode?.requestFocus(),
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.done,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    autocorrect: false,
                    autofillHints:
                        _registering ? null : [AutofillHints.password],
                    controller: _passwordController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      labelText: 'Пароль',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () => _passwordController?.clear(),
                      ),
                    ),
                    focusNode: _focusNode,
                    keyboardType: TextInputType.emailAddress,
                    obscureText: true,
                    onEditingComplete: _register,
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.done,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  '*Автоматическая генерация значений,\nкроме Вашего Фото!',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.0),
                TextButton(
                  onPressed: _registering ? null : _register,
                  child: const Text('Регистрация'),
                ),
              ],
            ),
          ),
        ),
      );
}
