import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/core/services/whatsapp_support_service.dart';
import 'package:ai_saas/shared/models/admin_plan_model.dart';
import 'package:ai_saas/shared/models/admin_subscription_model.dart';
import 'package:ai_saas/shared/models/admin_subscription_request_model.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class MerchantSubscriptionScreen extends StatefulWidget {
  const MerchantSubscriptionScreen({super.key});

  @override
  State<MerchantSubscriptionScreen> createState() =>
      _MerchantSubscriptionScreenState();
}

class _MerchantSubscriptionScreenState
    extends State<MerchantSubscriptionScreen> {
  static const Color _primary = Color(0xff4D41DF);
  static const Color _bg = Color(0xffF8F9FD);
  AdminPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<MerchantSubscriptionBloc>();
    bloc.add(const MerchantSubscriptionLoadRequested());
    bloc.add(const MerchantSubscriptionPlansLoadRequested());
    bloc.add(const MerchantSubscriptionRequestsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Color(0xff1A1A1A)),
          title: Text(
            l10n.subscriptionStatus,
            style: GoogleFonts.ibmPlexSans(
              color: const Color(0xff1A1A1A),
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<MerchantSubscriptionBloc, MerchantSubscriptionState>(
          listener: (context, state) {
            if (state is MerchantSubscriptionFailure &&
                (state.requests.isNotEmpty || state.plansError != null)) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is MerchantSubscriptionInitial ||
                (state is MerchantSubscriptionLoading &&
                    state is! MerchantSubscriptionLoaded)) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MerchantSubscriptionFailure &&
                state.subscription == null &&
                state.requests.isEmpty &&
                state.plansError == null) {
              return _Message(
                message: state.message,
                onRetry: () => context
                    .read<MerchantSubscriptionBloc>()
                    .add(const MerchantSubscriptionRequestsLoadRequested()),
              );
            }
            if (state is MerchantSubscriptionLoaded ||
                state is MerchantSubscriptionFailure) {
              final subscription = state is MerchantSubscriptionLoaded
                  ? state.subscription
                  : (state as MerchantSubscriptionFailure).subscription;
              final requests = state is MerchantSubscriptionLoaded
                  ? state.requests
                  : (state as MerchantSubscriptionFailure).requests;
              final plans = state is MerchantSubscriptionLoaded
                  ? state.plans
                  : (state as MerchantSubscriptionFailure).plans;
              final plansLoading =
                  state is MerchantSubscriptionLoaded && state.plansLoading;
              final plansError = state is MerchantSubscriptionFailure
                  ? state.plansError
                  : null;
              final requestsLoading =
                  state is MerchantSubscriptionLoaded && state.requestsLoading;
              return RefreshIndicator(
                onRefresh: () async => context
                    .read<MerchantSubscriptionBloc>()
                    .add(const MerchantSubscriptionRefreshRequested()),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  children: [
                    _buildStatusCard(subscription),
                    SizedBox(height: 18.h),
                    _buildPlanSection(
                      plans,
                      loading: plansLoading,
                      error: plansError,
                    ),
                    SizedBox(height: 18.h),
                    _buildRequestSection(
                      requests,
                      loading: requestsLoading,
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPlanSection(
    List<AdminPlan> plans, {
    required bool loading,
    String? error,
  }) {
    final l10n = AppLocalizations.of(context);
    final selectedId = _selectedPlan?.id;
    final selectedStillAvailable =
        selectedId != null && plans.any((plan) => plan.id == selectedId);
    if (!selectedStillAvailable && _selectedPlan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedPlan = null);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.availablePlans,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xff1A1A1A),
          ),
        ),
        SizedBox(height: 8.h),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null && plans.isEmpty)
          _Message(
            message: error,
            icon: Icons.cloud_off_outlined,
            onRetry: () => context
                .read<MerchantSubscriptionBloc>()
                .add(const MerchantSubscriptionPlansLoadRequested()),
          )
        else if (plans.isEmpty)
          _Message(
            message: l10n.noSubscriptionPlans,
            icon: Icons.card_membership_outlined,
            onRetry: () => context
                .read<MerchantSubscriptionBloc>()
                .add(const MerchantSubscriptionPlansLoadRequested()),
          )
        else ...[
          ...plans.map(_buildPlanCard),
          if (_selectedPlan != null) ...[
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRequestForm(plan: _selectedPlan),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text('${l10n.continueText} ${_selectedPlan!.displayName}'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPlanCard(AdminPlan plan) {
    final selected = _selectedPlan?.id == plan.id;
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      elevation: 0,
      color: selected ? _primary.withValues(alpha: 0.06) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(
          color: selected ? _primary : const Color(0xffECECF2),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => setState(() => _selectedPlan = plan),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.displayName,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? _primary : const Color(0xffAAAAAA),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                '${_priceLabel(plan.monthlyPrice, l10n.monthly)} · '
                '${_priceLabel(plan.yearlyPrice, l10n.yearly)}',
                style: GoogleFonts.ibmPlexSans(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                '${l10n.productLimitLabel}: ${_limitLabel(plan.productLimit)} · '
                '${l10n.storeLimitLabel}: ${_limitLabel(plan.storeLimit)}',
                style: GoogleFonts.ibmPlexSans(
                  color: const Color(0xff707070),
                  fontSize: 12.sp,
                ),
              ),
              if (plan.features.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  plan.features.join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSans(
                    color: const Color(0xff707070),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestSection(
    List<AdminSubscriptionRequest> requests, {
    required bool loading,
  }) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.subscriptionRequests,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1A1A1A),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _showRequestForm,
              icon: const Icon(Icons.add_rounded),
              label: Text(AppLocalizations.of(context).newRequest),
            ),
          ],
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (requests.isEmpty)
          _RequestEmptyState(onCreate: _showRequestForm)
        else
          ...requests.map(_buildRequestCard),
      ],
    );
  }

  Widget _buildRequestCard(AdminSubscriptionRequest request) {
    final l10n = AppLocalizations.of(context);
    final color = _requestStatusColor(request.status);
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: const BorderSide(color: Color(0xffECECF2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => _showRequestDetails(request),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19.r,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(Icons.receipt_long_outlined,
                    color: color, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.plan?.displayName ?? l10n.subscriptionRequestTitle,
                      style: GoogleFonts.ibmPlexSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_billingLabel(request.billingCycle)} · ${request.paymentMethod}',
                      style: GoogleFonts.ibmPlexSans(
                        color: const Color(0xff888888),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(_requestStatusLabel(request.status), color),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetails(AdminSubscriptionRequest request) {
    final bloc = context.read<MerchantSubscriptionBloc>();
    bloc.add(MerchantSubscriptionRequestDetailsRequested(request.id));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _MerchantRequestDetailsSheet(request: request),
      ),
    );
  }

  void _showRequestForm({AdminPlan? plan}) {
    final l10n = AppLocalizations.of(context);
    final selectedPlan = plan ?? _selectedPlan;
    final availablePlans =
        _plansFromState(context.read<MerchantSubscriptionBloc>().state);
    if (selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            availablePlans.isEmpty
                ? AppLocalizations.of(context).noSubscriptionPlans
                : AppLocalizations.of(context).choosePlanFirst,
          ),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<MerchantSubscriptionBloc>(),
        child: _MerchantRequestForm(
          suggestedPlanId: int.tryParse(
            selectedPlan.id,
          ),
        ),
      ),
    );
  }

  List<AdminPlan> _plansFromState(MerchantSubscriptionState state) {
    if (state is MerchantSubscriptionLoaded) return state.plans;
    if (state is MerchantSubscriptionFailure) return state.plans;
    return const [];
  }

  String _priceLabel(double price, String cycle) =>
      '$cycle: ${price.toStringAsFixed(2)}';

  String _limitLabel(int? value) => value == null ? 'غير محدود' : '$value';

  Color _requestStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xff00A878);
      case 'rejected':
        return const Color(0xffE53E3E);
      default:
        return const Color(0xffD58B00);
    }
  }

  String _requestStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return AppLocalizations.of(context).approvedStatus;
      case 'rejected':
        return AppLocalizations.of(context).rejectedStatus;
      case 'pending':
        return AppLocalizations.of(context).pendingStatus;
      default:
        return status.isEmpty ? AppLocalizations.of(context).unknownStatus : status;
    }
  }

  Widget _buildStatusCard(AdminSubscription? subscription) {
    final l10n = AppLocalizations.of(context);
    if (subscription == null) {
      return _Message(
        message: l10n.noSubscriptions,
        icon: Icons.card_membership_outlined,
      );
    }

    final entitled = subscription.isEntitled;
    final isTrial = subscription.isTrial;
    final endsAt = subscription.endsAt;
    final daysRemaining =
        endsAt?.difference(DateTime.now()).inDays.clamp(0, 9999);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isTrial ? Icons.timelapse_rounded : Icons.verified_outlined,
                  color: _primary,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  subscription.planName,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1A1A1A),
                  ),
                ),
              ),
              _statusPill(
                entitled ? AppLocalizations.of(context).activeStatus : AppLocalizations.of(context).expiredStatus,
                entitled ? const Color(0xff00A878) : const Color(0xffE53E3E),
              ),
            ],
          ),
          SizedBox(height: 22.h),
          _detailRow(AppLocalizations.of(context).typeLabel, isTrial ? AppLocalizations.of(context).trialLabel : AppLocalizations.of(context).paidSubscription),
          _detailRow(AppLocalizations.of(context).statusLabel, _statusLabel(subscription.status)),
          if (subscription.startsAt != null)
            _detailRow(
              AppLocalizations.of(context).startedAt,
              '${subscription.startsAt!.day}/${subscription.startsAt!.month}/${subscription.startsAt!.year}',
            ),
          if (subscription.billingCycle.isNotEmpty)
            _detailRow(
                AppLocalizations.of(context).billingCycleLabel, _billingLabel(subscription.billingCycle)),
          if (endsAt != null)
            _detailRow(
              AppLocalizations.of(context).endsAt,
              '${endsAt.day}/${endsAt.month}/${endsAt.year}'
                  '${daysRemaining != null ? ' (${daysRemaining} ${AppLocalizations.of(context).daysRemaining})' : ''}',
            ),
          if (!entitled)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).merchantAccessExpiredMessage,
                    style: GoogleFonts.ibmPlexSans(
                      color: const Color(0xffC53030),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openWhatsAppSupport,
                      icon: const Icon(Icons.chat_rounded),
                      label: Text(
                        AppLocalizations.of(context).supportViaWhatsApp,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openWhatsAppSupport() async {
    final opened = await WhatsAppSupportService.openChat();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).supportViaWhatsApp),
        ),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp, color: const Color(0xff888888))),
          const Spacer(),
          Text(value,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1A1A1A))),
        ],
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(label,
          style: GoogleFonts.ibmPlexSans(
              color: color, fontSize: 12.sp, fontWeight: FontWeight.bold)),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return AppLocalizations.of(context).activeStatus;
      case 'expired':
        return AppLocalizations.of(context).expiredStatus;
      case 'cancelled':
        return AppLocalizations.of(context).cancelledStatus;
      default:
        return status.isEmpty ? AppLocalizations.of(context).unknownStatus : status;
    }
  }

  String _billingLabel(String cycle) {
    switch (cycle) {
      case 'monthly':
        return AppLocalizations.of(context).monthly;
      case 'yearly':
        return AppLocalizations.of(context).yearly;
      default:
        return cycle;
    }
  }
}

