import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'localization.dart';
import 'notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  // حافظة للمواعيد التي تم جدولتها لمنع التكرار
  final Set<String> _scheduledAppointmentIds = {};

  // الألوان الأساسية
  final Color primaryGreen = const Color(
    0xFF2563EB,
  ); // الأزرق المعتمد من اللوجو
  final Color navyColor = const Color(0xFF001529);
  String searchQuery = "";
  final complaintController = TextEditingController();
  final _refNumberController = TextEditingController();

  @override
  void dispose() {
    complaintController.dispose();
    _refNumberController.dispose();
    super.dispose();
  }

  // دالة اختيار ورفع الصورة الشخصية
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

      // الحصول على النتيجة مباشرة من الـ Snapshot
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);

      // تحديث في مجموعة المرضى/المستخدمين
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

  void _submitComplaint() async {
    if (complaintController.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('Complaints').add({
        'patientId': FirebaseAuth.instance.currentUser?.uid,
        'patientEmail': FirebaseAuth.instance.currentUser?.email,
        'patientName': FirebaseAuth.instance.currentUser?.displayName,
        'complaintText': complaintController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      complaintController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr("تم إرسال شكواك بنجاح. سيتم مراجعتها من قبل الإدارة."),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error sending complaint: $e");
    }
  }

  void _onSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  // دالة الحجز وإرسال البيانات للفايربيز
  void _handleBooking(String dName, String dJob, String doctorId) async {
    try {
      var existing = await FirebaseFirestore.instance
          .collection('Appointments')
          .where(
            'patientEmail',
            isEqualTo: FirebaseAuth.instance.currentUser?.email,
          )
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  "لديك موعد نشط حالياً. يرجى إلغاء الموعد الحالي قبل حجز موعد جديد.",
                ),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('Appointments').add({
        'doctorId': doctorId,
        'doctorName': dName,
        'specialty': dJob,
        'status': 'pending',
        'bookingTime': FieldValue.serverTimestamp(),
        'patientEmail': FirebaseAuth.instance.currentUser?.email,
        'patientName': FirebaseAuth.instance.currentUser?.displayName ?? 'مريض',
        'fee': '20,000', // إضافة قيمة الحجز
        'referenceNumber': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr("تم إرسال طلب الحجز مع دكتور ") + dName + tr(" بنجاح"),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr("فشل الحجز: ") + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentDialog(BuildContext context, String appointmentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr("طرق الدفع المتاحة"),
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tr(
                "يرجى تحويل مبلغ 20,000 جنيه سوداني عبر إحدى الطرق التالية ثم إرفاق رقم العملية:",
              ),
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildPaymentMethodTile(
              "بنكك (Bankak)",
              "1234567",
              Icons.account_balance,
              Colors.green,
            ),
            _buildPaymentMethodTile(
              "أوكاش (O-Kash)",
              "0912345678",
              Icons.phone_android,
              Colors.orange,
            ),
            _buildPaymentMethodTile(
              "فوري (Fawry)",
              "987654321",
              Icons.qr_code,
              Colors.blue,
            ),
            const SizedBox(height: 25),
            Text(
              tr("أدخل رقم العملية (Reference Number):"),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _refNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: tr("مثلاً: 12345678"),
                filled: true,
                fillColor: Colors.grey.withAlpha(20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _submitReferenceNumber(appointmentId),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  tr("تأكيد إرسال الرقم"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    String title,
    String account,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  account,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, color: color),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: account));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(tr("تم نسخ الرقم"))));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitReferenceNumber(String appointmentId) async {
    String refNum = _refNumberController.text.trim();
    if (refNum.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr("الرجاء إدخال رقم العملية"))));
      return;
    }

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // تحديث الموعد في Firestore برقم العملية
      await FirebaseFirestore.instance
          .collection('Appointments')
          .doc(appointmentId)
          .update({
            'referenceNumber': refNum,
            'status': 'awaiting_admin_approval',
          });

      if (mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        Navigator.pop(context); // إغلاق نافذة الدفع
        _refNumberController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr("تم إرسال رقم العملية بنجاح، بانتظار موافقة الإدارة"),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr("فشل الإرسال: ") + e.toString()),
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
          tr("لوحة تحكم المريض"),
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
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
              tr("مرحباً، ") +
                  (FirebaseAuth.instance.currentUser?.displayName ??
                      tr('مريض')),
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: tr('ابحث عن طبيب عيون...'),

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
            _buildHeader(tr("مواعيدك")),
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
                  return Text(
                    tr("لا توجد مواعيد حالياً"),
                    style: const TextStyle(color: Colors.grey),
                  );
                }

                // جدولة إشعارات للمواعيد المؤكدة التي لها timestamp
                for (var doc in snapshot.data!.docs) {
                  var d = doc.data() as Map<String, dynamic>;
                  if (d['status'] == 'confirmed' &&
                      d['appointmentTimestamp'] != null &&
                      !_scheduledAppointmentIds.contains(doc.id)) {
                    final ts = d['appointmentTimestamp'] as Timestamp;
                    NotificationService().scheduleAppointmentReminder(
                      appointmentId: doc.id,
                      appointmentDateTime: ts.toDate(),
                      doctorName: d['doctorName'] ?? 'الطبيب',
                    );

                    // حفظ المعرف لمنع التكرار
                    _scheduledAppointmentIds.add(doc.id);
                  }
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String status = data['status'] ?? 'pending';
                    String timeStr = tr("في انتظار التأكيد من الطبيب");
                    if (status == 'confirmed') {
                      timeStr =
                          "موعد مؤكد: ${data['appointmentDate'] ?? ''} ${data['appointmentTime'] ?? ''}";
                    } else if (status == 'rejected') {
                      timeStr = tr("عذراً، تم رفض طلب الموعد من قبل الطبيب");
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        children: [
                          _buildStatusCard(
                            data['doctorName'] ?? 'طبيب',
                            timeStr,
                            doc.id,
                            status,
                          ),
                          if ((status == 'pending' ||
                                  status == 'awaiting_payment') &&
                              data['referenceNumber'] == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _showPaymentDialog(context, doc.id),
                                icon: const Icon(
                                  Icons.payment,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  tr("إدخال رقم العملية وتأكيد الدفع"),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  minimumSize: const Size(double.infinity, 45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            )
                          else if (status == 'awaiting_admin_approval')
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.hourglass_empty,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      tr("بانتظار تأكيد الإدارة للمدفوعات"),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 30),
            _buildHeader(tr("الأطباء المتاحين الآن")),

            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Doctors')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var doctors = snapshot.data!.docs.where((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  if (data['isApproved'] == false) return false;
                  String name = (data['name'] ?? '').toString().toLowerCase();
                  String specialty =
                      (data['specialty'] ?? data['Specialty'] ?? 'تخصص عام')
                          .toString()
                          .toLowerCase();

                  if (searchQuery.isEmpty) return true;
                  return name.contains(searchQuery) ||
                      specialty.contains(searchQuery);
                }).toList();

                if (doctors.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        tr("لم يتم العثور على أطباء يطابقون بحثك"),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: doctors.map((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    String specialty =
                        data['specialty'] ??
                        data['Specialty'] ??
                        tr('تخصص عام');
                    return _buildDoctorItem(
                      data['name'] ?? tr('بدون اسم'),
                      specialty,
                      (data['Rating'] ?? data['rating'] ?? 0.0).toString(),
                      onBook: () => _handleBooking(
                        data['name'] ?? tr('بدون اسم'),
                        specialty,
                        doc.id,
                      ),
                      onProfile: () => _showDoctorProfile(
                        context,
                        data['name'] ?? tr('بدون اسم'),
                        specialty,
                        (data['Rating'] ?? data['rating'] ?? 0.0).toString(),
                        data['cv'] ??
                            tr('لا توجد تفاصيل عن السيرة الذاتية أو الخبرات.'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            _buildHeader(tr("صندوق الشكاوى والمقترحات")),

            const SizedBox(height: 10),
            Text(
              tr(
                "إذا واجهتك أي مشكلة أو كان لديك مقترح لتحسين الخدمة، نرجو إرساله للإدارة:",
              ),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: complaintController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: tr("اكتب شكواك أو مقترحك هنا..."),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  tr("إرسال للإدارة"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
      style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildStatusCard(
    String doctorName,
    String timeStr,
    String docId,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: status == 'rejected' ? Colors.red.shade400 : primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            status == 'rejected' ? Icons.cancel_outlined : Icons.videocam,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr("موعدك مع ") + doctorName,
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
          if (status != 'rejected')
            TextButton(
              onPressed: () async {
                bool? confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(tr("إلغاء الموعد")),
                    content: Text(
                      tr("هل أنت متأكد من رغبتك في إلغاء هذا الموعد؟"),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(tr("تراجع")),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          tr("تأكيد الإلغاء"),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    // إلغاء إشعار التذكير أولاً
                    await NotificationService().cancelAppointmentReminder(
                      docId,
                    );
                    await FirebaseFirestore.instance
                        .collection('Appointments')
                        .doc(docId)
                        .delete();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr("تم إلغاء الموعد بنجاح"))),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr("حدث خطأ أثناء الإلغاء: ") + e.toString(),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(
                tr("إلغاء"),
                style: const TextStyle(color: Colors.white70),
              ),
            )
          else
            TextButton(
              onPressed: () async {
                try {
                  // إلغاء إشعار التذكير أولاً
                  await NotificationService().cancelAppointmentReminder(docId);
                  await FirebaseFirestore.instance
                      .collection('Appointments')
                      .doc(docId)
                      .delete();
                } catch (e) {
                  debugPrint("خطأ في حذف الموعد المرفوض: $e");
                }
              },
              child: Text(
                tr("إخفاء"),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorItem(
    String name,
    String job,
    String rate, {
    required VoidCallback onBook,
    required VoidCallback onProfile,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryGreen.withAlpha(26),
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
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),

                    // تمت إزالة قيمة الحجز من هنا ونقلها لنافذة الدفع بطلب المستخدم
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rate,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onProfile,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: primaryGreen),
                  ),
                  child: Text(
                    tr("الملف الشخصي"),
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    tr("حجز موعد"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDoctorProfile(
    BuildContext context,
    String name,
    String job,
    String rate,
    String cv,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: primaryGreen.withAlpha(26),
                  child: Icon(Icons.person, color: primaryGreen, size: 40),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        job,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rate,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Text(
              tr("السيرة الذاتية والخبرات"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                tr(cv),
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  tr("إغلاق"),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                        Icons.person,
                        size: 40,
                        color: Color(0xFF2563EB),
                      )
                    : null,
              ),
            ),
            accountName: Text(
              FirebaseAuth.instance.currentUser?.displayName ?? tr("مريض"),
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
