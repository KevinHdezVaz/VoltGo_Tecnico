import 'dart:io';

import 'package:Voltgo_app/data/services/ChatNotificationProvider.dart';
import 'package:Voltgo_app/data/services/ServiceChatScreen.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:Voltgo_app/utils/OneSignalService.dart';
import 'package:Voltgo_app/utils/bottom_nav.dart';
 import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:Voltgo_app/firebase_options.dart';
import 'package:Voltgo_app/ui/SplashScreen.dart';
import 'package:Voltgo_app/utils/AuthWrapper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // ✅ NUEVO

// Importa tus pantallas
import 'package:Voltgo_app/ui/login/LoginScreen.dart';
import 'package:Voltgo_app/ui/MenuPage/DashboardScreen.dart';
import 'package:Voltgo_app/ui/MenuPage/dashboard/CombinedDashboardScreen.dart';
import 'package:Voltgo_app/ui/MenuPage/moviles/MobilesScreen.dart';
import 'package:Voltgo_app/ui/profile/SettingsScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/services/SoundService.dart';

// GlobalKey para navegación
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Manejar notificaciones Firebase (existente)
void _handleMessage(RemoteMessage message) {
  final notificationId = message.data['notificationId'];

  if (notificationId != null) {
    print('Notificación Firebase recibida, navegando a detalle ID: $notificationId');
    try {
      navigatorKey.currentState?.pushNamed(
        '/notification_detail',
        arguments: int.parse(notificationId),
      );
    } catch (e) {
      print('Error al parsear el ID de la notificación o al navegar: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Cargar variables de entorno
    await dotenv.load(fileName: ".env");
    print('Variables de entorno cargadas');

    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado');

    // Inicializar OneSignal
    await OneSignalService.initialize();
    print('OneSignal inicializado');

    // Inicializar NotificationService para sonidos locales
    NotificationService.reinitialize();
    print('NotificationService inicializado');

    // Configurar Firebase Messaging (existente)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessage(message);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación Firebase en primer plano: ${message.notification?.title}');
    });

    print('Todos los servicios inicializados correctamente');

  } catch (e, stackTrace) {
    print('Error inicializando servicios: $e');
    print('StackTrace: $stackTrace');
    // Continuar para no bloquear la app completamente
  }

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  initializeDateFormatting('es_ES', null).then((_) {
    runApp(MyApp(onboardingCompleted: onboardingCompleted));
  });
}

class MyApp extends StatefulWidget {
  final bool onboardingCompleted;

  const MyApp({Key? key, required this.onboardingCompleted}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    
    // Observar ciclo de vida de la app
    WidgetsBinding.instance.addObserver(this);
    print('MyApp inicializada - observando ciclo de vida');
  }

  @override
  void dispose() {
    // Limpiar observer y servicios
    WidgetsBinding.instance.removeObserver(this);
    
    // Limpiar servicios
    OneSignalService.dispose();
    NotificationService.dispose();
    
    super.dispose();
  }

  /// Manejar cambios en el ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('Cambio en ciclo de vida: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('App en primer plano');
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        print('App pausada (segundo plano)');
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        print('App inactiva');
        break;
      case AppLifecycleState.detached:
        print('App desconectada');
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  /// Manejar cuando la app pasa a primer plano
  void _handleAppResumed() {
    try {
      OneSignalService.updateAppState('foreground');
      NotificationService.reinitialize();
    } catch (e) {
      print('Error manejando app resumed: $e');
    }
  }

  /// Manejar cuando la app pasa a segundo plano
  void _handleAppPaused() {
    try {
      OneSignalService.updateAppState('background');
      NotificationService.stop().catchError((e) {
        print('Error deteniendo sonido al pausar app: $e');
      });
    } catch (e) {
      print('Error manejando app paused: $e');
    }
  }

  /// Manejar cuando la app se desconecta
  void _handleAppDetached() {
    try {
      OneSignalService.updateAppState('background');
    } catch (e) {
      print('Error manejando app detached: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // ✅ ENVOLVER EN MULTIPROVIDER
      providers: [
        // ✅ AGREGAR CHAT NOTIFICATION PROVIDER
        ChangeNotifierProvider(
          create: (context) => ChatNotificationProvider(),
        ),
        // Aquí puedes agregar otros providers que tengas
      ],
      child: MaterialApp(
        title: 'Voltgo',
        debugShowCheckedModeBanner: false,

        // GlobalKey para navegación
        navigatorKey: navigatorKey,
        
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[100],
        ),

        locale: const Locale('en', ''),

        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('es', ''), // Spanish
        ],

        home: const SplashScreen(),
        
        onGenerateRoute: (settings) {
          print('Navegando a ruta: ${settings.name}');
          
          switch (settings.name) {
            case '/auth_wrapper':
              return MaterialPageRoute(builder: (_) => const AuthWrapper());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/home':
              return MaterialPageRoute(builder: (_) => BottomNavBar());
            case '/dashboard':
              return MaterialPageRoute(
                  builder: (_) => const DriverDashboardScreen());
            case '/dashboard_combined':
              return MaterialPageRoute(
                  builder: (_) => const CombinedDashboardScreen());
            case '/mobiles':
              return MaterialPageRoute(builder: (_) => MobilesScreen());
            case '/settings':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());

            // ✅ NUEVA RUTA PARA CHAT
            case '/chat':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args['serviceRequest'] != null) {
                return MaterialPageRoute(
                  builder: (_) => ServiceChatScreen(
                    serviceRequest: args['serviceRequest'],
                    userType: args['userType'] ?? 'user',
                  ),
                );
              }
              return MaterialPageRoute(builder: (_) => const SplashScreen());

            default:
              print('Ruta no encontrada: ${settings.name}');
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
        
        // Builder para configurar UI global y OneSignal context
        builder: (context, child) {
          // ✅ CONFIGURAR CONTEXTO PARA ONESIGNAL
          WidgetsBinding.instance.addPostFrameCallback((_) {
            OneSignalService.setContext(context);
          });
          
          return child ?? Container();
        },
      ),
    );
  }
}