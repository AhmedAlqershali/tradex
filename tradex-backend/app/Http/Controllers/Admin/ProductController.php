<?php

namespace App\Http\Controllers\Admin;

use App\Contracts\Services\CategoryServiceInterface;
use App\Contracts\Services\ProductServiceInterface;
use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ProductController extends Controller
{
    public function __construct(
        private readonly ProductServiceInterface $productService,
        private readonly CategoryServiceInterface $categoryService,
    ) {}

    public function index(Request $request): View
    {
        $this->authorize('viewAny', Product::class);

        return view('admin.products.index', [
            'products' => $this->productService->listAll(
                $request->only(['search', 'category_id', 'status', 'sort_by', 'sort_dir', 'per_page']),
            ),
            'categories' => $this->categoryService->listAll(['per_page' => 100]),
            'statuses' => ['active', 'inactive', 'out_of_stock'],
        ]);
    }

    public function show(int $product): View
    {
        $this->authorize('viewAny', Product::class);

        try {
            $productModel = $this->productService->findById($product);
        } catch (ModelNotFoundException) {
            abort(404, 'Product not found.');
        }

        return view('admin.products.show', ['product' => $productModel]);
    }
}