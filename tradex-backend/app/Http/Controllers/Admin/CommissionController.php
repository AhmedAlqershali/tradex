<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Commission;
use Illuminate\Http\Request;
use Illuminate\View\View;

class CommissionController extends Controller
{
    public function index(Request $request): View
    {
        $this->authorize('viewAny', Commission::class);

        $commissions = Commission::query()
            ->with(['order', 'merchant', 'store'])
            ->orderByDesc('created_at')
            ->paginate(min((int) ($request->query('per_page', 15)), 100))
            ->withQueryString();

        return view('admin.commissions.index', [
            'commissions' => $commissions,
        ]);
    }
}
