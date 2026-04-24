import 'package:flutter/material.dart';
import 'package:frontend/pages/admin/admin_home.dart';
import 'package:frontend/pages/admin/user_history.dart';
import 'package:frontend/pages/admin/parking.dart';
import 'package:frontend/pages/admin/users_reports.dart';
import 'admin_profile.dart';

class AdminNavBar extends StatefulWidget {
  final String currentPage;

  const AdminNavBar({super.key, required this.currentPage});

  @override
  State<AdminNavBar> createState() => _AdminNavBarState();
}

class _AdminNavBarState extends State<AdminNavBar> {
  bool _isHomePressed = false;
  bool _isHistoryPressed = false;
  bool _isParkingPressed = false;
  bool _isReportsPressed = false;
  bool _isProfilePressed = false;

  @override
  Widget build(BuildContext context) {
    final isHomePage = widget.currentPage == 'home';
    final isHistoryPage = widget.currentPage == 'history';
    final isParkingPage = widget.currentPage == 'parking';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width * 0.9,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A38),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMainIconButton(
                  icon: Icons.history,
                  isActive: isHistoryPage,
                  isPressed: _isHistoryPressed,
                  onPressedChange:
                      (pressed) => setState(() => _isHistoryPressed = pressed),
                  onTap: () => _navigateTo(context, 'history'),
                ),
                _buildMainIconButton(
                  icon: Icons.local_parking,
                  isActive: isParkingPage,
                  isPressed: _isParkingPressed,
                  onPressedChange:
                      (pressed) => setState(() => _isParkingPressed = pressed),
                  onTap: () => _navigateTo(context, 'parking'),
                ),
                _buildMainIconButton(
                  icon: Icons.home,
                  isActive: isHomePage,
                  isPressed: _isHomePressed,
                  onPressedChange:
                      (pressed) => setState(() => _isHomePressed = pressed),
                  onTap: () => _navigateTo(context, 'home'),
                ),
                _buildMainIconButton(
                  icon: Icons.report,
                  isActive: false,
                  isPressed: _isReportsPressed,
                  onPressedChange:
                      (pressed) => setState(() => _isReportsPressed = pressed),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UsersReportsPage(),
                      ),
                    );
                  },
                ),
                _buildMainIconButton(
                  icon: Icons.person,
                  isActive: false,
                  isPressed: _isProfilePressed,
                  onPressedChange:
                      (pressed) => setState(() => _isProfilePressed = pressed),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminProfilePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainIconButton({
    required IconData icon,
    required bool isActive,
    required bool isPressed,
    required void Function(bool) onPressedChange,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPressedChange(true),
      onTapUp: (_) {
        onPressedChange(false);
        onTap();
      },
      onTapCancel: () => onPressedChange(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isPressed ? 0.9 : 1.0,
        child: _MainButton(icon: icon, isActive: isActive, isElevated: true),
      ),
    );
  }

  void _navigateTo(BuildContext context, String page) {
    if (widget.currentPage == page) return;

    Widget nextPage;
    switch (page) {
      case 'history':
        nextPage = const AdminDashboard();
        break;
      case 'home':
        nextPage = const AdminHomePage();
        break;
      case 'parking':
        nextPage = const ParkingPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextPage,
        transitionsBuilder:
            (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }
}

class _MainButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isElevated;

  const _MainButton({
    required this.icon,
    required this.isActive,
    required this.isElevated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.tealAccent : const Color(0xFF1E2A38),
        boxShadow:
            isElevated
                ? [
                  BoxShadow(
                    color: const Color(
                      0xFF000000,
                    ).withOpacity(isActive ? 0.4 : 0.3),
                    blurRadius: isActive ? 15 : 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
        border: Border.all(
          color: Colors.white.withOpacity(isActive ? 0.3 : 0.2),
          width: isActive ? 3 : 2,
        ),
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.black : Colors.white,
        size: 28,
      ),
    );
  }
}
