@extends('admin.layout')

@section('title', 'Commissions')
@section('heading', 'Commission overview')

@section('content')
    <div class="mb-8 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
            <p class="text-sm leading-6 text-slate-500">Platform commissions generated from completed orders.</p>
            <p class="mt-1 text-xs text-slate-400">Read-only view for administrators.</p>
        </div>
        <div class="rounded-xl bg-indigo-50 px-4 py-2 text-sm font-semibold text-indigo-700">{{ $commissions->total() }} commissions</div>
    </div>

    <section class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100 text-left text-sm">
                <thead class="bg-slate-50">
                    <tr class="text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                        <th class="px-6 py-3">Order</th>
                        <th class="px-6 py-3">Merchant</th>
                        <th class="px-6 py-3">Order Amount</th>
                        <th class="px-6 py-3">Rate</th>
                        <th class="px-6 py-3">Commission</th>
                        <th class="px-6 py-3">Merchant Net</th>
                        <th class="px-6 py-3">Status</th>
                        <th class="px-6 py-3">Created</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                @forelse ($commissions as $commission)
                    <tr>
                        <td class="px-6 py-4 font-semibold text-slate-800">#{{ $commission->order_id }}</td>
                        <td class="px-6 py-4">
                            <p class="font-medium text-slate-700">{{ $commission->merchant?->name ?? 'Unknown merchant' }}</p>
                            <p class="text-xs text-slate-400">{{ $commission->store?->store_name ?? 'Store unavailable' }}</p>
                        </td>
                        <td class="px-6 py-4 text-slate-700">{{ number_format((float) $commission->order_amount, 2) }}</td>
                        <td class="px-6 py-4 text-slate-700">{{ number_format((float) $commission->commission_rate, 2) }}%</td>
                        <td class="px-6 py-4 text-slate-700">{{ number_format((float) $commission->commission_amount, 2) }}</td>
                        <td class="px-6 py-4 text-slate-700">{{ number_format((float) $commission->merchant_net_amount, 2) }}</td>
                        <td class="px-6 py-4"><span class="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold capitalize text-slate-600">{{ $commission->status }}</span></td>
                        <td class="px-6 py-4 text-slate-500">{{ $commission->created_at?->format('M j, Y · g:i A') }}</td>
                    </tr>
                @empty
                    <tr><td colspan="8" class="px-6 py-12 text-center text-sm text-slate-400">No commissions have been accrued yet.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
        @if ($commissions->hasPages())
            <div class="border-t border-slate-100 px-6 py-4">{{ $commissions->links() }}</div>
        @endif
    </section>
@endsection
