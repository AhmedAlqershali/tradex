import 'dart:io';

import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/shared/navigation/nav_shell.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfileMerchantScreen extends StatefulWidget {
final AppType type;

const CompleteProfileMerchantScreen({
super.key,
required this.type,
});

@override
State<CompleteProfileMerchantScreen> createState() =>
_CompleteProfileMerchantScreenState();
}

class _CompleteProfileMerchantScreenState
extends State<CompleteProfileMerchantScreen> {
final _formKey = GlobalKey<FormState>();

final TextEditingController _storeNameController =
TextEditingController();

final TextEditingController _addressDetailController =
TextEditingController();

final TextEditingController _descriptionController =
TextEditingController();

final TextEditingController _whatsappController =
TextEditingController();

final TextEditingController _workHoursController =
TextEditingController();

String? _selectedRegion;
String? _selectedCategory;

File? _logoFile;

bool _isLoading = false;

final ImagePicker _picker = ImagePicker();

static const Color primaryColor = Color(0xff4D41DF);
static const Color textColor = Color(0xff0d1e3d);
static const Color inputBackground = Color(0xffF8F9FD);
static const Color inputBorder = Color(0xffEFEFEF);

@override
void dispose() {
_storeNameController.dispose();
_addressDetailController.dispose();
_descriptionController.dispose();
_whatsappController.dispose();
_workHoursController.dispose();
super.dispose();
}

// ============================================================
// IMAGE PICKER
// ============================================================

Future<void> _pickLogo(ImageSource source) async {
try {
final XFile? pickedFile = await _picker.pickImage(
source: source,
imageQuality: 70,
);

if (pickedFile == null || !mounted) {
return;
}

setState(() {
_logoFile = File(pickedFile.path);
});
} catch (e) {
debugPrint('خطأ أثناء التقاط شعار المتجر: $e');

if (!mounted) {
return;
}

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تعذر اختيار صورة الشعار'),
backgroundColor: Colors.redAccent,
),
);
}
}

void _showLogoSourceBottomSheet() {
showModalBottomSheet(
context: context,
backgroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(
top: Radius.circular(20.r),
),
),
builder: (sheetContext) {
return Directionality(
textDirection: TextDirection.rtl,
child: SafeArea(
top: false,
child: Padding(
padding: EdgeInsets.fromLTRB(
20.w,
20.h,
20.w,
20.h + MediaQuery.of(sheetContext).viewPadding.bottom,
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
'اختر مصدر شعار المتجر',
style: GoogleFonts.ibmPlexSans(
fontSize: 16.sp,
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 20.h),
_buildSourceTile(
Icons.photo_library,
'المعرض (Gallery)',
ImageSource.gallery,
),
_buildSourceTile(
Icons.camera_alt,
'الكاميرا (Camera)',
ImageSource.camera,
),
],
),
),
),
);
},
);
}

Widget _buildSourceTile(
IconData icon,
String title,
ImageSource source,
) {
return ListTile(
leading: const Icon(
Icons.arrow_back_ios_new_rounded,
size: 16,
color: Colors.transparent,
),
trailing: Icon(
icon,
color: primaryColor,
),
title: Text(
title,
style: GoogleFonts.ibmPlexSans(
fontSize: 14.sp,
),
),
onTap: () {
Navigator.pop(context);
_pickLogo(source);
},
);
}

// ============================================================
// CATEGORY
// ============================================================

