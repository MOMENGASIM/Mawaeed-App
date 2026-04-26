import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'main.dart';
import 'localization.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final Color primaryGreen = const Color(0xFF2563EB);
  final Color navyColor = const Color(0xFF001529);

  // 1. دالة تحديث الحالة (قبول/رفض) مع الفايربيز
  Future<void> _updateStatus(
    String docId,
    String patientName,
    String status,
  ) async {
    try {
      String? appointmentTime;
      String? appointmentDate;
      Timestamp? appointmentTimestamp;

      if (status == "قبول") {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate == null) return;

        if (!mounted) return;
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime == null) return;

        if (!mounted) return;
        appointmentTime = pickedTime.format(context);
        appointmentDate =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

        DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        appointmentTimestamp = Timestamp.fromDate(fullDateTime);
      }

      Map<String, dynamic> updateData = {
        'status': status == "قبول" ? 'confirmed' : 'rejected',
      };
      if (appointmentTime != null) {
        updateData['appointmentTime'] = appointmentTime;
        updateData['appointmentDate'] = appointmentDate;
        updateData['appointmentTimestamp'] = appointmentTimestamp;
      }

      await FirebaseFirestore.instance
          .collection('Appointments')
          .doc(docId)
          .update(updateData);

      if (status == "قبول") {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        var docRef = FirebaseFirestore.instance.collection('Doctors').doc(uid);
        var docSnap = await docRef.get();
        if (docSnap.exists) {
          double currentRating =
              (docSnap.data()?['rating'] ?? docSnap.data()?['Rating'] ?? 0.0)
                  .toDouble();
          double newRating = currentRating + 0.1;
          if (newRating > 5.0) newRating = 5.0;
          await docRef.update({
            'rating': double.parse(newRating.toStringAsFixed(1)),
            'Rating': double.parse(newRating.toStringAsFixed(1)),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr("تم ") + tr(status) + tr(" موعد: ") + patientName),
            backgroundColor: status == "قبول" ? primaryGreen : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("خطأ في التحديث: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSideBar(context),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF001529), Color(0xFF000B18)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          tr("لوحة تحكم الطبيب"),
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white.withAlpha(50),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Appointments')
            .where(
              'doctorId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var allDocs = snapshot.hasData ? snapshot.data!.docs : [];
          var pendingDocs = allDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'pending';
          }).toList();
          var confirmedDocs = allDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'confirmed';
          }).toList();

          int count = pendingDocs.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Doctors')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, docSnap) {
                    Color statusColor = Colors.grey;
                    String tooltip = "غير معروف";
                    if (docSnap.hasData && docSnap.data!.exists) {
                      var data = docSnap.data!.data() as Map<String, dynamic>?;
                      var isApproved = data?['isApproved'];
                      if (isApproved == true || isApproved == null) {
                        statusColor = Colors.green;
                        tooltip = "حساب معتمد";
                      } else if (isApproved == false) {
                        statusColor = Colors.orange;
                        tooltip = "قيد المراجعة";
                      } else if (isApproved == 'rejected') {
                        statusColor = Colors.red;
                        tooltip = "مرفوض";
                      }
                    }
                    return Row(
                      children: [
                        Text(
                          tr("مرحباً د. ") +
                              (FirebaseAuth.instance.currentUser?.displayName ??
                                  tr("طبيب")),
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: tooltip,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Text(
                  tr("لديك ") + count.toString() + tr(" طلبات جديدة اليوم"),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 25),

                Row(
                  children: [
                    _buildStatCard(
                      tr("إجمالي الحجوزات"),
                      "${allDocs.length}",
                      Icons.calendar_month,
                    ),
                    const SizedBox(width: 15),
                    _buildStatCard(tr("طلبات جديدة"), "$count", Icons.people),
                  ],
                ),
                const SizedBox(height: 30),

                Text(
                  tr("طلبات الحجز المعلقة"),
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                if (pendingDocs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: Text(tr("لا توجد طلبات معلقة حالياً")),
                    ),
                  )
                else
                  ...pendingDocs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildRequestItem(
                      doc.id,
                      data['patientName'] ?? tr("مريض"),
                      data['date'] ?? tr("اليوم"),
                      data['reason'] ?? tr("فحص"),
                      true,
                    );
                  }),

                const SizedBox(height: 30),
                Text(
                  tr("المواعيد المؤكدة"),
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                if (confirmedDocs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: Text(tr("لا توجد مواعيد مؤكدة حالياً")),
                    ),
                  )
                else
                  ...confirmedDocs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String date = data['appointmentDate'] ?? tr("اليوم");
                    String time = data['appointmentTime'] ?? "";
                    return _buildRequestItem(
                      doc.id,
                      data['patientName'] ?? tr("مريض"),
                      date,
                      time.isNotEmpty ? time : tr("فحص"),
                      false,
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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

  Widget _buildRequestItem(
    String docId,
    String name,
    String time,
    String reason,
    bool isPending,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryGreen.withAlpha(26),
                child: const Icon(Icons.person_outline),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "$time - $reason",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (!isPending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tr("مؤكد"),
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (isPending) ...[
            const Divider(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(docId, name, "رفض"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      tr("رفض"),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(docId, name, "قبول"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      tr("قبول"),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF001529), Color(0xFF000B18)],
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.medical_services,
                size: 40,
                color: Color(0xFF2563EB),
              ),
            ),
            accountName: Text(
              tr("دكتور"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ""),
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
                  themeNotifier.value = value
                      ? ThemeMode.dark
                      : ThemeMode.light;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isDark', value);
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              tr("تسجيل الخروج"),
              style: const TextStyle(color: Colors.red),
            ),
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
    final nameController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName,
    );
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
                await FirebaseAuth.instance.currentUser?.updateDisplayName(
                  nameController.text.trim(),
                );
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(uid)
                        .update({'name': nameController.text.trim()});
                  } catch (_) {}
                  try {
                    await FirebaseFirestore.instance
                        .collection('Doctors')
                        .doc(uid)
                        .update({'name': nameController.text.trim()});
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
                    SnackBar(
                      content: Text(tr("حدث خطأ: ") + e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              tr("تحديث"),
              style: const TextStyle(color: Colors.white),
            ),
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
                await FirebaseAuth.instance.currentUser
                    ?.verifyBeforeUpdateEmail(emailController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr(
                          "تم إرسال رابط تأكيد للإيميل الجديد. يرجى التحقق منه.",
                        ),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr("حدث خطأ: ") + e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              tr("تحديث"),
              style: const TextStyle(color: Colors.white),
            ),
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
                await FirebaseAuth.instance.currentUser?.updatePassword(
                  passwordController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr("تم تغيير كلمة المرور بنجاح"))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr("حدث خطأ. قد تحتاج لتسجيل الدخول مرة أخرى."),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              tr("تحديث"),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
