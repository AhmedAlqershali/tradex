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

  @override
  void initState() {
    super.initState();
    // Load stores and products from the real backend.
    context.read<StoreBloc>().add(const StoresLoadRequested());
    context.read<ProductBloc>().add(const ProductsLoadRequested());
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
              const HomeTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HomeSearchBar(),
                      SizedBox(height: 16.h),
                      const HomeHeroBanner(),
                      SizedBox(height: 24.h),
                      const HomeCategoriesRow(),
                      SizedBox(height: 24.h),
                      _NearbyStoresSection(),
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

// ─── Nearby Stores ────────────────────────────────────────────────────────────

class _NearbyStoresSection extends StatelessWidget {
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

        if (stores.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SectionHeader(
              title: 'متاجر قريبة منك',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const NearbyStoresScreen())),
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
              onTap: () => Navigator.push(context,
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
