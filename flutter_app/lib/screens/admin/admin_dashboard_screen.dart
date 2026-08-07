import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/presentation/blocs/admin_dashboard/admin_dashboard_bloc.dart';
import 'package:ai_saas/shared/models/admin_dashboard_model.dart';
import 'package:ai_saas/shared/widgets/empty_state.dart';
import 'package:ai_saas/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardBloc>().add(
          const AdminDashboardLoadRequested(),
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
            'لوحة تحكم الإدارة',
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
                  .read<AdminDashboardBloc>()
                  .add(const AdminDashboardLoadRequested()),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
          builder: (context, state) {
            if (state is AdminDashboardInitial ||
                state is AdminDashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdminDashboardFailure) {
              return ErrorState(
                subtitle: state.message,
                onRetry: () => context
                    .read<AdminDashboardBloc>()
                    .add(const AdminDashboardLoadRequested()),
              );
            }

            final dashboard = (state as AdminDashboardLoaded).dashboard;
            if (dashboard.isEmpty) {
              return const EmptyState(
                icon: Icons.dashboard_outlined,
                title: 'لا توجد بيانات للعرض',
                subtitle: 'ستظهر إحصائيات المنصة هنا عند توفر البيانات.',
              );
            }
            return _DashboardContent(dashboard: dashboard);
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.dashboard});

  final AdminDashboardModel dashboard;

  @override
  Widget build(BuildContext context) {
    final overview = dashboard.overview;
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<AdminDashboardBloc>()
            .add(const AdminDashboardLoadRequested());
        await context.read<AdminDashboardBloc>().stream.firstWhere(
              (state) =>
                  state is AdminDashboardLoaded ||
                  state is AdminDashboardFailure,
            );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 28.h),
        children: [
          Text(
            'ملخص المنصة',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textDark,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'إحصائيات محدثة من بيانات Tradex الفعلية',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textGray,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 18.h),
          _StatsGrid(
            cards: [
              _StatCardData(
                title: 'المستخدمون',
                value: overview.users.total.toString(),
                detail:
                    '${overview.users.clients} عميل • ${overview.users.merchants} تاجر',
                icon: Icons.people_alt_outlined,
                color: AppColors.primary,
              ),
              _StatCardData(
                title: 'المتاجر',
                value: overview.stores.total.toString(),
                detail: '${overview.stores.active} متجر نشط',
                icon: Icons.storefront_outlined,
                color: const Color(0xff0EA5E9),
              ),
              _StatCardData(
                title: 'المنتجات',
                value: overview.products.total.toString(),
                detail: '${overview.products.outOfStock} غير متوفر',
                icon: Icons.inventory_2_outlined,
                color: AppColors.orange,
              ),
              _StatCardData(
                title: 'الطلبات',
                value: overview.orders.total.toString(),
                detail: '${overview.orders.pending} قيد الانتظار',
                icon: Icons.receipt_long_outlined,
                color: AppColors.green,
              ),
            ],
          ),
          SizedBox(height: 18.h),
          _SalesCard(totalSales: overview.totalSales),
          if (dashboard.recentOrders.isNotEmpty) ...[
            SizedBox(height: 22.h),
            _SectionTitle(title: 'أحدث الطلبات'),
            SizedBox(height: 8.h),
            ...dashboard.recentOrders
                .take(5)
                .map((order) => _OrderTile(order: order)),
          ],
          if (dashboard.newestUsers.isNotEmpty) ...[
            SizedBox(height: 22.h),
            _SectionTitle(title: 'أحدث المستخدمين'),
            SizedBox(height: 8.h),
            ...dashboard.newestUsers
                .take(5)
                .map((user) => _UserTile(user: user)),
          ],
          if (dashboard.newestStores.isNotEmpty) ...[
            SizedBox(height: 22.h),
            _SectionTitle(title: 'أحدث المتاجر'),
            SizedBox(height: 8.h),
            ...dashboard.newestStores.take(5).map((store) => _ActivityTile(
                  icon: Icons.storefront_outlined,
                  title: store.name,
                  subtitle: store.ownerName.isEmpty
                      ? store.status
                      : '${store.ownerName} • ${store.status}',
                )),
          ],
          if (dashboard.newestProducts.isNotEmpty) ...[
            SizedBox(height: 22.h),
            _SectionTitle(title: 'أحدث المنتجات'),
            SizedBox(height: 8.h),
            ...dashboard.newestProducts.take(5).map((product) => _ActivityTile(
                  icon: Icons.inventory_2_outlined,
                  title: product.name,
                  subtitle: product.storeName.isEmpty
                      ? product.status
                      : '${product.storeName} • ${product.status}',
                )),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.cards});

  final List<_StatCardData> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) => _StatCard(data: cards[index]),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  data.title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSans(
                    color: AppColors.textGray,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(data.icon, color: data.color, size: 19.sp),
              ),
            ],
          ),
          Text(
            data.value,
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textDark,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            data.detail,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textLight,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({required this.totalSales});

  final double totalSales;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(11.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payments_outlined,
              color: Colors.white,
              size: 25.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إجمالي المبيعات المكتملة',
                style: GoogleFonts.ibmPlexSans(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                '${totalSales.toStringAsFixed(2)} ₪',
                style: GoogleFonts.ibmPlexSans(
                  color: Colors.white,
                  fontSize: 23.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.ibmPlexSans(
        color: AppColors.textDark,
        fontSize: 17.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19.r,
            backgroundColor: AppColors.primarySoft,
            child: Icon(icon, color: AppColors.primary, size: 19.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSans(
                    color: AppColors.textDark,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                      color: AppColors.textGray,
                      fontSize: 11.sp,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final AdminUserActivity user;

  @override
  Widget build(BuildContext context) {
    return _ActivityTile(
      icon: Icons.person_outline,
      title: user.name,
      subtitle: user.email.isEmpty
          ? '${user.role} • ${user.status}'
          : '${user.email} • ${user.role}',
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final AdminOrderActivity order;

  @override
  Widget build(BuildContext context) {
    final amount =
        order.amount > 0 ? ' • ${order.amount.toStringAsFixed(2)} ₪' : '';
    return _ActivityTile(
      icon: Icons.receipt_long_outlined,
      title: order.customerName,
      subtitle:
          '${order.storeName.isEmpty ? order.status : order.storeName} • ${order.status}$amount',
    );
  }
}
