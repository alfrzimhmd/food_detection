import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/splashscreen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'data/nutrition_data.dart';
import 'providers/app_state.dart';

final RouteObserver<ModalRoute<void>> routeObserver = 
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NutritionData.loadData();
  
  // Initialize database dan provider
  final appState = AppState();
  await appState.init();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => appState,
      child: const FoodDetectionApp(),
    ),
  );
}

class FoodDetectionApp extends StatelessWidget {
  const FoodDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Detection',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF388E3C),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/splash': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
      },
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
    );
  }
}