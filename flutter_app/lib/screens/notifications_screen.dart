import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/core/services/fcm_service.dart';
import 'package:ai_saas/shared/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _primary = Color(0xff4D41DF);
  static const _background = Color(0xffF8F9FD);
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPageWhenNeeded);
    context.read<NotificationsBloc>().add(const NotificationsLoadRequested());
  }

  void _loadNextPageWhenNeeded() {
    if (_scrollController.position.extentAfter < 240) {
      context.read<NotificationsBloc>().add(
            const NotificationsNextPageRequested(),
          );
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPageWhenNeeded)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: Text(
            l10n.notifications,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1A1A1A),
            ),
          ),
          actions: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                final hasUnread =
                    state is NotificationsLoaded && state.unreadCount > 0;
                return IconButton(
                  tooltip: l10n.markAllRead,
                  onPressed: hasUnread
                      ? () => context.read<NotificationsBloc>().add(
                            const NotificationsMarkAllReadRequested(),
                          )
                      : null,
                  icon: const Icon(Icons.done_all_rounded),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsInitial ||
                (state is NotificationsLoading && state.items.isEmpty)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationsFailure && state.items.isEmpty) {
              return _MessageState(
                icon: Icons.notifications_off_outlined,
                message: state.message,
                actionLabel: l10n.retry,
                onAction: () => context
                    .read<NotificationsBloc>()
                    .add(const NotificationsLoadRequested()),
              );
            }

            final items = switch (state) {
              NotificationsLoaded(:final items) => items,
              NotificationsLoading(:final items) => items,
              NotificationsFailure(:final items) => items,
              _ => const <AppNotification>[],
            };

            if (items.isEmpty) {
              return _MessageState(
                icon: Icons.notifications_none_rounded,
                message: l10n.noNotifications,
              );
            }

            return RefreshIndicator(
              color: _primary,
              onRefresh: () => context.read<NotificationsBloc>().refresh(),
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.r),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, index) => _NotificationTile(
                  notification: items[index],
                  onTap: () {
                    final notification = items[index];
                    context.read<NotificationsBloc>().add(
                          NotificationReadRequested(notification.id),
                        );
                    FcmService.instance.openData(notification.data);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xffF0EEFF),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: notification.isRead
                ? const Color(0xffEEEEEE)
                : const Color(0xffDCD8FF),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xff4D41DF).withValues(alpha: .12),
              child: Icon(
                _iconFor(notification.type),
                color: const Color(0xff4D41DF),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff1A1A1A),
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: const BoxDecoration(
                            color: Color(0xff4D41DF),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    notification.message,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.sp,
                      color: const Color(0xff707070),
                      height: 1.35,
                    ),
                  ),
                  if (notification.createdAt != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      _formatDate(notification.createdAt!),
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11.sp,
                        color: const Color(0xff999999),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    if (type.startsWith('order')) return Icons.receipt_long_outlined;
    if (type.startsWith('subscription')) return Icons.card_membership_outlined;
    return Icons.notifications_none_rounded;
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 58.sp, color: Colors.black26),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14.sp,
                color: const Color(0xff707070),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 18.h),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