void _showCategoryBottomSheet() {
showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: Colors.transparent,
builder: (sheetContext) {
return Directionality(
textDirection: TextDirection.rtl,
child: Container(
height: MediaQuery.of(sheetContext).size.height * 0.7,
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.vertical(
top: Radius.circular(30.r),
),
),
padding: EdgeInsets.fromLTRB(
20.w,
20.h,
20.w,
20.h + MediaQuery.of(sheetContext).viewPadding.bottom,
),
child: Column(
children: [
Container(
width: 40.w,
height: 4.h,
decoration: BoxDecoration(
color: Colors.black12,
borderRadius: BorderRadius.circular(2.r),
),
),
SizedBox(height: 16.h),
Text(
'اختر فئة المتجر',
style: GoogleFonts.ibmPlexSans(
fontSize: 18.sp,
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 8.h),
const Divider(),
SizedBox(height: 8.h),
Expanded(
child: GridView.builder(
physics: const BouncingScrollPhysics(),
itemCount: 15,
gridDelegate:
SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 3,
mainAxisSpacing: 16.h,
crossAxisSpacing: 12.w,
childAspectRatio: 0.85,
),
itemBuilder: (context, index) {
final categories = [
{
'name': 'مطاعم',
'icon': Icons.restaurant,
},
{
'name': 'كافيهات',
'icon': Icons.local_cafe_outlined,
},
{
'name': 'ملابس',
'icon': Icons.checkroom_outlined,
},
{
'name': 'مساحات عمل',
'icon': Icons.laptop_chromebook_outlined,
},
{
'name': 'هدايا',
'icon': Icons.card_giftcard_outlined,
},
{
'name': 'أحذية',
'icon': Icons.roller_skating_outlined,
},
{
'name': 'سيارات',
'icon': Icons.directions_car_filled_outlined,
},
{
'name': 'مجوهرات',
'icon': Icons.diamond_outlined,
},
{
'name': 'كوزمتكس',
'icon': Icons.content_cut_outlined,
},
{
'name': 'سوبرماركت',
'icon': Icons.shopping_cart_outlined,
},
{
'name': 'مول',
'icon': Icons.business_outlined,
},
{
'name': 'متجر',
'icon': Icons.storefront_outlined,
},
{
'name': 'إلكترونيات',
'icon': Icons.devices_other_outlined,
},
{
'name': 'مستلزمات طبية',
'icon': Icons.medical_services_outlined,
},
{
'name': 'بصريات',
'icon': Icons.visibility_outlined,
},
];

return _buildCategoryItem(
categories[index]['name'] as String,
categories[index]['icon'] as IconData,
);
},
),
),
],
),
),
);
},
);
}

Widget _buildCategoryItem(
String name,
IconData icon,
) {
return InkWell(
borderRadius: BorderRadius.circular(20.r),
onTap: () {
setState(() {
_selectedCategory = name;
});

Navigator.pop(context);
},
child: Column(
mainAxisAlignment: MainAxisAlignment.start,
children: [
Container(
padding: EdgeInsets.all(12.r),
decoration: BoxDecoration(
color: primaryColor.withValues(alpha: 0.08),
shape: BoxShape.circle,
),
child: Icon(
icon,
color: primaryColor,
size: 24.sp,
),
),
SizedBox(height: 6.h),
Text(
name,
style: GoogleFonts.ibmPlexSans(
fontSize: 11.sp,
color: textColor,
),
textAlign: TextAlign.center,
maxLines: 2,
overflow: TextOverflow.ellipsis,
),
],
),
);
}

// ============================================================
// SUBMIT
// ============================================================

Future<void> _onSubmit() async {
if (_isLoading) {
return;
}

if (!_formKey.currentState!.validate()) {
return;
}

setState(() {
_isLoading = true;
});

try {
await UserController.instance.completeMerchantProfile(
storeName: _storeNameController.text.trim(),
storeCategory: _selectedCategory,
region: _selectedRegion,
logoPath: _logoFile?.path,
);

if (!mounted) {
return;
}

Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(
builder: (_) => BnScreen(
type: widget.type,
),
),
(route) => false,
);
} catch (e) {
debugPrint('Merchant profile error: $e');

if (!mounted) {
return;
}

final String message =
UserController.instance.authErrorNotifier.value ??
'حدث خطأ أثناء حفظ بيانات المتجر. حاول مرة أخرى.';

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
message,
style: GoogleFonts.ibmPlexSans(),
),
backgroundColor: Colors.redAccent,
),
);
} finally {
if (mounted) {
setState(() {
_isLoading = false;
});
}
}
}

// ============================================================
// BUILD
// ============================================================

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: Colors.white,
resizeToAvoidBottomInset: true,

appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0,
surfaceTintColor: Colors.white,
leading: IconButton(
icon: Icon(
Icons.arrow_back_ios_new_rounded,
color: textColor,
size: 20.sp,
),
onPressed: () => Navigator.pop(context),
),
title: Text(
'إكمال بروفايل التاجر',
style: GoogleFonts.ibmPlexSans(
color: Colors.grey,
fontSize: 16.sp,
),
),
centerTitle: true,
),

