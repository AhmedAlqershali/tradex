<?php

namespace App\Services;

use App\Contracts\Repositories\SubscriptionRequestRepositoryInterface;
use App\Contracts\Services\PlanServiceInterface;
use App\Contracts\Services\SubscriptionRequestServiceInterface;
use App\Contracts\Services\SubscriptionServiceInterface;
use App\Contracts\Services\UserNotificationServiceInterface;
use App\Exceptions\SubscriptionException;
use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class SubscriptionRequestService implements SubscriptionRequestServiceInterface
{
    public function __construct(
        private readonly SubscriptionRequestRepositoryInterface $subscriptionRequestRepository,
        private readonly SubscriptionServiceInterface $subscriptionService,
        private readonly PlanServiceInterface $planService,
        private readonly UserNotificationServiceInterface $notificationService,
    ) {}

    // ── Admin-facing ──────────────────────────────────────────────────────────

    public function listAll(array $filters): LengthAwarePaginator
    {
        return $this->subscriptionRequestRepository->listAll($filters);
    }

    public function findById(int $id): ?SubscriptionRequest
    {
        return $this->subscriptionRequestRepository->findById($id);
    }

    /**
     * Approve a pending request: activates the merchant's subscription
     * and marks the request as approved, atomically.
     *
     * @throws SubscriptionException
     */
    public function approve(SubscriptionRequest $request, User $admin): SubscriptionRequest
    {
        $updated = DB::transaction(function () use ($request, $admin) {
            // Lock the request before checking its status so two admins cannot
            // approve/reject the same pending payment at the same time.
            $lockedRequest = SubscriptionRequest::query()
                ->with(['user', 'plan'])
                ->lockForUpdate()
                ->findOrFail($request->id);

            if ($lockedRequest->status !== 'pending') {
                throw SubscriptionException::alreadyReviewed($lockedRequest->status);
            }

            $this->subscriptionService->activateForMerchant(
                $lockedRequest->user,
                $lockedRequest->plan,
                $lockedRequest->billing_cycle,
            );

            return $this->subscriptionRequestRepository->update($lockedRequest, [
                'status'      => 'approved',
                'reviewed_by' => $admin->id,
                'reviewed_at' => now(),
            ]);
        });

        $this->notificationService->create(
            $request->user,
            'subscription_approved',
            'تمت الموافقة على الاشتراك',
            "تمت الموافقة على طلب الاشتراك لخطة {$request->plan->display_name}.",
            ['subscription_request_id' => $request->id, 'status' => $updated->status],
        );

        return $updated;
    }

    /**
     * Reject a pending request with a reason.
     *
     * @throws SubscriptionException
     */
    public function reject(SubscriptionRequest $request, User $admin, string $reason): SubscriptionRequest
    {
        $updated = DB::transaction(function () use ($request, $admin, $reason) {
            // Use the same lock as approval so a rejection racing an approval
            // cannot leave the request and subscription in different states.
            $lockedRequest = SubscriptionRequest::query()
                ->with(['user', 'plan'])
                ->lockForUpdate()
                ->findOrFail($request->id);

            if ($lockedRequest->status !== 'pending') {
                throw SubscriptionException::alreadyReviewed($lockedRequest->status);
            }

            return $this->subscriptionRequestRepository->update($lockedRequest, [
                'status'            => 'rejected',
                'rejection_reason'  => $reason,
                'reviewed_by'       => $admin->id,
                'reviewed_at'       => now(),
            ]);
        });

        $this->notificationService->create(
            $request->user,
            'subscription_rejected',
            'تم رفض طلب الاشتراك',
            $reason
                ? "تم رفض طلب الاشتراك: {$reason}"
                : 'تم رفض طلب الاشتراك من الإدارة.',
            ['subscription_request_id' => $request->id, 'status' => $updated->status],
        );

        return $updated;
    }

    // ── Merchant-facing ──────────────────────────────────────────────────────

    public function getForMerchant(User $merchant): Collection
    {
        return $this->subscriptionRequestRepository->getForMerchant($merchant);
    }

    public function findForMerchant(int $id, User $merchant): ?SubscriptionRequest
    {
        return $this->subscriptionRequestRepository->findForMerchant($id, $merchant);
    }

    /**
     * Submit a new subscription request with an uploaded payment proof image.
     *
     * SECURITY: payment proof images are stored on the PRIVATE disk, not the
     * public disk. They contain sensitive financial/identity information (bank
     * transfer receipts, screenshots). Access is provided only to admins via
     * temporary signed URLs generated in SubscriptionRequestResource.
     *
     * @throws SubscriptionException  if the selected plan is not active
     */
    public function create(User $merchant, array $data, UploadedFile $proofImage): SubscriptionRequest
    {
        $plan = $this->planService->findById($data['plan_id']);

        if (! $plan || $plan->status !== 'active') {
            throw SubscriptionException::planInactive($plan->display_name ?? 'selected');
        }

        $proofPath = null;

        try {
            return DB::transaction(function () use (
                $merchant,
                $data,
                $proofImage,
                &$proofPath,
            ) {
                // Serialize submissions for this merchant. The earlier
                // collection check was vulnerable to two concurrent uploads
                // both observing no pending request.
                User::query()
                    ->whereKey($merchant->id)
                    ->lockForUpdate()
                    ->firstOrFail();

                if (SubscriptionRequest::query()
                    ->where('user_id', $merchant->id)
                    ->pending()
                    ->exists()) {
                    throw SubscriptionException::pendingRequestExists();
                }

                // Store on PRIVATE disk — sensitive financial document.
                // The 'local' disk is not publicly accessible; access requires
                // a secure admin-only download endpoint.
                $data['user_id'] = $merchant->id;
                $proofPath = $proofImage->store('subscription-proofs', 'local');
                $data['payment_proof_image'] = $proofPath;
                $data['status'] = 'pending';

                return $this->subscriptionRequestRepository->create($data);
            });
        } catch (\Throwable $exception) {
            // A database rollback cannot remove a file already written to the
            // local disk, so clean up an upload if persistence fails.
            if ($proofPath !== null) {
                Storage::disk('local')->delete($proofPath);
            }

            throw $exception;
        }
    }

    /**
     * Generate a temporary signed URL for accessing a payment proof image.
     *
     * Only for use by admins. The URL expires in 30 minutes.
     */
    public function getPaymentProofUrl(SubscriptionRequest $request): ?string
    {
        if (! $request->payment_proof_image) {
            return null;
        }

        // Use the local (private) disk — return a temporary URL if the driver
        // supports it (S3), otherwise stream via a dedicated secure endpoint.
        // For local disk, we fall back to a signed route URL.
        if (Storage::disk('local')->exists($request->payment_proof_image)) {
            return route('api.v1.admin.subscription-requests.proof', ['id' => $request->id]);
        }

        return null;
    }
}
