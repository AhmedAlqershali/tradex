import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/location_service.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/shared/users/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Opens the single location selection flow used by Home and Categories.
Future<void> showLocationSelector(
  BuildContext context, {
  VoidCallback? onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LocationSelector(onSelected: onSelected),
  );
}

class _LocationSelector extends StatefulWidget {
  const _LocationSelector({this.onSelected});

  final VoidCallback? onSelected;

  @override
  State<_LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<_LocationSelector> {
  bool _isSaving = false;
  String? _error;

  AppUser? get _user => UserController.instance.currentUser;

  Future<void> _useDeviceLocation() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final result = await LocationService.instance.getCurrentLocation();
      await UserController.instance.updateLocation(
        region: result.region,
        locationName: result.locationName,
        latitude: result.position.latitude,
        longitude: result.position.longitude,
      );
      if (!mounted) return;
      widget.onSelected?.call();
      Navigator.of(context).pop();
    } on LocationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر حفظ الموقع. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectRegion(String region) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await UserController.instance.updateLocation(
        region: region,
        locationName: region,
        latitude: null,
        longitude: null,
      );
      if (!mounted) return;
      widget.onSelected?.call();
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر حفظ المنطقة. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _user?.region;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
          decoration: BoxDecoration(
            color: const Color(0xffF8F9FD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'اختر موقعك',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _user?.locationName ?? selected ?? 'لم يتم تحديد موقع',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.sp,
                  color: const Color(0xff777777),
                ),
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _useDeviceLocation,
                  icon: _isSaving
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(
                    _isSaving ? 'جارٍ تحديد الموقع...' : 'استخدم موقعي الحالي',
                  ),
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 8.h),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12.sp,
                    color: const Color(0xffB42318),
                  ),
                ),
              ],
              SizedBox(height: 14.h),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'أو اختر المنطقة يدوياً',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: LocationService.supportedRegions.map((region) {
                  final isSelected = region == selected;
                  return ChoiceChip(
                    label: Text(region),
                    selected: isSelected,
                    onSelected: (_) => _selectRegion(region),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
