// lib/main.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/models.dart';
import 'services/hive_service.dart';
import 'repositories/medication_repository.dart';
import 'providers/medicine_provider.dart';
import 'services/notification_service.dart';
import 'providers/side_effect_provider.dart';
import 'screens/main_dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> _requestNotificationPermissions() async {
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
  
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestNotificationPermissions();
  
  await Hive.initFlutter();
  Hive.registerAdapter(MedicineAdapter());
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(SideEffectAdapter());
  Hive.registerAdapter(CycleDayAdapter());
  Hive.registerAdapter(CycleSettingsAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  
  await Hive.openBox<Medicine>('medicines');
  await Hive.openBox<Reminder>('reminders');
  await Hive.openBox<SideEffect>('side_effects');
  await Hive.openBox<CycleDay>('cycle_days');
  await Hive.openBox<CycleSettings>('cycle_settings');
  await Hive.openBox<UserProfile>('user_profile');

  
  final hiveService = HiveService();
  if (hiveService.getProfile() == null) {
    await hiveService.saveProfile(UserProfile(
      name: 'Анна',
      notificationsEnabled: true,
      createdAt: DateTime.now(),
    ));
  }
  await NotificationService().init();

  runApp(const MedicationTrackerApp());
}

class MedicationTrackerApp extends StatelessWidget {
  const MedicationTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = HiveService();
    if (hiveService.getCycleSettings() == null) {
      hiveService.saveCycleSettings(CycleSettings(
        lastPeriodStart: DateTime.now().subtract(const Duration(days: 14)), // Примерно середина цикла
        cycleLength: 28,
        periodLength: 5,
      ));
    }
    final repository = MedicationRepository(hiveService);

    return MultiProvider(
      providers: [
        Provider<MedicationRepository>.value(value: repository),
        ChangeNotifierProvider(
          create: (context) => MedicineProvider(
            // ✅ ИСПРАВЛЕНО: _ → context
            Provider.of<MedicationRepository>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SideEffectProvider(
            Provider.of<MedicationRepository>(context, listen: false),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'МедТрекер',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const SplashScreen(), 
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: const Color(0xFFF4B4C9),
      scaffoldBackgroundColor: const Color(0xFF2D2428),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFF4B4C9),
        secondary: Color(0xFFE8A4B8),
        surface: Color(0xFF3A2F35),
        error: Color(0xFFEF9A9A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF3A2F35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}