import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/views/home/home_screen.dart';
import 'package:presenzo_app/views/profile/profile_screen.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const _AttendanceScreen(),
    const _HistoryScreen(),
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
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColor.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, -2),
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
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
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

class _AttendanceScreen extends StatelessWidget {
  const _AttendanceScreen();

  @override
  Widget build(BuildContext context) {
    return _TabPlaceholder(
      title: 'Presensi',
      description: 'Halaman check in dan check out akan ditaruh di sini.',
      icon: Icons.fingerprint,
    );
  }
}

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen();

  @override
  Widget build(BuildContext context) {
    return _TabPlaceholder(
      title: 'Riwayat',
      description: 'Daftar riwayat presensi bulanan akan ditampilkan di sini.',
      icon: Icons.history,
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _TabPlaceholder({
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
              decoration: const BoxDecoration(
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
