import 'package:flutter/material.dart';
import 'package:pw_24/pages/login_page.dart';
import 'package:pw_24/pages/home_page.dart';
import 'package:pw_24/pages/register_page.dart';
import 'package:pw_24/pages/goals_page.dart';

class NavigationService {
  NavigationService() {
    _navigatorKey = GlobalKey<NavigatorState>();
  }

  late GlobalKey<NavigatorState> _navigatorKey;
  final Map<String, Widget Function(BuildContext)> _routes = {
    "/login": (context) => LoginPage(),
    "/register": (context) => RegisterPage(),
    "/home": (context) => HomePage(),
    "/goals" : (context) => GoalsPage(),
  };

  GlobalKey<NavigatorState>? get navigatorKey {
    return _navigatorKey;
  }

  Map<String, Widget Function(BuildContext)> get routes {
    return _routes;
  }

  void push(MaterialPageRoute route) {
    _navigatorKey.currentState?.push(route);
  }

  void pushNamed(String routeName) {
    _navigatorKey.currentState?.pushNamed(routeName);
  }

  void pushReplacementNamed(String routeName) {
    _navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  void goBack() {
    _navigatorKey.currentState?.pop();
  }

  void goToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }
}