import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/product_service.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/models/store_model.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(const ProductInitial()) {
    on<ProductsLoadRequested>(_onProductsLoadRequested);
    on<MerchantProductsLoadRequested>(_onMerchantProductsLoadRequested);
    on<ProductByIdRequested>(_onProductByIdRequested);
    on<ProductSearchRequested>(_onProductSearchRequested);
    on<UnifiedSearchRequested>(_onUnifiedSearchRequested);
    on<ProductCreateRequested>(_onProductCreateRequested);
    on<ProductUpdateRequested>(_onProductUpdateRequested);
    on<ProductDeleteRequested>(_onProductDeleteRequested);
    on<CategoriesLoadRequested>(_onCategoriesLoadRequested);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return 'تعذر إكمال العملية. حاول مرة أخرى.';
  }

  Future<void> _onProductsLoadRequested(
    ProductsLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final products = await ProductService.instance.getProducts(
        category: event.category,
        categoryId: event.categoryId,
        storeId: event.storeId,
        featured: event.featured,
        page: event.page,
      );
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductFailure(_errorMessage(e)));
    }
  }

  Future<void> _onMerchantProductsLoadRequested(
    MerchantProductsLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final products = await ProductService.instance.getMerchantProducts(
        status: event.status,
      );
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductFailure(_errorMessage(e)));
    }
  }

  Future<void> _onProductByIdRequested(
    ProductByIdRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final product = await ProductService.instance.getProductById(event.id);
      emit(ProductDetailLoaded(product));
    } catch (e) {
      emit(ProductFailure(_errorMessage(e)));
    }
  }

  Future<void> _onProductSearchRequested(
    ProductSearchRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final results = await ProductService.instance.search(
        event.query,
        categoryId: event.categoryId,
        storeId: event.storeId,
      );
      emit(ProductSearchResult(results, event.query));
    } catch (e) {
      emit(ProductFailure(_errorMessage(e)));
    }
  }

  Future<void> _onUnifiedSearchRequested(
    UnifiedSearchRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final result = await ProductService.instance.unifiedSearch(event.query);
      emit(UnifiedSearchResultState(result.products, result.stores, event.query));
    } catch (e) {
      emit(ProductFailure(_errorMessage(e)));
    }
  }

  Future<void> _onProductCreateRequested(
    ProductCreateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final product = await ProductService.instance.createProduct(
        name: event.name,
        category: event.category,
        price: event.price,
        description: event.description,
        quantity: event.quantity,
        isVisible: event.isVisible,
        isFeatured: event.isFeatured,
        imagePaths: event.imagePaths,
      );
      emit(ProductCreated(product));
    } catch (e) {
      emit(ProductFailure(_errorMessage(e)));
    }
  }

  Future<void> _onProductUpdateRequested(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final product = await ProductService.instance.updateProduct(
        event.id,
        name: event.name,
        category: event.category,
        price: event.price,
        description: event.description,
        quantity: event.quantity,
        isVisible: event.isVisible,
        isFeatured: event.isFeatured,
        imagePaths: event.imagePaths,
        clearImages: event.clearImages,
      );
      emit(ProductUpdated(product));
    } catch (e) {
      emit(ProductFailure(_errorMessage(e)));
    }
  }

  Future<void> _onProductDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      await ProductService.instance.deleteProduct(event.id);
      emit(ProductDeleted(event.id));
    } catch (e) {
      emit(ProductFailure(_errorMessage(e)));
    }
  }

  Future<void> _onCategoriesLoadRequested(
    CategoriesLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final categories = await ProductService.instance.getCategories();
      emit(ProductCategoriesLoaded(categories));
    } catch (e) {
      emit(ProductFailure(_errorMessage(e)));
    }
  }
}
