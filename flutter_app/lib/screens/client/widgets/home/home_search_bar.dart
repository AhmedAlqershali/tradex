import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── HomeSearchBar ────────────────────────────────────────────────────────────
//
// Search input on the shopper home page; submitting navigates to SearchScreen.
// ─────────────────────────────────────────────────────────────────────────────

class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({super.key});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _ctrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SearchScreen(initialQuery: query.isEmpty ? null : query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          controller: _ctrl,
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.ibmPlexSans(fontSize: 14.sp),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: l10n.search,
            hintStyle: GoogleFonts.ibmPlexSans(
                color: Colors.black38, fontSize: 13.sp),
            prefixIcon: GestureDetector(
              onTap: _submit,
              child: Icon(Icons.search_rounded,
                  color: Colors.black38, size: 22.sp),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          ),
        ),
      ),
    );
  }
}
