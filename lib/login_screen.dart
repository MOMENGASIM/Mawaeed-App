import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard.dart';
import 'doctor_dashboard.dart';
import 'patient_dashboard.dart';
import 'sign_up_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? selectedRole;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  // --- إضافة كود الذاكرة هنا ---
  @override
  void initState() {
    super.initState();
    _checkSavedRole();
  }

  Future<void> _checkSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('my_role');
    if (role != null) {
      setState(() {
        selectedRole = role;
      });
    }
  }

  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_role', role);
  }

  // الوظيفة الأساسية لتسجيل الدخول والتحقق
  Future<void> _handleLogin() async {
    // 1. التحقق من المدخلات
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء إدخال الإيميل وكلمة المرور")),
      );
      return;
    }

    // 2. التحقق من اختيار النوع (Role)
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء اختيار نوع الحساب أولاً")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 3. محاولة تسجيل الدخول عبر Firebase
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      if (userCredential.user != null) {
        if (!mounted) return;

        // 4. التوجيه بناءً على الـ Role
        Widget nextScreen;
        if (selectedRole == "Admin") {
          nextScreen = const AdminDashboard();
        } else if (selectedRole == "Doctor") {
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
      // هنا "الجاسوس" حيطبع ليك السبب الحقيقي في الـ Console تحت
      print("🚨 خطأ من فايربيز (الكود): ${e.code}");
      print("🚨 رسالة الخطأ: ${e.message}");

      if (!mounted) return;

      // رسائل تنبيهية للمستخدم حسب نوع الخطأ
      String errorMessage = "حدث خطأ أثناء تسجيل الدخول";

      if (e.code == 'user-not-found') {
        errorMessage = "هذا الحساب غير موجود";
      } else if (e.code == 'wrong-password') {
        errorMessage = "كلمة المرور غير صحيحة";
      } else if (e.code == 'network-request-failed') {
        errorMessage = "تأكد من اتصالك بالإنترنت";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "محاولات كثيرة خاطئة، جرب لاحقاً";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      // لأي أخطاء برمجية أخرى
      print("🚨 خطأ عام: $e");
    } finally {
      // الخطوة دي هي اللي بتضمن إن اللفة تقيف سواء نجح أو فشل
      if (mounted) {
        setState(() => isLoading = false);
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: const Color(0xFF147A74).withOpacity(0.05),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          size: 80,
                          color: Color(0xFF147A74),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "تسجيل الدخول",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D2137),
                        ),
                      ),
                      const SizedBox(height: 50),

                      if (selectedRole == null) ...[
                        Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            alignment: AlignmentDirectional.center,
                            decoration: const InputDecoration(
                              hintText: 'اختر نوع الحساب',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              border: InputBorder.none,
                            ),
                            items: ['Admin', 'Doctor', 'Patient'].map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedRole = val);
                                _saveRole(
                                  val,
                                ); // بنحفظ الاختيار طوالي أول ما يختار
                              }
                            },
                          ),
                        ),
                      ],

                      if (selectedRole != null) ...[
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Color(0xFF147A74),
                              ),
                              onPressed: () =>
                                  setState(() => selectedRole = null),
                            ),
                            Text(
                              'دخول كـ $selectedRole',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF147A74),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'الإيميل',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF147A74),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("ليس لديك حساب؟"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "سجل الآن",
                              style: TextStyle(
                                color: Color(0xFF147A74),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
