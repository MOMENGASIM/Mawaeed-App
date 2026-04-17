import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TeleAppointmentApp());
}

class TeleAppointmentApp extends StatelessWidget {
  const TeleAppointmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light(useMaterial3: true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'حجز مواعيد مستشفى العيون',
      theme: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: const Color(0xFF0F766E),
          secondary: const Color(0xFFF59E0B),
          surface: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme).apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        ),
        scaffoldBackgroundColor: Colors.transparent,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0B1220),
          indicatorColor: const Color(0xFF1F2937),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white70;
            return GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white70;
            return IconThemeData(color: color);
          }),
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const RoleHubPage(),
    );
  }
}

class RoleHubPage extends StatefulWidget {
  const RoleHubPage({super.key});

  @override
  State<RoleHubPage> createState() => _RoleHubPageState();
}

class _RoleHubPageState extends State<RoleHubPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          PatientDashboard(),
          DoctorDashboard(),
          AdminDashboard(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'المريض',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'الطبيب',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'المسؤول',
          ),
        ],
      ),
    );
  }
}

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0F766E);
    return RoleCanvas(
      gradient: const LinearGradient(
        colors: [Color(0xFFE0F2FE), Color(0xFFFFFBEB)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      bubbles: const [
        DecorBubble(top: -40, right: -30, size: 160, color: Color(0x330F766E)),
        DecorBubble(
          bottom: 120,
          left: -60,
          size: 200,
          color: Color(0x22F59E0B),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoleHeader(
            title: 'احجز موعد عيون عن بعد',
            subtitle: 'مستشفى مكة للعيون التخصصي',
            chipText: 'خدمة عيون فورية',
            accent: accent,
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.video_call, color: accent, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'موعدك التالي',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'غداً 10:30 ص مع د. ليلى منصور - شبكية',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_ios_new, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SearchField(hint: 'ابحث عن عيادة أو طبيب عيون'),
          const SizedBox(height: 24),
          SectionTitle(title: 'لمحة سريعة'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              StatPill(label: 'أطباء عيون متصلون', value: '42'),
              StatPill(label: 'متوسط الانتظار', value: '8 دقائق'),
              StatPill(label: 'جلسات العيون اليوم', value: '132'),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'الخدمات السريعة'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              ActionCard(
                title: 'احجز فحص نظر',
                subtitle: 'اختر العيادة والوقت الأنسب',
                icon: Icons.calendar_month,
                color: Color(0xFF0F766E),
              ),
              ActionCard(
                title: 'استشارة عيون الآن',
                subtitle: 'مكالمة فيديو مع طبيب عيون',
                icon: Icons.local_hospital,
                color: Color(0xFFF97316),
              ),
              ActionCard(
                title: 'نتائج الفحوصات',
                subtitle: 'تقارير الشبكية والقرنية',
                icon: Icons.folder_shared,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'عيادات العيون الأكثر طلباً'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              TagChip(label: 'شبكية'),
              TagChip(label: 'قرنية'),
              TagChip(label: 'زرق'),
              TagChip(label: 'عيون أطفال'),
              TagChip(label: 'تصحيح النظر'),
              TagChip(label: 'جراحة عيون'),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'أطباء مقترحون'),
          const SizedBox(height: 12),
          const DoctorCard(
            name: 'د. رامي القحطاني',
            specialty: 'استشاري شبكية',
            rating: '4.9',
            availability: 'متاح خلال 15 دقيقة',
          ),
          const SizedBox(height: 12),
          const DoctorCard(
            name: 'د. سلمى غانم',
            specialty: 'جراحة عيون',
            rating: '4.8',
            availability: 'متاح اليوم 6:00 م',
          ),
        ],
      ),
    );
  }
}

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF1E3A8A);
    return RoleCanvas(
      gradient: const LinearGradient(
        colors: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      bubbles: const [
        DecorBubble(top: -50, left: -20, size: 170, color: Color(0x331E3A8A)),
        DecorBubble(
          bottom: 150,
          right: -70,
          size: 220,
          color: Color(0x3322D3EE),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoleHeader(
            title: 'لوحة الطبيب',
            subtitle: 'مركز استشارات العيون المرئية',
            chipText: 'متاح الآن',
            accent: accent,
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.timer, color: accent, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أقرب جلسة',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'اليوم 2:45 م - متابعة حالة استشاري شبكيةية',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_fill, color: accent, size: 28),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'مؤشرات اليوم'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              StatPill(label: 'زيارات اليوم', value: '12'),
              StatPill(label: 'فحوصات فيديو', value: '5'),
              StatPill(label: 'رضا المرضى', value: '96%'),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'جدول الجلسات القادمة'),
          const SizedBox(height: 12),
          const ScheduleTile(
            time: '3:30 م',
            patient: 'نورة الهاجري',
            reason: 'متابعة ضغط العين',
          ),
          const SizedBox(height: 12),
          const ScheduleTile(
            time: '5:00 م',
            patient: 'سالم المطيري',
            reason: 'تحضير لعملية ليزر',
          ),
          const SizedBox(height: 12),
          const ScheduleTile(
            time: '6:15 م',
            patient: 'ريم العتيبي',
            reason: 'تقرير أشعة استشاري شبكيةية',
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'إجراءات سريعة'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              ActionCard(
                title: 'بدء فحص مرئي',
                subtitle: 'الاتصال بالمريض التالي',
                icon: Icons.videocam,
                color: Color(0xFF1E3A8A),
              ),
              ActionCard(
                title: 'الوصفات',
                subtitle: 'أوامر صرف الأدوية',
                icon: Icons.receipt_long,
                color: Color(0xFF0EA5E9),
              ),
              ActionCard(
                title: 'صور الشبكية',
                subtitle: 'آخر القياسات والصور',
                icon: Icons.monitor_heart,
                color: Color(0xFF14B8A6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0F172A);
    return RoleCanvas(
      gradient: const LinearGradient(
        colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      bubbles: const [
        DecorBubble(top: -60, right: -40, size: 190, color: Color(0x220F172A)),
        DecorBubble(
          bottom: 120,
          left: -70,
          size: 210,
          color: Color(0x22F59E0B),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoleHeader(
            title: 'لوحة إدارة مستشفى العيون',
            subtitle: 'متابعة التشغيل وجودة خدمات العيون',
            chipText: 'نظام مستقر',
            accent: accent,
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'أرقام اليوم'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              StatPill(label: 'حجوزات اليوم', value: '248'),
              StatPill(label: 'إلغاءات', value: '14'),
              StatPill(label: 'أطباء عيون متصلون', value: '37'),
              StatPill(label: 'الالتزام', value: '92%'),
            ],
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مركز المراقبة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'غرف الفحص تعمل بكفاءة 98%، وتوجد 3 طلبات اعتماد لأجهزة ليزر قيد المراجعة.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.analytics),
                        label: const Text('تقارير فورية'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.settings),
                        label: const Text('إدارة النظام'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'الإجراءات الإدارية'),
          const SizedBox(height: 12),
          const AdminActionTile(
            title: 'إدارة العيادات',
            subtitle: 'الجدولة، غرف الفحص، أجهزة الليزر',
            icon: Icons.apartment,
          ),
          const SizedBox(height: 12),
          const AdminActionTile(
            title: 'الموظفون والأطباء',
            subtitle: 'الاعتمادات، المناوبات، الصلاحيات',
            icon: Icons.people_alt,
          ),
          const SizedBox(height: 12),
          const AdminActionTile(
            title: 'طلبات الاعتماد',
            subtitle: 'مراجعة ملفات المرضى الجديدة',
            icon: Icons.verified_user,
          ),
          const SizedBox(height: 12),
          const AdminActionTile(
            title: 'التقارير والتحليلات',
            subtitle: 'مؤشرات الأداء والجودة',
            icon: Icons.bar_chart,
          ),
        ],
      ),
    );
  }
}

class RoleCanvas extends StatelessWidget {
  final Gradient gradient;
  final List<DecorBubble> bubbles;
  final Widget child;

  const RoleCanvas({
    super.key,
    required this.gradient,
    required this.bubbles,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: BoxDecoration(gradient: gradient)),
        ...bubbles,
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: child,
          ),
        ),
      ],
    );
  }
}

class DecorBubble extends StatelessWidget {
  final double? top;
  final double? right;
  final double? left;
  final double? bottom;
  final double size;
  final Color color;

  const DecorBubble({
    super.key,
    this.top,
    this.right,
    this.left,
    this.bottom,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      left: left,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class RoleHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String chipText;
  final Color accent;

  const RoleHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.chipText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            chipText,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.elMessiri(
            textStyle: Theme.of(context).textTheme.headlineSmall,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF475569)),
        ),
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  final String hint;

  const SearchField({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.elMessiri(
        textStyle: Theme.of(context).textTheme.titleLarge,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class StatPill extends StatelessWidget {
  final String label;
  final String value;

  const StatPill({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;

  const TagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String rating;
  final String availability;

  const DoctorCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.availability,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF0F766E).withOpacity(0.15),
            child: const Icon(Icons.person, color: Color(0xFF0F766E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  specialty,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  availability,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF0F766E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(height: 4),
              Text(
                rating,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ScheduleTile extends StatelessWidget {
  final String time;
  final String patient;
  final String reason;

  const ScheduleTile({
    super.key,
    required this.time,
    required this.patient,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                time,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_back_ios_new, size: 16),
        ],
      ),
    );
  }
}

class AdminActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AdminActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_back_ios_new, size: 16),
        ],
      ),
    );
  }
}
