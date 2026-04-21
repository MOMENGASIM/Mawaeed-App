import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'doctor_dashboard.dart';
import 'patient_dashboard.dart';
import 'localization.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<bool> languageNotifier = ValueNotifier(false);

void main() async {
  // السطرين ديل هم اللي بيربطوا الشغل اللي عملناه في الـ Gradle بالسيرفر
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDark') ?? false;
  final isEnglish = prefs.getBool('isEnglish') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  languageNotifier.value = isEnglish;

  runApp(const TeleAppointmentApp());
}

class TeleAppointmentApp extends StatelessWidget {
  const TeleAppointmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light(useMaterial3: true);
    final darkBaseTheme = ThemeData.dark(useMaterial3: true);

    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isEnglish, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, ThemeMode currentMode, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: tr('حجز مواعيد مستشفى العيون'),
              themeMode: currentMode,
              darkTheme: darkBaseTheme.copyWith(
                colorScheme: darkBaseTheme.colorScheme.copyWith(
                  primary: const Color(0xFF0F766E),
                  secondary: const Color(0xFFF59E0B),
                  surface: const Color(0xFF1E293B),
                ),
                textTheme: GoogleFonts.cairoTextTheme(
                  darkBaseTheme.textTheme,
                ).apply(bodyColor: Colors.white, displayColor: Colors.white),
                scaffoldBackgroundColor: const Color(0xFF1E1E1E),
              ),
              theme: baseTheme.copyWith(
                colorScheme: baseTheme.colorScheme.copyWith(
                  primary: const Color(0xFF0F766E),
                  secondary: const Color(0xFFF59E0B),
                  surface: Colors.white,
                ),
                textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme)
                    .apply(
                      bodyColor: const Color(0xFF0F172A),
                      displayColor: const Color(0xFF0F172A),
                    ),
                scaffoldBackgroundColor: Colors.white,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
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
                textDirection: isEnglish
                    ? TextDirection.ltr
                    : TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              ),
              home: FirebaseAuth.instance.currentUser == null
                  ? const LoginScreen()
                  : FutureBuilder<String>(
                      future: _getUserRole(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }
                        String role = snapshot.data ?? 'Patient';
                        if (role == 'Admin') return const AdminDashboard();
                        if (role == 'Doctor') return const DoctorDashboard();
                        return const PatientDashboard();
                      },
                    ),
            );
          },
        );
      },
    );
  }

  Future<String> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('my_role');
    if (role != null) return role;

    // Fallback: check Firestore if not in SharedPreferences
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        var userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .get();
        if (userDoc.exists && userDoc.data()!.containsKey('role')) {
          role = userDoc.data()!['role'];
          await prefs.setString('my_role', role!);
          return role;
        }
        var docDoc = await FirebaseFirestore.instance
            .collection('Doctors')
            .doc(uid)
            .get();
        if (docDoc.exists) {
          await prefs.setString('my_role', 'Doctor');
          return 'Doctor';
        }
        if (FirebaseAuth.instance.currentUser?.email?.toLowerCase() ==
            'admin@admin.com') {
          await prefs.setString('my_role', 'Admin');
          return 'Admin';
        }
      } catch (e) {
        debugPrint("Error fetching role: $e");
      }
    }
    return 'Patient';
  }
}

class RoleHubPage extends StatefulWidget {
  const RoleHubPage({super.key});

  @override
  State<RoleHubPage> createState() => _RoleHubPageState();
}

class _RoleHubPageState extends State<RoleHubPage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          PatientDashboard(),
          DoctorDashboard(),
          AdminDashboard(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: tr('المريض'),
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: tr('الطبيب'),
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: tr('المسؤول'),
          ),
        ],
      ),
    );
  }
}
