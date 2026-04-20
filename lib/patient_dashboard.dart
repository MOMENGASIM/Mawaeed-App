import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'localization.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final Color primaryGreen = const Color(0xFF0F766E);
  String searchQuery = "";

  // دالة البحث
  void _onSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  // دالة الحجز الذكية: بتمنع الحجز لو عندك موعد pending
  void _handleBooking(String dName, String dJob) async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;

      // 1. تشيك لو في حجز موجود أصلاً للمريض ده
      var existing = await FirebaseFirestore.instance
          .collection('Appointments')
          .where('patientEmail', isEqualTo: userEmail)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr("عفواً، لديك حجز معلق بالفعل. يجب إلغاؤه أولاً للحجز مرة أخرى."),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 2. إضافة الحجز لو الطريق فاضي
      await FirebaseFirestore.instance.collection('Appointments').add({
        'doctorName': dName,
        'specialty': dJob,
        'status': 'pending',
        'bookingTime': FieldValue.serverTimestamp(),
        'patientEmail': userEmail,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr("تم إرسال طلب الحجز لـ د. ") + dName + tr(" بنجاح")),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("فشل الحجز: ") + e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSideBar(context),
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: primaryGreen),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr("مرحباً، ") + (FirebaseAuth.instance.currentUser?.displayName ?? tr('مريض')),
              style: GoogleFonts.elMessiri(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 25),

            // حقل البحث
            TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: tr('ابحث عن طبيب...'),
                prefixIcon: Icon(Icons.search, color: primaryGreen),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),
            _buildHeader(tr("مواعيدك القادمة")),
            const SizedBox(height: 12),

            // عرض حالة الحجز الحالي (StreamBuilder)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Appointments')
                  .where(
                    'patientEmail',
                    isEqualTo: FirebaseAuth.instance.currentUser?.email,
                  )
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text(
                    tr("لا توجد مواعيد معلقة حالياً"),
                    style: const TextStyle(color: Colors.grey),
                  );
                }

                var doc = snapshot.data!.docs.first;
                var data = doc.data() as Map<String, dynamic>;

                return _buildStatusCard(
                  doctorName: data['doctorName'] ?? tr('طبيب'),
                  onCancel: () async {
                    await FirebaseFirestore.instance
                        .collection('Appointments')
                        .doc(doc.id)
                        .delete();
                  },
                );
              },
            ),

            const SizedBox(height: 30),
            _buildHeader(tr("الأطباء المتاحين الآن")),
            const SizedBox(height: 12),

            // قائمة الأطباء (StreamBuilder + Search Filter)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Doctors')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var doctors = snapshot.data!.docs;

                // تطبيق فلترة البحث
                var filteredDoctors = doctors.where((doc) {
                  String name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredDoctors.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredDoctors[index].data() as Map<String, dynamic>;
                    return _buildDoctorItem(
                      data['name'] ?? tr('بدون اسم'),
                      data['specialty'] ?? tr('تخصص عام'),
                      (data['rating'] ?? 0.0).toString(),
                      onTap: () => _handleBooking(
                        data['name'] ?? tr('بدون اسم'),
                        data['specialty'] ?? tr('تخصص عام'),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.elMessiri(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildStatusCard({
    required String doctorName,
    required VoidCallback onCancel,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr("موعدك مع د. ") + doctorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  tr("الحالة: في انتظار التأكيد"),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.white70),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorItem(
    String name,
    String job,
    String rate, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 5),
        ],
      ),
      child: Column(
        // استخدمنا Column عشان نحط الزر تحت البيانات
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFF0F766E),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      job,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 18),
                  Text(
                    rate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12), // مسافة قبل الزر
          SizedBox(
            width: double.infinity, // الزر ياخد العرض كامل
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF0F766E,
                ), // نفس لون المكنة الأخضر
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                tr("حجز موعد الآن"),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // الـ Sidebar (Drawer)
  Widget _buildSideBar(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryGreen),
            accountName: Text(
              FirebaseAuth.instance.currentUser?.displayName ?? tr("مريض"),
            ),
            accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ""),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(tr("تغيير الاسم")),
            onTap: () {
              Navigator.pop(context);
              _showChangeNameDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(tr("تغيير الإيميل")),
            onTap: () {
              Navigator.pop(context);
              _showChangeEmailDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text(tr("تغيير كلمة المرور")),
            onTap: () {
              Navigator.pop(context);
              _showChangePasswordDialog();
            },
          ),
          const Divider(),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: Text(tr("الوضع الليلي")),
                value: currentMode == ThemeMode.dark,
                onChanged: (value) async {
                  themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isDark', value);
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(tr("تسجيل الخروج"), style: const TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showChangeNameDialog() {
    final nameController = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr("تغيير الاسم")),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: tr("الاسم الجديد")),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr("إلغاء")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.updateDisplayName(nameController.text.trim());
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  try {
                    await FirebaseFirestore.instance.collection('Users').doc(uid).update({'name': nameController.text.trim()});
                  } catch (_) {}
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr("تم تغيير الاسم بنجاح"))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr("حدث خطأ: ") + e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(tr("تحديث"), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr("تغيير الإيميل")),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: tr("الإيميل الجديد")),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr("إلغاء")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.verifyBeforeUpdateEmail(emailController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr("تم إرسال رابط تأكيد للإيميل الجديد. يرجى التحقق منه."))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr("حدث خطأ: ") + e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(tr("تحديث"), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr("تغيير كلمة المرور")),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: tr("كلمة المرور الجديدة")),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr("إلغاء")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(passwordController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr("تم تغيير كلمة المرور بنجاح"))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr("حدث خطأ. قد تحتاج لتسجيل الدخول مرة أخرى.")), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(tr("تحديث"), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
