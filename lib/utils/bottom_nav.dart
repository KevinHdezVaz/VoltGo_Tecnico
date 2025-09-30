import 'package:Voltgo_app/data/services/ChatHistoryScreen.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart'; // ✅ AGREGAR
import 'package:Voltgo_app/ui/MenuPage/TechnicianReviewsScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Voltgo_app/ui/HistoryScreen/HistoryScreen.dart';
import 'package:Voltgo_app/ui/MenuPage/earnins/EarningsScreen.dart';
import 'package:Voltgo_app/ui/profile/SettingsScreen.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/ui/MenuPage/DashboardScreen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _pages = [
    const DriverDashboardScreen(),
    const TechnicianReviewsScreen(),
    const HistoryScreen(),
    const ChatHistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    print('BottomNavBar initialized with index: $_selectedIndex');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index && index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
      print('Navigated to index: $index');
    }
  }

  Widget _buildErrorBoundary({required Widget child}) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e, stackTrace) {
          print('Error rendering widget: $e\n$stackTrace');
          return Center(
            child: Text(
            "Error loading page", // ✅ LOCALIZADO
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              size: 25,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Scaffold(
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildErrorBoundary(child: _pages[_selectedIndex]),
      ),
      floatingActionButton: SizedBox(
        width: 64.0,
        height: 64.0,
        child: FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: () => _onItemTapped(0),
          backgroundColor: AppColors.primary,
          elevation: 6.0,
          shape: const CircleBorder(),
          child: const Icon(Icons.electric_car, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        color: AppColors.primary,
        elevation: 9.0,
        shadowColor: Colors.black.withOpacity(0.3),
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
              icon: Icons.star_border,
              label: l10n.reviews, // ✅ LOCALIZADO
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.history,
              label: l10n.history, // ✅ LOCALIZADO
              index: 2,
            ),
            const SizedBox(width: 80),
            _buildNavItem(
              icon: Icons.chat_bubble_outline,
              label: l10n.chat, // ✅ LOCALIZADO
              index: 3,
            ),
            _buildNavItem(
              icon: Icons.settings_outlined,
              label: l10n.settings, // ✅ LOCALIZADO
              index: 4,
            ),
          ],
        ),
      ),
    );
  }
}