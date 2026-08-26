import 'package:flutter/material.dart';

// ─── OrderStatus ──────────────────────────────────────────────────────────────
//
// The canonical order-status enum and its UI helpers.
// Used by AppOrder (order_controller.dart), all order screens, and OrderBloc.
//
// MockOrder and MockOrderProduct have been removed — all order data now comes
// from the backend via OrderBloc (GET /orders, GET /orders/merchant).
// ─────────────────────────────────────────────────────────────────────────────

enum OrderStatus {
  pendingReview,
  orderConfirmed,
  completed,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendingReview:     return 'قيد المراجعة';
      case OrderStatus.orderConfirmed:    return 'تم تأكيد الطلب';
      case OrderStatus.completed:         return 'مكتمل';
      case OrderStatus.cancelled:         return 'ملغي';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pendingReview:     return const Color(0xffF59E0B);
      case OrderStatus.orderConfirmed:    return const Color(0xff0891B2);
      case OrderStatus.completed:         return const Color(0xff00C896);
      case OrderStatus.cancelled:         return const Color(0xffE53E3E);
    }
  }

  Color get bgColor => color.withValues(alpha: 0.12);

  IconData get icon {
    switch (this) {
      case OrderStatus.pendingReview:     return Icons.hourglass_top_rounded;
      case OrderStatus.orderConfirmed:    return Icons.check_circle_outline_rounded;
      case OrderStatus.completed:         return Icons.done_all_rounded;
      case OrderStatus.cancelled:         return Icons.cancel_outlined;
    }
  }

  /// Index in the 3-step forward timeline (0–2). Returns -1 for cancelled.
  int get timelineStep {
    switch (this) {
      case OrderStatus.pendingReview:     return 0;
      case OrderStatus.orderConfirmed:    return 1;
      case OrderStatus.completed:         return 2;
      case OrderStatus.cancelled:         return -1;
    }
  }
}
