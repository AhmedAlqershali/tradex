<?php

namespace App\Services\AI;

use App\Contracts\Services\AI\AiServiceInterface;
use App\Contracts\Services\AI\AiProviderInterface;
use App\Contracts\Services\AI\AiUsageServiceInterface;
use App\Exceptions\AiNotImplementedException;

class AiService implements AiServiceInterface
{
    protected AiProviderInterface $provider;
    protected AiUsageServiceInterface $usageService;

    public function __construct(AiProviderInterface $provider, AiUsageServiceInterface $usageService)
    {
        $this->provider = $provider;
        $this->usageService = $usageService;
    }

    public function ask(string $prompt, int $userId, array $options = []): string
    {
        if (!$this->usageService->hasAvailableQuota($userId)) {
            throw new \RuntimeException("AI Usage limit reached for this user.");
        }

        try {
            $response = $this->provider->generateResponse($prompt, $options);
            $this->usageService->logUsage($userId, $prompt, $response);
            return $response;
        } catch (AiNotImplementedException $e) {
            return "نظام الذكاء الاصطناعي قيد الإعداد حالياً. يرجى المحاولة لاحقاً.";
        }
    }
}
