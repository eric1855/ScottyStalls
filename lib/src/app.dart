import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'review_page.dart';
import 'reader_review_page.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'providers/auth_provider.dart';
import 'providers/restroom_provider.dart';
import 'services/api_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.settingsController});
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        // NO trailing slash here
        const String apiBaseUrl = 'https://atq65hnu62.execute-api.us-east-1.amazonaws.com/first';

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(apiBaseUrl),
            ),
            ChangeNotifierProxyProvider<AuthProvider, RestroomProvider>(
              create: (context) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                return RestroomProvider(
                  ApiService(baseUrl: apiBaseUrl, token: auth.user.token),
                );
              },
              update: (context, auth, previous) {
                return RestroomProvider(
                  ApiService(baseUrl: apiBaseUrl, token: auth.user.token),
                );
              },
            ),
          ],
          child: MaterialApp(
            restorationScopeId: 'app',
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', '')],
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appTitle,
            theme: ThemeData(
              scaffoldBackgroundColor: const Color(0xFFFAFAFA),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF111827),
                elevation: 0,
              ),
              textTheme: GoogleFonts.interTextTheme(),
            ),
            darkTheme: ThemeData.dark(),
            themeMode: settingsController.themeMode,
            initialRoute: LoginPage.routeName,
            routes: {
              SettingsView.routeName: (_) =>
                  SettingsView(controller: settingsController),
              LoginPage.routeName: (_) => const LoginPage(),
              HomePage.routeName: (_) => const HomePage(),
            },
            onGenerateRoute: (RouteSettings routeSettings) {
              if (routeSettings.name == ReviewPage.routeName) {
                final args = routeSettings.arguments;
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (BuildContext context) =>
                      ReviewPage(restroom: args as dynamic),
                );
              }
              if (routeSettings.name == ReaderReviewPage.routeName) {
                final args = routeSettings.arguments;
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (BuildContext context) =>
                      ReaderReviewPage(restroom: args as dynamic),
                );
              }
              return MaterialPageRoute<void>(
                settings: routeSettings,
                builder: (BuildContext context) => const LoginPage(),
              );
            },
          ),
        );
      },
    );
  }
}
