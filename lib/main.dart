import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splashscreen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'data/nutrition_data.dart';
import 'data/database_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load nutrition data
  await NutritionData.loadData();
  
  // Initialize database manager
  final dbManager = DatabaseManager();
  await dbManager.init();

  // Test apakah database berfungsi
  if (await dbManager.isDatabaseOpen()) {
    debugPrint('✅ Database ready');
  } else {
    debugPrint('❌ Database failed to open');
  }
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const FoodDetectionApp()); // Hapus parameter
}

class FoodDetectionApp extends StatelessWidget {
  const FoodDetectionApp({super.key}); // Hapus parameter isOnboardingCompleted

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
      initialRoute: '/splash', // Selalu mulai dari splash screen
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/splash': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}