import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  // الألوان الأساسية
  final Color primaryGreen = const Color(0xFF0F766E);
  final Color scaffoldBg = Colors.white;

  void _onSearch(String query) {
    debugPrint("جاري البحث عن: $query");
  }

  // دالة الحجز وإرسال البيانات للفايربيز
  void _handleBooking(String dName, String dJob, String doctorId) async {
    try {
      await FirebaseFirestore.instance.collection('Appointments').add({
        'doctorId': doctorId,
        'doctorName': dName,
        'specialty': dJob,
        'status': 'pending',
        'bookingTime': FieldValue.serverTimestamp(),
        'patientEmail': FirebaseAuth.instance.currentUser?.email,
        'patientName': FirebaseAuth.instance.currentUser?.displayName ?? 'مريض',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم إرسال طلب الحجز لـ $dName بنجاح"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل الحجز: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      drawer: _buildSideBar(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              "مرحباً، ${FirebaseAuth.instance.currentUser?.displayName ?? 'مريض'}",
              style: GoogleFonts.elMessiri(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'ابحث عن طبيب عيون...',
                prefixIcon: Icon(Icons.search, color: primaryGreen),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildHeader("مواعيدك"),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Appointments')
                  .where(
                    'patientEmail',
                    isEqualTo: FirebaseAuth.instance.currentUser?.email,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    "لا توجد مواعيد حالياً",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                var doc = snapshot.data!.docs.first;
                var data = doc.data() as Map<String, dynamic>;
                String status = data['status'] ?? 'pending';
                String timeStr = "في انتظار التأكيد من الطبيب";
                if (status == 'confirmed') {
                  timeStr =
                      "موعد مؤكد: ${data['appointmentDate'] ?? ''} ${data['appointmentTime'] ?? ''}";
                } else if (status == 'rejected') {
                  timeStr = "تم رفض الموعد";
                }

                return _buildStatusCard(data['doctorName'] ?? 'طبيب', timeStr);
              },
            ),
            const SizedBox(height: 30),
            _buildHeader("الأطباء المتاحين الآن"),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Doctors')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var doctors = snapshot.data!.docs;
                return Column(
                  children: doctors.map((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    return _buildDoctorItem(
                      data['name'] ?? 'بدون اسم',
                      data['Specialty'] ?? 'تخصص عام',
                      (data['Rating'] ?? 0.0).toString(),
                      onTap: () => _handleBooking(
                        data['name'] ?? 'بدون اسم',
                        data['Specialty'] ?? 'تخصص عام',
                        doc.id,
                      ),
                    );
                  }).toList(),
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
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStatusCard(String doctorName, String timeStr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "موعدك مع $doctorName",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("إلغاء", style: TextStyle(color: Colors.white70)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primaryGreen.withValues(alpha: 0.1),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "حجز",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryGreen),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF0F766E)),
            ),
            accountName: const Text(
              "مؤمن أبو القاسم",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              FirebaseAuth.instance.currentUser?.email ?? "لا يوجد بريد",
            ),
          ),
          ListTile(
            leading: Icon(Icons.edit, color: primaryGreen),
            title: const Text("تعديل الملف الشخصي"),
            onTap: () {
              Navigator.pop(context);
              _showEditProfileSheet(context);
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
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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

  Widget _buildProfileField(String label, String initialValue, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
