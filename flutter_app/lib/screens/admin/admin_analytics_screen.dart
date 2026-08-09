import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/presentation/blocs/admin_analytics/admin_analytics_bloc.dart';
import 'package:ai_saas/shared/models/admin_ai_insight_model.dart';
import 'package:ai_saas/shared/models/admin_analytics_model.dart';
import 'package:ai_saas/shared/widgets/app_card.dart';
import 'package:ai_saas/shared/widgets/empty_state.dart';
import 'package:ai_saas/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminAnalyticsBloc>().add(
          const AdminAnalyticsLoadRequested(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text(
            'تحليلات المنصة',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => context
                  .read<AdminAnalyticsBloc>()
                  .add(const AdminAnalyticsLoadRequested()),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocBuilder<AdminAnalyticsBloc, AdminAnalyticsState>(
          builder: (context, state) {
            if (state is AdminAnalyticsInitial ||
                state is AdminAnalyticsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdminAnalyticsFailure) {
              return ErrorState(
                subtitle: state.message,
                onRetry: () => context
                    .read<AdminAnalyticsBloc>()
                    .add(const AdminAnalyticsLoadRequested()),
              );
            }

            final loaded = state as AdminAnalyticsLoaded;
            final analytics = loaded.analytics;
            if (analytics.isEmpty) {
              return const EmptyState(
                icon: Icons.insights_outlined,
                title: 'لا توجد بيانات للتحليل',
                subtitle: 'ستظهر تحليلات المنصة عند توفر بيانات كافية.',
              );
            }
            return _AnalyticsContent(state: loaded);
          },
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.state});

  final AdminAnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final analytics = state.analytics;
    final status = analytics.orders.byStatus;
    final productStatus = analytics.products.byStatus;
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminAnalyticsBloc>().add(
              const AdminAnalyticsLoadRequested(),
            );
        await context.read<AdminAnalyticsBloc>().stream.firstWhere(
              (state) =>
                  state is AdminAnalyticsLoaded ||
                  state is AdminAnalyticsFailure,
            );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 28.h),
        children: [
          _AiInsightsCard(
            insight: state.aiInsight,
            loading: state.aiLoading,
            error: state.aiError,
            onGenerate: () => context
                .read<AdminAnalyticsBloc>()
                .add(const AdminAiInsightsRequested()),
          ),
          SizedBox(height: 14.h),
          Text(
            'أداء المنصة',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textDark,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'بيانات فعلية لآخر 12 شهراً من واجهة Tradex',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textGray,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 18.h),
          _SectionCard(
            title: 'المبيعات الشهرية',
            icon: Icons.trending_up_rounded,
            child: analytics.sales.monthlySales.isEmpty
                ? const _InlineEmpty(text: 'لا توجد مبيعات مكتملة خلال الفترة.')
                : _SalesChart(sales: analytics.sales.monthlySales),
          ),
          SizedBox(height: 14.h),
          _SectionCard(
            title: 'حالة الطلبات',
            icon: Icons.receipt_long_outlined,
            child: _StatusGrid(
              values: [
                _StatusValue('مكتملة', status.completed, AppColors.green),
                _StatusValue('قيد الانتظار', status.pending, AppColors.orange),
                _StatusValue('مؤكدة', status.confirmed, AppColors.primary),
                _StatusValue(
                    'قيد التنفيذ', status.processing, const Color(0xff0EA5E9)),
                _StatusValue('ملغاة', status.cancelled, AppColors.red),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          _SectionCard(
            title: 'نمو المستخدمين والتجار',
            icon: Icons.people_alt_outlined,
            child: Column(
              children: [
                _GrowthRow(
                  label: 'المستخدمون الجدد',
                  points: analytics.userGrowth,
                  color: AppColors.primary,
                ),
                SizedBox(height: 16.h),
                _GrowthRow(
                  label: 'التجار الجدد',
                  points: analytics.merchantGrowth,
                  color: const Color(0xff0EA5E9),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          _SectionCard(
            title: 'المنتجات حسب الحالة',
            icon: Icons.inventory_2_outlined,
            child: _StatusGrid(
              values: [
                _StatusValue('نشطة', productStatus.active, AppColors.green),
                _StatusValue(
                    'غير نشطة', productStatus.inactive, AppColors.textGray),
                _StatusValue(
                    'نفدت الكمية', productStatus.outOfStock, AppColors.orange),
              ],
            ),
          ),
          if (analytics.products.byCategory.isNotEmpty) ...[
            SizedBox(height: 14.h),
            _SectionCard(
              title: 'المنتجات حسب التصنيف',
              icon: Icons.category_outlined,
              child: _CategoryBars(
                categories: analytics.products.byCategory,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiInsightsCard extends StatelessWidget {
  const _AiInsightsCard({
    required this.insight,
    required this.loading,
    required this.error,
    required this.onGenerate,
  });

  final AdminAiInsight? insight;
  final bool loading;
  final String? error;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'رؤى الذكاء الاصطناعي',
                  style: GoogleFonts.ibmPlexSans(
                    color: AppColors.textDark,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: loading ? null : onGenerate,
                child: const Text('تحليل الآن'),
              ),
            ],
          ),
          if (loading || error != null || insight != null) ...[
            SizedBox(height: 12.h),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Text(
                'تعذر إنشاء التحليل: $error',
                style: GoogleFonts.ibmPlexSans(color: AppColors.red),
              )
            else if (insight == null || insight!.result.isEmpty)
              const Text('لم يُرجع مزود الذكاء الاصطناعي نتيجة.')
            else
              Text(
                insight!.result,
                style: GoogleFonts.ibmPlexSans(
                  color: AppColors.textDark,
                  height: 1.6,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardTitle(text: title, icon: icon),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.sales});

  final List<AdminMonthlySale> sales;

  @override
  Widget build(BuildContext context) {
    final maxRevenue = sales.fold<double>(
      0,
      (max, item) => item.revenue > max ? item.revenue : max,
    );
    return SizedBox(
      height: 190.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sales.map((sale) {
          final factor = maxRevenue == 0 ? 0.0 : sale.revenue / maxRevenue;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _compactNumber(sale.revenue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                      color: AppColors.textGray,
                      fontSize: 9.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    height: (105.h * factor).clamp(4.h, 105.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(6.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    sale.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                      color: AppColors.textLight,
                      fontSize: 9.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GrowthRow extends StatelessWidget {
  const _GrowthRow({
    required this.label,
    required this.points,
    required this.color,
  });

  final String label;
  final List<AdminGrowthPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _InlineEmpty(text: 'لا توجد بيانات لـ $label.');
    }
    final maxCount = points.fold<int>(
      0,
      (max, item) => item.count > max ? item.count : max,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            color: AppColors.textMid,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 72.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.map((point) {
              final factor = maxCount == 0 ? 0.0 : point.count / maxCount;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        point.count.toString(),
                        style: GoogleFonts.ibmPlexSans(
                          color: AppColors.textGray,
                          fontSize: 9.sp,
                        ),
                      ),
                      Container(
                        height: (32.h * factor).clamp(3.h, 32.h),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        point.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexSans(
                          color: AppColors.textLight,
                          fontSize: 8.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.categories});

  final List<AdminCategoryProductCount> categories;

  @override
  Widget build(BuildContext context) {
    final maxCount = categories.fold<int>(
      0,
      (max, item) => item.count > max ? item.count : max,
    );
    return Column(
      children: categories.map((category) {
        final factor = maxCount == 0 ? 0.0 : category.count / maxCount;
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.category,
                      style: GoogleFonts.ibmPlexSans(
                        color: AppColors.textMid,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  Text(
                    category.count.toString(),
                    style: GoogleFonts.ibmPlexSans(
                      color: AppColors.textDark,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: factor,
                  child: Container(
                    height: 7.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({required this.values});

  final List<_StatusValue> values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: values.map((item) {
        return Container(
          width: 132.w,
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value.toString(),
                style: GoogleFonts.ibmPlexSans(
                  color: item.color,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                item.label,
                style: GoogleFonts.ibmPlexSans(
                  color: AppColors.textGray,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatusValue {
  const _StatusValue(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.ibmPlexSans(
        color: AppColors.textGray,
        fontSize: 12.sp,
      ),
    );
  }
}

String _compactNumber(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
}
