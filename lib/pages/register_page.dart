import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  static route() =>
      MaterialPageRoute(builder: (context) => RegisterPage(onTap: () {}));

  // email and pw controllers
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  // tap to go to register page
  final Function()? onTap;

  RegisterPage({
    super.key,
    required this.onTap,
  });

  // register method
  void register(BuildContext context) async {
    // get auth service
    final authService = AuthService();

    // passwords match -> create user
    if (_pwController.text == _confirmPwController.text) {
      try {
        await authService.signUpWithEmailPassword(
          _emailController.text,
          _pwController.text,
        );
      } catch (e) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(e.toString()),
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('Passwords don\'t match!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // logo
            Icon(
              Icons.message,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 50),

            // welcome back message
            Text(
              'Let\'s create an account for you',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

            // email textfield
            MyTextfield(
              controller: _emailController,
              hintText: 'Email',
              obscureText: false,
            ),

            const SizedBox(height: 10),

            // password textfield
            MyTextfield(
              controller: _pwController,
              hintText: 'Password',
              obscureText: true,
            ),

            const SizedBox(height: 10),

            // confirm password textfield
            MyTextfield(
              controller: _confirmPwController,
              hintText: 'Confirm password',
              obscureText: true,
            ),

            const SizedBox(height: 25),

            // login button
            MyButton(
              onTap: () => register(context),
              text: "Register",
            ),

            const SizedBox(height: 25),

            // register now
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    'Login now',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
