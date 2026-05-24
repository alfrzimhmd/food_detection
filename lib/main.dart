import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splashscreen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'data/nutrition_data.dart';
import 'data/database_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load nutrition data
  await NutritionData.loadData();
  
  // Initialize database manager (WAJIB sebelum cek onboarding)
  final dbManager = DatabaseManager();
  await dbManager.init();

  // Test apakah database berfungsi
  if (await dbManager.isDatabaseOpen()) {
    debugPrint('✅ Database ready');
  } else {
    debugPrint('❌ Database failed to open');
  }
  
  // Cek apakah user sudah memiliki profile di database
  final userProfile = await dbManager.getUserProfile();
  final hasUserProfile = userProfile != null;
  
  // Jika tidak ada profile, onboarding belum selesai
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_completed', hasUserProfile);
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(FoodDetectionApp(
    isOnboardingCompleted: hasUserProfile,
  ));
}

class FoodDetectionApp extends StatelessWidget {
  final bool isOnboardingCompleted;
  
  const FoodDetectionApp({super.key, required this.isOnboardingCompleted});

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
      debugShowCheckedModeBanner: false,
    );
  }
}