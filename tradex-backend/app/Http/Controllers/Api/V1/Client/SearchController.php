<?php

namespace App\Http\Controllers\Api\V1\Client;

use App\Contracts\Services\ProductServiceInterface;
use App\Contracts\Services\StoreServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Resources\Product\ProductCollection;
use App\Http\Resources\Store\StoreCollection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SearchController extends BaseApiController
{
    private ProductServiceInterface $productService;

    private StoreServiceInterface $storeService;

    public function __construct(
        ProductServiceInterface $productService,
        StoreServiceInterface $storeService,
    ) {
        $this->productService = $productService;
        $this->storeService = $storeService;
    }

    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'query' => ['required', 'string', 'max:100'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $query = trim($request->string('query')->toString());
        if ($query === '') {
            return $this->validationError(['query' => ['The query field is required.']]);
        }
        $perPage = (int) $request->input('per_page', 20);

        $products = $this->productService->listForClient([
            'search' => $query,
            'per_page' => $perPage,
        ]);
        $stores = $this->storeService->listActive([
            'search' => $query,
            'per_page' => $perPage,
        ]);

        return $this->success([
            'products' => (new ProductCollection($products))->toArray($request),
            'stores' => (new StoreCollection($stores))->toArray($request),
        ], 'Search results retrieved successfully.');
    }
}