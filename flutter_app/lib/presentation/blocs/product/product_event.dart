part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductsLoadRequested extends ProductEvent {
  const ProductsLoadRequested({
    this.category,
    this.storeId,
    this.featured = false,
    this.page = 1,
  });

  final String? category;
  final String? storeId;
  final bool featured;
  final int page;

  @override
  List<Object?> get props => [category, storeId, featured, page];
}

class ProductByIdRequested extends ProductEvent {
  const ProductByIdRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class ProductSearchRequested extends ProductEvent {
  const ProductSearchRequested(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class ProductCreateRequested extends ProductEvent {
  const ProductCreateRequested({
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.isVisible = true,
    this.isFeatured = false,
    this.imagePaths = const [],
  });

  final String name;
  final String category;
  final double price;
  final String description;
  final bool isVisible;
  final bool isFeatured;

  /// Local file paths of images picked by the merchant, uploaded as part of
  /// the same create request (backend has no separate image sub-endpoint).
  final List<String> imagePaths;

  @override
  List<Object?> get props => [
        name,
        category,
        price,
        description,
        isVisible,
        isFeatured,
        imagePaths,
      ];
}

class ProductUpdateRequested extends ProductEvent {
  const ProductUpdateRequested(
    this.id, {
    this.name,
    this.category,
    this.price,
    this.description,
    this.isVisible,
    this.isFeatured,
    this.imagePaths = const [],
    this.clearImages = false,
  });

  final String id;
  final String? name;
  final String? category;
  final double? price;
  final String? description;
  final bool? isVisible;
  final bool? isFeatured;

  /// New local image files to upload. Non-empty values *replace the entire
  /// gallery* — the backend has no per-image add/delete endpoint.
  final List<String> imagePaths;

  /// When true (and [imagePaths] is empty), removes all existing images.
  final bool clearImages;

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        price,
        description,
        isVisible,
        isFeatured,
        imagePaths,
        clearImages,
      ];
}

class ProductDeleteRequested extends ProductEvent {
  const ProductDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class CategoriesLoadRequested extends ProductEvent {
  const CategoriesLoadRequested();
}
