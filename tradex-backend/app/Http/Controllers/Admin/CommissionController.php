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

        $search = trim((string) $request->query('search', ''));
        $paymentStatus = trim((string) $request->query('payment_status', ''));

        $commissions = Commission::query()
            ->with(['order', 'merchant', 'store'])
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($innerQuery) use ($search) {
                    $innerQuery->where('order_id', 'like', "%{$search}%")
                        ->orWhereHas('merchant', function ($merchantQuery) use ($search) {
                            $merchantQuery->where('name', 'like', "%{$search}%")
                                ->orWhere('email', 'like', "%{$search}%");
                        })
                        ->orWhereHas('order', function ($orderQuery) use ($search) {
                            $orderQuery->where('customer_phone', 'like', "%{$search}%")
                                ->orWhere('id', 'like', "%{$search}%");
                        });
                });
            })
            ->when($paymentStatus !== '', fn ($query) => $query->where('payment_status', $paymentStatus))
            ->orderByDesc('created_at')
            ->paginate(min((int) ($request->query('per_page', 15)), 100))
            ->withQueryString();

        return view('admin.commissions.index', [
            'commissions' => $commissions,
            'search' => $search,
            'paymentStatus' => $paymentStatus,
        ]);
    }

    public function markPaid(Request $request, Commission $commission): \Illuminate\Http\RedirectResponse
    {
        $this->authorize('update', $commission);

        if ($commission->payment_status === 'paid') {
            return redirect()->back()->with('error', 'تم تسجيل الدفع مسبقًا.');
        }

        $commission->update([
            'payment_status' => 'paid',
            'paid_at' => now(),
            'paid_by' => $request->user()->id,
            'recorded_by' => $request->user()->id,
        ]);

        return redirect()->route('admin.commissions.index')->with('success', 'تم تسجيل الدفع بنجاح.');
    }
}
