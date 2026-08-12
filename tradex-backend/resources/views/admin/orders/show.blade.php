@extends('admin.layout')

@section('title', 'Order #'.$order->id)
@section('heading', 'Order #'.$order->id)

@section('content')
    <div class="mb-6"><a href="{{ route('admin.orders.index') }}" class="text-sm font-semibold text-indigo-700 hover:text-indigo-900">← Back to orders</a></div>
    @if (session('status'))<div class="mb-6 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-medium text-emerald-800">{{ session('status') }}</div>@endif
    @if ($errors->any())<div class="mb-6 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800"><ul class="list-disc space-y-1 pl-5">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>@endif
    <div class="grid gap-6 xl:grid-cols-[1.5fr_1fr]">
        <section class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
            <div class="flex items-start justify-between border-b border-slate-100 px-6 py-5"><div><h2 class="font-semibold text-slate-900">Order details</h2><p class="mt-1 text-xs text-slate-400">{{ $order->created_at?->format('M j, Y · g:i A') }}</p></div><span class="rounded-full bg-indigo-50 px-3 py-1 text-xs font-semibold capitalize text-indigo-700">{{ str_replace('_', ' ', $order->status) }}</span></div>
            <dl class="grid gap-5 px-6 py-6 sm:grid-cols-2">
                <div><dt class="text-xs font-semibold uppercase tracking-wider text-slate-400">Customer</dt><dd class="mt-1 font-medium text-slate-800">{{ $order->customer_name }}</dd><dd class="text-sm text-slate-500">{{ $order->client?->email ?? '—' }}</dd><dd class="text-sm text-slate-500">{{ $order->customer_phone }}</dd></div>
                <div><dt class="text-xs font-semibold uppercase tracking-wider text-slate-400">Delivery</dt><dd class="mt-1 font-medium text-slate-800">{{ $order->customer_city }}</dd><dd class="mt-1 text-sm text-slate-500">{{ $order->notes ?: 'No notes' }}</dd></div>
                <div><dt class="text-xs font-semibold uppercase tracking-wider text-slate-400">Store</dt><dd class="mt-1 font-medium text-slate-800">{{ $order->store?->store_name ?? 'Store unavailable' }}</dd><dd class="text-sm text-slate-500">{{ $order->store?->owner?->name ?? 'Merchant unavailable' }}</dd></div>
                <div><dt class="text-xs font-semibold uppercase tracking-wider text-slate-400">Total</dt><dd class="mt-1 text-xl font-semibold text-slate-900">{{ number_format((float) $order->total_amount, 2) }}</dd></div>
            </dl>
            <div class="border-t border-slate-100 px-6 py-5"><h3 class="font-semibold text-slate-900">Items</h3><div class="mt-4 divide-y divide-slate-100">@forelse ($order->items as $item)<div class="flex items-center justify-between gap-4 py-3 text-sm"><div><p class="font-medium text-slate-700">{{ $item->product_name }}</p><p class="text-xs text-slate-400">{{ $item->quantity }} × {{ number_format((float) $item->unit_price, 2) }}</p></div><p class="font-semibold text-slate-700">{{ number_format((float) $item->subtotal, 2) }}</p></div>@empty<p class="text-sm text-slate-400">No line items recorded.</p>@endforelse</div></div>
        </section>
        <section class="h-fit rounded-2xl border border-slate-200 bg-white p-6 shadow-sm shadow-slate-200/40">
            <h2 class="font-semibold text-slate-900">Status action</h2><p class="mt-1 text-sm leading-6 text-slate-500">Only statuses accepted by the existing order validation and service are available.</p>
            <form method="POST" action="{{ route('admin.orders.status', $order) }}" class="mt-5 space-y-4">@csrf @method('PUT')
                <label for="status" class="block text-xs font-semibold uppercase tracking-wider text-slate-500">New status</label>
                <select id="status" name="status" class="block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm focus:border-indigo-400 focus:bg-white focus:ring-4 focus:ring-indigo-500/10">
                    @foreach ([\App\Models\Order::STATUS_CONFIRMED, \App\Models\Order::STATUS_PROCESSING, \App\Models\Order::STATUS_COMPLETED, \App\Models\Order::STATUS_CANCELLED] as $status)<option value="{{ $status }}" @selected($order->status === $status)>{{ ucfirst($status) }}</option>@endforeach
                </select>
                <button type="submit" class="w-full rounded-xl bg-slate-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-700">Update order status</button>
            </form>
        </section>
    </div>
@endsection