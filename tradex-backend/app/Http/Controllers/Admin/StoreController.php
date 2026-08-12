<?php

namespace App\Http\Controllers\Admin;

use App\Contracts\Services\AdminStoreManagementServiceInterface;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateStoreStatusRequest;
use App\Models\Store;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class StoreController extends Controller
{
    public function __construct(
        private readonly AdminStoreManagementServiceInterface $storeService,
    ) {}

    public function index(Request $request): View
    {
        $this->authorize('viewAny', Store::class);

        return view('admin.stores.index', [
            'stores' => $this->storeService->listStores(
                $request->only(['search', 'status', 'per_page']),
            ),
            'statuses' => ['active', 'inactive', 'suspended'],
        ]);
    }

    public function show(int $store): View
    {
        $model = $this->storeService->findById($store);
        abort_unless($model, 404, 'Store not found.');
        $this->authorize('view', $model);

        return view('admin.stores.show', ['store' => $model]);
    }

    public function updateStatus(UpdateStoreStatusRequest $request, int $store): RedirectResponse
    {
        $model = $this->storeService->findById($store);
        abort_unless($model, 404, 'Store not found.');
        $this->authorize('updateStatus', $model);

        $this->storeService->updateStatus($model, $request->validated('status'));

        return back()->with('status', 'Store status updated.');
    }
}