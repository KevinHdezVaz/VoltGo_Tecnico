
// 4. Pantalla principal de reseñas con colores actualizados
import 'dart:math';

import 'package:Voltgo_app/data/models/TechnicianReview.dart';
import 'package:Voltgo_app/data/models/User/RatingSummary.dart';
import 'package:Voltgo_app/data/services/ReviewsService.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';

class TechnicianReviewsScreen extends StatefulWidget {
  const TechnicianReviewsScreen({Key? key}) : super(key: key);

  @override
  State<TechnicianReviewsScreen> createState() => _TechnicianReviewsScreenState();
}

class _TechnicianReviewsScreenState extends State<TechnicianReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RatingSummary? _ratingSummary;
  List<TechnicianReview> _allReviews = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreReviews();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final summary = await ReviewsService.getTechnicianReviews();
      final allReviews = await ReviewsService.getAllReviews(page: 1);
      
      if (mounted) {
        setState(() {
          _ratingSummary = summary;
          _allReviews = allReviews;
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Error al cargar las reseñas: $e');
      }
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final newReviews = await ReviewsService.getAllReviews(page: _currentPage + 1);
      
      if (mounted && newReviews.isNotEmpty) {
        setState(() {
          _allReviews.addAll(newReviews);
          _currentPage++;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return Scaffold( // Puedes mantener un Scaffold base SIN AppBar si lo necesitas para el background color
    backgroundColor: AppColors.background,
    // El RefreshIndicator ahora envuelve todo el cuerpo de la pantalla
    body: RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      backgroundColor: AppColors.white,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          // Estos son los slivers que aparecen en la parte superior (tu AppBar)
          return <Widget>[
            SliverAppBar(
              title: Text(
                l10n.myRatings,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
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
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
              // Pinned mantiene la AppBar visible
              pinned: true,
              // Floating hace que la AppBar reaparezca al hacer scroll hacia arriba
              floating: true,
              // La TabBar va en el 'bottom' de la SliverAppBar
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                tabs: [
                  Tab(text: l10n.summary),
                  Tab(text: l10n.allReviews),
                ],
              ),
            ),
          ];
        },
        // El cuerpo del NestedScrollView es tu TabBarView
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(),
                  _buildAllReviewsTab(),
                ],
              ),
      ),
    ),
  );
}
 
Widget _buildSummaryTab() {
  if (_ratingSummary == null) {
    return _buildEmptyState();
  }
  // Se quita el RefreshIndicator de aquí
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        _buildRatingOverview(),
        const SizedBox(height: 20),
        _buildRatingDistribution(),
        const SizedBox(height: 20),
        _buildRecentReviews(),
      ],
    ),
  );
}

 Widget _buildAllReviewsTab() {
  if (_allReviews.isEmpty) {
    return _buildEmptyState();
  }
  // Se quita el RefreshIndicator de aquí
  return ListView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.all(16),
    itemCount: _allReviews.length + (_isLoadingMore ? 1 : 0),
    itemBuilder: (context, index) {
      if (index == _allReviews.length) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildReviewCard(_allReviews[index]),
      );
    },
  );
}

  Widget _buildRatingOverview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.brandBlue.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.white,
            border: Border.all(color: AppColors.border.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _ratingSummary!.averageRating.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Icon(
                      Icons.star,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStarRating(_ratingSummary!.averageRating, size: 28),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_ratingSummary!.totalReviews} reviews',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray300.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ratingDistribution,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(5, (index) {
                final stars = 5 - index;
                final percentage = _ratingSummary!.getPercentageForRating(stars);
                final count = _ratingSummary!.ratingDistribution[stars] ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        '$stars',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star, color: Colors.green, size: 16),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percentage / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.brandBlue],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$count',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReviews() {
    final l10n = AppLocalizations.of(context);
    if (_ratingSummary!.recentReviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray300.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recentReviews,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _tabController.animateTo(1),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                     l10n.viewAll,
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...(_ratingSummary!.recentReviews.take(3).map((review) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCompactReviewCard(review),
                )
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(TechnicianReview review) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray300.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.1), AppColors.brandBlue.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        review.clientName[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.clientName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          review.formattedDate,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStarRating(review.rating),
                ],
              ),
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withOpacity(0.3)),
                  ),
                  child: Text(
                    review.comment!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (review.vehicleInfo != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.electric_car,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        review.vehicleInfo!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactReviewCard(TechnicianReview review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.clientName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildStarRating(review.rating, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.formattedDate,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.green, size: size);
        } else if (index < rating) {
          return Icon(Icons.star_half, color: Colors.green, size: size);
        } else {
          return Icon(Icons.star_border, color: AppColors.gray300, size: size);
        }
      }),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.star_border,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
             l10n.noReviewsYet,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
             l10n.completeServices,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }   } 