<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Api\V1\BaseApiController;
use App\Models\Commission;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommissionController extends BaseApiController
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Commission::class);

        $perPage = min((int) ($request->query('per_page', 15)), 100);

        $commissions = Commission::query()
            ->with(['order', 'merchant', 'store'])
            ->orderByDesc('created_at')
            ->paginate($perPage)
            ->withQueryString();

        return $this->success($commissions, 'Commissions retrieved successfully.');
    }

    public function show(int $id): JsonResponse
    {
        $commission = Commission::query()->with(['order', 'merchant', 'store'])->find($id);

        if (! $commission) {
            return $this->notFound('Commission not found.');
        }

        $this->authorize('view', $commission);

        return $this->success($commission, 'Commission retrieved successfully.');
    }
}
