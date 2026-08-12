@extends('admin.layout')

@section('title', 'Orders')
@section('heading', 'Order management')

@section('content')
    <div class="mb-8 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
            <p class="text-sm leading-6 text-slate-500">Review marketplace orders across every merchant store.</p>
            <p class="mt-1 text-xs text-slate-400">Order data and status rules come from the existing Laravel order service.</p>
        </div>
        <div class="rounded-xl bg-indigo-50 px-4 py-2 text-sm font-semibold text-indigo-700">{{ $orders->total() }} orders</div>
    </div>

    @if (session('status'))
        <div class="mb-6 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-medium text-emerald-800">{{ session('status') }}</div>
    @endif
    @if ($errors->any())
        <div class="mb-6 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">
            <ul class="list-disc space-y-1 pl-5">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul>
        </div>
    @endif

    <section class="mb-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm shadow-slate-200/40">
        <form method="GET" action="{{ route('admin.orders.index') }}" class="grid gap-4 md:grid-cols-[1fr_180px_160px_160px_auto] md:items-end">
            <div>
                <label for="status" class="mb-2 block text-xs font-semibold uppercase tracking-wider text-slate-500">Status</label>
                <select id="status" name="status" class="block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm focus:border-indigo-400 focus:bg-white focus:ring-4 focus:ring-indigo-500/10">
                    <option value="">All statuses</option>
                    @foreach ($statuses as $status)
                        <option value="{{ $status }}" @selected(request('status') === $status)>{{ ucfirst($status) }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label for="date_from" class="mb-2 block text-xs font-semibold uppercase tracking-wider text-slate-500">From</label>
                <input id="date_from" name="date_from" type="date" value="{{ request('date_from') }}" class="block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm focus:border-indigo-400 focus:bg-white focus:ring-4 focus:ring-indigo-500/10">
            </div>
            <div>
                <label for="date_to" class="mb-2 block text-xs font-semibold uppercase tracking-wider text-slate-500">To</label>
                <input id="date_to" name="date_to" type="date" value="{{ request('date_to') }}" class="block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm focus:border-indigo-400 focus:bg-white focus:ring-4 focus:ring-indigo-500/10">
            </div>
            <div></div>
            <button type="submit" class="rounded-xl bg-slate-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-700">Apply filters</button>
        </form>
    </section>

    <section class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
        <div class="border-b border-slate-100 px-6 py-5">
            <h2 class="font-semibold text-slate-900">All orders</h2>
            <p class="mt-1 text-xs text-slate-400">Use order details to review line items and apply an existing valid status action.</p>
        </div>
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100 text-left">
                <thead class="bg-slate-50"><tr class="text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                    <th class="px-6 py-3">Order</th><th class="px-6 py-3">Customer</th><th class="px-6 py-3">Store / merchant</th><th class="px-6 py-3">Total</th><th class="px-6 py-3">Status</th><th class="px-6 py-3">Date</th>
                </tr></thead>
                <tbody class="divide-y divide-slate-100">
                @forelse ($orders as $order)
                    <tr class="text-sm">
                        <td class="px-6 py-4"><a class="font-semibold text-indigo-700 hover:text-indigo-900" href="{{ route('admin.orders.show', $order) }}">#{{ $order->id }}</a></td>
                        <td class="px-6 py-4"><p class="font-medium text-slate-700">{{ $order->customer_name }}</p><p class="text-xs text-slate-400">{{ $order->client?->email ?? $order->customer_phone }}</p></td>
                        <td class="px-6 py-4"><p class="font-medium text-slate-700">{{ $order->store?->store_name ?? 'Store unavailable' }}</p><p class="text-xs text-slate-400">{{ $order->store?->owner?->name ?? 'Merchant unavailable' }}</p></td>
                        <td class="px-6 py-4 font-semibold text-slate-700">{{ number_format((float) $order->total_amount, 2) }}</td>
                        <td class="px-6 py-4"><span class="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold capitalize text-slate-600">{{ str_replace('_', ' ', $order->status) }}</span></td>
                        <td class="px-6 py-4 text-slate-500">{{ $order->created_at?->format('M j, Y · g:i A') }}</td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="px-6 py-12 text-center text-sm text-slate-400">No orders match the selected filters.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
        @if ($orders->hasPages())<div class="border-t border-slate-100 px-6 py-4">{{ $orders->links() }}</div>@endif
    </section>
@endsection