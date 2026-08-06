<?php

namespace App\Http\Controllers\Api\V1\Client;

use App\Contracts\Services\FavoriteServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Resources\Favorite\FavoriteCollection;
use App\Http\Resources\Favorite\FavoriteResource;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Client favorites management.
 *
 * All routes require auth:sanctum + role:client.
 * GET    /api/v1/favorites
 * POST   /api/v1/favorites/{product}
 * DELETE /api/v1/favorites/{product}
 */
class FavoriteController extends BaseApiController
{
    public function __construct(
        private readonly FavoriteServiceInterface $favoriteService,
    ) {}

    // ── GET /api/v1/favorites ─────────────────────────────────────────────────

    public function index(Request $request): JsonResponse
    {
        $favorites = $this->favoriteService->getFavorites($request->user());

        return $this->success(
            new FavoriteCollection($favorites),
            'Favorites retrieved successfully.',
        );
    }

    // ── POST /api/v1/favorites/{product} ─────────────────────────────────────

    public function add(Request $request, int $product): JsonResponse
    {
        try {
            $result = $this->favoriteService->add($request->user(), $product);
        } catch (ModelNotFoundException $e) {
            return $this->notFound($e->getMessage());
        }

        if ($result['already_favorited']) {
            return $this->success(
                new FavoriteResource($result['favorite']),
                'Product is already in your favorites.',
            );
        }

        return $this->created(
            new FavoriteResource($result['favorite']),
            'Product added to favorites.',
        );
    }

    // ── DELETE /api/v1/favorites/{product} ────────────────────────────────────

    public function remove(Request $request, int $product): JsonResponse
    {
        try {
            $this->favoriteService->remove($request->user(), $product);
        } catch (ModelNotFoundException) {
            return $this->notFound('Favorite not found.');
        }

        return $this->success(null, 'Product removed from favorites.');
    }
}
