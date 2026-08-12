@extends('admin.layout')

@section('title', 'Edit category')
@section('heading', 'Edit category')

@section('content')
    <div class="mb-6"><a href="{{ route('admin.categories.index') }}" class="text-sm font-semibold text-indigo-700 hover:text-indigo-900">← Back to categories</a></div>
    @include('admin.categories.form', ['formAction' => route('admin.categories.update', $category), 'method' => 'PUT', 'category' => $category, 'submitLabel' => 'Save changes'])
@endsection