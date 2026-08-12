<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Tradex administrator sign in">
    <title>Admin sign in · Tradex</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="min-h-screen bg-slate-950 text-slate-100 antialiased">
    <main class="grid min-h-screen lg:grid-cols-[1.1fr_0.9fr]">
        <section class="relative hidden overflow-hidden bg-indigo-700 p-12 lg:flex lg:flex-col lg:justify-between">
            <div class="absolute -right-32 -top-32 h-96 w-96 rounded-full bg-indigo-400/30 blur-3xl"></div>
            <div class="absolute -bottom-40 -left-24 h-96 w-96 rounded-full bg-violet-400/20 blur-3xl"></div>
            <div class="relative">
                <div class="flex items-center gap-3 text-xl font-semibold tracking-tight">
                    <span class="flex h-10 w-10 items-center justify-center rounded-xl bg-white text-indigo-700">T</span>
                    Tradex
                </div>
                <div class="mt-24 max-w-lg">
                    <p class="text-sm font-semibold uppercase tracking-[0.24em] text-indigo-200">Operations console</p>
                    <h1 class="mt-5 text-5xl font-semibold leading-tight tracking-tight text-white">
                        Keep the marketplace moving.
                    </h1>
                    <p class="mt-6 max-w-md text-lg leading-8 text-indigo-100">
                        Monitor platform health, merchants, catalog activity, and orders from one secure workspace.
                    </p>
                </div>
            </div>
            <p class="relative text-sm text-indigo-200">Authorized Tradex administrators only.</p>
        </section>

        <section class="flex items-center justify-center bg-slate-950 px-6 py-12 sm:px-10">
            <div class="w-full max-w-md">
                <div class="mb-10 lg:hidden">
                    <div class="flex items-center gap-3 text-xl font-semibold tracking-tight">
                        <span class="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-500 text-white">T</span>
                        Tradex
                    </div>
                </div>

                <div class="mb-8">
                    <p class="text-sm font-semibold uppercase tracking-[0.2em] text-indigo-400">Admin portal</p>
                    <h2 class="mt-3 text-3xl font-semibold tracking-tight text-white">Welcome back</h2>
                    <p class="mt-3 text-sm leading-6 text-slate-400">Sign in with your active administrator account.</p>
                </div>

                @if ($errors->any())
                    <div class="mb-6 rounded-xl border border-rose-400/30 bg-rose-400/10 px-4 py-3 text-sm text-rose-200" role="alert">
                        {{ $errors->first() }}
                    </div>
                @endif

                <form method="POST" action="{{ route('admin.login.store') }}" class="space-y-5">
                    @csrf
                    <div>
                        <label for="email" class="mb-2 block text-sm font-medium text-slate-200">Email address</label>
                        <input id="email" name="email" type="email" value="{{ old('email') }}" required autofocus autocomplete="email"
                               class="block w-full rounded-xl border border-slate-700 bg-slate-900 px-4 py-3.5 text-white outline-none transition placeholder:text-slate-600 focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15"
                               placeholder="admin@tradex.com">
                    </div>
                    <div>
                        <label for="password" class="mb-2 block text-sm font-medium text-slate-200">Password</label>
                        <input id="password" name="password" type="password" required autocomplete="current-password"
                               class="block w-full rounded-xl border border-slate-700 bg-slate-900 px-4 py-3.5 text-white outline-none transition placeholder:text-slate-600 focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15"
                               placeholder="Enter your password">
                    </div>
                    <label class="flex items-center gap-3 text-sm text-slate-400">
                        <input name="remember" type="checkbox" value="1" class="h-4 w-4 rounded border-slate-600 bg-slate-900 text-indigo-500 focus:ring-indigo-500">
                        Remember this device
                    </label>
                    <button type="submit"
                            class="w-full rounded-xl bg-indigo-500 px-4 py-3.5 text-sm font-semibold text-white shadow-lg shadow-indigo-500/20 transition hover:bg-indigo-400 focus:outline-none focus:ring-4 focus:ring-indigo-500/30">
                        Sign in to dashboard
                    </button>
                </form>

                <p class="mt-8 text-center text-xs leading-5 text-slate-500">
                    Client and merchant accounts use the Tradex mobile experience.
                </p>
            </div>
        </section>
    </main>
</body>
</html>