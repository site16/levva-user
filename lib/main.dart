// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:levva/screens/home/levva_eats/cart_screen.dart';
import 'package:levva/screens/home/levva_eats/checkout_screen.dart';
import 'package:levva/screens/home/levva_eats/eats_landing_screen.dart';
import 'package:levva/screens/home/levva_eats/order_confirmation_screen.dart';
import 'package:levva/screens/home/levva_eats/store_details_screen.dart';
import 'package:levva/screens/home/levva_eats/store_list_screen.dart';
import 'package:levva/screens/home/levva_eats/favorite_stores_screen.dart';

import 'package:levva/providers/eats_orders_provider.dart';
import 'package:levva/screens/orders/orders_screen.dart'; // Presumindo que EatsOrdersScreen e routeName estão aqui ou é global


import 'package:levva/services/google_maps_service.dart';
import 'package:levva/widgets/pulsing_logo_loader.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/eats_store_model.dart';
import 'models/enums.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/discount_provider.dart';
import 'providers/driver_registration_provider.dart';
import 'providers/levva_pay_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/ride_history_provider.dart';
import 'providers/ride_request_provider.dart';

// Telas
import 'screens/auth/login_screen.dart';
import 'screens/become_driver/become_driver_screen.dart';
import 'screens/become_driver/driver_registration_form_screen.dart';
import 'screens/become_driver/pre_registration_type_screen.dart';
import 'screens/discounts/discounts_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/legal/terms_of_use_screen.dart';
import 'screens/levva_pay/levva_pay_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/referral/referral_screen.dart';
// Remova o import da antiga RideDetailScreen se houver um específico para ela aqui
// import 'screens/ride_detail/ride_detail_screen.dart'; // Exemplo de como poderia estar
import 'screens/ride_history/ride_history_screen.dart';
import 'screens/sos/sos_screen.dart';
import 'screens/support/support_screen.dart';

// Serviços
import 'services/auth_service.dart';
import 'services/discount_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
    print("Firebase App Check ativado com sucesso (modo debug).");
  } catch (e) {
    print("Erro ao ativar o Firebase App Check: $e");
  }

  await initializeDateFormatting('pt_BR', null);
  runApp(const LevvaApp());
}

class LevvaApp extends StatelessWidget {
  const LevvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color appPrimaryColor = Colors.black;
    const Color appOnPrimaryColor = Colors.white;
    const Color appBackgroundColor = Colors.white;
    const Color appOnBackgroundColor = Colors.black87;
    const Color appSecondaryTextColor = Colors.black54;

