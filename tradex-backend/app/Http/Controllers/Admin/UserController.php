<?php

namespace App\Http\Controllers\Admin;

use App\Contracts\Services\UserManagementServiceInterface;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class UserController extends Controller
{
    private UserManagementServiceInterface $userService;

    public function __construct(UserManagementServiceInterface $userService)
    {
        $this->userService = $userService;
    }

    public function index(Request $request): View
    {
        return view('admin.users.index', [
            'users' => $this->userService->listUsers(
                $request->only(['search', 'role', 'status', 'per_page']),
            ),
        ]);
    }

    public function destroy(Request $request, User $user): RedirectResponse
    {
        if ($user->id === $request->user()->id) {
            return back()->withErrors(['user' => 'You cannot delete your own account.']);
        }

        $this->authorize('delete', $user);

        try {
            $this->userService->deleteUser($user);
        } catch (\Throwable $exception) {
            return back()->withErrors(['user' => $exception->getMessage()]);
        }

        return redirect()->route('admin.users.index')
            ->with('status', 'User and associated data deleted successfully.');
    }
}
