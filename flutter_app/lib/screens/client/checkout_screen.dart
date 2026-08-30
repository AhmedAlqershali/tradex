import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/client/order_confirmation_screen.dart';
import 'package:ai_saas/shared/cart/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color _primary    = Color(0xff4D41DF);
  static const Color _scaffoldBg = Color(0xffF8F9FD);
  static const Color _textDark   = Color(0xff1A1A1A);
  static const Color _textGray   = Color(0xff888888);
  static const Color _cardBg     = Colors.white;
  static const Color _fieldFill  = Color(0xffF3F3F8);

  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController(text: '');
  final _phoneCtrl = TextEditingController(text: '');
  final _cityCtrl  = TextEditingController(text: '');
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _confirmOrder(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<OrderBloc>().add(OrderCreateRequested(
          customerName: _nameCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim(),
          customerCity: _cityCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderCreated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderConfirmationScreen(orders: state.orders),
            ),
          );
        } else if (state is OrderFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message, style: GoogleFonts.ibmPlexSans()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        final isLoading = state is OrderLoading;
        final l10n = AppLocalizations.of(context);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: _scaffoldBg,
            appBar: _buildAppBar(context),
            body: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProgressBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(l10n.deliveryInfo),
                          SizedBox(height: 14.h),
                          _buildCard(
                            children: [
                              _buildField(
                                context: context,
                                label: l10n.fullName,
                                hint: l10n.fullNameExample,
                                icon: Icons.person_outline,
                                controller: _nameCtrl,
                                isRequired: true,
                              ),
                              SizedBox(height: 14.h),
                              _buildField(
                                context: context,
                                label: l10n.phoneNumber,
                                hint: l10n.phoneNumberExample,
                                icon: Icons.phone_outlined,
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                isRequired: true,
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          _buildSectionTitle(l10n.address),
                          SizedBox(height: 14.h),
                          _buildCard(
                            children: [
                              _buildField(
                                context: context,
                                label: l10n.city,
                                hint: l10n.cityExample,
                                icon: Icons.location_city_outlined,
                                controller: _cityCtrl,
                                isRequired: true,
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          _buildSectionTitle(l10n.additionalNotes),
                          SizedBox(height: 14.h),
                          _buildCard(
                            children: [
                              _buildField(
                                context: context,
                                label: l10n.notes,
                                hint: l10n.deliveryNoteHint,
                                icon: Icons.notes_outlined,
                                controller: _notesCtrl,
                                maxLines: 3,
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),

                          // Order summary
                          _buildOrderSummaryCard(context),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),

                  // Confirm button
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _confirmOrder(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                l10n.confirmRequest,
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: _textDark, size: 20.sp),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      title: Text(
        l10n.checkout,
        style: GoogleFonts.ibmPlexSans(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4.h,
      color: const Color(0xffEDE9FF),
      child: FractionallySizedBox(
        alignment: Alignment.centerRight,
        widthFactor: 0.66,
        child: Container(color: _primary),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: _textDark,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context) {
    final items = CartController.instance.items;
    final total = items.fold<double>(0, (s, i) => s + i.lineTotal);
    final l10n = AppLocalizations.of(context);

    return _buildCard(children: [
      Text(
        l10n.orderTotal,
        style: GoogleFonts.ibmPlexSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: _textDark),
      ),
      SizedBox(height: 12.h),
      ...items.map(
        (item) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${item.name} × ${item.quantity}',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.sp, color: _textGray),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '₪${item.lineTotal.toStringAsFixed(0)}',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _textDark),
              ),
            ],
          ),
        ),
      ),
      Divider(height: 20.h, color: const Color(0xffF0F0F0)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.orderTotal,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: _textDark)),
          Text('₪${total.toStringAsFixed(0)}',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: _primary)),
        ],
      ),
    ]);
  }

  Widget _buildField({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _textDark)),
            if (isRequired)
              Text(' *',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.sp, color: Colors.redAccent)),
          ],
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          textDirection: TextDirection.rtl,
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? l10n.requiredFieldMessage : null
              : null,
          style: GoogleFonts.ibmPlexSans(fontSize: 13.sp, color: _textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.ibmPlexSans(
                fontSize: 12.sp, color: const Color(0xffBBBBBB)),
            prefixIcon:
                Icon(icon, size: 18.sp, color: const Color(0xffBBBBBB)),
            filled: true,
            fillColor: _fieldFill,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                  color: _primary.withValues(alpha: 0.5), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
