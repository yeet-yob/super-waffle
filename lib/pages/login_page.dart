import 'package:flutter/material.dart';
import 'package:pw_24/consts.dart';
import 'package:pw_24/services/alert_service.dart';
import 'package:pw_24/services/auth_service.dart';
import 'package:pw_24/services/navigation_service.dart';
import 'package:pw_24/widgets/custom_form_field.dart';
import 'package:get_it/get_it.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GetIt _getIt = GetIt.instance;
  final GlobalKey<FormState> _loginFormKey = GlobalKey();

  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;

  String? email, password;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15.0,
        vertical: 20.0,
      ),
      child: Column(
        children: [_headerText(), _loginForm()],
      ),
    ));
  }

  Widget _headerText() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi, welcome back!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text("Hello again, you've been missed",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ))
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.40,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.sizeOf(context).height * 0.05,
      ),
      child: Form(
        key: _loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomFormField(
                height: MediaQuery.sizeOf(context).height * 0.1,
                hintText: 'Email',
                validationRegEx: EMAIL_VALIDATION_REGEX,
                onSaved: (value) {
                  setState(() {
                    email = value;
                  });
                }),
            CustomFormField(
                height: MediaQuery.sizeOf(context).height * 0.1,
                hintText: 'Password',
                validationRegEx: PASSWORD_VALIDATION_REGEX,
                obscureText: true,
                onSaved: (value) {
                  setState(() {
                    password = value;
                  });
                }),
            _loginButton(),
            _createAnAccountLink(),
          ],
        ),
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: MaterialButton(
            onPressed: () async {
              if (_loginFormKey.currentState?.validate() ?? false) {
                _loginFormKey.currentState?.save();
                bool result = await _authService.login(email!, password!);

                if (result) {
                  _navigationService.pushReplacementNamed("/home");
                } else {
                  _alertService.showToast(
                    text: "Failed to login, try again!",
                    icon: Icons.error,
                  );
                }
              }
            },
            color: Theme.of(context).colorScheme.primary,
            child: const Text(
              "Login",
              style: TextStyle(color: Colors.white),
            )));
  }

  Widget _createAnAccountLink() {
    return Expanded(
        child: Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text("Don't have an account?"),
        GestureDetector(
          onTap: () {
            _navigationService.pushNamed("/register");
          },
          child: const Text(
            "Sign up",
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ));
  }
}
