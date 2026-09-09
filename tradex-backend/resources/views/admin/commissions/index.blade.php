@extends('admin.layout')

@section('title', 'Commission / العمولات')
@section('heading', 'Commission overview / نظرة عامة على العمولات')

@section('content')
    <div class="mb-8 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div class="text-right">
            <p class="text-sm leading-6 text-slate-500">العمولات المولدة من الطلبات المكتملة.</p>
            <p class="mt-1 text-xs text-slate-400">تسجيل الدفع متاح فقط للمشرف، مع مراقبة واضحة للحالة.</p>
        </div>
        <div class="rounded-xl bg-indigo-50 px-4 py-2 text-sm font-semibold text-indigo-700">{{ $commissions->total() }} عمولة</div>
    </div>

    <section class="mb-6 grid gap-4 md:grid-cols-3">
        <div class="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm shadow-slate-200/40">
            <p class="text-xs uppercase tracking-wide text-slate-500">إجمالي العمولات</p>
            <p class="mt-2 text-2xl font-semibold text-slate-900">{{ number_format((float) $commissions->total(), 0) }}</p>
        </div>
        <div class="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm shadow-amber-100/60">
            <p class="text-xs uppercase tracking-wide text-slate-500">غير المدفوعة</p>
            <p class="mt-2 text-2xl font-semibold text-amber-600">{{ number_format((float) $commissions->where('payment_status', 'unpaid')->count(), 0) }}</p>
        </div>
        <div class="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm shadow-emerald-100/60">
            <p class="text-xs uppercase tracking-wide text-slate-500">المدفوعة</p>
            <p class="mt-2 text-2xl font-semibold text-emerald-600">{{ number_format((float) $commissions->where('payment_status', 'paid')->count(), 0) }}</p>
        </div>
    </section>

    <section class="mb-5 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm shadow-slate-200/40">
        <form method="GET" action="{{ route('admin.commissions.index') }}" class="flex flex-col gap-3 md:flex-row md:items-center md:justify-end">
            <input type="text" name="search" value="{{ $search }}" placeholder="ابحث باسم التاجر أو رقم الطلب أو الهاتف" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-indigo-300 focus:bg-white" />
            <select name="payment_status" class="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-indigo-300 focus:bg-white">
                <option value="">كل الحالات</option>
                <option value="unpaid" {{ $paymentStatus === 'unpaid' ? 'selected' : '' }}>لم يتم الدفع</option>
                <option value="paid" {{ $paymentStatus === 'paid' ? 'selected' : '' }}>تم الدفع</option>
            </select>
            <button type="submit" class="rounded-xl bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-indigo-500">تصفية</button>
        </form>
    </section>

    <section class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100 text-right text-sm">
                <thead class="bg-slate-50">
                    <tr class="text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                        <th class="px-6 py-3">الطلب</th>
                        <th class="px-6 py-3">التاجر</th>
                        <th class="px-6 py-3">رقم الهاتف</th>
                        <th class="px-6 py-3">قيمة الطلب</th>
                        <th class="px-6 py-3">نسبة 5%</th>
                        <th class="px-6 py-3">قيمة العمولة</th>
                        <th class="px-6 py-3">صافي التاجر</th>
                        <th class="px-6 py-3">الحالة</th>
                        <th class="px-6 py-3">الإجراء</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                @forelse ($commissions as $commission)
                    <tr>
                        <td class="px-6 py-4 font-semibold text-slate-800">#{{ $commission->order_id }}</td>
                        <td class="px-6 py-4">
                            <p class="font-medium text-slate-700">{{ $commission->merchant?->name ?? 'تاجر غير معروف' }}</p>
                            <p class="text-xs text-slate-400">{{ $commission->store?->store_name ?? 'المتجر غير متوفر' }}</p>
                        </td>
                        <td class="px-6 py-4 text-slate-700">{{ $commission->order?->customer_phone ?? '—' }}</td>
                        <td class="px-6 py-4 text-slate-700">{{ number_format((float) $commission->order_amount, 2) }}</td>
                        <td class="px-6 py-4 text-slate-700">5%</td>
                        <td class="px-6 py-4 text-slate-700">{{ number_format((float) $commission->commission_amount, 2) }}</td>
                        <td class="px-6 py-4 text-slate-700">{{ number_format((float) $commission->merchant_net_amount, 2) }}</td>
                        <td class="px-6 py-4">
                            <span class="rounded-full {{ $commission->payment_status === 'paid' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700' }} px-2.5 py-1 text-xs font-semibold">
                                {{ $commission->payment_status === 'paid' ? 'تم الدفع' : 'لم يتم الدفع' }}
                            </span>
                        </td>
                        <td class="px-6 py-4">
                            @if ($commission->payment_status === 'paid')
                                <span class="text-xs text-slate-500">تم التسجيل</span>
                            @else
                                <form method="POST" action="{{ route('admin.commissions.mark-paid', $commission) }}">
                                    @csrf
                                    <button type="submit" class="rounded-lg bg-emerald-600 px-3 py-2 text-xs font-semibold text-white hover:bg-emerald-500">تسجيل الدفع</button>
                                </form>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="9" class="px-6 py-12 text-center text-sm text-slate-400">لا توجد عمولات مسجلة حتى الآن.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
        @if ($commissions->hasPages())
            <div class="border-t border-slate-100 px-6 py-4">{{ $commissions->links() }}</div>
        @endif
    </section>
@endsection
