<?php

namespace App\Http\Controllers\Admin;

use App\Contracts\Services\CategoryServiceInterface;
use App\Exceptions\CategoryException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Category\StoreCategoryRequest;
use App\Http\Requests\Category\UpdateCategoryRequest;
use App\Models\Category;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class CategoryController extends Controller
{
    public function __construct(
        private readonly CategoryServiceInterface $categoryService,
    ) {}

    public function index(Request $request): View
    {
        $this->authorize('viewAny', Category::class);

        return view('admin.categories.index', [
            'categories' => $this->categoryService->listAll(
                $request->only(['search', 'status', 'per_page']),
            ),
            'statuses' => ['active', 'inactive'],
        ]);
    }

    public function create(): View
    {
        $this->authorize('create', Category::class);

        return view('admin.categories.create');
    }

    public function store(StoreCategoryRequest $request): RedirectResponse
    {
        $this->authorize('create', Category::class);
        $this->categoryService->create($request->validated(), $request->file('image'));

        return redirect()->route('admin.categories.index')->with('status', 'Category created.');
    }

    public function edit(int $category): View
    {
        $model = $this->findCategory($category);
        $this->authorize('update', $model);

        return view('admin.categories.edit', ['category' => $model]);
    }

    public function update(UpdateCategoryRequest $request, int $category): RedirectResponse
    {
        $model = $this->findCategory($category);
        $this->authorize('update', $model);
        $this->categoryService->update($model, $request->validated(), $request->file('image'));

        return redirect()->route('admin.categories.index')->with('status', 'Category updated.');
    }

    public function destroy(int $category): RedirectResponse
    {
        $model = $this->findCategory($category);
        $this->authorize('delete', $model);

        try {
            $this->categoryService->delete($model);
        } catch (CategoryException $exception) {
            return back()->withErrors(['category' => $exception->getMessage()]);
        }

        return redirect()->route('admin.categories.index')->with('status', 'Category deleted.');
    }

    private function findCategory(int $id): Category
    {
        try {
            $category = $this->categoryService->findById($id);
        } catch (ModelNotFoundException) {
            $category = null;
        }

        abort_unless($category, 404, 'Category not found.');

        return $category;
    }
}