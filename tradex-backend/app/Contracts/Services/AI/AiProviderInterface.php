<?php

namespace App\Contracts\Services\AI;

use Generator;

interface AiProviderInterface
{
    public function generateResponse(string $prompt, array $options = []): string;
    public function streamResponse(string $prompt, array $options = []): Generator;
}
