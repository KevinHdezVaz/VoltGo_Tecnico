import 'package:Voltgo_app/data/models/User/UserModel.dart';
import 'package:Voltgo_app/data/services/ChatHistoryScreen.dart';
import 'package:Voltgo_app/data/services/EarningsService.dart';
import 'package:Voltgo_app/data/services/auth_api_service.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:Voltgo_app/ui/MenuPage/TechnicianReviewsScreen.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/ui/login/LoginScreen.dart';
import 'package:Voltgo_app/ui/profile/EditProfileScreen.dart';
import 'package:Voltgo_app/ui/profile/PrivacyPolicyScreen.dart';
import 'package:Voltgo_app/ui/profile/TermsAndConditionsScreen.dart';
import 'package:Voltgo_app/utils/EditVehicleScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  late Future<UserModel?> _userFuture;
  bool _darkModeEnabled = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _userFuture = AuthService.fetchUserProfile();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await _showLogoutConfirmationDialog();
    if (!shouldLogout) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 500));
      await AuthService.logout();

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)
                        .logoutError, // Usa AppLocalizations
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<bool> _showLogoutConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).logout, // Usa AppLocalizations
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                AppLocalizations.of(context)
                    .logoutConfirmationMessage, // Usa AppLocalizations
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    AppLocalizations.of(context).cancel, // Usa AppLocalizations
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).logout, // Usa AppLocalizations
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).settings, // Usa AppLocalizations
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppColors.textOnPrimary,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.brandBlue.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: AppColors.gray300.withOpacity(0.4),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.lightGrey.withOpacity(0.5)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0)
              .copyWith(bottom: 130.0),
          children: [
            FutureBuilder<UserModel?>(
              future: _userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _buildProfileHeader(
                    name: AppLocalizations.of(context)
                        .error, // Usa AppLocalizations
                    email: AppLocalizations.of(context)
                        .couldNotLoadProfile, // Usa AppLocalizations
                  );
                }
                final user = snapshot.data!;
                return _buildProfileHeader(name: user.name, email: user.email);
              },
            ),
            const SizedBox(height: 16),

                      _buildRatingCard(), // ✅ NUEVO CARD DEL RATING


            const SizedBox(height: 24),
            _buildSectionHeader(
                AppLocalizations.of(context).account), // Usa AppLocalizations
             
             _buildSettingsItem(
              icon: Icons.account_balance_wallet_outlined,
              title: AppLocalizations.of(context)
                  .paymentMethods, // Usa AppLocalizations
              onTap: () {},
            ),
               _buildSettingsItem(
              icon: Icons.star_outline,
              title: "Reviews", // Usa AppLocalizations
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const TechnicianReviewsScreen()),
                );
              },
            ),
            const Divider(height: 32, color: AppColors.gray300),
            _buildSectionHeader(
                AppLocalizations.of(context).vehicle), // Usa AppLocalizations
            _buildSettingsItem(
              icon: Icons.directions_car_outlined,
              title: AppLocalizations.of(context)
                  .manageVehicles, // Usa AppLocalizations
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const EditVehicleScreen()),
                );
              },
            ),
            _buildSettingsItem(
              icon: Icons.article_outlined,
              title: AppLocalizations.of(context)
                  .documents, // Usa AppLocalizations
              onTap: () {},
            ),
              const Divider(height: 32, color: AppColors.gray300),
                // Vehicle Section
                _buildSectionHeader(l10n.otros),
                _buildSettingsItem(
                  icon: Icons.bookmark_outline,
                  title: l10n.tyc,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsAndConditionsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.politicadeprivacidad, // ✅ CAMBIAR de 'Documentos'
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),

                const Divider(height: 32, color: AppColors.gray300),
                const SizedBox(height: 24),
                
            _buildLogoutButton(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoggingOut
            ? null
            : () {
                HapticFeedback.lightImpact();
              },
        backgroundColor: _isLoggingOut ? AppColors.disabled : AppColors.accent,
        child: Icon(
          Icons.edit,
          color:
              _isLoggingOut ? AppColors.textSecondary : AppColors.textOnPrimary,
        ),
        elevation: 4,
        tooltip:
            AppLocalizations.of(context).editProfile, // Usa AppLocalizations
      ),
    );
  }

Widget _buildProfileHeader({required String name, required String email}) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.lightGrey, AppColors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 32, color: AppColors.textOnPrimary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ✅ NUEVO WIDGET PARA EL CARD DEL RATING
Widget _buildRatingCard() {

  final l10n = AppLocalizations.of(context);
  return FutureBuilder<Map<String, dynamic>?>(
    future: EarningsService.getEarningsSummary(),
    builder: (context, snapshot) {
      double rating = 5.0;
        bool isLoading = snapshot.connectionState == ConnectionState.waiting;
      
      if (snapshot.hasData && snapshot.data != null) {
        // ✅ CORREGIR: Buscar en today.rating en lugar de technician_rating
        final todayData = snapshot.data!['today'];
        if (todayData != null && todayData['rating'] != null) {
          rating = double.tryParse(todayData['rating'].toString()) ?? 5.0;
        }
        
        // ✅ FALLBACK: Si no hay rating en today, intentar technician_rating
        if (rating == 5.0) {
          rating = double.tryParse(
            snapshot.data!['technician_rating']?.toString() ?? '5.0'
          ) ?? 5.0;
        }
        
        print('📊 Rating obtenido: $rating'); // Debug
        print('📊 Datos completos: ${snapshot.data}'); // Debug
      }
      
      
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warning.withOpacity(0.1),
                AppColors.warning.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Lado izquierdo - Rating grande
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.star,
                      color: AppColors.warning,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    if (isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.warning),
                        ),
                      )
                    else
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Lado derecho - Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                     l10n.yourRating,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.averageRating,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Estrellas visuales
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.floor() 
                            ? Icons.star
                            : (index < rating && rating % 1 >= 0.5)
                              ? Icons.star_half
                              : Icons.star_border,
                          color: AppColors.warning,
                          size: 20,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shadowColor: AppColors.gray300.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Icon(icon, color: AppColors.brandBlue, size: 28),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTapDown: _isLoggingOut ? null : (_) => _animationController.forward(),
      onTapUp: _isLoggingOut ? null : (_) => _animationController.reverse(),
      onTapCancel: _isLoggingOut ? null : () => _animationController.reverse(),
      onTap: _isLoggingOut ? null : _handleLogout,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          elevation: 3,
          shadowColor: AppColors.error.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: _isLoggingOut
                    ? AppColors.error.withOpacity(0.05)
                    : AppColors.error.withOpacity(0.1),
                border: Border.all(
                  color: _isLoggingOut
                      ? AppColors.error.withOpacity(0.2)
                      : AppColors.error.withOpacity(0.3),
                ),
              ),
              child: ListTile(
                enabled: !_isLoggingOut,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 8,
                ),
                leading: _isLoggingOut
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.error.withOpacity(0.7),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.logout,
                        color: AppColors.error,
                        size: 28,
                      ),
                title: Text(
                  _isLoggingOut
                      ? AppLocalizations.of(context)
                          .loggingOut // Usa AppLocalizations
                      : AppLocalizations.of(context)
                          .logout, // Usa AppLocalizations
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isLoggingOut
                        ? AppColors.error.withOpacity(0.7)
                        : AppColors.error,
                  ),
                ),
                subtitle: _isLoggingOut
                    ? Text(
                        AppLocalizations.of(context)
                            .pleaseWait, // Usa AppLocalizations
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
