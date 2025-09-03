import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/data/services/EarningsService.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _earningsSummary;
  List<dynamic> _earningsHistory = [];
  bool _isLoading = true;
  bool _isLoadingHistory = false;
  String _selectedPeriod = 'today';
  int _currentPage = 1;
  bool _hasMorePages = true;
  final _withdrawAmountController = TextEditingController();
  String _selectedPaymentMethod = 'bank_transfer';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEarningsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _withdrawAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadEarningsData() async {
    setState(() => _isLoading = true);

    try {
      final summary = await EarningsService.getEarningsSummary();
      final history = await EarningsService.getEarningsHistory(page: 1);

      if (mounted) {
        setState(() {
          _earningsSummary = summary;
          _earningsHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando datos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(AppLocalizations.of(context)
            .loadingEarningsError); // Usa AppLocalizations
      }
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingHistory || !_hasMorePages) return;

    setState(() => _isLoadingHistory = true);

    try {
      final moreHistory = await EarningsService.getEarningsHistory(
        page: _currentPage + 1,
      );

      if (mounted) {
        setState(() {
          if (moreHistory.isEmpty) {
            _hasMorePages = false;
          } else {
            _earningsHistory.addAll(moreHistory);
            _currentPage++;
          }
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('Error cargando más historial: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  void _showWithdrawModal() {
    final availableBalance = double.tryParse(
            _earningsSummary?['wallet']?['balance']?.toString() ?? '0') ??
        0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)
                    .withdrawFunds, // Usa AppLocalizations
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context).availableBalance}: \$${availableBalance.toStringAsFixed(2)}', // Usa AppLocalizations
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _withdrawAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)
                      .withdrawalAmount, // Usa AppLocalizations
                  prefixText: '\$',
                  hintText: AppLocalizations.of(context)
                      .minimumWithdrawal, // Usa AppLocalizations
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)
                    .paymentMethod, // Usa AppLocalizations
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildPaymentMethodOption(
                'bank_transfer',
                AppLocalizations.of(context)
                    .bankTransfer, // Usa AppLocalizations
                Icons.account_balance,
              ),
              _buildPaymentMethodOption(
                'debit_card',
                AppLocalizations.of(context).debitCard, // Usa AppLocalizations
                Icons.credit_card,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)
                        .confirmWithdrawal, // Usa AppLocalizations
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == value
                ? AppColors.primary
                : AppColors.gray300,
            width: _selectedPaymentMethod == value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _selectedPaymentMethod == value
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: _selectedPaymentMethod == value
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (_selectedPaymentMethod == value)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _processWithdrawal() async {
    final amount = double.tryParse(_withdrawAmountController.text) ?? 0;

    if (amount < 10) {
      _showErrorSnackBar(AppLocalizations.of(context)
          .minimumWithdrawalError); // Usa AppLocalizations
      return;
    }

    final availableBalance = double.tryParse(
            _earningsSummary?['wallet']?['balance']?.toString() ?? '0') ??
        0.0;

    if (amount > availableBalance) {
      _showErrorSnackBar(AppLocalizations.of(context)
          .insufficientBalance); // Usa AppLocalizations
      return;
    }

    Navigator.pop(context);
    _showLoadingDialog();

    final success = await EarningsService.requestWithdrawal(
      amount,
      _selectedPaymentMethod,
    );

    Navigator.pop(context); // Cerrar loading

    if (success) {
      _showSuccessSnackBar(AppLocalizations.of(context)
          .withdrawalSuccess); // Usa AppLocalizations
      _withdrawAmountController.clear();
      _loadEarningsData();
    } else {
      _showErrorSnackBar(
          AppLocalizations.of(context).withdrawalError); // Usa AppLocalizations
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildWeekTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        AppLocalizations.of(context).myEarnings, // Usa AppLocalizations
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: AppColors.textOnPrimary,
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.brandBlue.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 2,
      shadowColor: AppColors.gray300.withOpacity(0.3),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.white),
          onPressed: _loadEarningsData,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: [
          Tab(text: AppLocalizations.of(context).today), // Usa AppLocalizations
          Tab(text: AppLocalizations.of(context).week), // Usa AppLocalizations
          Tab(
              text:
                  AppLocalizations.of(context).history), // Usa AppLocalizations
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    final todayData = _earningsSummary?['today'];
    final walletData = _earningsSummary?['wallet'];

    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceCard(walletData),
            const SizedBox(height: 20),
            _buildTodayStats(todayData),
            const SizedBox(height: 20),
            _buildQuickStats(todayData),
            const SizedBox(height: 20),
            _buildRecentEarnings(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekTab() {
    final weekData = _earningsSummary?['week'];
    final monthData = _earningsSummary?['month'];

    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPeriodCard(AppLocalizations.of(context).thisWeek, weekData,
                AppColors.info), // Usa AppLocalizations
            const SizedBox(height: 16),
            _buildPeriodCard(AppLocalizations.of(context).thisMonth, monthData,
                AppColors.success), // Usa AppLocalizations
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMoreHistory();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: _loadEarningsData,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _earningsHistory.length + (_isLoadingHistory ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _earningsHistory.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            final earning = _earningsHistory[index];
            // return _buildHistoryItem(earning);
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, dynamic>? walletData) {
    final balance =
        double.tryParse(walletData?['balance']?.toString() ?? '0') ?? 0.0;
    final pendingBalance =
        double.tryParse(walletData?['pending_balance']?.toString() ?? '0') ??
            0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.brandBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .availableBalance, // Usa AppLocalizations
                    style: TextStyle(
                      color: AppColors.textOnPrimary.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          if (pendingBalance > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${AppLocalizations.of(context).pending}: \$${pendingBalance.toStringAsFixed(2)}', // Usa AppLocalizations
                    style: TextStyle(
                      color: AppColors.textOnPrimary.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: balance >= 10 ? _showWithdrawModal : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_downward, color: AppColors.black),
                  const SizedBox(width: 8),
                  Text(
                    balance >= 10
                        ? AppLocalizations.of(context)
                            .withdrawFunds // Usa AppLocalizations
                        : AppLocalizations.of(context)
                            .minimumWithdrawal, // Usa AppLocalizations
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats(Map<String, dynamic>? todayData) {
    final earnings =
        double.tryParse(todayData?['earnings']?.toString() ?? '0') ?? 0.0;
    final services =
        int.tryParse(todayData?['services']?.toString() ?? '0') ?? 0;
    final tips = double.tryParse(todayData?['tips']?.toString() ?? '0') ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray300.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)
                    .todaySummary, // Usa AppLocalizations
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '\$${earnings.toStringAsFixed(2)}',
                AppLocalizations.of(context).earnings, // Usa AppLocalizations
                AppColors.success,
                Icons.attach_money,
              ),
              Container(width: 1, height: 40, color: AppColors.gray300),
              _buildStatItem(
                services.toString(),
                AppLocalizations.of(context).services, // Usa AppLocalizations
                AppColors.info,
                Icons.electric_bolt,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.gray300,
              ),
              _buildStatItem(
                '\$${tips.toStringAsFixed(2)}',
                AppLocalizations.of(context).tips, // Usa AppLocalizations
                AppColors.warning,
                Icons.card_giftcard,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String value, String label, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(Map<String, dynamic>? todayData) {
    final distance =
        double.tryParse(todayData?['distance']?.toString() ?? '0') ?? 0.0;
    final rating =
        double.tryParse(todayData?['rating']?.toString() ?? '0') ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            AppLocalizations.of(context).distance, // Usa AppLocalizations
            '${distance.toStringAsFixed(1)} km',
            Icons.route,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            AppLocalizations.of(context).rating, // Usa AppLocalizations
            rating > 0 ? rating.toStringAsFixed(1) : 'N/A',
            Icons.star,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(
      String title, Map<String, dynamic>? data, Color color) {
    final earnings =
        double.tryParse(data?['earnings']?.toString() ?? '0') ?? 0.0;
    final services = int.tryParse(data?['services']?.toString() ?? '0') ?? 0;
    final tips = double.tryParse(data?['tips']?.toString() ?? '0') ?? 0.0;
    final distance =
        double.tryParse(data?['distance']?.toString() ?? '0') ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${earnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)
                        .totalEarned, // Usa AppLocalizations
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      services.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)
                          .services, // Usa AppLocalizations
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat(
                  Icons.card_giftcard,
                  '\$${tips.toStringAsFixed(2)}',
                  AppLocalizations.of(context).tips), // Usa AppLocalizations
              const SizedBox(width: 20),
              _buildMiniStat(
                  Icons.route,
                  '${distance.toStringAsFixed(1)} km',
                  AppLocalizations.of(context)
                      .distance), // Usa AppLocalizations
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.white.withOpacity(0.9), size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.white.withOpacity(0.95),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentEarnings() {
    if (_earningsHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray300),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 48,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)
                  .noRecentServices, // Usa AppLocalizations
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).recentActivity, // Usa AppLocalizations
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...(_earningsHistory
            .take(5)
            // .map((earning) => _buildHistoryItem(earning))
            .toList()),
      ],
    );
  }
}
