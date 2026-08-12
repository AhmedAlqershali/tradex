@extends('admin.layout')

@section('title', 'Merchants')
@section('heading', 'Merchant management')

@section('content')
    <div class="mb-8 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
            <p class="text-sm leading-6 text-slate-500">Review merchant accounts, stores, and access periods.</p>
            <p class="mt-1 text-xs text-slate-400">Data is read from the Laravel database at request time.</p>
        </div>
        <div class="rounded-xl bg-indigo-50 px-4 py-2 text-sm font-semibold text-indigo-700">
            {{ $merchants->total() }} merchants
        </div>
    </div>

    <section class="mb-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm shadow-slate-200/40">
        <form method="GET" action="{{ route('admin.merchants.index') }}" class="grid gap-4 md:grid-cols-[1fr_220px_auto] md:items-end">
            <div>
                <label for="search" class="mb-2 block text-xs font-semibold uppercase tracking-wider text-slate-500">Search merchants</label>
                <input id="search" name="search" value="{{ request('search') }}" type="search"
                       placeholder="Name, email, or phone"
                       class="block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-indigo-400 focus:bg-white focus:ring-4 focus:ring-indigo-500/10">
            </div>
            <div>
                <label for="status" class="mb-2 block text-xs font-semibold uppercase tracking-wider text-slate-500">Account status</label>
                <select id="status" name="status"
                        class="block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-900 outline-none focus:border-indigo-400 focus:bg-white focus:ring-4 focus:ring-indigo-500/10">
                    <option value="">All statuses</option>
                    @foreach (['active', 'inactive', 'banned'] as $status)
                        <option value="{{ $status }}" @selected(request('status') === $status)>{{ ucfirst($status) }}</option>
                    @endforeach
                </select>
            </div>
            <button type="submit" class="rounded-xl bg-slate-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-700">
                Apply filters
            </button>
        </form>
    </section>

    <section id="subscriptions" class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
        <div class="flex items-center justify-between border-b border-slate-100 px-6 py-5">
            <div>
                <h2 class="font-semibold text-slate-900">All merchants</h2>
                <p class="mt-1 text-xs text-slate-400">Subscription status reflects the latest entitlement period.</p>
            </div>
            <span class="rounded-lg bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500">Page {{ $merchants->currentPage() }}</span>
        </div>

        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100 text-left">
                <thead class="bg-slate-50">
                    <tr class="text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                        <th class="px-6 py-3">Merchant</th>
                        <th class="px-6 py-3">Store</th>
                        <th class="px-6 py-3">Account</th>
                        <th class="px-6 py-3">Subscription</th>
                        <th class="px-6 py-3">Period</th>
                        <th class="px-6 py-3">Created</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse ($merchants as $merchant)
                        @php
                            $subscription = $merchant->getAttribute('admin_current_subscription');
                            $store = $merchant->getAttribute('admin_store');
                            $state = $merchant->getAttribute('admin_subscription_state');
                        @endphp
                        <tr class="align-top transition hover:bg-slate-50/80">
                            <td class="px-6 py-5">
                                <a href="{{ route('admin.merchants.show', $merchant) }}" class="font-semibold text-slate-900 hover:text-indigo-600">{{ $merchant->name }}</a>
                                <p class="mt-1 text-xs text-slate-500">{{ $merchant->email }}</p>
                                @if ($merchant->phone)
                                    <p class="mt-1 text-xs text-slate-400">{{ $merchant->phone }}</p>
                                @endif
                            </td>
                            <td class="px-6 py-5">
                                @if ($store)
                                    <p class="font-medium text-slate-700">{{ $store->store_name }}</p>
                                    <p class="mt-1 text-xs capitalize text-slate-400">{{ $store->status }}</p>
                                @else
                                    <span class="text-sm text-slate-400">No store</span>
                                @endif
                            </td>
                            <td class="px-6 py-5">
                                @php
                                    $accountClasses = match ($merchant->status) {
                                        'active' => 'bg-emerald-50 text-emerald-700',
                                        'banned' => 'bg-rose-50 text-rose-700',
                                        default => 'bg-amber-50 text-amber-700',
                                    };
                                @endphp
                                <span class="inline-flex rounded-full px-2.5 py-1 text-xs font-semibold capitalize {{ $accountClasses }}">{{ $merchant->status }}</span>
                            </td>
                            <td class="px-6 py-5">
                                @php
                                    $subscriptionClasses = match ($state) {
                                        'trial' => 'bg-violet-50 text-violet-700',
                                        'paid' => 'bg-emerald-50 text-emerald-700',
                                        'expired_trial', 'expired' => 'bg-amber-50 text-amber-700',
                                        default => 'bg-slate-100 text-slate-500',
                                    };
                                @endphp
                                <span class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-semibold {{ $subscriptionClasses }}">{{ $merchant->getAttribute('admin_subscription_label') }}</span>
                                @if ($subscription?->plan)
                                    <p class="mt-2 text-xs text-slate-500">{{ $subscription->plan->display_name }}</p>
                                @endif
                            </td>
                            <td class="whitespace-nowrap px-6 py-5 text-xs text-slate-500">
                                @if ($subscription)
                                    <p>Starts {{ $subscription->starts_at?->format('M j, Y') ?? '—' }}</p>
                                    <p class="mt-1">Ends {{ $subscription->ends_at?->format('M j, Y') ?? '—' }}</p>
                                @else
                                    <span>—</span>
                                @endif
                            </td>
                            <td class="whitespace-nowrap px-6 py-5 text-xs text-slate-500">{{ $merchant->created_at?->format('M j, Y') ?? '—' }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-14 text-center text-sm text-slate-400">No merchants match the current filters.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if ($merchants->hasPages())
            <div class="border-t border-slate-100 px-6 py-4">{{ $merchants->links() }}</div>
        @endif
    </section>
@endsection