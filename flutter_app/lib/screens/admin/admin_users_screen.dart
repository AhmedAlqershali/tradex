import 'dart:async';

import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/presentation/blocs/admin_users/admin_users_bloc.dart';
import 'package:ai_saas/shared/models/admin_user_model.dart';
import 'package:ai_saas/shared/widgets/empty_state.dart';
import 'package:ai_saas/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    context.read<AdminUsersBloc>().add(const AdminUsersLoadRequested());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<AdminUsersBloc>().add(AdminUsersSearchChanged(value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text(
            'إدارة المستخدمين',
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
                  .read<AdminUsersBloc>()
                  .add(const AdminUsersLoadRequested()),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocConsumer<AdminUsersBloc, AdminUsersState>(
          listener: (context, state) {
            if (state is AdminUsersFailure && state.previousPage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final page = _pageFrom(state);
            if (page == null) {
              if (state is AdminUsersFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersLoadRequested()),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            return _UsersContent(
              page: page,
              loading: state is AdminUsersLoading,
              searchController: _searchController,
              onSearchChanged: _searchChanged,
              onRoleChanged: (value) => context
                  .read<AdminUsersBloc>()
                  .add(AdminUsersRoleFilterChanged(value)),
              onStatusChanged: (value) => context
                  .read<AdminUsersBloc>()
                  .add(AdminUsersStatusFilterChanged(value)),
              onPageChanged: (value) => context
                  .read<AdminUsersBloc>()
                  .add(AdminUsersPageRequested(value)),
            );
          },
        ),
      ),
    );
  }

  AdminUserPage? _pageFrom(AdminUsersState state) {
    if (state is AdminUsersLoaded) return state.page;
    if (state is AdminUsersLoading) return state.previousPage;
    if (state is AdminUsersFailure) return state.previousPage;
    return null;
  }
}

class _UsersContent extends StatelessWidget {
  const _UsersContent({
    required this.page,
    required this.loading,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onPageChanged,
  });

  final AdminUserPage page;
  final bool loading;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو البريد أو الهاتف',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'الدور',
                  value: null,
                  options: const {
                    'client': 'عميل',
                    'merchant': 'تاجر',
                    'admin': 'مدير',
                  },
                  onChanged: onRoleChanged,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _FilterDropdown(
                  label: 'الحالة',
                  value: null,
                  options: const {
                    'active': 'نشط',
                    'inactive': 'غير نشط',
                    'banned': 'محظور',
                  },
                  onChanged: onStatusChanged,
                ),
              ),
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: page.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'لا يوجد مستخدمون',
                  subtitle: 'جرّب تغيير البحث أو الفلاتر.',
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  itemCount: page.users.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final user = page.users[index];
                    return _UserCard(
                      user: user,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              AdminUserDetailsScreen(userId: user.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (page.pagination.lastPage > 1)
          _Pagination(
            pagination: page.pagination,
            onPageChanged: onPageChanged,
          ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      hint: Text('الكل', style: GoogleFonts.ibmPlexSans(fontSize: 13.sp)),
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: Text('الكل', style: GoogleFonts.ibmPlexSans(fontSize: 13.sp)),
        ),
        ...options.entries.map(
          (entry) => DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: GoogleFonts.ibmPlexSans(fontSize: 13.sp),
            ),
          ),
        ),
      ],
      onChanged: (selected) => onChanged(
        selected == null || selected.isEmpty ? null : selected,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});

  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: AppColors.primarySoft,
              backgroundImage:
                  user.avatar == null ? null : NetworkImage(user.avatar!),
              child: user.avatar == null
                  ? Text(
                      user.displayName.characters.first.toUpperCase(),
                      style: GoogleFonts.ibmPlexSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                      color: AppColors.textDark,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    user.email.isEmpty ? user.phone : user.email,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Badge(label: _roleLabel(user.role), color: AppColors.primary),
                SizedBox(height: 5.h),
                _Badge(
                  label: _statusLabel(user.status),
                  color: _statusColor(user.status),
                ),
              ],
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_left_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSans(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.pagination, required this.onPageChanged});

  final AdminUserPagination pagination;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: pagination.hasPrevious
                ? () => onPageChanged(pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          Text(
            '${pagination.currentPage} / ${pagination.lastPage}',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: pagination.hasNext
                ? () => onPageChanged(pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
    );
  }
}

