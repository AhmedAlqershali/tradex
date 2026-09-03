import 'dart:io';
import 'package:flutter/material.dart';

/// Displays a product image from either a network URL (http/https)
/// or a local file path picked from the device (image_picker).
/// Falls back gracefully on error or empty URL.
class ProductImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;

  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallback,
  });

  bool get _isNetwork =>
      url.startsWith('http://') || url.startsWith('https://');

  Widget get _fallbackWidget =>
      fallback ??
      Container(
        color: const Color(0xffF0F1F5),
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.shopping_bag_outlined, color: Colors.grey),
        ),
      );

  Widget _loadingWidget(BuildContext context) => Container(
        color: const Color(0xffF0F1F5),
        width: width,
        height: height,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallbackWidget;

    if (_isNetwork) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _loadingWidget(context);
        },
        errorBuilder: (_, __, ___) => _fallbackWidget,
      );
    }

    // Local file path from image_picker
    try {
      return Image.file(
        File(url),
        fit: fit,
        width: width,
        height: height,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _loadingWidget(context);
        },
        errorBuilder: (_, __, ___) => _fallbackWidget,
      );
    } catch (_) {
      return _fallbackWidget;
    }
  }
}
