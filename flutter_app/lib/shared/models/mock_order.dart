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
  merchantContacted,
  orderConfirmed,
  preparing,
  completed,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendingReview:     return 'قيد المراجعة';
      case OrderStatus.merchantContacted: return 'تم التواصل';
      case OrderStatus.orderConfirmed:    return 'تم تأكيد الطلب';
      case OrderStatus.preparing:         return 'جاري تجهيز الطلب';
      case OrderStatus.completed:         return 'مكتمل';
      case OrderStatus.cancelled:         return 'ملغي';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pendingReview:     return const Color(0xffF59E0B);
      case OrderStatus.merchantContacted: return const Color(0xff4D41DF);
      case OrderStatus.orderConfirmed:    return const Color(0xff0891B2);
      case OrderStatus.preparing:         return const Color(0xffEA580C);
      case OrderStatus.completed:         return const Color(0xff00C896);
      case OrderStatus.cancelled:         return const Color(0xffE53E3E);
    }
  }

  Color get bgColor => color.withValues(alpha: 0.12);

  IconData get icon {
    switch (this) {
      case OrderStatus.pendingReview:     return Icons.hourglass_top_rounded;
      case OrderStatus.merchantContacted: return Icons.phone_in_talk_outlined;
      case OrderStatus.orderConfirmed:    return Icons.check_circle_outline_rounded;
      case OrderStatus.preparing:         return Icons.inventory_2_outlined;
      case OrderStatus.completed:         return Icons.done_all_rounded;
      case OrderStatus.cancelled:         return Icons.cancel_outlined;
    }
  }

  /// Index in the 5-step forward timeline (0–4). Returns -1 for cancelled.
  int get timelineStep {
    switch (this) {
      case OrderStatus.pendingReview:     return 0;
      case OrderStatus.merchantContacted: return 1;
      case OrderStatus.orderConfirmed:    return 2;
      case OrderStatus.preparing:         return 3;
      case OrderStatus.completed:         return 4;
      case OrderStatus.cancelled:         return -1;
    }
  }
}