    return MultiProvider(
      providers: [
        // Serviços
        Provider<AuthService>(
          create: (_) => AuthService(FirebaseAuth.instance),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(FirebaseFirestore.instance),
        ),
        Provider<GoogleMapsService>(create: (_) => GoogleMapsService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<DiscountService>(create: (_) => DiscountService()),

        // Providers de Estado
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create:
              (context) => AuthProvider(
                context.read<AuthService>(),
                context.read<FirestoreService>(),
              ),
          update:
              (context, authService, previousAuthProvider) =>
                  previousAuthProvider ??
                  AuthProvider(authService, context.read<FirestoreService>()),
        ),
        ChangeNotifierProxyProvider2<
            GoogleMapsService,
            FirestoreService,
            RideRequestProvider>(
          create:
              (context) => RideRequestProvider(
                context.read<GoogleMapsService>(),
                context.read<FirestoreService>(),
              ),
          update:
              (
                context,
                googleMapsService,
                firestoreService,
                previousRideRequestProvider,
              ) =>
                  previousRideRequestProvider ??
                  RideRequestProvider(googleMapsService, firestoreService),
        ),
        ChangeNotifierProxyProvider<NotificationService, NotificationProvider>(
          create:
              (context) =>
                  NotificationProvider(context.read<NotificationService>()),
          update:
              (context, notificationService, previousNotificationProvider) =>
                  previousNotificationProvider ??
                  NotificationProvider(notificationService),
        ),
        
        ChangeNotifierProxyProvider2<
            FirestoreService,
            AuthService,
            RideHistoryProvider>(
          create:
              (context) => RideHistoryProvider(
                context.read<FirestoreService>(),
                context.read<AuthService>(),
              ),
          update:
              (
                context,
                firestoreService,
                authService,
                previousRideHistoryProvider,
              ) =>
                  previousRideHistoryProvider ??
                  RideHistoryProvider(firestoreService, authService),
        ),
        ChangeNotifierProvider(create: (_) => LevvaPayProvider()),
        ChangeNotifierProxyProvider2<
            AuthProvider,
            DiscountService,
            DiscountProvider>(
          create:
              (context) => DiscountProvider(
                context.read<DiscountService>(),
                context.read<AuthProvider>(),
              ),
          update:
              (
                context,
                authProvider,
                discountService,
                previousDiscountProvider,
              ) =>
                  previousDiscountProvider ??
                  DiscountProvider(discountService, authProvider),
        ),
        ChangeNotifierProvider(create: (_) => DriverRegistrationProvider()),
        ChangeNotifierProxyProvider<AuthService, EatsOrdersProvider>(
          create: (context) => EatsOrdersProvider(context.read<AuthService>()),
          update:
              (context, authService, previousEatsOrdersProvider) =>
                  previousEatsOrdersProvider ?? EatsOrdersProvider(authService),
        ),
      ],
      child: MaterialApp(
        title: 'Levva',
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: appPrimaryColor,
          scaffoldBackgroundColor: appBackgroundColor,
          cardColor: appBackgroundColor,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: appPrimaryColor,
            elevation: 0,
            iconTheme: IconThemeData(color: appOnPrimaryColor),
            titleTextStyle: TextStyle(
              color: appOnPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
            actionsIconTheme: IconThemeData(color: appOnPrimaryColor),
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: appOnBackgroundColor),
            displayMedium: TextStyle(color: appOnBackgroundColor),
            displaySmall: TextStyle(color: appOnBackgroundColor),
            headlineMedium: TextStyle(
              color: appOnBackgroundColor,
              fontWeight: FontWeight.w600,
            ),
            headlineSmall: TextStyle(
              color: appOnBackgroundColor,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: TextStyle(
              color: appOnBackgroundColor,
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
            titleMedium: TextStyle(
              color: appOnBackgroundColor,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            titleSmall: TextStyle(color: appSecondaryTextColor, fontSize: 16),
            bodyLarge: TextStyle(color: appOnBackgroundColor, fontSize: 16),
            bodyMedium: TextStyle(color: appOnBackgroundColor, fontSize: 14),
            labelLarge: TextStyle(
              color: appOnPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          iconTheme: const IconThemeData(color: appPrimaryColor),
          inputDecorationTheme: InputDecorationTheme(
            prefixIconColor: MaterialStateColor.resolveWith(
              (states) =>
                  states.contains(MaterialState.focused)
                      ? appPrimaryColor
                      : Colors.grey.shade600,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: appPrimaryColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            labelStyle: TextStyle(
              color: Colors.grey.shade700,
              fontFamily: 'Inter',
            ),
            floatingLabelStyle: const TextStyle(
              color: appPrimaryColor,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.grey.shade50.withOpacity(0.7),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontFamily: 'Inter',
            ),
            errorStyle: const TextStyle(fontSize: 12, fontFamily: 'Inter'),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: appPrimaryColor,
              foregroundColor: appOnPrimaryColor,
              minimumSize: const Size(double.infinity, 52),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 2,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: appPrimaryColor,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: appPrimaryColor,
              side: const BorderSide(color: appPrimaryColor, width: 1.5),
              minimumSize: const Size(double.infinity, 50),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 0.5,
            color: appBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          ),
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: appPrimaryColor,
            onPrimary: appOnPrimaryColor,
            secondary: Color(0xFF212121),
            onSecondary: appOnPrimaryColor,
            error: Color(0xFFB00020),
            onError: Colors.white,
            background: appBackgroundColor,
            onBackground: appOnBackgroundColor,
            surface: appBackgroundColor,
            onSurface: appOnBackgroundColor,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        onGenerateRoute: (settings) {
          print(
            "Navegando para: ${settings.name} com argumentos: ${settings.arguments}",
          );

          // --- BLOCO REMOVIDO/COMENTADO ---
          // if (settings.name == RideDetailScreen.routeName) {
          //   final rideId = settings.arguments as String?;
          //   if (rideId != null) {
          //     return MaterialPageRoute(
          //       builder: (ctx) => RideDetailScreen(rideId: rideId),
          //     );
          //   }
          //   return MaterialPageRoute(
          //     builder:
          //         (_) => const Scaffold(
          //           body: Center(child: Text('ID da corrida não fornecido!')),
          //         ),
          //   );
          // }
          // --- FIM DO BLOCO REMOVIDO/COMENTADO ---


          if (settings.name == DriverRegistrationFormScreen.routeName) {
            final vehicleType = settings.arguments as VehicleType?;
            if (vehicleType != null) {
              return MaterialPageRoute(
                builder:
                    (_) =>
                        DriverRegistrationFormScreen(vehicleType: vehicleType),
              );
            }
            return MaterialPageRoute(
              builder:
                  (_) => const Scaffold(
                    body: Center(
                      child: Text("Tipo de veículo não especificado."),
                    ),
                  ),
            );
          }

          if (settings.name == StoreDetailsScreen.routeName) {
            final store = settings.arguments as EatsStoreModel?;
            if (store != null) {
              return MaterialPageRoute(
                builder: (_) => StoreDetailsScreen(store: store),
              );
            }
            return MaterialPageRoute(
              builder:
                  (_) => const Scaffold(
                    body: Center(child: Text("Dados da loja não fornecidos.")),
                  ),
            );
          }

          if (settings.name == StoreListScreen.routeName) {
            final routeArgs = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => StoreListScreen(routeArgs: routeArgs),
            );
          }

          if (settings.name == CheckoutScreen.routeName) {
            final totalAmount = settings.arguments as double?;
            if (totalAmount != null) {
              return MaterialPageRoute(
                builder: (_) => CheckoutScreen(totalAmount: totalAmount),
              );
            }
            return MaterialPageRoute(
              builder:
                  (_) => const Scaffold(
                    body: Center(
                      child: Text("Valor total não fornecido para checkout."),
                    ),
                  ),
            );
          }

          if (settings.name == OrderConfirmationScreen.routeName) {
            final orderDetails = settings.arguments as Map<String, dynamic>?;
            if (orderDetails != null) {
              return MaterialPageRoute(
                builder:
                    (_) => OrderConfirmationScreen(orderDetails: orderDetails),
              );
            }
            return MaterialPageRoute(
              builder:
                  (_) => const Scaffold(
                    body: Center(
                      child: Text("Detalhes do pedido não fornecidos."),
                    ),
                  ),
            );
          }

          switch (settings.name) {
            case LoginScreen.routeName:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case HomeScreen.routeName:
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case ProfileScreen.routeName:
              return MaterialPageRoute(builder: (_) => const ProfileScreen());
            case NotificationsScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              );
            case RideHistoryScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const RideHistoryScreen(),
              );
            case LevvaPayScreen.routeName:
              return MaterialPageRoute(builder: (_) => const LevvaPayScreen());
            case DiscountsScreen.routeName:
              return MaterialPageRoute(builder: (_) => const DiscountsScreen());
            case BecomeDriverScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const BecomeDriverScreen(),
              );
            case PreRegistrationTypeScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const PreRegistrationTypeScreen(),
              );
            case ReferralScreen.routeName:
              return MaterialPageRoute(builder: (_) => const ReferralScreen());
            case SupportScreen.routeName:
              return MaterialPageRoute(builder: (_) => const SupportScreen());
            case TermsOfUseScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const TermsOfUseScreen(),
              );
            case SosScreen.routeName:
              return MaterialPageRoute(builder: (_) => const SosScreen());
            case EatsOrdersScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const EatsOrdersScreen(),
              );
            case LevvaEatsLandingScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const LevvaEatsLandingScreen(),
              );
            case CartScreen.routeName:
              return MaterialPageRoute(builder: (_) => const CartScreen());
            case FavoriteStoresScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const FavoriteStoresScreen(),
              );

