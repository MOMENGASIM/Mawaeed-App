import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  // الألوان الأساسية: أبيض وأخضر
  final Color primaryGreen = const Color(0xFF0F766E);
  final Color scaffoldBg = Colors.white;

  void _onSearch(String query) {
    print("جاري البحث عن: $query");
  }

  void _bookAppointment(String doctorName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم إرسال طلب الحجز لـ $doctorName"),
        backgroundColor: primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      drawer: _buildSideBar(context),
      // AppBar أنيق باللون الأبيض
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
            // 1. رسالة الترحيب
            Text(
              "مرحباً، مؤمن", // هنا حتربطها بـ Firebase Auth لاحقاً
              style: GoogleFonts.elMessiri(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const Text(
              "كيف يمكننا مساعدتك اليوم؟",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 25),

            // 2. حقل البحث (أبيض بحدود خضراء)
            TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'ابحث عن طبيب عيون...',
                prefixIcon: Icon(Icons.search, color: primaryGreen),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: primaryGreen.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 3. قسم المواعيد القادمة
            _buildHeader("مواعيدك القادمة"),
            const SizedBox(height: 12),
            _buildStatusCard(),

            const SizedBox(height: 30),

            // 4. قائمة الأطباء
            _buildHeader("الأطباء المتاحين الآن"),
            const SizedBox(height: 12),
            _buildDoctorItem("د. ليلى منصور", "استشاري شبكية", "4.9"),
            _buildDoctorItem("د. محمد عثمان", "جراحة عيون", "4.7"),
            _buildDoctorItem("د. سارة عادل", "فحص نظر", "4.8"),
          ],
        ),
      ),
    );
  }

  // ويلجيت العنوان
  Widget _buildHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.elMessiri(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  // كرت الموعد (أخضر خفيف)
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "موعدك القادم",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  "غداً، الساعة 10:00 صباحاً",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {}, // إضافة دالة إلغاء هنا
            child: const Text("إلغاء", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  // عنصر الطبيب في القائمة
  Widget _buildDoctorItem(String name, String job, String rate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryGreen.withOpacity(0.1),
            child: Icon(Icons.person, color: primaryGreen, size: 35),
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
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  Text(
                    rate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _bookAppointment(name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 0,
                  ),
                ),
                child: const Text("حجز", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. القائمة الجانبية (Side Bar)
  Widget _buildSideBar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0F766E)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF0F766E)),
            ),
            accountName: const Text(
              "مؤمن أبو القاسم",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text("momen@example.com"),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFF0F766E)),
            title: const Text("تعديل الملف الشخصي"),
            onTap: () {
              Navigator.pop(context);
              _showEditProfileSheet(context); // حنحتاج نضيف الفنكشن دي كمان
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "تسجيل الخروج",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 2. صفحة التعديل (Bottom Sheet)
  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "تعديل البيانات",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // الحقول زي ما في الصورة اللي رفعتها قبل شوية
              _buildProfileField("رقم الهاتف", "249912740956", Icons.phone),
              _buildProfileField("تاريخ الميلاد", "1990/08/26", Icons.cake),
              _buildProfileField("الجنسية", "سوداني", Icons.flag),
              _buildProfileField("الجنس", "ذكر", Icons.person_outline),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 3. شكل حقل الإدخال
  Widget _buildProfileField(String label, String initialValue, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF0F766E)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
