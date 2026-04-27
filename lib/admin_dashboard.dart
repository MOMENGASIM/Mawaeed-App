import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'main.dart';
import 'localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final Color adminColor = const Color(0xFF2563EB); // الأزرق المعتمد من اللوجو
  final Color navyColor = const Color(0xFF001529);

  @override
  void dispose() {
    super.dispose();
  }

  // دالة اختيار ورفع الصورة الشخصية للمسؤول
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    try {
      File file = File(image.path);
      String uid = FirebaseAuth.instance.currentUser!.uid;

      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_pics')
          .child('$uid.jpg');

      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      UploadTask uploadTask = ref.putFile(file, metadata);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);

      // تحديث في مجموعة المستخدمين (لأن المسؤول مخزن في Users)
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({
        'profilePic': downloadUrl,
      });

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("تم تحديث الصورة الشخصية بنجاح"))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr("فشل رفع الصورة: ") + e.toString()),
            backgroundColor: Colors.red,
          ),
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
          tr("لوحة الإدارة"),
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              bool? confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(tr("تسجيل الخروج")),
                  content: Text(tr("هل أنت متأكد أنك تريد تسجيل الخروج؟")),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(tr("تراجع")),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        tr("تأكيد"),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Complaints')
            .where('isRead', isEqualTo: false)
            .snapshots(),
        builder: (context, complaintsSnapshot) {
          int pendingComplaints = complaintsSnapshot.hasData
              ? complaintsSnapshot.data!.docs.length
              : 0;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Doctors')
                .where('isApproved', isEqualTo: false)
                .snapshots(),
            builder: (context, doctorsSnapshot) {
              var pendingDoctors = doctorsSnapshot.hasData
                  ? doctorsSnapshot.data!.docs
                  : [];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(tr("إحصائيات النظام")),
                    const SizedBox(height: 15),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Users')
                              .where('role', isEqualTo: 'Patient')
                              .snapshots(),
                          builder: (context, snapshot) {
                            String count = snapshot.hasData
                                ? snapshot.data!.docs.length.toString()
                                : "...";
                            return _buildSummaryCard(
                              tr("إجمالي المرضى"),
                              count,
                              Icons.person_add,
                              Colors.blue,
                            );
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Doctors')
                              .snapshots(),
                          builder: (context, snapshot) {
                            String count = snapshot.hasData
                                ? snapshot.data!.docs.length.toString()
                                : "...";
                            return _buildSummaryCard(
                              tr("الأطباء"),
                              count,
                              Icons.medical_services,
                              Colors.orange,
                            );
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Appointments')
                              .where(
                                'bookingTime',
                                isGreaterThanOrEqualTo: Timestamp.fromDate(
                                  DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                  ),
                                ),
                              )
                              .snapshots(),
                          builder: (context, snapshot) {
                            String count = snapshot.hasData
                                ? snapshot.data!.docs.length.toString()
                                : "...";
                            return _buildSummaryCard(
                              tr("حجوزات اليوم"),
                              count,
                              Icons.book_online,
                              adminColor,
                            );
                          },
                        ),
                        _buildSummaryCard(
                          tr("شكاوى معلقة"),
                          "$pendingComplaints",
                          Icons.report_problem,
                          Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 2. إدارة المدفوعات وتأكيد الحجوزات
                    _buildHeader(tr("تأكيدات الحجوزات (المدفوعات)")),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Appointments')
                          .where('status', isEqualTo: 'awaiting_admin_approval')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text(
                            tr("لا توجد دفعات بانتظار التأكيد حالياً"),
                            style: const TextStyle(color: Colors.grey),
                          );
                        }
                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            return _buildPaymentApprovalTile(doc.id, data);
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // 3. إدارة الأطباء (طلبات الانضمام)
                    _buildHeader(tr("طلبات انضمام أطباء جدد")),
                    const SizedBox(height: 12),
                    if (pendingDoctors.isEmpty)
                      Text(
                        tr("لا توجد طلبات معلقة حالياً"),
                        style: const TextStyle(color: Colors.grey),
                      )
                    else
                      ...pendingDoctors.map((doc) {
                        Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;
                        return _buildRequestTile(
                          doc.id,
                          data['name'] ?? tr("طبيب بدون اسم"),
                          data['specialty'] ?? tr("تخصص عام"),
                          data['cv'] ?? tr("لا توجد سيرة ذاتية"),
                        );
                      }),

                    const SizedBox(height: 30),

                    // 4. الشكاوى والمقترحات
                    _buildHeader(tr("الشكاوى والمقترحات")),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Complaints')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, allComplaintsSnap) {
                        if (!allComplaintsSnap.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        var complaints = allComplaintsSnap.data!.docs;
                        if (complaints.isEmpty)
                          return Text(
                            tr("لا توجد شكاوى حالياً"),
                            style: const TextStyle(color: Colors.grey),
                          );
                        return Column(
                          children: complaints.map((doc) {
                            Map<String, dynamic> data =
                                doc.data() as Map<String, dynamic>;
                            return Card(
                              color: data['isRead'] == true
                                  ? Theme.of(context).cardColor
                                  : Colors.red.withAlpha(13),
                              child: ListTile(
                                title: Text(data['patientName'] ?? tr("مريض")),
                                subtitle: Text(data['complaintText'] ?? ""),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.check_circle,
                                    color: data['isRead'] == true
                                        ? Colors.grey
                                        : Colors.green,
                                  ),
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('Complaints')
                                        .doc(doc.id)
                                        .update({'isRead': true});
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // 4. أزرار التحكم السريع
                    _buildHeader(tr("إجراءات سريعة")),
                    const SizedBox(height: 12),
                    _buildAdminAction(
                      Icons.add_moderator,
                      tr("إضافة مدير للنظام"),
                    ),
                    _buildAdminAction(
                      Icons.analytics,
                      tr("تصدير تقارير الأداء"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
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
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha(26)),
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
  Widget _buildRequestTile(
    String docId,
    String name,
    String spec,
    String docs,
  ) {
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
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('Doctors')
                    .doc(docId)
                    .update({'isApproved': true});
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('Doctors')
                    .doc(docId)
                    .update({'isApproved': 'rejected'});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentApprovalTile(String docId, Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.receipt_long, color: Colors.blue),
        ),
        title: Text(
          data['patientName'] ?? tr("مريض"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${tr("مع دكتور:")} ${data['doctorName']}"),
            const SizedBox(height: 4),
            Text(
              "${tr("رقم العملية:")} ${data['referenceNumber'] ?? tr("غير متوفر")}",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('Appointments')
                    .doc(docId)
                    .update({
                      'status': 'confirmed',
                      'isConfirmedByAdmin': true,
                    });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr("تم تأكيد الحجز بنجاح"))),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('Appointments')
                    .doc(docId)
                    .update({
                      'status': 'rejected',
                      'isConfirmedByAdmin': false,
                    });
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(tr("تم رفض الحجز"))));
                }
              },
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
        tileColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: adminColor),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {},
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
            currentAccountPicture: GestureDetector(
              onTap: _pickAndUploadImage,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    FirebaseAuth.instance.currentUser?.photoURL != null
                    ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                    : null,
                child: FirebaseAuth.instance.currentUser?.photoURL == null
                    ? const Icon(
                        Icons.admin_panel_settings,
                        size: 40,
                        color: Color(0xFF2563EB),
                      )
                    : null,
              ),
            ),
            accountName: Text(
              FirebaseAuth.instance.currentUser?.displayName ?? tr("المسؤول"),
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
            style: ElevatedButton.styleFrom(backgroundColor: adminColor),
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
            style: ElevatedButton.styleFrom(backgroundColor: adminColor),
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
            style: ElevatedButton.styleFrom(backgroundColor: adminColor),
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
