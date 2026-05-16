import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// استيراد الشاشات - تأكد أن أسماء الملفات صحيحة في مشروعك
import 'admin_dashboard.dart';
import 'doctor_dashboard.dart';
import 'patient_dashboard.dart';
import 'sign_up_screen.dart'; // تأكد من وجود هذا الملف
import 'localization.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_role', role);
  }

  Future<void> _handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("الرجاء إدخال الإيميل وكلمة المرور"))),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;
        String role = "Patient"; // default

        try {
          var userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(uid)
              .get();
          if (userDoc.exists && userDoc.data()!.containsKey('role')) {
            role = userDoc.data()!['role'];
          } else {
            // Fallback for existing accounts
            var docDoc = await FirebaseFirestore.instance
                .collection('Doctors')
                .doc(uid)
                .get();
            if (docDoc.exists) {
              role = "Doctor";
            } else if (emailController.text.trim().toLowerCase() ==
                'admin@admin.com') {
              role = "Admin";
            }
          }
        } catch (e) {
          debugPrint("Error fetching role: $e");
        }

        await _saveRole(role);

        if (!mounted) return;

        Widget nextScreen;
        if (role == "Admin") {
          nextScreen = const AdminDashboard();
        } else if (role == "Doctor") {
          nextScreen = const DoctorDashboard();
        } else {
          nextScreen = const PatientDashboard();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("🚨 Firebase Error: ${e.code}");

      if (!mounted) return;

      String errorMessage = tr("حدث خطأ أثناء تسجيل الدخول");
      if (e.code == 'user-not-found') {
        errorMessage = tr("هذا الحساب غير موجود");
      } else if (e.code == 'wrong-password') {
        errorMessage = tr("كلمة المرور غير صحيحة");
      } else if (e.code == 'invalid-email') {
        errorMessage = tr("صيغة الإيميل غير صحيحة");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isEnglish, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          body: Stack(
            children: [
              // خلفية بيضاء مع تدرج خفيف في الأعلى
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF000B18) : Colors.white,
                ),
              ),
              if (!isDark)
                Positioned(
                  top: -100,
                  right: -100,
                  child: CircleAvatar(
                    radius: 200,
                    backgroundColor: const Color(0xFF3B82F6).withAlpha(15),
                  ),
                ),
              Positioned(
                top: 50,
                right: 20,
                child: TextButton.icon(
                  onPressed: () async {
                    languageNotifier.value = !languageNotifier.value;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isEnglish', languageNotifier.value);
                  },
                  icon: const Icon(Icons.language, color: Color(0xFF2563EB)),
                  label: Text(
                    tr("عربي"),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // اللوجو (العين)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withAlpha(50),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            'assets/app_icon.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.remove_red_eye,
                                  size: 100,
                                  color: Color(0xFF2563EB),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF001D3D).withAlpha(180)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(
                              0xFF3B82F6,
                            ).withAlpha(isDark ? 50 : 30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 50 : 15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              tr("تسجيل الدخول"),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF001529),
                              ),
                            ),
                            const SizedBox(height: 30),
                            TextField(
                              controller: emailController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: tr('الإيميل'),
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Color(0xFF3B82F6),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: tr('كلمة المرور'),
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Color(0xFF3B82F6),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF001529),
                                    Color(0xFF2563EB),
                                  ],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  minimumSize: const Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        tr('تسجيل الدخول'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tr("ليس لديك حساب؟"),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    tr("سجل الآن"),
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
