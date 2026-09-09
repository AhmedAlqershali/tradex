<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="لوحة تحكم Tradex">
    <title>@yield('title', 'Dashboard') · Tradex Admin</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="min-h-screen bg-slate-100 text-slate-900 antialiased" dir="rtl">
    <div class="min-h-screen lg:flex lg:flex-row-reverse">
        <aside class="hidden w-72 shrink-0 flex-col bg-slate-950 text-slate-300 lg:flex">
            <div class="flex h-20 items-center justify-between gap-3 border-b border-white/10 px-7">
                <div class="flex items-center gap-3">
                    <span class="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-500 text-lg font-bold text-white">T</span>
                    <div class="text-right">
                        <p class="font-semibold tracking-tight text-white">Tradex</p>
                        <p class="text-xs text-slate-500">مساحة الإدارة</p>
                    </div>
                </div>
            </div>
            <nav class="flex-1 space-y-1 px-4 py-6" aria-label="Admin navigation">
                <a href="{{ route('admin.dashboard') }}" class="flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-semibold transition {{ request()->routeIs('admin.dashboard') ? 'bg-indigo-500/15 text-indigo-300' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <span class="flex items-center gap-3"><span aria-hidden="true">▦</span> لوحة التحكم</span>
                </a>
                <p class="px-4 pb-2 pt-8 text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-600">الإدارة</p>
                <a href="{{ route('admin.merchants.index') }}" class="flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-medium transition {{ request()->routeIs('admin.merchants.*') && request('section') !== 'subscriptions' ? 'bg-indigo-500/15 text-indigo-300' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <span class="flex items-center gap-3"><span aria-hidden="true">◈</span> التجار</span>
                </a>
                <a href="{{ route('admin.subscriptions.index') }}" class="flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-medium transition {{ request('section') === 'subscriptions' ? 'bg-indigo-500/15 text-indigo-300' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <span class="flex items-center gap-3"><span aria-hidden="true">◌</span> الاشتراكات</span>
                </a>
                <a href="{{ route('admin.stores.index') }}" class="flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-medium transition {{ request()->routeIs('admin.stores.*') ? 'bg-indigo-500/15 text-indigo-300' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <span class="flex items-center gap-3"><span aria-hidden="true">⌂</span> المتاجر</span>
                </a>
                <a href="{{ route('admin.orders.index') }}" class="flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-medium transition {{ request()->routeIs('admin.orders.*') ? 'bg-indigo-500/15 text-indigo-300' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <span class="flex items-center gap-3"><span aria-hidden="true">▤</span> الطلبات</span>
                </a>
                <a href="{{ route('admin.commissions.index') }}" class="flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-medium transition {{ request()->routeIs('admin.commissions.*') ? 'bg-indigo-500/15 text-indigo-300' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <span class="flex items-center gap-3"><span aria-hidden="true">◍</span> العمولات</span>
                </a>
                <a href="{{ route('admin.products.index') }}" class="flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-medium transition {{ request()->routeIs('admin.products.*') ? 'bg-indigo-500/15 text-indigo-300' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <span class="flex items-center gap-3"><span aria-hidden="true">□</span> المنتجات</span>
                </a>
                <a href="{{ route('admin.categories.index') }}" class="flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-medium transition {{ request()->routeIs('admin.categories.*') ? 'bg-indigo-500/15 text-indigo-300' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <span class="flex items-center gap-3"><span aria-hidden="true">◫</span> التصنيفات</span>
                </a>
                <a href="{{ route('admin.users.index') }}" class="flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-medium transition {{ request()->routeIs('admin.users.*') ? 'bg-indigo-500/15 text-indigo-300' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <span class="flex items-center gap-3"><span aria-hidden="true">•</span> المستخدمون</span>
                </a>
                @foreach (['خطط والاشتراكات', 'المراجعات'] as $item)
                    <div class="flex cursor-not-allowed items-center justify-between rounded-xl px-4 py-3 text-sm text-slate-500" aria-disabled="true">
                        <span class="flex items-center gap-3"><span aria-hidden="true">•</span>{{ $item }}</span>
                        <span class="text-[10px] uppercase tracking-wider text-slate-700">قريبًا</span>
                    </div>
                @endforeach
            </nav>
            <div class="border-t border-white/10 p-5">
                <div class="rounded-2xl bg-white/5 p-4 text-right">
                    <p class="text-xs font-medium text-slate-400">تم الدخول بحساب</p>
                    <p class="mt-1 truncate text-sm font-semibold text-white">{{ auth('web')->user()->name }}</p>
                    <p class="mt-1 truncate text-xs text-slate-500">{{ auth('web')->user()->email }}</p>
                </div>
            </div>
        </aside>

        <div class="min-w-0 flex-1">
            <header class="border-b border-slate-200 bg-white">
                <div class="flex min-h-20 items-center justify-between gap-4 px-5 sm:px-8">
                    <div class="text-right">
                        <p class="text-xs font-semibold uppercase tracking-[0.18em] text-indigo-500">Tradex operations</p>
                        <h1 class="mt-1 text-xl font-semibold tracking-tight text-slate-900">@yield('heading', 'Dashboard')</h1>
                    </div>
                    <div class="flex items-center gap-3">
                        <div class="hidden text-right sm:block">
                            <p class="text-sm font-semibold text-slate-800">{{ auth('web')->user()->name }}</p>
                            <p class="text-xs text-slate-500">مسؤول النظام</p>
                        </div>
                        <div class="flex h-10 w-10 items-center justify-center rounded-full bg-indigo-100 font-semibold text-indigo-700">
                            {{ str(auth('web')->user()->name)->substr(0, 1)->upper() }}
                        </div>
                        <form method="POST" action="{{ route('admin.logout') }}">
                            @csrf
                            <button type="submit" class="rounded-lg px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900">
                                تسجيل الخروج
                            </button>
                        </form>
                    </div>
                </div>
                <details class="border-t border-slate-100 lg:hidden">
                    <summary class="cursor-pointer px-5 py-3 text-sm font-semibold text-slate-600">فتح القائمة</summary>
                    <nav class="grid grid-cols-2 gap-2 px-5 pb-4 sm:grid-cols-4" aria-label="Mobile admin navigation">
                        <a href="{{ route('admin.dashboard') }}" class="rounded-lg px-3 py-2 text-sm font-semibold {{ request()->routeIs('admin.dashboard') ? 'bg-indigo-100 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' }}">لوحة التحكم</a>
                        <a href="{{ route('admin.merchants.index') }}" class="rounded-lg px-3 py-2 text-sm font-semibold {{ request()->routeIs('admin.merchants.*') && request('section') !== 'subscriptions' ? 'bg-indigo-100 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' }}">التجار</a>
                        <a href="{{ route('admin.subscriptions.index') }}" class="rounded-lg px-3 py-2 text-sm font-semibold {{ request('section') === 'subscriptions' ? 'bg-indigo-100 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' }}">الاشتراكات</a>
                        <a href="{{ route('admin.stores.index') }}" class="rounded-lg px-3 py-2 text-sm font-semibold {{ request()->routeIs('admin.stores.*') ? 'bg-indigo-100 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' }}">المتاجر</a>
                        <a href="{{ route('admin.orders.index') }}" class="rounded-lg px-3 py-2 text-sm font-semibold {{ request()->routeIs('admin.orders.*') ? 'bg-indigo-100 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' }}">الطلبات</a>
                        <a href="{{ route('admin.commissions.index') }}" class="rounded-lg px-3 py-2 text-sm font-semibold {{ request()->routeIs('admin.commissions.*') ? 'bg-indigo-100 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' }}">العمولات</a>
                        <a href="{{ route('admin.products.index') }}" class="rounded-lg px-3 py-2 text-sm font-semibold {{ request()->routeIs('admin.products.*') ? 'bg-indigo-100 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' }}">المنتجات</a>
                        <a href="{{ route('admin.categories.index') }}" class="rounded-lg px-3 py-2 text-sm font-semibold {{ request()->routeIs('admin.categories.*') ? 'bg-indigo-100 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' }}">التصنيفات</a>
                        <a href="{{ route('admin.users.index') }}" class="rounded-lg px-3 py-2 text-sm font-semibold {{ request()->routeIs('admin.users.*') ? 'bg-indigo-100 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' }}">المستخدمون</a>
                    </nav>
                </details>
            </header>

            <main class="p-5 sm:p-8">
                @yield('content')
            </main>
        </div>
    </div>
</body>
</html>