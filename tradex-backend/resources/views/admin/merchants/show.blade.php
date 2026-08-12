@extends('admin.layout')

@section('title', $merchant->name)
@section('heading', 'Merchant details')

@section('content')
    @if (session('status'))
        <div class="mb-6 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-medium text-emerald-800" role="status">
            {{ session('status') }}
        </div>
    @endif

    @if ($errors->any())
        <div class="mb-6 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800" role="alert">
            {{ $errors->first() }}
        </div>
    @endif

    <div class="mb-6 flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
            <a href="{{ route('admin.merchants.index') }}" class="text-sm font-semibold text-indigo-600 hover:text-indigo-500">← Back to merchants</a>
            <h2 class="mt-3 text-2xl font-semibold tracking-tight text-slate-900">{{ $merchant->name }}</h2>
            <p class="mt-1 text-sm text-slate-500">Merchant account #{{ $merchant->id }}</p>
        </div>
        @php
            $accountClasses = match ($merchant->status) {
                'active' => 'bg-emerald-50 text-emerald-700',
                'banned' => 'bg-rose-50 text-rose-700',
                default => 'bg-amber-50 text-amber-700',
            };
        @endphp
        <span class="inline-flex w-fit rounded-full px-3 py-1.5 text-xs font-semibold capitalize {{ $accountClasses }}">{{ $merchant->status }} account</span>
    </div>

    <section class="grid gap-6 xl:grid-cols-3">
        <article class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm shadow-slate-200/40">
            <p class="text-xs font-semibold uppercase tracking-wider text-indigo-500">User information</p>
            <dl class="mt-5 space-y-4">
                <div>
                    <dt class="text-xs text-slate-400">Full name</dt>
                    <dd class="mt-1 font-semibold text-slate-900">{{ $merchant->name }}</dd>
                </div>
                <div>
                    <dt class="text-xs text-slate-400">Email</dt>
                    <dd class="mt-1 break-all text-sm font-medium text-slate-700">{{ $merchant->email }}</dd>
                </div>
                <div>
                    <dt class="text-xs text-slate-400">Phone</dt>
                    <dd class="mt-1 text-sm text-slate-700">{{ $merchant->phone ?: 'Not provided' }}</dd>
                </div>
                <div>
                    <dt class="text-xs text-slate-400">Created</dt>
                    <dd class="mt-1 text-sm text-slate-700">{{ $merchant->created_at?->format('M j, Y g:i A') ?? '—' }}</dd>
                </div>
            </dl>
        </article>

        <article class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm shadow-slate-200/40">
            <p class="text-xs font-semibold uppercase tracking-wider text-indigo-500">Store information</p>
            @php
                $store = $merchant->getAttribute('admin_store');
            @endphp
            @if ($store)
                <dl class="mt-5 space-y-4">
                    <div>
                        <dt class="text-xs text-slate-400">Store name</dt>
                        <dd class="mt-1 font-semibold text-slate-900">{{ $store->store_name }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs text-slate-400">Region</dt>
                        <dd class="mt-1 text-sm text-slate-700">{{ $store->region ?: 'Not provided' }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs text-slate-400">Store status</dt>
                        <dd class="mt-1 text-sm capitalize text-slate-700">{{ $store->status }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs text-slate-400">Description</dt>
                        <dd class="mt-1 text-sm leading-6 text-slate-600">{{ $store->description ?: 'No description provided.' }}</dd>
                    </div>
                </dl>
            @else
                <p class="mt-5 text-sm text-slate-400">This merchant has not created a store yet.</p>
            @endif
        </article>

        @php
            $subscription = $merchant->getAttribute('admin_current_subscription');
            $state = $merchant->getAttribute('admin_subscription_state');
            $subscriptionClasses = match ($state) {
                'trial' => 'bg-violet-50 text-violet-700',
                'paid' => 'bg-emerald-50 text-emerald-700',
                'expired_trial', 'expired' => 'bg-amber-50 text-amber-700',
                default => 'bg-slate-100 text-slate-500',
            };
        @endphp
        <article class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm shadow-slate-200/40">
            <div class="flex items-start justify-between gap-3">
                <p class="text-xs font-semibold uppercase tracking-wider text-indigo-500">Current entitlement</p>
                <span class="inline-flex rounded-full px-2.5 py-1 text-[11px] font-semibold {{ $subscriptionClasses }}">{{ $merchant->getAttribute('admin_subscription_label') }}</span>
            </div>
            @if ($subscription)
                <h3 class="mt-5 text-lg font-semibold text-slate-900">{{ $subscription->plan?->display_name ?? 'Plan unavailable' }}</h3>
                <dl class="mt-5 space-y-4">
                    <div>
                        <dt class="text-xs text-slate-400">Type</dt>
                        <dd class="mt-1 text-sm capitalize text-slate-700">{{ $subscription->type }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs text-slate-400">Billing cycle</dt>
                        <dd class="mt-1 text-sm capitalize text-slate-700">{{ $subscription->billing_cycle }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs text-slate-400">Subscription period</dt>
                        <dd class="mt-1 text-sm text-slate-700">
                            {{ $subscription->starts_at?->format('M j, Y') ?? '—' }} → {{ $subscription->ends_at?->format('M j, Y') ?? '—' }}
                        </dd>
                    </div>
                </dl>
            @else
                <p class="mt-5 text-sm leading-6 text-slate-400">No trial or paid subscription has been recorded for this merchant.</p>
            @endif
        </article>
    </section>

    <section class="mt-6 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
        <div class="border-b border-slate-100 px-6 py-5">
            <h2 class="font-semibold text-slate-900">Subscription requests</h2>
            <p class="mt-1 text-xs leading-5 text-slate-400">Payment is verified outside Tradex. Approve only after the external confirmation is complete.</p>
        </div>
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100 text-left">
                <thead class="bg-slate-50">
                    <tr class="text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                        <th class="px-6 py-3">Plan</th>
                        <th class="px-6 py-3">Cycle</th>
                        <th class="px-6 py-3">Payment</th>
                        <th class="px-6 py-3">Status</th>
                        <th class="px-6 py-3">Submitted</th>
                        <th class="px-6 py-3 text-right">Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse ($merchant->getAttribute('admin_subscription_requests') as $request)
                        @php
                            $requestClasses = match ($request->status) {
                                'approved' => 'bg-emerald-50 text-emerald-700',
                                'rejected' => 'bg-rose-50 text-rose-700',
                                default => 'bg-amber-50 text-amber-700',
                            };
                        @endphp
                        <tr class="align-top">
                            <td class="px-6 py-5">
                                <p class="font-medium text-slate-800">{{ $request->plan?->display_name ?? 'Plan unavailable' }}</p>
                                @if ($request->notes)
                                    <p class="mt-1 max-w-xs text-xs leading-5 text-slate-400">{{ $request->notes }}</p>
                                @endif
                            </td>
                            <td class="whitespace-nowrap px-6 py-5 text-sm capitalize text-slate-600">{{ $request->billing_cycle }}</td>
                            <td class="px-6 py-5 text-sm text-slate-600">
                                <p class="capitalize">{{ str_replace('_', ' ', $request->payment_method) }}</p>
                                <p class="mt-1 text-xs text-slate-400">{{ $request->phone }}</p>
                            </td>
                            <td class="px-6 py-5">
                                <span class="inline-flex rounded-full px-2.5 py-1 text-xs font-semibold capitalize {{ $requestClasses }}">{{ $request->status }}</span>
                                @if ($request->rejection_reason)
                                    <p class="mt-2 max-w-xs text-xs leading-5 text-rose-600">{{ $request->rejection_reason }}</p>
                                @endif
                            </td>
                            <td class="whitespace-nowrap px-6 py-5 text-xs text-slate-500">{{ $request->created_at?->format('M j, Y g:i A') ?? '—' }}</td>
                            <td class="px-6 py-5">
                                @if ($request->status === 'pending')
                                    <div class="flex min-w-48 flex-col items-end gap-3">
                                        <form method="POST" action="{{ route('admin.merchants.subscription-requests.approve', [$merchant, $request]) }}">
                                            @csrf
                                            <button type="submit" class="rounded-lg bg-emerald-600 px-3 py-2 text-xs font-semibold text-white transition hover:bg-emerald-500">
                                                Approve & activate
                                            </button>
                                        </form>
                                        <form method="POST" action="{{ route('admin.merchants.subscription-requests.reject', [$merchant, $request]) }}" class="flex w-full gap-2">
                                            @csrf
                                            <input name="rejection_reason" required maxlength="500" placeholder="Reason for rejection"
                                                   class="min-w-0 flex-1 rounded-lg border border-slate-200 px-2.5 py-2 text-xs text-slate-700 outline-none focus:border-rose-400 focus:ring-2 focus:ring-rose-500/10">
                                            <button type="submit" class="rounded-lg border border-rose-200 px-3 py-2 text-xs font-semibold text-rose-700 transition hover:bg-rose-50">Reject</button>
                                        </form>
                                    </div>
                                @else
                                    <span class="text-xs text-slate-400">Reviewed</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-12 text-center text-sm text-slate-400">No subscription requests have been submitted.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </section>

    <section class="mt-6 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
        <div class="border-b border-slate-100 px-6 py-5">
            <h2 class="font-semibold text-slate-900">Subscription history</h2>
            <p class="mt-1 text-xs text-slate-400">Previous periods remain preserved by the entitlement system.</p>
        </div>
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100 text-left">
                <thead class="bg-slate-50">
                    <tr class="text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                        <th class="px-6 py-3">Plan</th>
                        <th class="px-6 py-3">Type</th>
                        <th class="px-6 py-3">Status</th>
                        <th class="px-6 py-3">Start</th>
                        <th class="px-6 py-3">End</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse ($merchant->subscriptions->sortByDesc('starts_at') as $history)
                        <tr class="text-sm">
                            <td class="px-6 py-4 font-medium text-slate-700">{{ $history->plan?->display_name ?? 'Plan unavailable' }}</td>
                            <td class="px-6 py-4 capitalize text-slate-500">{{ $history->type }}</td>
                            <td class="px-6 py-4 capitalize text-slate-500">{{ $history->status }}</td>
                            <td class="px-6 py-4 text-slate-500">{{ $history->starts_at?->format('M j, Y') ?? '—' }}</td>
                            <td class="px-6 py-4 text-slate-500">{{ $history->ends_at?->format('M j, Y') ?? '—' }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-6 py-12 text-center text-sm text-slate-400">No subscription history.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </section>
@endsection