import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/auth_helper.dart';
import 'package:magic_dashbord/helpers/message_helper.dart';
import 'package:magic_dashbord/screen/main/main_screen.dart';
import 'package:magic_dashbord/style/brand_color.dart';
import 'package:magic_dashbord/widgets/login_widget.dart';
import 'package:magic_dashbord/widgets/logo_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    emailController = TextEditingController();
    passwordController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signIn() async {
    if (emailController.text.isEmpty || !emailController.text.contains('@')) {
      showMessage('errorEmail');
      return;
    }
    if (!emailController.text.contains('admin')) {
      return;
    }
    if (passwordController.text.isEmpty) {
      showMessage('errorPassword');
      return;
    }
    if (passwordController.text.length < 8) {
      showMessage('errorBadPassword');
      return;
    }
    AuthHelper auth = AuthHelper();
    // await auth.createUser(
    //     emailController.text.trim(), passwordController.text.trim());
    // Ensure user is fetched before sign in
    Map<String, dynamic> state = await auth.signIn(
      emailController.text.trim(),
      passwordController.text.trim(),
    );
    if (state['userId'] != null) {
      //check admin
      toDashbord();
    }
    if (state['error'] != null && state['error'].toString().isNotEmpty) {
      showMessage(state['error'].toString());
      return;
    } else {
      showMessage('errorSignIn');
    }
  }

  showMessage(String text) {
    MessageHelper.show(context, text);
  }

  void toDashbord() {
    emailController.clear();
    passwordController.clear();
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.kRed.withOpacity(0.2),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const LogoWidget(),
                const SizedBox(height: 20.0),
                LoginTextField(
                  lable: 'Email',
                  hintText: 'example@gmail.com',
                  controller: emailController,
                ),
                LoginTextField(
                  lable: 'Password',
                  hintText: '********',
                  obscureText: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 12.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                      icon: const Icon(Icons.login_outlined),
                      onPressed: signIn,
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 8.0),
                        child: Text('Enter'.toUpperCase()),
                      )),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
