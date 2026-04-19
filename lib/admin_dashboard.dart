import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final Color adminColor = const Color(0xFF0F766E); // الأخضر المعتمد

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "لوحة الإدارة",
          style: GoogleFonts.elMessiri(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Icon(Icons.admin_panel_settings, color: adminColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ملخص سريع بالأرقام الكبيرة
            _buildHeader("إحصائيات النظام"),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryCard(
                  "إجمالي المرضى",
                  "1,240",
                  Icons.person_add,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  "الأطباء",
                  "85",
                  Icons.medical_services,
                  Colors.orange,
                ),
                _buildSummaryCard(
                  "حجوزات اليوم",
                  "42",
                  Icons.book_online,
                  adminColor,
                ),
                _buildSummaryCard(
                  "شكاوى معلقة",
                  "3",
                  Icons.report_problem,
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 2. إدارة الأطباء (طلبات الانضمام)
            _buildHeader("طلبات انضمام أطباء جدد"),
            const SizedBox(height: 12),
            _buildRequestTile(
              "د. خالد عيسى",
              "جراحة عامة",
              "شهادة تخصص + ترخيص",
            ),
            _buildRequestTile("د. منى علي", "طب أطفال", "شهادة جامعية"),

            const SizedBox(height: 30),

            // 3. أزرار التحكم السريع
            _buildHeader("إجراءات سريعة"),
            const SizedBox(height: 12),
            _buildAdminAction(Icons.add_moderator, "إضافة مدير للنظام"),
            _buildAdminAction(Icons.analytics, "تصدير تقارير الأداء"),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.elMessiri(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  // كرت إحصائي صغير
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // طلب انضمام طبيب
  Widget _buildRequestTile(String name, String spec, String docs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$spec - $docs"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  // زر إجراء سريع
  Widget _buildAdminAction(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Colors.grey[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: adminColor),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {},
      ),
    );
  }
}
