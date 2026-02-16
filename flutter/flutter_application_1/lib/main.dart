import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'controllers/simulation_controller.dart';
import 'screens/digital_twin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E1A),
    ),
  );
  runApp(const SolarAgriNeuroTwinApp());
}

class SolarAgriNeuroTwinApp extends StatelessWidget {
  const SolarAgriNeuroTwinApp({super.key});

  // === DESIGN TOKENS ===
  static const Color bgDeep = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF111827);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonMagenta = Color(0xFFFF00E5);
  static const Color solarGold = Color(0xFFFFD700);
  static const Color surfaceGlass = Color(0x1AFFFFFF);
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8892B0);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SimulationController(),
      child: MaterialApp(
        title: 'SolarAgri NeuroTwin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bgDeep,
          colorScheme: ColorScheme.dark(
            surface: bgDeep,
            primary: neonCyan,
            secondary: neonMagenta,
            tertiary: solarGold,
            onSurface: textPrimary,
          ),
          textTheme: GoogleFonts.outfitTextTheme(
            ThemeData.dark().textTheme,
          ).apply(
            bodyColor: textPrimary,
            displayColor: textPrimary,
          ),
          cardTheme: CardTheme(
            color: bgCard.withOpacity(0.6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: neonCyan.withOpacity(0.15),
            foregroundColor: neonCyan,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: neonCyan.withOpacity(0.4)),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              letterSpacing: 2,
            ),
          ),
        ),
        home: const DigitalTwinScreen(),
      ),
    );
  }
}
