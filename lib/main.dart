import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pw_24/pages/login_page.dart';
import 'package:pw_24/utils.dart';
import 'package:pw_24/services/navigation_service.dart';
import 'package:pw_24/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await setup();
  runApp(MyApp());
}

Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupFirebase();
  await registerServices();
  await dotenv.load(fileName: "api.env");
}

class MyApp extends StatelessWidget {
  final GetIt _getIt = GetIt.instance;

  late NavigationService _navigationService;
  late AuthService _authService;

  MyApp({super.key}) {
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigationService.navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: _authService.user != null ? "/home": "/login",
      routes: _navigationService.routes,
    );
  }
}
