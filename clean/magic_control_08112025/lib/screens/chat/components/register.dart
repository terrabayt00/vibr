import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:magic_control/helper/db_helper.dart';
import 'package:magic_control/helper/message_helper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // String? _email;
  String? _firstName;
  String? _lastName;
  //FocusNode? _focusNode;
  bool _registering = false;

//  TextEditingController? _passwordController;
//   TextEditingController? _usernameController;

  @override
  void initState() {
    super.initState();
    final faker = Faker();
    _firstName = faker.person.firstName();
    _lastName = faker.person.lastName();
    // _email =
    //     '${_firstName!.toLowerCase()}.${_lastName!.toLowerCase()}@${faker.internet.domainName()}';
    // _focusNode = FocusNode();
    // _passwordController = TextEditingController();
    // _usernameController = TextEditingController(
    //   text: _email,
    // );
  }

  void _register() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _registering = true;
    });

    try {
      // final credential =
      //     await FirebaseAuth.instance.createUserWithEmailAndPassword(
      //   email: _usernameController!.text,
      //   password: _passwordController!.text,
      // );

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      String userId = currentUser.uid;
      await FirebaseChatCore.instance.createUserInFirestore(
        types.User(
          firstName: _firstName,
          id: userId,
          //  imageUrl: 'https://i.pravatar.cc/300?u=$_email',
          imageUrl: 'https://i.pravatar.cc/300?u=douglas.schuster@hintz.ca',
          lastName: _lastName,
        ),
      );
//!save girl id
      DbHelper db = DbHelper();
      await db.saveGirlId({
        'id': userId,
        'firstName': _firstName,
        'imageUrl': 'https://i.pravatar.cc/300?u=douglas.schuster@hintz.ca',
        'lastName': _lastName,
        'email': currentUser.email,
        'isActive': true
      });

      if (!mounted) return;
      Navigator.of(context).pop();
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

  // @override
  // void dispose() {
  //   _focusNode?.dispose();

  //   _passwordController?.dispose();
  //   _usernameController?.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text('Регистрация'),
        ),
        body: Container(
          padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Нажми кнопку - "Создать" для СОЗДАНИЯ профиля'),
                // TextField(
                //   autocorrect: false,
                //   autofillHints: _registering ? null : [AutofillHints.email],
                //   autofocus: true,
                //   controller: _firstController,
                //   decoration: InputDecoration(
                //     border: const OutlineInputBorder(
                //       borderRadius: BorderRadius.all(
                //         Radius.circular(8),
                //       ),
                //     ),
                //     labelText: 'Имя',
                //     suffixIcon: IconButton(
                //       icon: const Icon(Icons.cancel),
                //       onPressed: () => _firstController?.clear(),
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
                // Container(
                //   margin: const EdgeInsets.symmetric(vertical: 8),
                //   child: TextField(
                //     autocorrect: false,
                //     autofillHints:
                //         _registering ? null : [AutofillHints.password],
                //     controller: _lastController,
                //     decoration: InputDecoration(
                //       border: const OutlineInputBorder(
                //         borderRadius: BorderRadius.all(
                //           Radius.circular(8),
                //         ),
                //       ),
                //       labelText: 'Фамилия',
                //       suffixIcon: IconButton(
                //         icon: const Icon(Icons.cancel),
                //         onPressed: () => _lastController?.clear(),
                //       ),
                //     ),
                //     focusNode: _focusNode,
                //     keyboardType: TextInputType.emailAddress,
                //     obscureText: false,
                //     onEditingComplete: _register,
                //     textCapitalization: TextCapitalization.none,
                //     textInputAction: TextInputAction.done,
                //   ),
                // ),
                TextButton(
                  onPressed: _registering ? null : _register,
                  child: const Text('Создать'),
                ),
              ],
            ),
          ),
        ),
      );
}
