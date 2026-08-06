<?php

namespace App\Contracts\Services\AI;

interface AiServiceInterface
{
    public function ask(string $prompt, int $userId, array $options = []): string;
}
