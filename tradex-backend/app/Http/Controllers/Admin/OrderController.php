<?php

namespace App\Http\Controllers\Admin;

use App\Contracts\Services\OrderServiceInterface;
use App\Exceptions\OrderException;
use App\Http\Requests\Order\UpdateOrderStatusRequest;
use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class OrderController extends Controller
{
    public function __construct(
        private readonly OrderServiceInterface $orderService,
    ) {}

    public function index(Request $request): View
    {
        $orders = $this->orderService->listForAdmin(
            $request->only(['status', 'date_from', 'date_to', 'per_page']),
        );

        return view('admin.orders.index', [
            'orders' => $orders,
            'statuses' => [
                Order::STATUS_PENDING,
                Order::STATUS_CONTACTED,
                Order::STATUS_CONFIRMED,
                Order::STATUS_PROCESSING,
                Order::STATUS_COMPLETED,
                Order::STATUS_CANCELLED,
            ],
        ]);
    }

    public function show(int $order): View
    {
        try {
            $orderModel = $this->orderService->findForAdmin($order);
        } catch (ModelNotFoundException) {
            abort(404, 'Order not found.');
        }

        return view('admin.orders.show', ['order' => $orderModel]);
    }

    public function updateStatus(UpdateOrderStatusRequest $request, int $order): RedirectResponse
    {
        try {
            $this->orderService->updateStatusForAdmin($order, $request->validated('status'));
        } catch (ModelNotFoundException) {
            abort(404, 'Order not found.');
        } catch (OrderException $exception) {
            return back()->withErrors(['status' => $exception->getMessage()]);
        }

        return redirect()
            ->route('admin.orders.show', $order)
            ->with('status', 'Order status updated.');
    }
}