@extends('admin.layout')

@section('title', 'Dashboard')
@section('heading', 'Dashboard overview')

@section('content')
    <div class="mb-8 flex flex-col justify-between gap-3 sm:flex-row sm:items-end">
        <div>
            <p class="text-sm leading-6 text-slate-500">A live snapshot of the Tradex marketplace.</p>
            <p class="mt-1 text-xs text-slate-400">Values are read from the Laravel database at request time.</p>
        </div>
        <span class="inline-flex w-fit items-center gap-2 rounded-full bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700">
            <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>
            System operational
        </span>
    </div>

    <section class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4" aria-label="Platform statistics">
        @php
            $cards = [
                ['label' => 'Total users', 'value' => $overview['users']['total'], 'detail' => $overview['users']['clients'] . ' clients', 'icon_bg' => 'bg-indigo-50', 'icon_text' => 'text-indigo-600', 'icon' => '◎', 'url' => null],
                ['label' => 'Total merchants', 'value' => $overview['users']['merchants'], 'detail' => $overview['users']['active_merchants'] . ' active accounts', 'icon_bg' => 'bg-violet-50', 'icon_text' => 'text-violet-600', 'icon' => '◈', 'url' => route('admin.merchants.index')],
                ['label' => 'Active merchants', 'value' => $overview['users']['active_merchants'], 'detail' => $overview['subscriptions']['trials'] . ' active trials', 'icon_bg' => 'bg-emerald-50', 'icon_text' => 'text-emerald-600', 'icon' => '↗', 'url' => route('admin.merchants.index')],
                ['label' => 'Active subscriptions', 'value' => $overview['subscriptions']['active'], 'detail' => 'Includes active trials', 'icon_bg' => 'bg-amber-50', 'icon_text' => 'text-amber-600', 'icon' => '◇', 'url' => route('admin.subscriptions.index')],
                ['label' => 'Products', 'value' => $overview['products']['total'], 'detail' => $overview['products']['active'] . ' active listings', 'icon_bg' => 'bg-sky-50', 'icon_text' => 'text-sky-600', 'icon' => '□', 'url' => route('admin.products.index')],
                ['label' => 'Orders', 'value' => $overview['orders']['total'], 'detail' => $overview['orders']['pending'] . ' pending', 'icon_bg' => 'bg-rose-50', 'icon_text' => 'text-rose-600', 'icon' => '▤', 'url' => route('admin.orders.index')],
                ['label' => 'Active stores', 'value' => $overview['stores']['active'], 'detail' => $overview['stores']['total'] . ' total stores', 'icon_bg' => 'bg-teal-50', 'icon_text' => 'text-teal-600', 'icon' => '⌂', 'url' => route('admin.stores.index')],
                ['label' => 'Completed sales', 'value' => number_format($overview['total_sales'], 2), 'detail' => 'Marketplace revenue', 'icon_bg' => 'bg-orange-50', 'icon_text' => 'text-orange-600', 'icon' => '$', 'url' => route('admin.orders.index', ['status' => \App\Models\Order::STATUS_COMPLETED])],
            ];
        @endphp

        @foreach ($cards as $card)
            @if ($card['url'])
                <a href="{{ $card['url'] }}" aria-label="View {{ $card['label'] }}" class="block rounded-2xl border border-slate-200 bg-white p-5 shadow-sm shadow-slate-200/40 transition hover:-translate-y-0.5 hover:border-indigo-200 hover:shadow-md">
            @else
                <article class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm shadow-slate-200/40">
            @endif
                <div class="flex items-start justify-between gap-3">
                    <p class="text-sm font-medium text-slate-500">{{ $card['label'] }}</p>
                    <span class="flex h-9 w-9 items-center justify-center rounded-xl {{ $card['icon_bg'] }} text-lg font-semibold {{ $card['icon_text'] }}">{{ $card['icon'] }}</span>
                </div>
                <p class="mt-5 text-3xl font-semibold tracking-tight text-slate-900">{{ $card['value'] }}</p>
                <p class="mt-2 text-xs text-slate-400">{{ $card['detail'] }}</p>
            @if ($card['url'])
                </a>
            @else
                </article>
            @endif
        @endforeach
    </section>

    <section class="mt-8 grid gap-6 xl:grid-cols-[1.15fr_0.85fr]">
        <article class="rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
            <div class="flex items-center justify-between border-b border-slate-100 px-6 py-5">
                <div>
                    <h2 class="font-semibold text-slate-900">Recent orders</h2>
                    <p class="mt-1 text-xs text-slate-400">Latest marketplace activity</p>
                </div>
                <span class="rounded-lg bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500">Last 10</span>
            </div>
            <div class="divide-y divide-slate-100">
                @forelse ($marketplace['recent_orders'] as $order)
                    <div class="flex items-center justify-between gap-4 px-6 py-4">
                        <div class="min-w-0">
                            <p class="truncate text-sm font-semibold text-slate-800">Order #{{ $order->id }}</p>
                            <p class="mt-1 truncate text-xs text-slate-400">{{ $order->client?->name ?? 'Unknown client' }} · {{ $order->store?->store_name ?? 'Unknown store' }}</p>
                        </div>
                        <div class="shrink-0 text-right">
                            <p class="text-sm font-semibold text-slate-800">{{ number_format((float) $order->total_amount, 2) }}</p>
                            <span class="mt-1 inline-block rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-medium capitalize text-slate-500">{{ $order->status }}</span>
                        </div>
                    </div>
                @empty
                    <p class="px-6 py-10 text-center text-sm text-slate-400">No orders have been placed yet.</p>
                @endforelse
            </div>
        </article>

        <article class="rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
            <div class="border-b border-slate-100 px-6 py-5">
                <h2 class="font-semibold text-slate-900">Platform mix</h2>
                <p class="mt-1 text-xs text-slate-400">Current account and catalog status</p>
            </div>
            <div class="space-y-6 px-6 py-6">
                @php
                    $mix = [
                        ['label' => 'Clients', 'value' => $overview['users']['clients'], 'total' => max($overview['users']['total'], 1), 'color' => 'bg-indigo-500'],
                        ['label' => 'Merchants', 'value' => $overview['users']['merchants'], 'total' => max($overview['users']['total'], 1), 'color' => 'bg-violet-500'],
                        ['label' => 'Active products', 'value' => $overview['products']['active'], 'total' => max($overview['products']['total'], 1), 'color' => 'bg-emerald-500'],
                        ['label' => 'Completed orders', 'value' => $overview['orders']['completed'], 'total' => max($overview['orders']['total'], 1), 'color' => 'bg-amber-500'],
                    ];
                @endphp
                @foreach ($mix as $item)
                    <div>
                        <div class="mb-2 flex items-center justify-between text-sm">
                            <span class="font-medium text-slate-600">{{ $item['label'] }}</span>
                            <span class="font-semibold text-slate-900">{{ $item['value'] }}</span>
                        </div>
                        <div class="h-2 overflow-hidden rounded-full bg-slate-100">
                            <div class="{{ $item['color'] }} h-full rounded-full" style="width: {{ min(100, ($item['value'] / $item['total']) * 100) }}%"></div>
                        </div>
                    </div>
                @endforeach
            </div>
        </article>
    </section>
@endsection