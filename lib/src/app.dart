import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'theme/app_theme.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'review_page.dart';
import 'reader_review_page.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'providers/auth_provider.dart';
import 'providers/restroom_provider.dart';
import 'services/api_service.dart';
import 'providers/location_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.settingsController});
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(apiBaseUrl),
            ),
            ChangeNotifierProvider<LocationProvider>(
              create: (_) => LocationProvider(),
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
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', '')],
            onGenerateTitle: (BuildContext context) => 'Restroom Finder',
            theme: AppTheme.light(),
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
