import 'package:arujisho/pages/about.dart';
import 'package:arujisho/pages/home.dart';
import 'package:arujisho/providers/display_item_notifier.dart';
import 'package:arujisho/providers/extended_item_notifier.dart';
import 'package:arujisho/providers/theme_notifier.dart';
import 'package:arujisho/providers/tts_cache_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:arujisho/pages/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // make navigation bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  // make flutter draw behind navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
      ),
      ChangeNotifierProvider(create: (_) => DisplayItemCountNotifier()),
      ChangeNotifierProvider(create: (_) => ExpandedItemCountNotifier()),
      Provider<Logger>(
          create: (_) => Logger(printer: PrettyPrinter(), level: Level.debug
              // filter: DevelopmentFilter(),
              )),
      Provider<TtsCacheProvider>(
        create: (_) => TtsCacheProvider(),
      )
    ],
    child: const MyApp(),
  ));
}

const int myInf = 999;

class MyApp extends StatelessWidget {
  static const isRelease = true;

  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    const font = "NotoSansJP";
    const indigo = Colors.indigo;
    return MaterialApp(
      title: 'ある辞書',
      theme: ThemeData(
        drawerTheme: DrawerThemeData(
          surfaceTintColor: indigo[200],
        ),
        fontFamily: font,
        brightness: Brightness.light,
        colorSchemeSeed: indigo,
        // appBarTheme: AppBarTheme(
        //     scrolledUnderElevation: 6.0, surfaceTintColor: Colors.transparent),
        // shadowColor: Colors.transparent,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        drawerTheme: DrawerThemeData(surfaceTintColor: indigo[800]),
        fontFamily: font,
        colorSchemeSeed: indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: themeNotifier.themeMode,
      initialRoute: '/splash',
      routes: {
        '/': (context) => const MyHomePage(),
        '/splash': (context) => const SplashScreen(),
        '/about': (context) => const AboutPage(),
      },
    );
  }
}
