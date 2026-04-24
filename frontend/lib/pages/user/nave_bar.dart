import 'package:flutter/material.dart';
import 'package:frontend/pages/user/home.dart';
import 'package:frontend/pages/user/profile.dart';
import 'package:frontend/pages/user/search.dart';

class FloatingCircularNavBar extends StatefulWidget {
  final String currentPage;

  const FloatingCircularNavBar({super.key, required this.currentPage});

  @override
  State<FloatingCircularNavBar> createState() => _FloatingCircularNavBarState();
}

class _FloatingCircularNavBarState extends State<FloatingCircularNavBar> {
  bool _isHomePressed = false;
  bool _isSearchPressed = false;
  bool _isProfilePressed = false;

  @override
  Widget build(BuildContext context) {
    final isHomePage = widget.currentPage == 'home';
    final isSearchPage = widget.currentPage == 'search';
    final isProfilePage = widget.currentPage == 'profile';

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width * 0.8,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A38),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (isSearchPage)
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isSearchPressed = true),
                      onTapUp: (_) {
                        setState(() => _isSearchPressed = false);
                        _navigateTo(context, 'search');
                      },
                      onTapCancel:
                          () => setState(() => _isSearchPressed = false),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: _isSearchPressed ? 0.9 : 1.0,
                        child: _MainButton(
                          icon: Icons.search,
                          isActive: true,
                          isElevated: true,
                        ),
                      ),
                    ),
                  )
                else
                  _NavItem(
                    icon: Icons.search,
                    isActive: false,
                    onTap: () => _navigateTo(context, 'search'),
                  ),
                if (isHomePage)
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isHomePressed = true),
                      onTapUp: (_) {
                        setState(() => _isHomePressed = false);
                        _navigateTo(context, 'home');
                      },
                      onTapCancel: () => setState(() => _isHomePressed = false),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: _isHomePressed ? 0.9 : 1.0,
                        child: _MainButton(
                          icon: Icons.home,
                          isActive: true,
                          isElevated: true,
                        ),
                      ),
                    ),
                  )
                else
                  _NavItem(
                    icon: Icons.home,
                    isActive: false,
                    onTap: () => _navigateTo(context, 'home'),
                  ),
                if (isProfilePage)
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: GestureDetector(
                      onTapDown:
                          (_) => setState(() => _isProfilePressed = true),
                      onTapUp: (_) {
                        setState(() => _isProfilePressed = false);
                        _navigateTo(context, 'profile');
                      },
                      onTapCancel:
                          () => setState(() => _isProfilePressed = false),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: _isProfilePressed ? 0.9 : 1.0,
                        child: _MainButton(
                          icon: Icons.person,
                          isActive: true,
                          isElevated: true,
                        ),
                      ),
                    ),
                  )
                else
                  _NavItem(
                    icon: Icons.person,
                    isActive: false,
                    onTap: () => _navigateTo(context, 'profile'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, String page) {
    if (widget.currentPage == page) return;

    switch (page) {
      case 'search':
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const SearchPage(),
            transitionsBuilder:
                (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
        break;
      case 'home':
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomePage(),
            transitionsBuilder:
                (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
        break;
      case 'profile':
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ProfilePage(),
            transitionsBuilder:
                (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
        break;
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isActive
                  ? Colors.tealAccent.withOpacity(0.2)
                  : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.tealAccent : Colors.white70,
          size: isActive ? 30 : 28,
        ),
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
      width: isElevated ? 60 : 50,
      height: isElevated ? 60 : 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.tealAccent : const Color(0xFF1E2A38),
        boxShadow:
            isElevated
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isActive ? 0.4 : 0.3),
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
