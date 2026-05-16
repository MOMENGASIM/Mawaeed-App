import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'doctor_dashboard.dart';
import 'patient_dashboard.dart';
import 'localization.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // متغير لتحديد الدور (null يعني لسه ما اختار)
  String? selectedRole;
  final Color primaryGreen = const Color(0xFF3B82F6);

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final specialtyController = TextEditingController();
  final cvController = TextEditingController();
  bool isLoading = false;
  bool _obscurePasswords = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    specialtyController.dispose();
    cvController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr("الرجاء ملء جميع الحقول"))));
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr("كلمات المرور غير متطابقة"))));
      return;
    }

    if (selectedRole == "طبيب" && specialtyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr("الرجاء إدخال التخصص الطبي"))));
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(
          nameController.text.trim(),
        );

        String roleEn = selectedRole == "طبيب" ? "Doctor" : "Patient";
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('my_role', roleEn);

        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userCredential.user!.uid)
            .set({
              'name': nameController.text.trim(),
              'email': emailController.text.trim(),
              'phone': phoneController.text.trim(),
              'role': roleEn,
            });

        if (roleEn == "Doctor") {
          await FirebaseFirestore.instance
              .collection('Doctors')
              .doc(userCredential.user!.uid)
              .set({
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'specialty': specialtyController.text.trim(),
                'cv': cvController.text.trim(),
                'rating': 0.0,
                'isApproved': false,
              });
        }

        if (!mounted) return;

        if (roleEn == "Doctor") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  "تم إنشاء الحساب بنجاح. ملفك الآن قيد المراجعة من قبل الإدارة.",
                ),
              ),
              backgroundColor: primaryGreen,
            ),
          );
        }

        Widget nextScreen = roleEn == "Doctor"
            ? const DoctorDashboard()
            : const PatientDashboard();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = tr("حدث خطأ أثناء إنشاء الحساب");
      if (e.code == 'email-already-in-use') {
        errorMessage = tr("هذا الإيميل مستخدم بالفعل");
      } else if (e.code == 'weak-password') {
        errorMessage = tr("كلمة المرور ضعيفة");
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // خلفية بيضاء أو كحلية حسب الوضع
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF000B18) : Colors.white,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF001D3D).withAlpha(200)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withAlpha(isDark ? 50 : 30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 50 : 15),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // اللوجو (العين)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset(
                        'assets/app_icon.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.remove_red_eye,
                              size: 50,
                              color: Color(0xFF2563EB),
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr("إنشاء حساب جديد"),
                      style: GoogleFonts.cairo(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // داخل children: [ ... ]
                    const SizedBox(height: 20),
                    if (selectedRole == null) ...[
                      // 1. واجهة اختيار الدور (بتظهر في البداية فقط)
                      Text(
                        tr("سجل كـ:"),
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          _buildRoleCard("مريض", Icons.person, Colors.blue),
                          const SizedBox(width: 15),
                          _buildRoleCard(
                            "طبيب",
                            Icons.medical_services,
                            primaryGreen,
                          ),
                        ],
                      ),
                    ] else ...[
                      // 2. واجهة البيانات (بتظهر لما يختار الدور)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 18),
                            onPressed: () => setState(
                              () => selectedRole = null,
                            ), // يرجع يختار الدور
                          ),
                          Text(
                            tr("التسجيل كـ ") + tr(selectedRole!),
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        tr("الاسم الكامل"),
                        Icons.person_outline,
                        controller: nameController,
                      ),
                      _buildTextField(
                        tr("البريد الإلكتروني"),
                        Icons.email_outlined,
                        controller: emailController,
                      ),
                      if (selectedRole == "طبيب") ...[
                        _buildTextField(
                          tr("التخصص الطبي (مثال: طبيب عيون)"),
                          Icons.medical_information_outlined,
                          controller: specialtyController,
                        ),
                        _buildTextField(
                          tr("السيرة الذاتية أو الخبرات"),
                          Icons.description_outlined,
                          controller: cvController,
                          maxLines: 3,
                        ),
                      ],
                      _buildTextField(
                        tr("رقم الهاتف"),
                        Icons.phone_outlined,
                        controller: phoneController,
                        isNumber: true,
                      ),
                      _buildTextField(
                        tr("كلمة المرور"),
                        Icons.lock_outline,
                        isPass: true,
                        controller: passwordController,
                      ),
                      _buildTextField(
                        tr("تأكيد كلمة المرور"),
                        Icons.lock_outline,
                        isPass: true,
                        controller: confirmPasswordController,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  tr("إنشاء حساب"),
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // كرت اختيار الدور
  Widget _buildRoleCard(String role, IconData icon, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withAlpha(13),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(77)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 45, color: color),
              const SizedBox(height: 10),
              Text(
                tr(role),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // حقل إدخال موحد
  Widget _buildTextField(
    String hint,
    IconData icon, {
    bool isPass = false,
    bool isNumber = false,
    int maxLines = 1,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPass ? _obscurePasswords : false,
        maxLines: isPass ? 1 : maxLines,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryGreen),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(
                    _obscurePasswords ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePasswords = !_obscurePasswords;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
