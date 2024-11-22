import 'package:arujisho/pages/about.dart';
import 'package:arujisho/pages/home.dart';
import 'package:arujisho/pages/splash_screen.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: SplashScreen.routeName,
  routes: [
    GoRoute(
      path: MyHomePage.routeName,
      builder: (context, state) => MyHomePage(
        initialInput: state.uri.queryParameters.containsKey('search')
            ? state.uri.queryParameters['search']
            : null,
      ),
    ),
    GoRoute(
      path: SplashScreen.routeName,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AboutPage.routeName,
      builder: (context, state) => const AboutPage(),
    )
  ],
);
