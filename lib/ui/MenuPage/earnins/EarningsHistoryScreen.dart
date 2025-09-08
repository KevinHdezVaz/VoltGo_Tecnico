import 'package:flutter/material.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/data/services/EarningsService.dart';
import 'package:intl/intl.dart';

class EarningsHistoryScreen extends StatefulWidget {
  final List<dynamic> initialHistory;

  const EarningsHistoryScreen({
    Key? key,
    required this.initialHistory,
  }) : super(key: key);

  @override
  State<EarningsHistoryScreen> createState() => _EarningsHistoryScreenState();
}

class _EarningsHistoryScreenState extends State<EarningsHistoryScreen> {
  List<dynamic> _earningsHistory = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMorePages = true;
  String? _selectedStatus;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _earningsHistory = List.from(widget.initialHistory);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreHistory();
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreHistory = await EarningsService.getEarningsHistory(
        page: _currentPage + 1,
        startDate: _selectedStartDate?.toIso8601String().split('T')[0],
        endDate: _selectedEndDate?.toIso8601String().split('T')[0],
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          if (moreHistory.isEmpty) {
            _hasMorePages = false;
          } else {
            _earningsHistory.addAll(moreHistory);
            _currentPage++;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error cargando más historial: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMorePages = true;
    });

    try {
      final newHistory = await EarningsService.getEarningsHistory(
        page: 1,
        startDate: _selectedStartDate?.toIso8601String().split('T')[0],
        endDate: _selectedEndDate?.toIso8601String().split('T')[0],
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          _earningsHistory = newHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error refrescando historial: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersModal(),
    );
  }

  Widget _buildFiltersModal() {
    return Container(
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
              'Filtros',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Filtro por estado
            Text(
              'Estado',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildStatusChip('Todos', null),
                _buildStatusChip('Pendiente', 'pending'),
                _buildStatusChip('Pagado', 'paid'),
                _buildStatusChip('Retirado', 'withdrawn'),
              ],
            ),
            const SizedBox(height: 20),
            
            // Filtro por fechas
            Text(
              'Rango de fechas',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    'Desde',
                    _selectedStartDate,
                    (date) => _selectedStartDate = date,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateSelector(
                    'Hasta',
                    _selectedEndDate,
                    (date) => _selectedEndDate = date,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = null;
                        _selectedStartDate = null;
                        _selectedEndDate = null;
                      });
                      Navigator.pop(context);
                      _refreshHistory();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.gray300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _refreshHistory();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Aplicar',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String? value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? value : null;
        });
      },
      backgroundColor: AppColors.white,
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.gray300,
      ),
    );
  }

  Widget _buildDateSelector(
      String label, DateTime? selectedDate, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(Duration(days: 365)),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() {
            onChanged(date);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(selectedDate)
                        : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
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

  Widget _buildHistoryItem(Map<String, dynamic> earning) {
    final netAmount = double.tryParse(earning['net_amount']?.toString() ?? '0') ?? 0.0;
    final totalAmount = double.tryParse(earning['total_amount']?.toString() ?? '0') ?? 0.0;
    final tips = double.tryParse(earning['tips']?.toString() ?? '0') ?? 0.0;
    final status = earning['status'] ?? 'pending';
    final createdAt = earning['created_at'] ?? '';
    
    // Formatear fecha
    String formattedDate = 'Fecha no disponible';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (e) {
        formattedDate = 'Fecha inválida';
      }
    }

    // Determinar color del estado
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'paid':
        statusColor = AppColors.success;
        statusText = 'Pagado';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusText = 'Pendiente';
        statusIcon = Icons.schedule;
        break;
      case 'withdrawn':
        statusColor = AppColors.info;
        statusText = 'Retirado';
        statusIcon = Icons.arrow_downward;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'Desconocido';
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray300.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray300.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${netAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  if (totalAmount != netAmount)
                    Text(
                      'Bruto: \$${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (tips > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.card_giftcard, size: 16, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  'Propinas: \$${tips.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_earningsHistory.isEmpty) return SizedBox.shrink();

    final totalEarnings = _earningsHistory.fold<double>(
      0.0,
      (sum, earning) =>
          sum + (double.tryParse(earning['net_amount']?.toString() ?? '0') ?? 0.0),
    );

    final totalTips = _earningsHistory.fold<double>(
      0.0,
      (sum, earning) =>
          sum + (double.tryParse(earning['tips']?.toString() ?? '0') ?? 0.0),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.8), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '\$${totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'Total Ganado',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.white.withOpacity(0.3)),
          Expanded(
            child: Column(
              children: [
                Text(
                  _earningsHistory.length.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'Servicios',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.white.withOpacity(0.3)),
          Expanded(
            child: Column(
              children: [
                Text(
                  '\$${totalTips.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'Propinas',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Historial de Ganancias',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
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
            icon: const Icon(Icons.filter_list, color: AppColors.white),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _earningsHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: AppColors.gray300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay registros de ganancias',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completa servicios para ver tu historial',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _earningsHistory.length + 1 + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildSummaryCard();
                      } else if (index == _earningsHistory.length + 1) {
                        return _isLoadingMore
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary),
                                ),
                              )
                            : const SizedBox.shrink();
                      } else {
                        final earning = _earningsHistory[index - 1];
                        return _buildHistoryItem(earning);
                      }
                    },
                  ),
      ),
    );
  }
}