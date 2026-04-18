import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        backgroundColor: const Color(0xFF147A74),
      ),
      body: Center(
        // السطر 23: نغيره لـ Center عشان يوسط كل شي
        child: SingleChildScrollView(
          // عشان لو الحقول كترت تقدر تعمل scroll
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // ده اللي بيوسط العناصر عمودياً
            children: [
              // حقل الإيميل (موجود عندك)
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),

              // حقل كلمة المرور (موجود عندك)
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 15),

              // حقل تأكيد كلمة المرور (الجديد)
              TextField(
                controller: _confirmPasswordController, // السطر 13 اللي عرفناه
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
              const SizedBox(height: 15),

              // حقل الـ Dropdown (اختيار الدور)
              DropdownButtonFormField<String>(
                hint: const Text('سجل كـ (مريض / دكتور)'),
                items: ['Patient', 'Doctor']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setState(() => selectedRole = val),
              ),
              const SizedBox(height: 30),

              // زر التسجيل الأخضر
              ElevatedButton(
                onPressed: () {
                  // هنا حنشيك لو الباسورد متطابق قبل ما نسجل
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF147A74),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'إكمال التسجيل',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