            default:
              return MaterialPageRoute(
                builder:
                    (_) => const Scaffold(
                      body: Center(child: Text('Página não encontrada')),
                    ),
              );
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Corrigindo o print para que funcione corretamente
    print("AuthWrapper build: isLoading=${authProvider.isLoading}, authStatus=${authProvider.authStatus}, isUserFetched=${authProvider.isUserFetched}");

    const Widget loadingScreen = Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: PulsingLogoLoader(
          imagePath: 'assets/images/levva_icon_transp_branco.png',
          size: 80.0,
          color: Colors.white,
        ),
      ),
    );

    if (authProvider.isLoading &&
        (authProvider.authStatus == AuthStatus.uninitialized ||
            authProvider.authStatus == AuthStatus.authenticating ||
            !authProvider.isUserFetched)) {
      print(
        "AuthWrapper: Mostrando loadingScreen (condição principal)",
      ); 
      return loadingScreen;
    }

    if (authProvider.currentUser != null &&
        authProvider.authStatus == AuthStatus.authenticated &&
        authProvider.isUserFetched) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
         Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
         Provider.of<DiscountProvider>(context, listen: false).fetchDiscounts();
        }
      });
      return const HomeScreen();
    } else if (authProvider.authStatus == AuthStatus.unauthenticated &&
        authProvider.isUserFetched) {
      return const LoginScreen();
    } else if (authProvider.authStatus == AuthStatus.error &&
        authProvider.isUserFetched) {
      print(
        "AuthWrapper: Erro de autenticação detectado - ${authProvider.errorMessage}",
      );
      return const LoginScreen();
    } else {
      print(
        "AuthWrapper: Mostrando loadingScreen (fallback) - Status: ${authProvider.authStatus}, UserFetched: ${authProvider.isUserFetched}",
      );
      return loadingScreen;
    }
  }
}