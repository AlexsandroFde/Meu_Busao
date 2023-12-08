import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projeto_bd_sql/view/home.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'contants/constants.dart';

Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    MaterialApp(
      theme: ThemeData(
        primarySwatch: base,
      ),
      debugShowCheckedModeBanner: false,
      title: 'SQL',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      home: AnimatedSplashScreen(
          backgroundColor: base,
          splash: "assets/meu_busao_logo.png",
          splashIconSize: 300,
          nextScreen: Home()
      )
    ),
  );
}