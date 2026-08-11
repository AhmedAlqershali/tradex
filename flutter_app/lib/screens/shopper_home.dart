import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/client/widgets/home/home_categories_row.dart';
import 'package:ai_saas/screens/client/widgets/home/home_hero_banner.dart';
import 'package:ai_saas/screens/client/widgets/home/home_search_bar.dart';
import 'package:ai_saas/screens/client/widgets/home/home_top_bar.dart';
import 'package:ai_saas/screens/client/widgets/home/product_cards.dart';
import 'package:ai_saas/screens/client/widgets/home/store_card.dart';
import 'package:ai_saas/screens/client/widgets/home/weekend_promo_banner.dart';
import 'package:ai_saas/screens/nearby_stores_screen.dart' hide StoreCard;
import 'package:ai_saas/screens/recently_arrived_screen.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/models/store_model.dart';
import 'package:ai_saas/shared/widgets/section_header.dart';
import 'package:ai_saas/core/services/location_service.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShopperHomePage extends StatefulWidget {
  const ShopperHomePage({super.key});

  @override
  State<ShopperHomePage> createState() => _ShopperHomePageState();
}

class _ShopperHomePageState extends State<ShopperHomePage> {
  static const Color _scaffoldBg = Color(0xffF8F9FD);
  String? _currentRegion;
  String? _locationError;
  bool _isLocationLoading = true;

  @override
  void initState() {
    super.initState();
    UserController.instance.refreshProfile().catchError((_) {});
    _loadHomeData();
    context.read<CategoryBloc>().add(const CategoryListRequested());
    context.read<ProductBloc>().add(const ProductsLoadRequested());
    context
        .read<ClientDashboardBloc>()
        .add(const ClientDashboardLoadRequested());
  }

  Future<void> _loadHomeData() async {
    if (mounted) {
      setState(() {
        _isLocationLoading = true;
        _locationError = null;
      });
    }

    try {
      final result = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;
      if (result.region == null || result.region!.isEmpty) {
        setState(() {
          _isLocationLoading = false;
          _locationError = 'تعذر مطابقة موقعك مع منطقة مدعومة.';
        });
        return;
      }

      setState(() {
        _currentRegion = result.region;
        _isLocationLoading = false;
      });
      context.read<StoreBloc>().add(StoresLoadRequested(region: result.region));
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLocationLoading = false;
        _locationError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLocationLoading = false;
        _locationError = 'تعذر الحصول على موقعك الحالي.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              HomeTopBar(
                locationName: _currentRegion,
                isLocationLoading: _isLocationLoading,
                locationError: _locationError,
                onLocationRetry: _loadHomeData,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ClientDashboardCounters(),
                      SizedBox(height: 16.h),
                      const HomeSearchBar(),
                      SizedBox(height: 16.h),
                      const HomeHeroBanner(),
                      SizedBox(height: 24.h),
                      const HomeCategoriesRow(),
                      SizedBox(height: 24.h),
                      _NearbyStoresSection(region: _currentRegion),
                      SizedBox(height: 24.h),
                      _NearbyProductsSection(),
                      SizedBox(height: 24.h),
                      const WeekendPromoBanner(),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Client dashboard counters ───────────────────────────────────────────────

class _ClientDashboardCounters extends StatelessWidget {
  const _ClientDashboardCounters();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientDashboardBloc, ClientDashboardState>(
      builder: (context, state) {
        if (state is ClientDashboardInitial ||
            state is ClientDashboardLoading) {
          return SizedBox(
            height: 96.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ClientDashboardFailure) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _DashboardCountersError(
              message: state.message,
              onRetry: () => context
                  .read<ClientDashboardBloc>()
                  .add(const ClientDashboardLoadRequested()),
            ),
          );
        }

        if (state is ClientDashboardLoaded) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                  child: _DashboardCounterCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'طلباتي',
                    value: state.dashboard.ordersCount,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _DashboardCounterCard(
                    icon: Icons.favorite_border_rounded,
                    label: 'مفضلاتي',
                    value: state.dashboard.favoritesCount,
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _DashboardCounterCard extends StatelessWidget {
  const _DashboardCounterCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: const Color(0xffEDE9FF),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(icon, color: const Color(0xff4D41DF), size: 21.sp),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: const Color(0xff1A1A1A),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xff888888),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCountersError extends StatelessWidget {
  const _DashboardCountersError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xffFEE2E2),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: const Color(0xffEF4444),
              size: 22.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xff7F1D1D),
                  fontSize: 12.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nearby Stores ────────────────────────────────────────────────────────────

class _NearbyStoresSection extends StatelessWidget {
  const _NearbyStoresSection({this.region});

  final String? region;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreBloc, StoreState>(
      builder: (context, state) {
        List<StoreModel> stores = [];
        if (state is StoresLoaded) stores = state.stores;

        if (stores.isEmpty && state is StoreLoading) {
          return SizedBox(
            height: 180.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (stores.isEmpty && state is StoreFailure) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              state.message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12.sp),
            ),
          );
        }
        if (stores.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SectionHeader(
              title: region == null ? 'متاجر المنطقة' : 'متاجر في $region',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NearbyStoresScreen(region: region))),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 180.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: stores.length.clamp(0, 5),
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, index) =>
                    StoreCard(store: stores[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Nearby Products ──────────────────────────────────────────────────────────

class _NearbyProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return SizedBox(
            height: 200.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        List<Product> products = [];
        if (state is ProductsLoaded) products = state.products;
        if (products.isEmpty) return const SizedBox.shrink();

        final featured = products.where((p) => p.isFeatured).toList();
        final featuredIds = featured.map((p) => p.id).toSet();
        final small =
            products.where((p) => !featuredIds.contains(p.id)).take(2).toList();

        return Column(
          children: [
            SectionHeader(
              title: 'منتجات مختارة لك',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RecentlyArrivedScreen())),
            ),
            SizedBox(height: 12.h),
            if (featured.isNotEmpty) ...[
              FeaturedProductCard(product: featured.first),
              SizedBox(height: 16.h),
            ],
            if (small.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Expanded(child: SmallProductCard(product: small[0])),
                    if (small.length > 1) ...[
                      SizedBox(width: 12.w),
                      Expanded(child: SmallProductCard(product: small[1])),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