body: SafeArea(
child: SingleChildScrollView(
physics: const BouncingScrollPhysics(),
keyboardDismissBehavior:
ScrollViewKeyboardDismissBehavior.onDrag,

padding: EdgeInsets.only(
left: 20.w,
right: 20.w,
top: 10.h,
bottom: 24.h +
MediaQuery.of(context).viewPadding.bottom,
),

child: Form(
key: _formKey,

child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// ==================================================
// HEADER
// ==================================================

Text(
'الخطوة الأخيرة: إكمال البيانات',
style: GoogleFonts.ibmPlexSans(
fontSize: 18.sp,
fontWeight: FontWeight.bold,
color: textColor,
),
),

SizedBox(height: 10.h),

ClipRRect(
borderRadius: BorderRadius.circular(10.r),
child: LinearProgressIndicator(
value: 1.0,
minHeight: 4.h,
backgroundColor: const Color(0xffeff3ff),
valueColor:
const AlwaysStoppedAnimation<Color>(
primaryColor,
),
),
),

SizedBox(height: 24.h),

// ==================================================
// LOGO
// ==================================================

Center(
child: GestureDetector(
onTap: _showLogoSourceBottomSheet,
child: Stack(
clipBehavior: Clip.none,
alignment: Alignment.bottomLeft,
children: [
Container(
width: 100.w,
height: 100.w,
decoration: BoxDecoration(
color: primaryColor.withValues(
alpha: 0.05,
),
shape: BoxShape.circle,
border: Border.all(
color: primaryColor.withValues(
alpha: 0.1,
),
width: 1.5.w,
),
image: _logoFile != null
? DecorationImage(
image: FileImage(_logoFile!),
fit: BoxFit.cover,
)
    : null,
),
child: _logoFile == null
? Icon(
Icons.storefront_rounded,
size: 40.sp,
color: primaryColor.withValues(
alpha: 0.5,
),
)
    : null,
),

Positioned(
bottom: -2.h,
left: -2.w,
child: CircleAvatar(
radius: 16.r,
backgroundColor: primaryColor,
child: Icon(
Icons.edit,
size: 14.sp,
color: Colors.white,
),
),
),
],
),
),
),

SizedBox(height: 28.h),

// ==================================================
// STORE NAME
// ==================================================

_buildFieldLabel('اسم المتجر'),

_buildTextField(
_storeNameController,
'مثال: متجر التقنية الحديثة',
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'يرجى إدخال اسم المتجر';
}

return null;
},
),

SizedBox(height: 16.h),

// ==================================================
// CATEGORY + REGION
// ==================================================

Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
_buildFieldLabel('فئة المتجر'),

_buildPickerField(
_selectedCategory ?? 'اختر الفئة',
_showCategoryBottomSheet,
),
],
),
),

SizedBox(width: 12.w),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
_buildFieldLabel('المنطقة'),

_buildDropdownField(),
],
),
),
],
),

SizedBox(height: 16.h),

// ==================================================
// ADDRESS
// ==================================================

_buildFieldLabel('العنوان بالتفصيل'),

_buildTextField(
_addressDetailController,
'الشارع، رقم المبنى...',
maxLines: 2,
),

SizedBox(height: 20.h),

// ==================================================
// AI HINT
// ==================================================

_buildAIHint(primaryColor),

SizedBox(height: 20.h),

// ==================================================
// DESCRIPTION
// ==================================================

_buildFieldLabel('وصف المتجر'),

_buildTextField(
_descriptionController,
'تحدث عن ما يميز متجرك...',
maxLines: 3,
),

SizedBox(height: 16.h),

// ==================================================
// WHATSAPP
// ==================================================

_buildFieldLabel('رقم الواتساب'),

_buildWhatsAppField(),

SizedBox(height: 16.h),

// ==================================================
// WORK HOURS
// ==================================================

_buildFieldLabel('مواعيد العمل'),

_buildTextField(
_workHoursController,
'مثلاً: 10 صباحاً - 8 مساءً',
),

