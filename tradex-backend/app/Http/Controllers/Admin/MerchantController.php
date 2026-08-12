<?php

namespace App\Http\Controllers\Admin;

use App\Contracts\Services\SubscriptionRequestServiceInterface;
use App\Contracts\Services\SubscriptionServiceInterface;
use App\Contracts\Services\UserManagementServiceInterface;
use App\Exceptions\SubscriptionException;
use App\Http\Requests\Subscription\RejectSubscriptionRequestRequest;
use App\Models\Subscription;
use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class MerchantController
{
    public function __construct(
        private readonly UserManagementServiceInterface $userService,
        private readonly SubscriptionServiceInterface $subscriptionService,
        private readonly SubscriptionRequestServiceInterface $subscriptionRequestService,
    ) {}

    public function index(Request $request): View
    {
        $paginator = $this->userService->listUsers([
            ...$request->only(['search', 'status', 'per_page']),
            'role' => 'merchant',
        ]);

        $paginator->getCollection()->transform(
            fn (User $merchant): User => $this->decorateMerchant($merchant),
        );

        return view('admin.merchants.index', [
            'merchants' => $paginator,
        ]);
    }

    public function show(int $merchant): View
    {
        $merchantUser = $this->findMerchant($merchant);
        $merchantUser = $this->decorateMerchant($merchantUser);
        $merchantUser->setAttribute(
            'admin_subscription_requests',
            $this->subscriptionRequestService->getForMerchant($merchantUser),
        );

        return view('admin.merchants.show', [
            'merchant' => $merchantUser,
        ]);
    }

    public function approveSubscription(int $merchant, int $subscriptionRequest): RedirectResponse
    {
        $merchantUser = $this->findMerchant($merchant);
        $request = $this->findMerchantSubscriptionRequest($subscriptionRequest, $merchantUser);

        try {
            $this->subscriptionRequestService->approve($request, request()->user());
        } catch (SubscriptionException $exception) {
            return back()->withErrors(['subscription' => $exception->getMessage()]);
        }

        return redirect()
            ->route('admin.merchants.show', $merchantUser)
            ->with('status', 'Subscription approved and activated from the verified external payment.');
    }

    public function rejectSubscription(
        RejectSubscriptionRequestRequest $request,
        int $merchant,
        int $subscriptionRequest,
    ): RedirectResponse {
        $merchantUser = $this->findMerchant($merchant);
        $subscription = $this->findMerchantSubscriptionRequest($subscriptionRequest, $merchantUser);

        try {
            $this->subscriptionRequestService->reject(
                $subscription,
                $request->user(),
                $request->validated('rejection_reason'),
            );
        } catch (SubscriptionException $exception) {
            return back()->withErrors(['subscription' => $exception->getMessage()]);
        }

        return redirect()
            ->route('admin.merchants.show', $merchantUser)
            ->with('status', 'Subscription request rejected.');
    }

    private function findMerchant(int $id): User
    {
        $merchant = $this->userService->findById($id);

        abort_unless($merchant?->isMerchant(), 404, 'Merchant not found.');

        return $merchant;
    }

    private function findMerchantSubscriptionRequest(int $id, User $merchant): SubscriptionRequest
    {
        $subscription = $this->subscriptionRequestService->findById($id);

        abort_unless($subscription && $subscription->user_id === $merchant->id, 404, 'Subscription request not found.');

        return $subscription;
    }

    private function decorateMerchant(User $merchant): User
    {
        $subscription = $this->subscriptionService->getCurrentForMerchant($merchant);
        $merchant->load('stores', 'subscriptions.plan');

        return $merchant
            ->setAttribute('admin_current_subscription', $subscription)
            ->setAttribute('admin_subscription_state', $this->subscriptionState($subscription))
            ->setAttribute('admin_subscription_label', $this->subscriptionLabel($subscription))
            ->setAttribute('admin_store', $merchant->stores->first());
    }

    private function subscriptionState(?Subscription $subscription): string
    {
        if (! $subscription) {
            return 'none';
        }

        if ($subscription->isEntitled()) {
            return $subscription->isTrial() ? 'trial' : 'paid';
        }

        return $subscription->isTrial() ? 'expired_trial' : 'expired';
    }

    private function subscriptionLabel(?Subscription $subscription): string
    {
        return match ($this->subscriptionState($subscription)) {
            'trial' => 'Active trial',
            'paid' => 'Active paid subscription',
            'expired_trial' => 'Expired trial',
            'expired' => 'Expired subscription',
            default => 'No active subscription',
        };
    }
}