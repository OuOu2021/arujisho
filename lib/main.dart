import 'package:arujisho/providers/db_provider.dart';
import 'package:arujisho/providers/item_count_notifier.dart';
import 'package:arujisho/providers/search_history_notifier.dart';
import 'package:arujisho/providers/theme_notifier.dart';
import 'package:arujisho/providers/tts_cache_provider.dart';
import 'package:arujisho/router.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

// Do not interrupt other audio
Future initAudioService() async {
  final session = await AudioSession.instance;
  await session.configure(
    const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: true,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // make navigation bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  // make flutter draw behind navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  initAudioService();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
      ),
      ChangeNotifierProvider(create: (_) => ItemCountNotifier()),
      ChangeNotifierProvider(create: (_) => SearchHistoryNotifier()),
      Provider<Logger>(
          create: (_) => Logger(printer: PrettyPrinter(), level: Level.debug
              // filter: DevelopmentFilter(),
              )),
      Provider<TtsCacheProvider>(
        create: (_) => TtsCacheProvider(),
      ),
      Provider<DbProvider>(
        create: (context) => DbProvider(),
      ),
    ],
    child: const MyApp(),
  ));
}

const int myInf = 999;

class MyApp extends StatelessWidget {
  static const isRelease = true;

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    const font = "NotoSansJP";
    const indigo = Colors.indigo;
    return MaterialApp.router(
      title: 'ある辞書',
      theme: ThemeData(
        drawerTheme: DrawerThemeData(
          surfaceTintColor: indigo[200],
        ),
        fontFamily: font,
        brightness: Brightness.light,
        colorSchemeSeed: indigo,
        sliderTheme:
            SliderThemeData(overlayShape: SliderComponentShape.noOverlay),
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
        sliderTheme:
            SliderThemeData(overlayShape: SliderComponentShape.noOverlay),
        useMaterial3: true,
      ),
      themeMode: themeNotifier.themeMode,
      routerConfig: router,
    );
  }
}
