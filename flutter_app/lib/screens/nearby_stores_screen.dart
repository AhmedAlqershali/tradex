import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/store_details_screen.dart';
import 'package:ai_saas/shared/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class NearbyStoresScreen extends StatefulWidget {
  const NearbyStoresScreen({super.key, this.region});

  final String? region;

  @override
  State<NearbyStoresScreen> createState() => _NearbyStoresScreenState();
}

class _NearbyStoresScreenState extends State<NearbyStoresScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StoreBloc>().add(StoresLoadRequested(region: widget.region));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: l10n.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: const Color(0xff1A1A1A), size: 20.sp),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
                widget.region == null
                ? l10n.storeListTitle
                : l10n.storesForRegion.replaceFirst('{region}', widget.region ?? ''),
            style: GoogleFonts.ibmPlexSans(
              color: const Color(0xff1A1A1A),
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<StoreBloc, StoreState>(
          builder: (context, state) {
            if (state is StoreLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is StoreFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 60.sp, color: Colors.grey.shade300),
                    SizedBox(height: 16.h),
                    Text(state.message,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 13.sp, color: const Color(0xff888888))),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: () => context
                          .read<StoreBloc>()
                          .add(StoresLoadRequested(region: widget.region)),
                      child: Text(AppLocalizations.of(context).retry,
                          style: GoogleFonts.ibmPlexSans()),
                    ),
                  ],
                ),
              );
            }

            List<StoreModel> stores = [];
            if (state is StoresLoaded) stores = state.stores;

            if (stores.isEmpty) {
              return Center(
                child: Text(l10n.noStoresFound,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp, color: const Color(0xff888888))),
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              itemCount: stores.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final store = stores[index];
                return StoreCard(
                  storeName: store.title,
                  location: store.location ?? store.subTitle,
                  rating: store.rating?.toStringAsFixed(1) ?? '—',
                  imageUrl: store.imageUrl,
                  targetScreen: StoreDetailsScreen(store: store),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class StoreCard extends StatelessWidget {
  final String storeName;
  final String location;
  final String rating;
  final String imageUrl;
  final Widget targetScreen;

  const StoreCard({
    super.key,
    required this.storeName,
    required this.location,
    required this.rating,
    required this.imageUrl,
    required this.targetScreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imageUrl,
              height: 160.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160.h,
                color: Colors.grey.shade100,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 12.sp, color: const Color(0xff888888)),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                location,
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 12.sp,
                                    color: const Color(0xff888888)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF8E7),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 14.sp, color: const Color(0xffF59E0B)),
                        SizedBox(width: 3.w),
                        Text(rating,
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xffF59E0B))),
                      ],
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
}
