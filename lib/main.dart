import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'doctor_dashboard.dart';
import 'patient_dashboard.dart';

void main() async {
  // السطرين ديل هم اللي بيربطوا الشغل اللي عملناه في الـ Gradle بالسيرفر
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientDashboard(), // بيبدأ بصفحة اللوجن زي ما خططت في الـ Sequence
    ),
  );
}

class TeleAppointmentApp extends StatelessWidget {
  const TeleAppointmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light(useMaterial3: true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'حجز مواعيد مستشفى العيون',
      theme: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: const Color(0xFF0F766E),
          secondary: const Color(0xFFF59E0B),
          surface: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme).apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        ),
        scaffoldBackgroundColor: Colors.transparent,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0B1220),
          indicatorColor: const Color(0xFF1F2937),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white70;
            return GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white70;
            return IconThemeData(color: color);
          }),
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const RoleHubPage(),
    );
  }
}

class RoleHubPage extends StatefulWidget {
  const RoleHubPage({super.key});

  @override
  State<RoleHubPage> createState() => _RoleHubPageState();
}

class _RoleHubPageState extends State<RoleHubPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          PatientDashboard(),
          DoctorDashboard(),
          AdminDashboard(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'المريض',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'الطبيب',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'المسؤول',
          ),
        ],
      ),
    );
  }
}
