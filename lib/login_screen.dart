import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'doctor_dashboard.dart';
import 'patient_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  String? selectedRole;
  void _navigateToDashboard() {
    String user = _userController.text.trim().toLowerCase();

    if (user == "admin") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    } else if (user == "doctor") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DoctorDashboard()),
      );
      // هنا استبدل DoctorDashboard باسم الكلاس الحقيقي عندك لواجهة الدكتور
      // Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorDashboard()));
    } else if (user == "patient") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PatientDashboard()),
      );
      // هنا لواجهة المريض
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استخدمنا backgroundColor لضمان عدم ظهور شاشة بيضاء فاقعة
      backgroundColor: const Color(0xFFF8FAFF),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // 1. الدائرة الديكورية في الخلفية
            Positioned(
              top: -50,
              right: -50,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: const Color(0xFF147A74).withOpacity(0.05),
              ),
            ),

            // 2. المحتوى الأساسي
            Center(
              // لضمان توسيط كل شيء في الشاشة
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // الأيقونة الطبية
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

                      // حقل اختيار نوع الحساب (Dropdown)
                      Container(
                        width:
                            MediaQuery.of(context).size.width *
                            0.8, // عرض متناسق
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
                          // استايل القائمة نفسها عند الفتح
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          value: selectedRole,
                          items: ['Admin', 'Doctor', 'Patient'].map((
                            String role,
                          ) {
                            return DropdownMenuItem<String>(
                              value: role,
                              alignment: AlignmentDirectional.center,
                              child: Text(
                                role,
                                style: const TextStyle(
                                  color: Color(0xFF0D2137),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedRole = newValue;
                              _userController.text = newValue!.toLowerCase();
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 25),

                      // زر الدخول
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: ElevatedButton(
                          onPressed: _navigateToDashboard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF147A74),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "دخول",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
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