class _RequestEmptyState extends StatelessWidget {
  const _RequestEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xffECECF2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined,
              color: Color(0xff888888), size: 34),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).noPreviousSubscriptionRequests,
            style: GoogleFonts.ibmPlexSans(
              color: const Color(0xff707070),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          OutlinedButton(
            onPressed: onCreate,
            child: Text(AppLocalizations.of(context).sendSubscriptionRequest),
          ),
        ],
      ),
    );
  }
}

class _MerchantRequestForm extends StatefulWidget {
  const _MerchantRequestForm({this.suggestedPlanId});

  final int? suggestedPlanId;

  @override
  State<_MerchantRequestForm> createState() => _MerchantRequestFormState();
}

class _MerchantRequestFormState extends State<_MerchantRequestForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _planIdController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _notesController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _proof;
  String _billingCycle = 'monthly';
  String _paymentMethod = 'bank_transfer';

  @override
  void initState() {
    super.initState();
    final user = UserController.instance.currentUser;
    _planIdController =
        TextEditingController(text: widget.suggestedPlanId?.toString() ?? '');
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _planIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xffF8F9FD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child:
              BlocConsumer<MerchantSubscriptionBloc, MerchantSubscriptionState>(
            listener: (context, state) {
              if (state is MerchantSubscriptionLoaded &&
                  state.submissionMessage != null) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(state.submissionMessage!)),
                );
              } else if (state is MerchantSubscriptionFailure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              final submitting =
                  state is MerchantSubscriptionLoaded && state.submitting;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w,
                    20.h + MediaQuery.of(context).viewInsets.bottom),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).requestSubscription,
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 19.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6.h),
                      Text(
                        AppLocalizations.of(context).requestSubscriptionDescription,
                        style: GoogleFonts.ibmPlexSans(
                            color: const Color(0xff707070), fontSize: 12.sp),
                      ),
                      SizedBox(height: 16.h),
                      _field(
                        controller: _planIdController,
                        label: AppLocalizations.of(context).planIdLabel,
                        hint: '2',
                        keyboardType: TextInputType.number,
                        validator: (value) => int.tryParse(value ?? '') == null
                            ? AppLocalizations.of(context).planIdRequired
                            : null,
                      ),
                      SizedBox(height: 10.h),
                      DropdownButtonFormField<String>(
                        value: _billingCycle,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).billingCycleLabel),
                        items: [
                          DropdownMenuItem(
                              value: 'monthly', child: Text(AppLocalizations.of(context).monthly)),
                          DropdownMenuItem(
                              value: 'yearly', child: Text(AppLocalizations.of(context).yearly)),
                        ],
                        onChanged: submitting
                            ? null
                            : (value) => setState(() {
                                  _billingCycle = value ?? 'monthly';
                                }),
                      ),
                      SizedBox(height: 10.h),
                      _field(
                        controller: _nameController,
                        label: AppLocalizations.of(context).fullName,
                        validator: (value) =>
                            value!.trim().isEmpty ? AppLocalizations.of(context).fullNameRequired : null,
                      ),
                      SizedBox(height: 10.h),
                      _field(
                        controller: _phoneController,
                        label: AppLocalizations.of(context).phoneNumber,
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value!.trim().isEmpty ? AppLocalizations.of(context).phoneRequired : null,
                      ),
                      SizedBox(height: 10.h),
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).paymentMethodLabel),
                        items: [
                          DropdownMenuItem(
                              value: 'bank_transfer',
                              child: Text(AppLocalizations.of(context).bankTransfer)),
                          DropdownMenuItem(
                              value: 'cash', child: Text(AppLocalizations.of(context).cash)),
                        ],
                        onChanged: submitting
                            ? null
                            : (value) => setState(() {
                                  _paymentMethod = value ?? 'bank_transfer';
                                }),
                      ),
                      SizedBox(height: 10.h),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).notesOptional,
                          alignLabelWithHint: true,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      OutlinedButton.icon(
                        onPressed: submitting ? null : _pickProof,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(_proof == null
                            ? AppLocalizations.of(context).selectPaymentProofLabel
                            : _proof!.name),
                      ),
                      if (_proof == null)
                        Padding(
                          padding: EdgeInsets.only(top: 5.h),
                          child: Text(
                            AppLocalizations.of(context).paymentProofRequirements,
                            style: GoogleFonts.ibmPlexSans(
                                color: const Color(0xff888888),
                                fontSize: 11.sp),
                          ),
                        ),
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitting ? null : _submit,
                          child: submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(AppLocalizations.of(context).sendRequestLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  TextFormField _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Future<void> _pickProof() async {
    final proof = await _picker.pickImage(source: ImageSource.gallery);
    if (proof != null && mounted) setState(() => _proof = proof);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final proof = _proof;
    if (proof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).paymentProofRequired)),
      );
      return;
    }
    context.read<MerchantSubscriptionBloc>().add(
          MerchantSubscriptionRequestSubmitRequested(
            planId: int.parse(_planIdController.text.trim()),
            billingCycle: _billingCycle,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            paymentMethod: _paymentMethod,
            paymentProof: proof,
            notes: _notesController.text.trim(),
          ),
        );
  }
}