SizedBox(height: 32.h),

// ==================================================
// SUBMIT
// ==================================================

_buildSubmitButton(primaryColor),

// IMPORTANT:
// Extra bottom spacing to prevent the button
// from touching the bottom navigation/system area.
SizedBox(
height: 12.h +
MediaQuery.of(context).viewPadding.bottom,
),
],
),
),
),
),
),
);
}

// ============================================================
// FIELD LABEL
// ============================================================

Widget _buildFieldLabel(String label) {
return Padding(
padding: EdgeInsets.only(
bottom: 8.h,
top: 4.h,
),
child: Text(
label,
style: GoogleFonts.ibmPlexSans(
color: textColor,
fontWeight: FontWeight.bold,
fontSize: 14.sp,
),
),
);
}

// ============================================================
// TEXT FIELD
// ============================================================

Widget _buildTextField(
TextEditingController controller,
String hint, {
int maxLines = 1,
String? Function(String?)? validator,
}) {
return TextFormField(
controller: controller,
maxLines: maxLines,
validator: validator,
textInputAction:
maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
style: GoogleFonts.ibmPlexSans(
fontSize: 14.sp,
color: textColor,
),
decoration: _inputDecoration(hint),
);
}

// ============================================================
// CATEGORY PICKER
// ============================================================

Widget _buildPickerField(
String text,
VoidCallback onTap,
) {
final bool isPlaceholder = text.contains('اختر');

return InkWell(
borderRadius: BorderRadius.circular(12.r),
onTap: onTap,
child: Container(
height: 52.h,
padding: EdgeInsets.symmetric(
horizontal: 14.w,
),
decoration: BoxDecoration(
color: inputBackground,
borderRadius: BorderRadius.circular(12.r),
border: Border.all(
color: inputBorder,
),
),
child: Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Text(
text,
style: GoogleFonts.ibmPlexSans(
fontSize: 14.sp,
color: isPlaceholder
? Colors.black38
    : textColor,
),
overflow: TextOverflow.ellipsis,
),
),
Icon(
Icons.keyboard_arrow_down_rounded,
color: Colors.black45,
size: 20.sp,
),
],
),
),
);
}

// ============================================================
// REGION DROPDOWN
// ============================================================

Widget _buildDropdownField() {
 return Column(
   crossAxisAlignment: CrossAxisAlignment.stretch,
   children: [
     DropdownButtonFormField<String>(
      value: _selectedRegion,
isExpanded: true,
dropdownColor: Colors.white,

items: const [
'غزة',
'خانيونس',
'الوسطى',
'رفح',
].map(
(String value) {
return DropdownMenuItem<String>(
value: value,
child: Text(
value,
overflow: TextOverflow.ellipsis,
),
);
},
).toList(),

onChanged: (newValue) {
setState(() {
_selectedRegion = newValue;
});
},

style: GoogleFonts.ibmPlexSans(
fontSize: 14.sp,
color: textColor,
),

decoration: _inputDecoration(
'اختر المنطقة',
),
     ),
     SizedBox(height: 8.h),
     OutlinedButton.icon(
       onPressed: _useCurrentLocation,
       icon: Icon(
         Icons.my_location,
         size: 16.sp,
         color: primaryColor,
       ),
       label: Text(
         'استخدام موقعي الحالي',
         style: GoogleFonts.ibmPlexSans(
           fontSize: 12.sp,
           color: primaryColor,
           fontWeight: FontWeight.bold,
         ),
       ),
       style: OutlinedButton.styleFrom(
         padding: EdgeInsets.symmetric(vertical: 10.h),
         side: BorderSide.none,
         backgroundColor: primaryColor.withValues(alpha: 0.05),
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(10.r),
         ),
       ),
     ),
   ],
 );
}

Future<void> _useCurrentLocation() async {
 try {
   final result = await LocationService.instance.getCurrentLocation();
   if (!mounted) {
     return;
   }
   if (result.region == null) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
         content: Text(
           'تم تحديد موقعك، لكن تعذر مطابقة المنطقة تلقائياً. اخترها من القائمة.',
         ),
       ),
     );
     return;
   }
   setState(() {
     _selectedRegion = result.region;
   });
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text('تم تحديد الموقع: ${result.region}')),
   );
 } on LocationException catch (e) {
   if (mounted) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(e.message)),
     );
   }
 } catch (_) {
   if (mounted) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('تعذر الحصول على موقعك الحالي.')),
     );
   }
 }
}

