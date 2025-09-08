import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/data/services/HistoryService.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:Voltgo_app/ui/HistoryScreen/ServiceDetailsScreen.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<ServiceRequestModel>> _historyFuture;
  String _selectedFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<ServiceRequestModel> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _historyFuture = HistoryService.fetchHistory();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedFilter = AppLocalizations.of(context).all;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = HistoryService.fetchHistory();
    });
  }

  void _filterHistory(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  // NUEVO MÉTODO PARA NAVEGACIÓN
  void _navigateToServiceDetails(ServiceRequestModel serviceRequest) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(
          serviceRequest: serviceRequest,
        ),
      ),
    );
  }

  // NUEVO MÉTODO PARA FORMATEAR ESTADOS
  String _getStatusDisplayText(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppLocalizations.of(context).completed;
      case 'cancelled':
        return AppLocalizations.of(context).cancelled;
      case 'pending':
        return 'Pendiente'; // O AppLocalizations.of(context).pending si lo tienes
      case 'in_progress':
        return 'En Progreso'; // O AppLocalizations.of(context).inProgress si lo tienes
      default:
        return status;
    }
  }

  List<ServiceRequestModel> get _filteredList {
    if (_selectedFilter == AppLocalizations.of(context).all) {
      return _historyItems;
    }
    return _historyItems
        .where((item) =>
            item.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).serviceHistory,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
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
        child: RefreshIndicator(
          onRefresh: _refreshHistory,
          color: AppColors.primary,
          backgroundColor: AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  AppLocalizations.of(context).reviewPreviousServices,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _buildFilterChips(),
              Expanded(
                child: FutureBuilder<List<ServiceRequestModel>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    _historyItems = snapshot.data!;
                    final displayedItems = _filteredList;

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: displayedItems.length,
                      itemBuilder: (context, index) {
                        final item = displayedItems[index];
                        return _buildHistoryItem(item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildChip(AppLocalizations.of(context).all),
            const SizedBox(width: 12),
            _buildChip(AppLocalizations.of(context).completed),
            const SizedBox(width: 12),
            _buildChip(AppLocalizations.of(context).cancelled),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        _filterHistory(label);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FilterChip(
          label: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
                  isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => _filterHistory(label),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.white,
          checkmarkColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.border.withOpacity(0.5)),
          ),
          elevation: isSelected ? 3 : 1,
          pressElevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ServiceRequestModel item) {
    IconData icon;
    Color statusColor;

    // MEJORADO: Más estados y mejor manejo
    switch (item.status.toLowerCase()) {
      case 'completed':
        icon = Icons.check_circle;
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        statusColor = AppColors.error;
        break;
      case 'pending':
        icon = Icons.schedule;
        statusColor = AppColors.warning;
        break;
      case 'in_progress':
        icon = Icons.hourglass_empty;
        statusColor = AppColors.primary;
        break;
      default:
        icon = Icons.help_outline;
        statusColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToServiceDetails(item); // ACTUALIZADO: Navegar a detalles
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(icon, color: statusColor, size: 28),
                ),
                subtitle: Text(
                  '${item.formattedDate} - ${item.formattedTime} • ${_getStatusDisplayText(item.status, context)}', // ACTUALIZADO: Mejor formato
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: item.finalCost != null
                    ? Text(
                        '\$${item.finalCost!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : const Icon(
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '${AppLocalizations.of(context).errorLoadingHistory}: $error',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              AppLocalizations.of(context).retry,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_toggle_off,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noServiceHistory,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // TODO: Navigate to request service screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              AppLocalizations.of(context).requestService,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}