import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // متغير لتحديد الدور (null يعني لسه ما اختار)
  String? selectedRole;
  final Color primaryGreen = const Color(0xFF0F766E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار بسيط أو نص ترحيبي
              Icon(Icons.health_and_safety, size: 80, color: primaryGreen),
              const SizedBox(height: 10),
              Text(
                "إنشاء حساب جديد",
                style: GoogleFonts.elMessiri(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // داخل children: [ ... ]
              const SizedBox(height: 20),
              if (selectedRole == null) ...[
                // 1. واجهة اختيار الدور (بتظهر في البداية فقط)
                Text(
                  "سجل كـ:",
                  style: GoogleFonts.elMessiri(
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
                      "التسجيل كـ $selectedRole",
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField("الاسم الكامل", Icons.person_outline),
                _buildTextField("البريد الإلكتروني", Icons.email_outlined),
                _buildTextField(
                  "كلمة المرور",
                  Icons.lock_outline,
                  isPass: true,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "إنشاء حساب",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 45, color: color),
              const SizedBox(height: 10),
              Text(
                role,
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
  Widget _buildTextField(String hint, IconData icon, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        obscureText: isPass,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryGreen),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