// ============================================================
// WHATSAPP
// ============================================================

Widget _buildWhatsAppField() {
return Row(
children: [
Container(
width: 70.w,
height: 52.h,
alignment: Alignment.center,
decoration: BoxDecoration(
color: const Color(0xffeff3ff),
borderRadius: BorderRadius.circular(12.r),
),
child: Text(
'+970',
style: GoogleFonts.ibmPlexSans(
fontWeight: FontWeight.bold,
fontSize: 14.sp,
),
textDirection: TextDirection.ltr,
),
),

SizedBox(width: 10.w),

Expanded(
child: TextFormField(
controller: _whatsappController,
keyboardType: TextInputType.phone,
textDirection: TextDirection.ltr,
style: GoogleFonts.ibmPlexSans(
fontSize: 14.sp,
color: textColor,
),
decoration: _inputDecoration(
'59XXXXXXX',
),
),
),
],
);
}

// ============================================================
// AI HINT
// ============================================================

Widget _buildAIHint(Color color) {
return Container(
width: double.infinity,
padding: EdgeInsets.all(12.r),
decoration: BoxDecoration(
color: color.withValues(
alpha: 0.05,
),
borderRadius: BorderRadius.circular(12.r),
border: Border.all(
color: color.withValues(
alpha: 0.1,
),
),
),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Icon(
Icons.auto_awesome,
color: color,
size: 20.sp,
),

SizedBox(width: 10.w),

Expanded(
child: Text(
'إضافة وصف دقيق يساعد الذكاء الاصطناعي في ترشيح متجرك للعملاء المناسبين.',
style: GoogleFonts.ibmPlexSans(
fontSize: 12.sp,
color: color,
height: 1.4,
),
),
),
],
),
);
}

// ============================================================
// SUBMIT BUTTON
// ============================================================

Widget _buildSubmitButton(
Color primaryColor,
) {
if (_isLoading) {
return SizedBox(
width: double.infinity,
height: 54.h,
child: Center(
child: SizedBox(
width: 26.w,
height: 26.w,
child: CircularProgressIndicator(
strokeWidth: 2.5,
color: primaryColor,
),
),
),
);
}

return SizedBox(
width: double.infinity,
height: 54.h,
child: DecoratedBox(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(14.r),
gradient: LinearGradient(
colors: [
primaryColor,
primaryColor.withBlue(200),
],
),
),
child: ElevatedButton(
onPressed: _onSubmit,
style: ElevatedButton.styleFrom(
backgroundColor: Colors.transparent,
foregroundColor: Colors.white,
shadowColor: Colors.transparent,
surfaceTintColor: Colors.transparent,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14.r),
),
),
child: Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Text(
'حفظ وإكمال التسجيل',
style: GoogleFonts.ibmPlexSans(
fontSize: 16.sp,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),

SizedBox(width: 10.w),

Icon(
Icons.rocket_launch_rounded,
color: Colors.white,
size: 18.sp,
),
],
),
),
),
);
}

// ============================================================
// INPUT DECORATION
// ============================================================

InputDecoration _inputDecoration(
String hint,
) {
return InputDecoration(
hintText: hint,

hintStyle: GoogleFonts.ibmPlexSans(
color: Colors.black26,
fontSize: 13.sp,
),

filled: true,
fillColor: inputBackground,

contentPadding: EdgeInsets.symmetric(
vertical: 16.h,
horizontal: 16.w,
),

border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12.r),
borderSide: const BorderSide(
color: inputBorder,
),
),

enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12.r),
borderSide: const BorderSide(
color: inputBorder,
),
),

focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12.r),
borderSide: const BorderSide(
color: primaryColor,
width: 1.5,
),
),

errorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12.r),
borderSide: const BorderSide(
color: Colors.redAccent,
),
),

focusedErrorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12.r),
borderSide: const BorderSide(
color: Colors.redAccent,
width: 1.5,
),
),
);
}
}
