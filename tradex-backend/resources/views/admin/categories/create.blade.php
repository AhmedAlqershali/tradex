@extends('admin.layout')

@section('title', 'New category')
@section('heading', 'Create category')

@section('content')
    <div class="mb-6"><a href="{{ route('admin.categories.index') }}" class="text-sm font-semibold text-indigo-700 hover:text-indigo-900">← Back to categories</a></div>
    @include('admin.categories.form', ['formAction' => route('admin.categories.store'), 'method' => 'POST', 'category' => null, 'submitLabel' => 'Create category'])
@endsection