class _MerchantRequestDetailsSheet extends StatelessWidget {
  const _MerchantRequestDetailsSheet({required this.request});

  final AdminSubscriptionRequest request;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child:
              BlocBuilder<MerchantSubscriptionBloc, MerchantSubscriptionState>(
            builder: (context, state) {
              final selected = state is MerchantSubscriptionLoaded
                  ? state.selectedRequest ?? request
                  : request;
              final loading =
                  state is MerchantSubscriptionLoaded && state.detailsLoading;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(AppLocalizations.of(context).subscriptionRequestDetails,
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 18.sp, fontWeight: FontWeight.bold)),
                      ),
                      if (loading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  _line(AppLocalizations.of(context).planId, selected.plan?.displayName ?? '—'),
                  _line(AppLocalizations.of(context).statusLabel, selected.status),
                  _line(AppLocalizations.of(context).billingCycleLabel, selected.billingCycle),
                  _line(AppLocalizations.of(context).paymentMethodLabel, selected.paymentMethod),
                  _line(AppLocalizations.of(context).fullName, selected.fullName),
                  _line(AppLocalizations.of(context).phoneNumber, selected.phone),
                  if (selected.rejectionReason != null)
                    _line('سبب الرفض', selected.rejectionReason!),
                  if (selected.notes != null && selected.notes!.isNotEmpty)
                    _line(AppLocalizations.of(context).notesOptional, selected.notes!),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 11.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105.w,
            child: Text(label,
                style: GoogleFonts.ibmPlexSans(
                    color: const Color(0xff888888), fontSize: 12.sp)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.ibmPlexSans(
                    color: const Color(0xff1A1A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry, this.icon});

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.error_outline,
                size: 42.sp, color: const Color(0xff888888)),
            SizedBox(height: 12.h),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 14.sp, color: const Color(0xff707070))),
            if (onRetry != null) ...[
              SizedBox(height: 8.h),
              TextButton(
                  onPressed: onRetry, child: Text(AppLocalizations.of(context).retry)),
            ],
          ],
        ),
      ),
    );
  }
}
