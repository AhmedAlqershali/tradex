import 'package:ai_saas/screens/store_details_screen.dart';
import 'package:ai_saas/shared/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── StoreCard ────────────────────────────────────────────────────────────────
//
// Horizontal-list card for a single nearby store.
// Used in the shopper home's "متاجر قريبة منك" section.
// ─────────────────────────────────────────────────────────────────────────────

class StoreCard extends StatelessWidget {
  final StoreModel store;

  const StoreCard({super.key, required this.store});

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoreDetailsScreen(store: store)),
      ),
      child: Container(
        width: 240.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16.r)),
                child: store.imageUrl.isNotEmpty
                    ? Image.network(
                        store.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.sp),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(
                        '${store.rating ?? "—"}',
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          store.location ?? store.subTitle,
                          style: TextStyle(
                              color: Colors.black38, fontSize: 11.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: _primary.withValues(alpha: 0.05),
      child: Center(
        child: Icon(Icons.storefront_rounded,
            size: 40.sp, color: _primary.withValues(alpha: 0.3)),
      ),
    );
  }
}