class AdminUserDetailsScreen extends StatefulWidget {
  const AdminUserDetailsScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<AdminUsersBloc>()
        .add(AdminUserDetailsRequested(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(title: const Text('تفاصيل المستخدم')),
        body: BlocConsumer<AdminUsersBloc, AdminUsersState>(
          listener: (context, state) {
            if (state is AdminUsersFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final user = _selectedUser(state);
            if (user == null) {
              if (state is AdminUsersFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context
                      .read<AdminUsersBloc>()
                      .add(AdminUserDetailsRequested(widget.userId)),
                );
              }
              if (state is AdminUsersLoaded && state.selectedUser == null) {
                return const EmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'المستخدم غير متوفر',
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            return _DetailsContent(
              user: user,
              loading: state is AdminUsersLoading,
              onRole: () => _chooseRole(context, user),
              onStatus: () => _chooseStatus(context, user),
              onDelete: () => _confirmDelete(context, user),
            );
          },
        ),
      ),
    );
  }

  AdminUser? _selectedUser(AdminUsersState state) {
    if (state is AdminUsersLoaded) return state.selectedUser;
    if (state is AdminUsersLoading) return state.selectedUser;
    if (state is AdminUsersFailure) return state.selectedUser;
    return null;
  }

  Future<void> _chooseRole(BuildContext context, AdminUser user) async {
    final role = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('تغيير الدور'),
        children: const [
          SimpleDialogOption(value: 'client', child: Text('عميل')),
          SimpleDialogOption(value: 'merchant', child: Text('تاجر')),
          SimpleDialogOption(value: 'admin', child: Text('مدير')),
        ],
      ),
    );
    if (role != null && role != user.role && context.mounted) {
      context.read<AdminUsersBloc>().add(
            AdminUserRoleUpdateRequested(userId: user.id, role: role),
          );
    }
  }

  Future<void> _chooseStatus(BuildContext context, AdminUser user) async {
    final status = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('تغيير الحالة'),
        children: const [
          SimpleDialogOption(value: 'active', child: Text('نشط')),
          SimpleDialogOption(value: 'inactive', child: Text('غير نشط')),
          SimpleDialogOption(value: 'banned', child: Text('محظور')),
        ],
      ),
    );
    if (status != null && status != user.status && context.mounted) {
      context.read<AdminUsersBloc>().add(
            AdminUserStatusUpdateRequested(userId: user.id, status: status),
          );
    }
  }

  Future<void> _confirmDelete(BuildContext context, AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستخدم؟'),
        content: Text('سيتم حذف حساب ${user.displayName} نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AdminUsersBloc>().add(AdminUserDeleteRequested(user.id));
    }
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.user,
    required this.loading,
    required this.onRole,
    required this.onStatus,
    required this.onDelete,
  });

  final AdminUser user;
  final bool loading;
  final VoidCallback onRole;
  final VoidCallback onStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36.r,
                backgroundColor: AppColors.primarySoft,
                backgroundImage:
                    user.avatar == null ? null : NetworkImage(user.avatar!),
                child: user.avatar == null
                    ? Text(
                        user.displayName.characters.first.toUpperCase(),
                        style: GoogleFonts.ibmPlexSans(
                          color: AppColors.primary,
                          fontSize: 25.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              SizedBox(height: 10.h),
              Text(
                user.displayName,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                user.email,
                style: GoogleFonts.ibmPlexSans(color: AppColors.textGray),
              ),
              SizedBox(height: 16.h),
              _DetailRow(label: 'الهاتف', value: user.phone),
              _DetailRow(label: 'الدور', value: _roleLabel(user.role)),
              _DetailRow(label: 'الحالة', value: _statusLabel(user.status)),
              _DetailRow(
                label: 'تاريخ التسجيل',
                value: _formatDate(user.createdAt),
              ),
              _DetailRow(
                label: 'البريد موثق',
                value: user.emailVerifiedAt == null ? 'لا' : 'نعم',
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        if (loading) const LinearProgressIndicator(),
        SizedBox(height: 12.h),
        OutlinedButton.icon(
          onPressed: loading ? null : onRole,
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('تغيير الدور'),
        ),
        SizedBox(height: 8.h),
        OutlinedButton.icon(
          onPressed: loading ? null : onStatus,
          icon: const Icon(Icons.toggle_on_outlined),
          label: const Text('تغيير الحالة'),
        ),
        SizedBox(height: 8.h),
        OutlinedButton.icon(
          onPressed: loading ? null : onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('حذف المستخدم'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Text(
            '$label:',
            style: GoogleFonts.ibmPlexSans(color: AppColors.textGray),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.ibmPlexSans(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'merchant':
      return 'تاجر';
    case 'admin':
      return 'مدير';
    default:
      return 'عميل';
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'inactive':
      return 'غير نشط';
    case 'banned':
      return 'محظور';
    default:
      return 'نشط';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'inactive':
      return AppColors.orange;
    case 'banned':
      return AppColors.red;
    default:
      return AppColors.green;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
}
