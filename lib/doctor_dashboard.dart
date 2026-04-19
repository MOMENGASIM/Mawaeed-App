import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final Color primaryGreen = const Color(0xFF0F766E);

  // دالة لتغيير حالة الموعد (قبول/رفض)
  void _updateAppointmentStatus(String patientName, String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم $status موعد المريض: $patientName"),
        backgroundColor: status == "قبول" ? primaryGreen : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "لوحة تحكم الطبيب",
          style: GoogleFonts.elMessiri(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: primaryGreen.withOpacity(0.1),
            child: Icon(Icons.person, color: primaryGreen),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ترحيب وإحصائيات سريعة
            Text(
              "مرحباً د. أحمد",
              style: GoogleFonts.elMessiri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const Text(
              "لديك 5 مواعيد جديدة اليوم",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // 2. كروت الإحصائيات (ملخص سريع)
            Row(
              children: [
                _buildStatCard("إجمالي الحجوزات", "128", Icons.calendar_month),
                const SizedBox(width: 15),
                _buildStatCard("مرضى اليوم", "5", Icons.people),
              ],
            ),
            const SizedBox(height: 30),

            // 3. قائمة طلبات الحجز القادمة
            Text(
              "طلبات الحجز المعلقة",
              style: GoogleFonts.elMessiri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            _buildAppointmentRequest("مؤمن أبو القاسم", "10:30 ص", "فحص دوري"),
            _buildAppointmentRequest("عمر خالد", "11:15 ص", "متابعة عملية"),
            _buildAppointmentRequest("سارة يوسف", "12:00 م", "استشارة فورية"),
          ],
        ),
      ),
    );
  }

  // ويلجيت الإحصائيات الصغيرة
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryGreen),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ويلجيت طلب الموعد (مع زراير قبول ورفض)
  Widget _buildAppointmentRequest(
    String patientName,
    String time,
    String reason,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryGreen.withOpacity(0.1),
                child: const Icon(Icons.person_outline),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "$time - $reason",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateAppointmentStatus(patientName, "رفض"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("رفض", style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _updateAppointmentStatus(patientName, "قبول"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "قبول",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
