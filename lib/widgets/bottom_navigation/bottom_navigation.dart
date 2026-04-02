import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/views/profile/profile_screen.dart';

class AttendanceBottomNavigation extends StatefulWidget {
  const AttendanceBottomNavigation({super.key});

  @override
  State<AttendanceBottomNavigation> createState() =>
      _AttendanceBottomNavigationState();
}

class _AttendanceBottomNavigationState
    extends State<AttendanceBottomNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions = <Widget>[
    const _DashboardHomePage(),
    const _AttendancePage(),
    const _HistoryPage(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundLight,
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColor.shadowLight,
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint_outlined),
              activeIcon: Icon(Icons.fingerprint),
              label: 'Presensi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppColor.primary,
          unselectedItemColor: AppColor.textHint,
          backgroundColor: AppColor.surface,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class _DashboardHomePage extends StatelessWidget {
  const _DashboardHomePage();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: 'Beranda',
      description:
          'Ringkasan presensi hari ini, status check-in, dan info lokasi.',
      icon: Icons.dashboard_outlined,
    );
  }
}

class _AttendancePage extends StatelessWidget {
  const _AttendancePage();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: 'Presensi',
      description: 'Halaman untuk check in dan check out karyawan.',
      icon: Icons.fingerprint,
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: 'Riwayat',
      description: 'Daftar riwayat presensi, izin, dan keterlambatan.',
      icon: Icons.receipt_long,
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _PlaceholderPage({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColor.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColor.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
